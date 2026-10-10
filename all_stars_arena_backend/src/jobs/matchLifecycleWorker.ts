import cron from 'node-cron';
import { dbPool } from '../config/db.config.js';
import { env } from '../config/env.config.js';
import { getSocketIO } from '../config/socket.config.js';
import { logger } from '../utils/logger.js';
import { CctvService } from '../modules/cctv/cctv.service.js';
import { CctvRecordingService } from '../services/cctvRecording.service.js';

/**
 * Single Reconciliation & Lifecycle Execution Pass (Restart-Safe & Idempotent)
 */
export const runLifecycleCycle = async () => {
  const client = await dbPool.connect();
  try {
    // -------------------------------------------------------------
    // PHASE 0: AUTOMATIC UNAPPROVED MATCH CANCELLATION & WALLET REFUNDS
    // -------------------------------------------------------------
    await client.query('BEGIN');

    // Ensure cancellation_reason column exists on public.games
    await client.query('ALTER TABLE public.games ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;');

    const unapprovedGames = await client.query(
      `SELECT g.id, g.creator_id, g.title, g.entry_fee, g.match_date, g.start_time
       FROM public.games g
       WHERE g.approval_status = 'PENDING_APPROVAL' AND g.status <> 'CANCELLED'
         AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`
    );

    for (const game of unapprovedGames.rows) {
      await client.query(
        `UPDATE public.games
         SET status = 'CANCELLED',
             approval_status = 'REJECTED',
             rejection_reason = 'Auto-cancelled: Game was not approved by manager before scheduled start time',
             cancellation_reason = 'Auto-cancelled: Game was not approved by manager before scheduled start time',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id]
      );

      logger.info(`🚫 [LifecycleWorker] Auto-cancelled unapproved game ${game.id} ("${game.title}") past scheduled start time`);

      const paidPlayers = await client.query(
        `SELECT gp.user_id, COALESCE(g.entry_fee, 0) as refund_amount
         FROM public.game_players gp
         JOIN public.games g ON g.id = gp.game_id
         WHERE gp.game_id = $1 AND gp.payment_status = 'PAID';`,
        [game.id]
      );

      for (const player of paidPlayers.rows) {
        const refundAmt = Number(player.refund_amount);
        if (refundAmt > 0) {
          await client.query(
            `INSERT INTO public.wallets (user_id, balance)
             VALUES ($1, $2)
             ON CONFLICT (user_id)
             DO UPDATE SET balance = public.wallets.balance + $2, updated_at = CURRENT_TIMESTAMP;`,
            [player.user_id, refundAmt]
          );

          await client.query(
            `INSERT INTO public.wallet_transactions (
               wallet_id, user_id, type, amount, status, description
             ) VALUES (
               (SELECT id FROM public.wallets WHERE user_id = $1),
               $1, 'REFUND', $2, 'SUCCESS',
               $3
             );`,
            [
              player.user_id,
              refundAmt,
              `Automated refund: Match "${game.title}" was auto-cancelled due to manager non-approval`,
            ]
          );

          await client.query(
            `UPDATE public.game_players
             SET payment_status = 'REFUNDED', updated_at = CURRENT_TIMESTAMP
             WHERE game_id = $1 AND user_id = $2;`,
            [game.id, player.user_id]
          );

          logger.info(`💰 [LifecycleWorker] Refunded ₹${refundAmt} to user ${player.user_id} for auto-cancelled game ${game.id}`);
        }
      }

      try {
        const io = getSocketIO();
        io.emit('match:cancelled', {
          gameId: game.id,
          status: 'CANCELLED',
          reason: 'Auto-cancelled: Not approved before scheduled start time',
        });
      } catch (_) {}
    }

    await client.query('COMMIT');

    // -------------------------------------------------------------
    // PHASE 12 & 31: AUTOMATIC MATCH START + CCTV RECORDING START
    // -------------------------------------------------------------
    await client.query('BEGIN');

    const startingGames = await client.query(
      `SELECT g.id, g.club_id, g.court_id, g.title, g.match_date, g.start_time, g.end_time
       FROM public.games g
       WHERE g.approval_status = 'APPROVED'
         AND g.status IN ('OPEN_FOR_JOINING', 'FULL')
         AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP
         AND (g.match_date + g.end_time) > CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`
    );

    const gamesToRecord: Array<{ gameId: string; cameraId: string }> = [];

    for (const game of startingGames.rows) {
      // 1. Update Game to ONGOING (STARTED)
      await client.query(
        `UPDATE public.games
         SET status = 'ONGOING', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id]
      );

      logger.info(`⚽ [LifecycleWorker] Auto-started match ${game.id} ("${game.title}") to ONGOING`);

      // 2. Identify Camera for Court/Club
      try {
        const camRes = await client.query(
          `SELECT id, is_enabled FROM public.cctv_cameras
           WHERE (court_id = $1 OR (club_id = $2 AND court_id IS NULL))
             AND is_enabled = true
           ORDER BY court_id NULLS LAST
           LIMIT 1;`,
          [game.court_id, game.club_id]
        );

        if (camRes.rows.length > 0) {
          const camera = camRes.rows[0];

          // Check if recording already exists for this game (idempotent)
          const existingRec = await client.query(
            `SELECT id FROM public.cctv_recordings WHERE game_id = $1 LIMIT 1;`,
            [game.id]
          );

          if (existingRec.rows.length === 0) {
            gamesToRecord.push({ gameId: game.id, cameraId: camera.id });
          }
        }
      } catch (cctvErr: any) {
        logger.error({ cctvErr }, `Failed to query camera for game ${game.id}`);
      }

      // 3. Create Notifications for Manager and Roster Players
      try {
        const courtName = game.court_id === 'court_2' ? 'Court 2' : 'Court 1';

        // Notify managers
        const managers = await client.query(
          `SELECT user_id FROM public.club_managers WHERE club_id = $1;`,
          [game.club_id]
        );
        for (const mgr of managers.rows) {
          await client.query(
            `INSERT INTO public.notifications (user_id, title, body, message, type, data)
             VALUES ($1, $2, $3, $3, 'MATCH_AUTO_STARTED', $4);`,
            [
              mgr.user_id,
              '⚽ Match Auto-Started',
              `Match "${game.title}" on ${courtName} has auto-started at scheduled start time!`,
              JSON.stringify({ gameId: game.id, route: '/manager/games/details' }),
            ]
          );
        }

        // Notify roster players
        const players = await client.query(
          `SELECT user_id FROM public.game_players WHERE game_id = $1;`,
          [game.id]
        );
        for (const ply of players.rows) {
          await client.query(
            `INSERT INTO public.notifications (user_id, title, body, message, type, data)
             VALUES ($1, $2, $3, $3, 'MATCH_AUTO_STARTED', $4);`,
            [
              ply.user_id,
              '⚽ Kick-off! Match Started',
              `Your match "${game.title}" on ${courtName} has officially started! Good luck!`,
              JSON.stringify({ gameId: game.id, route: '/games/details' }),
            ]
          );
        }
      } catch (notifErr: any) {
        logger.error({ notifErr }, `Failed to create auto-start notifications for game ${game.id}`);
      }

      // 4. Emit Real-time Socket Event
      try {
        const io = getSocketIO();
        io.to(`game:${game.id}`).emit('match:started', {
          gameId: game.id,
          status: 'ONGOING',
          message: 'Match has started!',
        });
        io.emit('match:live_feed', {
          gameId: game.id,
          status: 'ONGOING',
          eventText: `⚽ KICK-OFF: ${game.title}`,
        });
      } catch (sockErr: any) {
        // Socket errors should never abort DB transaction
      }
    }

    await client.query('COMMIT');

    // Trigger real CCTV recordings now that games are committed as ONGOING
    for (const item of gamesToRecord) {
      try {
        await CctvService.startMatchRecording(
          'SYSTEM_WORKER',
          'Auto Lifecycle Worker',
          1,
          item.gameId,
          item.cameraId
        );
        logger.info(`📹 [LifecycleWorker] Auto-triggered CCTV recording for Match ${item.gameId}`);
      } catch (cctvStartErr: any) {
        logger.error({ cctvStartErr }, `[LifecycleWorker] Could not start CCTV recording for game ${item.gameId}`);
      }
    }

    // -------------------------------------------------------------
    // PHASE 13 & 32: AUTOMATIC MATCH END
    // -------------------------------------------------------------
    await client.query('BEGIN');

    const endingGames = await client.query(
      `SELECT g.id, g.club_id, g.court_id, g.title, g.match_date, g.end_time
       FROM public.games g
       WHERE g.status = 'ONGOING'
         AND (g.match_date + g.end_time) <= CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`
    );

    const postMatchMinutes = env.RECORDING_POST_MATCH_MINUTES || 15;

    for (const game of endingGames.rows) {
      await client.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id]
      );

      logger.info(`🏁 [LifecycleWorker] Auto-completed match ${game.id} ("${game.title}") to COMPLETED`);

      // Switch active CCTV recording to POST_MATCH (recording up to end + 15 mins)
      await client.query(
        `UPDATE public.cctv_recordings
         SET recording_status = 'POST_MATCH',
             stop_deadline = CURRENT_TIMESTAMP + ($2 || ' minutes')::interval,
             post_match_stop_at = CURRENT_TIMESTAMP + ($2 || ' minutes')::interval
         WHERE game_id = $1 AND (status = 'RECORDING' OR recording_status = 'RECORDING');`,
        [game.id, postMatchMinutes]
      );

      try {
        const io = getSocketIO();
        io.to(`game:${game.id}`).emit('match:completed', {
          gameId: game.id,
          status: 'COMPLETED',
          message: 'Match full-time reached. Final score submission open.',
        });
        io.emit('match:live_feed', {
          gameId: game.id,
          status: 'COMPLETED',
          eventText: `🏁 FULL-TIME: ${game.title}`,
        });
      } catch (sockErr) {}
    }

    await client.query('COMMIT');

    // -------------------------------------------------------------
    // PHASE 32 & 40: CCTV AUTO-STOP AT MATCH_END + 15 MINUTES
    // -------------------------------------------------------------
    await client.query('BEGIN');

    const expiredRecordings = await client.query(
      `SELECT rec.id, rec.game_id
       FROM public.cctv_recordings rec
       WHERE (rec.status = 'RECORDING' OR rec.recording_status IN ('RECORDING', 'POST_MATCH'))
         AND (
           rec.stop_deadline <= CURRENT_TIMESTAMP
           OR rec.post_match_stop_at <= CURRENT_TIMESTAMP
         )
       FOR UPDATE SKIP LOCKED;`
    );

    const recsToStop = expiredRecordings.rows;
    await client.query('COMMIT');

    for (const rec of recsToStop) {
      logger.info(`🛑 [LifecycleWorker] CCTV Auto-stopping recording ${rec.id} for Game ${rec.game_id} (15-min post-match window expired)`);
      try {
        await CctvRecordingService.stopRecording(rec.id, {
          userId: 'SYSTEM_LIFECYCLE_WORKER',
          reason: 'LIFECYCLE_POST_MATCH_DEADLINE_EXPIRED',
          manualStop: false,
        });
      } catch (stopErr: any) {
        logger.error({ stopErr }, `Failed to auto-stop recording ${rec.id}`);
      }
    }
  } catch (err: any) {
    await client.query('ROLLBACK').catch(() => {});
    logger.error({ err }, 'Error executing Match Lifecycle & CCTV Worker cycle');
  } finally {
    client.release();
  }
};

/**
 * Start Scheduled Match Lifecycle & CCTV Recording Job
 */
export const startMatchLifecycleWorker = () => {
  // 1. Run immediately on boot to reconcile state after any server restart
  runLifecycleCycle().catch((err) => {
    logger.error({ err }, 'Initial lifecycle reconciliation cycle failed on boot');
  });

  // 2. Schedule to run every 30 seconds
  cron.schedule('*/30 * * * * *', async () => {
    await runLifecycleCycle();
  });

  logger.info('⏱️ [Worker] Match Lifecycle & CCTV Auto-Worker scheduled (every 30s + restart-safe)');
};
