import cron from "node-cron";
import { dbPool } from "../config/db.js";
import { logger } from "../config/logger.js";

export const startCctvRecordingJob = () => {
  cron.schedule("* * * * *", async () => {
    try {
      const expiredRecordings = await dbPool.query(
        `SELECT id, game_id, club_id, court_id, s3_object_key
         FROM public.cctv_recordings
         WHERE status = 'RECORDING' AND stop_deadline <= CURRENT_TIMESTAMP;`,
      );

      for (const rec of expiredRecordings.rows) {
        logger.info(
          `⏰ [Job] CCTV Auto-stopping recording ${rec.id} for Game ${rec.game_id}`,
        );

        await dbPool.query(
          `UPDATE public.cctv_recordings
           SET status = 'COMPLETED', actual_stop_time = CURRENT_TIMESTAMP
           WHERE id = $1;`,
          [rec.id],
        );

        await dbPool.query(
          `INSERT INTO public.game_videos (game_id, club_id, court_id, cctv_id, title, video_url, status)
           VALUES ($1, $2, $3, $4, $5, $6, 'AVAILABLE')
           ON CONFLICT DO NOTHING;`,
          [
            rec.game_id,
            rec.club_id,
            rec.court_id,
            rec.camera_id || null,
            `Match Recording - Game ${rec.game_id}`,
            rec.s3_object_key,
          ],
        );

        await dbPool.query(
          `INSERT INTO public.audit_logs (admin_name, action, target, details)
           VALUES ('CCTV_WORKER', 'AUTO_STOP_RECORDING', $1, $2);`,
          [
            `Recording:${rec.id}`,
            `Auto-stopped CCTV recording after 15-min post-match window expired`,
          ],
        );
      }
    } catch (err) {
      logger.error({ err }, "Error in CCTV recording cron job");
    }
  });
};
