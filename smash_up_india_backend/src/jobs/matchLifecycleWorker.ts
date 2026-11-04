import cron from "node-cron";
import { dbPool } from "../config/db.config.js";
import { env } from "../config/env.config.js";
import { getSocketIO } from "../config/socket.config.js";
import { logger } from "../utils/logger.js";
import { CctvService } from "../modules/cctv/cctv.service.js";
import { CctvRecordingService } from "../services/cctvRecording.service.js";

export const runLifecycleCycle = async () => {
  const client = await dbPool.connect();
  try {
    await client.query("BEGIN");

    await client.query(
      "ALTER TABLE public.games ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;",
    );

    // =========================================================================
    // STEP 1: Auto-cancel all unapproved or expired past/overdue matches
    // =========================================================================
    const unapprovedGames = await client.query(
      `SELECT g.id, g.creator_id, g.title, g.entry_fee, g.match_date, g.start_time, g.end_time, g.approval_status
       FROM public.games g
       WHERE g.approval_status = 'PENDING_APPROVAL' AND g.status <> 'CANCELLED'
         AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`,
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
        [game.id],
      );

      logger.info(
        `🚫 [LifecycleWorker] Auto-cancelled unapproved game ${game.id} ("${game.title}") past scheduled start time`,
      );

      const paidPlayers = await client.query(
        `SELECT gp.user_id, gp.payment_method, gp.payment_reference, gp.payment_status, gp.refund_status
         FROM public.game_players gp
         WHERE gp.game_id = $1 AND gp.payment_status = 'PAID' AND gp.payment_method IN ('WALLET', 'RAZORPAY')
         FOR UPDATE;`,
        [game.id],
      );

      for (const player of paidPlayers.rows) {
        const isHost = game.creator_id && player.user_id === game.creator_id;
        let refundAmt = isHost
          ? parseFloat(game.entry_fee || "0.00")
          : parseFloat(game.per_player_fee || "0.00");

        if (player.payment_method === "WALLET") {
          const txCheck = await client.query(
            `SELECT amount FROM public.transactions 
             WHERE user_id = $1 AND type = 'PAYMENT' AND reference_id = $2 AND status = 'SUCCESS' 
             ORDER BY created_at DESC LIMIT 1;`,
            [player.user_id, game.id],
          );
          if (txCheck.rows.length > 0) {
            const amt = parseFloat(txCheck.rows[0].amount || "0.00");
            if (amt > 0) refundAmt = amt;
          }
        } else if (
          player.payment_method === "RAZORPAY" &&
          player.payment_reference
        ) {
          const poCheck = await client.query(
            `SELECT amount_paise FROM public.payment_orders 
             WHERE (provider_payment_id = $1 OR provider_order_id = $1 OR id = $1) AND user_id = $2 AND status = 'PAID' 
             ORDER BY created_at DESC LIMIT 1;`,
            [player.payment_reference, player.user_id],
          );
          if (poCheck.rows.length > 0) {
            const amt = parseFloat(poCheck.rows[0].amount_paise || "0") / 100.0;
            if (amt > 0) refundAmt = amt;
          }
        }

        if (
          refundAmt > 0 &&
          player.refund_status !== "REFUNDED_TO_WALLET" &&
          player.payment_status !== "REFUNDED"
        ) {
          const refundRef = isHost
            ? `MATCH_HOST_REFUND:${game.id}:${player.user_id}`
            : `MATCH_REFUND:${game.id}:${player.user_id}`;

          const existingRefund = await client.query(
            `SELECT id FROM public.transactions WHERE user_id = $1 AND type = 'REFUND' AND reference_id = $2;`,
            [player.user_id, refundRef],
          );

          if (existingRefund.rows.length === 0) {
            const refundDesc = `Automated refund: Match "${game.title || "Pickle Match"}" was auto-cancelled due to manager non-approval`;

            const txRes = await client.query(
              `INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
               VALUES ($1, 'REFUND', $2, 0, 'SUCCESS', $3, $4)
               RETURNING id, balance_after;`,
              [player.user_id, refundAmt, refundDesc, refundRef],
            );
            const newBal = parseFloat(txRes.rows[0]?.balance_after || "0.00");

            await client.query(
              `INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
               VALUES ($1, $2, 'REFUND', $3, $4, $5, 'SUCCESS', $6)
               ON CONFLICT (id) DO NOTHING;`,
              [
                txRes.rows[0]?.id,
                player.user_id,
                refundAmt,
                newBal,
                refundDesc,
                refundRef,
              ],
            );

            await client.query(
              `UPDATE public.game_players
               SET payment_status = 'REFUNDED', refund_status = 'REFUNDED_TO_WALLET', refund_reference = $1, refund_amount = $2, refunded_at = CURRENT_TIMESTAMP
               WHERE game_id = $3 AND user_id = $4;`,
              [refundRef, refundAmt, game.id, player.user_id],
            );

            if (player.payment_reference) {
              await client.query(
                `UPDATE public.payment_orders
                 SET status = 'REFUNDED', updated_at = CURRENT_TIMESTAMP
                 WHERE provider_payment_id = $1 OR provider_order_id = $1 OR id = $1;`,
                [player.payment_reference],
              );
            }

            logger.info(
              `💰 [LifecycleWorker] Refunded ₹${refundAmt} to user ${player.user_id} for auto-cancelled game ${game.id}`,
            );
          }
        }
      }

      try {
        const io = getSocketIO();
        io.emit("match:cancelled", {
          gameId: game.id,
          status: "CANCELLED",
          reason: "Auto-cancelled: Not approved before scheduled start time",
        });
      } catch (_) {}
    }

    await client.query("COMMIT");

    await client.query("BEGIN");

    const startingGames = await client.query(
      `SELECT g.id, c.club_id, g.court_id, g.title, g.match_date, g.start_time, g.end_time
       FROM public.games g
       LEFT JOIN public.courts c ON c.id = g.court_id
       WHERE g.approval_status = 'APPROVED'
         AND g.status IN ('OPEN_FOR_JOINING', 'FULL')
         AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP
         AND (g.match_date + g.end_time) > CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`,
    );

    const gamesToRecord: Array<{ gameId: string; cameraId: string }> = [];

    for (const game of startingGames.rows) {
      await client.query(
        `UPDATE public.games
         SET status = 'ONGOING', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id],
      );

      logger.info(
        `⚽ [LifecycleWorker] Auto-started match ${game.id} ("${game.title}") to ONGOING`,
      );

      try {
        const camRes = await client.query(
          `SELECT id, is_enabled FROM public.cctv_cameras
           WHERE (court_id = $1 OR club_id = $2 OR court_id IS NULL)
             AND is_enabled = true
           ORDER BY (CASE WHEN court_id = $1 THEN 0 WHEN club_id = $2 THEN 1 ELSE 2 END)
           LIMIT 1;`,
          [game.court_id, game.club_id],
        );

        if (camRes.rows.length > 0) {
          const camera = camRes.rows[0];

          const existingRec = await client.query(
            `SELECT id FROM public.cctv_recordings WHERE game_id = $1 LIMIT 1;`,
            [game.id],
          );

          if (existingRec.rows.length === 0) {
            gamesToRecord.push({ gameId: game.id, cameraId: camera.id });
          }
        }
      } catch (cctvErr: any) {
        logger.error({ cctvErr }, `Failed to query camera for game ${game.id}`);
      }

      try {
        const courtName = game.court_id === "court_2" ? "Court 2" : "Court 1";

        const managers = await client.query(
          `SELECT user_id FROM public.club_managers WHERE club_id = $1;`,
          [game.club_id],
        );
        for (const mgr of managers.rows) {
          await client.query(
            `INSERT INTO public.notifications (user_id, title, body, message, type, data)
             VALUES ($1, $2, $3, $3, 'MATCH_AUTO_STARTED', $4);`,
            [
              mgr.user_id,
              "⚽ Match Auto-Started",
              `Match "${game.title}" on ${courtName} has auto-started at scheduled start time!`,
              JSON.stringify({
                gameId: game.id,
                route: "/manager/games/details",
              }),
            ],
          );
        }

        const players = await client.query(
          `SELECT user_id FROM public.game_players WHERE game_id = $1;`,
          [game.id],
        );
        for (const ply of players.rows) {
          await client.query(
            `INSERT INTO public.notifications (user_id, title, body, message, type, data)
             VALUES ($1, $2, $3, $3, 'MATCH_AUTO_STARTED', $4);`,
            [
              ply.user_id,
              "⚽ Kick-off! Match Started",
              `Your match "${game.title}" on ${courtName} has officially started! Good luck!`,
              JSON.stringify({ gameId: game.id, route: "/games/details" }),
            ],
          );
        }
      } catch (notifErr: any) {
        logger.error(
          { notifErr },
          `Failed to create auto-start notifications for game ${game.id}`,
        );
      }

      try {
        const io = getSocketIO();
        io.to(`game:${game.id}`).emit("match:started", {
          gameId: game.id,
          status: "ONGOING",
          message: "Match has started!",
        });
        io.emit("match:live_feed", {
          gameId: game.id,
          status: "ONGOING",
          eventText: `⚽ KICK-OFF: ${game.title}`,
        });
      } catch (sockErr: any) {}
    }

    await client.query("COMMIT");

    for (const item of gamesToRecord) {
      try {
        await CctvService.startMatchRecording(
          "SYSTEM_WORKER",
          "Auto Lifecycle Worker",
          1,
          item.gameId,
          item.cameraId,
        );
        logger.info(
          `📹 [LifecycleWorker] Auto-triggered CCTV recording for Match ${item.gameId}`,
        );
      } catch (cctvStartErr: any) {
        logger.error(
          { cctvStartErr },
          `[LifecycleWorker] Could not start CCTV recording for game ${item.gameId}`,
        );
      }
    }

    await client.query("BEGIN");

    const endingGames = await client.query(
      `SELECT g.id, c.club_id, g.court_id, g.title, g.match_date, g.end_time
       FROM public.games g
       LEFT JOIN public.courts c ON c.id = g.court_id
       WHERE g.status NOT IN ('COMPLETED', 'CANCELLED')
         AND (g.match_date + g.end_time) <= CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`,
    );

    const postMatchMinutes = env.RECORDING_POST_MATCH_MINUTES || 5;

    for (const game of endingGames.rows) {
      await client.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE id = $1;`,
        [game.id],
      );

      logger.info(
        `🏁 [LifecycleWorker] Auto-completed match ${game.id} ("${game.title}") to COMPLETED`,
      );

      await client.query(
        `UPDATE public.cctv_recordings
         SET recording_status = 'POST_MATCH',
             stop_deadline = CURRENT_TIMESTAMP + ($2 || ' minutes')::interval,
             post_match_stop_at = CURRENT_TIMESTAMP + ($2 || ' minutes')::interval
         WHERE game_id = $1 AND (status = 'RECORDING' OR recording_status = 'RECORDING');`,
        [game.id, postMatchMinutes],
      );

      try {
        const io = getSocketIO();
        io.to(`game:${game.id}`).emit("match:completed", {
          gameId: game.id,
          status: "COMPLETED",
          message: "Match full-time reached. Final score submission open.",
        });
        io.emit("match:live_feed", {
          gameId: game.id,
          status: "COMPLETED",
          eventText: `🏁 FULL-TIME: ${game.title}`,
        });
      } catch (sockErr) {}
    }

    await client.query("COMMIT");

    await client.query("BEGIN");

    const expiredRecordings = await client.query(
      `SELECT rec.id, rec.game_id
       FROM public.cctv_recordings rec
       WHERE (rec.status = 'RECORDING' OR rec.recording_status IN ('RECORDING', 'POST_MATCH'))
         AND (
           rec.stop_deadline <= CURRENT_TIMESTAMP
           OR rec.post_match_stop_at <= CURRENT_TIMESTAMP
         )
       FOR UPDATE SKIP LOCKED;`,
    );

    const recsToStop = expiredRecordings.rows;
    await client.query("COMMIT");

    for (const rec of recsToStop) {
      logger.info(
        `🛑 [LifecycleWorker] CCTV Auto-stopping recording ${rec.id} for Game ${rec.game_id} (5-min post-match window expired)`,
      );
      try {
        await CctvRecordingService.stopRecording(rec.id, {
          userId: "SYSTEM_LIFECYCLE_WORKER",
          reason: "LIFECYCLE_POST_MATCH_DEADLINE_EXPIRED",
          manualStop: false,
        });
      } catch (stopErr: any) {
        logger.error({ stopErr }, `Failed to auto-stop recording ${rec.id}`);
      }
    }
  } catch (err: any) {
    await client.query("ROLLBACK").catch(() => {});
    logger.error(
      { err },
      "Error executing Match Lifecycle & CCTV Worker cycle",
    );
  } finally {
    client.release();
  }
};

export const startMatchLifecycleWorker = () => {
  runLifecycleCycle().catch((err) => {
    logger.error(
      { err },
      "Initial lifecycle reconciliation cycle failed on boot",
    );
  });

  cron.schedule("*/30 * * * * *", async () => {
    await runLifecycleCycle();
  });

  logger.info(
    "⏱️ [Worker] Match Lifecycle & CCTV Auto-Worker scheduled (every 30s + restart-safe)",
  );
};
