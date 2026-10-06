import cron from 'node-cron';
import { dbPool } from '../config/db.config.js';
import { getSocketIO } from '../config/socket.config.js';
import { logger } from '../utils/logger.js';

/**
 * Single Reconciliation & Lifecycle Execution Pass (Restart-Safe & Idempotent)
 */
export const runLifecycleCycle = async () => {
  const client = await dbPool.connect();
  try {
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

    for (const game of startingGames.rows) {
      // 1. Update Game to ONGOING (STARTED)
      await client.query(
        `UPDATE public.games
         SET status = 'ONGOING', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id]
      );

      logger.info(`⚽ [LifecycleWorker] Auto-started match ${game.id} ("${game.title}") to ONGOING`);

      // 2. Trigger CCTV Recording if Camera Configured for Court/Club
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
            const s3Key = `recordings/${game.club_id}/${game.id}_${Date.now()}.mp4`;
            await client.query(
              `INSERT INTO public.cctv_recordings (
                game_id, club_id, court_id, camera_id,
                start_time, started_at,
                scheduled_match_end, scheduled_match_end_at,
                stop_deadline, post_match_stop_at,
                s3_object_key, storage_object_key,
                status, recording_status
              ) VALUES (
                $1, $2, $3, $4,
                CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
                ($5::date + $6::time), ($5::date + $6::time),
                ($5::date + $6::time + INTERVAL '10 minutes'), ($5::date + $6::time + INTERVAL '10 minutes'),
                $7, $7,
                'RECORDING', 'RECORDING'
              ) ON CONFLICT DO NOTHING;`,
              [game.id, game.club_id, game.court_id, camera.id, game.match_date, game.end_time, s3Key]
            );

            logger.info(`📹 [LifecycleWorker] Auto-triggered CCTV recording for Match ${game.id} on Court ${game.court_id}`);
          }
        }
      } catch (cctvErr: any) {
        logger.error({ cctvErr }, `Failed to initialize CCTV for game ${game.id}`);
      }

      // 3. Emit Real-time Socket Event
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

    for (const game of endingGames.rows) {
      await client.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id]
      );

      logger.info(`🏁 [LifecycleWorker] Auto-completed match ${game.id} ("${game.title}") to COMPLETED`);

      // Switch active CCTV recording to POST_MATCH (recording up to end + 10 mins)
      await client.query(
        `UPDATE public.cctv_recordings
         SET recording_status = 'POST_MATCH'
         WHERE game_id = $1 AND (status = 'RECORDING' OR recording_status = 'RECORDING');`,
        [game.id]
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
    // PHASE 32 & 40: CCTV AUTO-STOP AT MATCH_END + 10 MINUTES
    // -------------------------------------------------------------
    await client.query('BEGIN');

    const expiredRecordings = await client.query(
      `SELECT rec.id, rec.game_id, rec.club_id, rec.court_id, rec.s3_object_key,
              COALESCE(rec.storage_object_key, rec.s3_object_key) as final_s3_key
       FROM public.cctv_recordings rec
       WHERE (rec.status = 'RECORDING' OR rec.recording_status IN ('RECORDING', 'POST_MATCH'))
         AND (
           rec.stop_deadline <= CURRENT_TIMESTAMP
           OR rec.post_match_stop_at <= CURRENT_TIMESTAMP
         )
       FOR UPDATE SKIP LOCKED;`
    );

    for (const rec of expiredRecordings.rows) {
      logger.info(`🛑 [LifecycleWorker] CCTV Auto-stopping recording ${rec.id} for Game ${rec.game_id} (10-min window expired)`);

      await client.query(
        `UPDATE public.cctv_recordings
         SET status = 'COMPLETED', recording_status = 'COMPLETED',
             actual_stop_time = CURRENT_TIMESTAMP, actual_stopped_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [rec.id]
      );

      // Save metadata into game_videos
      await client.query(
        `INSERT INTO public.game_videos (game_id, club_id, court_id, title, video_url, status)
         VALUES ($1, $2, $3, $4, $5, 'AVAILABLE')
         ON CONFLICT DO NOTHING;`,
        [rec.game_id, rec.club_id, rec.court_id, `Match Recording - Game ${rec.game_id}`, rec.final_s3_key]
      );

      // Audit log
      await client.query(
        `INSERT INTO public.audit_logs (admin_name, action, target, details)
         VALUES ('SYSTEM_LIFECYCLE_WORKER', 'AUTO_STOP_CCTV', $1, $2);`,
        [`Recording:${rec.id}`, `Auto-stopped CCTV recording after 10-minute post-match window expired`]
      );

      try {
        const io = getSocketIO();
        io.to(`game:${rec.game_id}`).emit('recording:available', {
          gameId: rec.game_id,
          status: 'AVAILABLE',
          title: `Match Recording - Game ${rec.game_id}`,
        });
      } catch (sockErr) {}
    }

    await client.query('COMMIT');
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
