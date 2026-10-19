import cron from "node-cron";
import { dbPool } from "../config/db.config.js";
import { razorpayClient } from "../config/razorpay.js";
import { WalletService } from "../modules/wallet/wallet.service.js";
import { logger } from "../config/logger.js";

export const startPaymentReconciliationJob = () => {
  // Run every 10 minutes to reconcile pending payment orders with Razorpay API
  cron.schedule("*/10 * * * *", async () => {
    try {
      const pendingOrders = await dbPool.query(
        `SELECT po.*, u.email as user_email
         FROM public.payment_orders po
         JOIN public.users u ON u.id = po.user_id
         WHERE po.status = 'PENDING' AND po.provider_order_id IS NOT NULL AND po.expires_at > CURRENT_TIMESTAMP;`,
      );

      for (const order of pendingOrders.rows) {
        try {
          if (razorpayClient && razorpayClient.orders) {
            const rzpOrder = await razorpayClient.orders.fetch(
              order.provider_order_id,
            );
            if (rzpOrder && rzpOrder.status === "paid") {
              const payments = await razorpayClient.orders.fetchPayments(
                order.provider_order_id,
              );
              const capturedPayment = payments.items?.find(
                (p) => p.status === "captured",
              );

              if (capturedPayment) {
                logger.info(
                  `🔄 [Reconciliation] Settling paid order ${order.id} for payment ${capturedPayment.id}`,
                );
                await WalletService.verifyTopupPayment(
                  order.user_id,
                  order.user_email,
                  order.id,
                  capturedPayment.id,
                  order.provider_order_id,
                );
              }
            }
          }
        } catch (orderErr) {
          logger.error(
            { orderErr },
            `Reconciliation check failed for order ${order.id}`,
          );
        }
      }
    } catch (err) {
      logger.error({ err }, "Error in paymentReconciliation cron job");
    }
  });
};
