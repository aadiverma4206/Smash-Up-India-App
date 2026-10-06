import cron from 'node-cron';
import { dbPool } from '../config/db.config.js';
import { logger } from '../utils/logger.js';

export const startPaymentExpiryJob = () => {
  // Run every 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    try {
      const res = await dbPool.query('SELECT public.expire_stale_payment_orders() as expired_count;');
      const expiredCount = res.rows[0]?.expired_count || 0;
      if (expiredCount > 0) {
        logger.info(`⏰ [Job] Expired ${expiredCount} stale payment orders`);
      }
    } catch (err) {
      logger.error({ err }, 'Error in paymentExpiry cron job');
    }
  });
};
