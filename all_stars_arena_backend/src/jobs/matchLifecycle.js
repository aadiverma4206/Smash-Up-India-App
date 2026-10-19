import cron from "node-cron";
import { dbPool } from "../config/db.js";
import { logger } from "../config/logger.js";

export const startMatchLifecycleJob = () => {
  // Run every 2 minutes to update match status to ONGOING if match start time has arrived
  cron.schedule("*/2 * * * *", async () => {
    try {
      const result = await dbPool.query(
        `UPDATE public.games
         SET status = 'ONGOING'
         WHERE status IN ('OPEN_FOR_JOINING', 'FULL')
           AND match_date <= CURRENT_DATE
           AND start_time <= CURRENT_TIME
           AND end_time > CURRENT_TIME
         RETURNING id;`,
      );

      if (result.rowCount > 0) {
        logger.info(
          `⚽ [Job] Updated ${result.rowCount} football matches to ONGOING status`,
        );
      }
    } catch (err) {
      logger.error({ err }, "Error in matchLifecycle cron job");
    }
  });
};
