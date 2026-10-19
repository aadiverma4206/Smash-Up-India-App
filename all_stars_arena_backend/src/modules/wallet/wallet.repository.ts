import { dbPool } from "../../config/db.config.js";

export class WalletRepository {
  /**
   * Get Player Wallet Balance & Details
   */
  static async getWalletDetails(userId: string) {
    const res = await dbPool.query(
      `SELECT wallet_balance, wallet_pin_set_at, wallet_pin_failed_attempts, wallet_pin_locked_until,
              (wallet_pin_hash IS NOT NULL) as is_pin_set
       FROM public.player_details
       WHERE user_id = $1::VARCHAR;`,
      [userId],
    );
    return res.rows[0] || null;
  }

  /**
   * Call DB function set_wallet_pin
   */
  static async setWalletPin(userId: string, pin: string) {
    await dbPool.query(
      "SELECT public.set_wallet_pin($1::VARCHAR, $2::VARCHAR);",
      [userId, pin],
    );
  }

  /**
   * Call DB function verify_wallet_pin
   */
  static async verifyWalletPin(userId: string, pin: string): Promise<boolean> {
    const res = await dbPool.query(
      "SELECT public.verify_wallet_pin($1::VARCHAR, $2::VARCHAR) as is_valid;",
      [userId, pin],
    );
    return res.rows[0]?.is_valid === true;
  }

  /**
   * Call DB function create_payment_order (Explicit type casts to prevent PG 42725 function ambiguity)
   */
  static async createPaymentOrder(data: {
    userId: string;
    provider: string;
    amountPaise: number;
    idempotencyKey: string;
    walletPin?: string;
  }) {
    const res = await dbPool.query(
      "SELECT public.create_payment_order($1::VARCHAR, $2::VARCHAR, $3::INT, $4::VARCHAR, $5::VARCHAR) as payment_order_id;",
      [
        data.userId,
        data.provider,
        data.amountPaise,
        data.idempotencyKey,
        data.walletPin || null,
      ],
    );
    return res.rows[0]?.payment_order_id;
  }

  /**
   * Update Provider Order ID in payment_orders
   */
  static async updateProviderOrderId(
    paymentOrderId: string,
    providerOrderId: string,
  ) {
    await dbPool.query(
      `UPDATE public.payment_orders
       SET provider_order_id = $1::VARCHAR, status = 'PENDING', updated_at = CURRENT_TIMESTAMP
       WHERE id = $2::VARCHAR;`,
      [providerOrderId, paymentOrderId],
    );
  }

  /**
   * Call DB function settle_wallet_payment
   */
  static async settleWalletPayment(
    paymentOrderId: string,
    providerPaymentId: string,
  ) {
    const res = await dbPool.query(
      "SELECT public.settle_wallet_payment($1::VARCHAR, $2::VARCHAR) as tx_id;",
      [paymentOrderId, providerPaymentId],
    );
    return res.rows[0]?.tx_id;
  }

  /**
   * Call DB function get_payment_order_status
   */
  static async getPaymentOrderStatus(userId: string, paymentOrderId: string) {
    const res = await dbPool.query(
      "SELECT * FROM public.get_payment_order_status($1::VARCHAR, $2::VARCHAR);",
      [userId, paymentOrderId],
    );
    return res.rows[0] || null;
  }

  /**
   * Deduplicate and record Webhook Event in payment_webhook_events
   */
  static async recordWebhookEvent(data: {
    provider: string;
    eventId: string;
    eventType: string;
    paymentOrderId?: string;
    signatureVerified: boolean;
    payload: any;
  }) {
    const res = await dbPool.query(
      `INSERT INTO public.payment_webhook_events
       (provider, event_id, event_type, payment_order_id, signature_verified, payload, processing_status)
       VALUES ($1::VARCHAR, $2::VARCHAR, $3::VARCHAR, $4::VARCHAR, $5::BOOLEAN, $6::JSONB, 'RECEIVED')
       ON CONFLICT (provider, event_id) DO NOTHING
       RETURNING id;`,
      [
        data.provider,
        data.eventId,
        data.eventType,
        data.paymentOrderId || null,
        data.signatureVerified,
        JSON.stringify(data.payload),
      ],
    );
    return res.rows[0]?.id || null;
  }

  /**
   * Update Webhook Event Processing Status
   */
  static async updateWebhookStatus(eventId: string, status: string) {
    await dbPool.query(
      `UPDATE public.payment_webhook_events
       SET processing_status = $1::VARCHAR, processed_at = CURRENT_TIMESTAMP
       WHERE event_id = $2::VARCHAR;`,
      [status, eventId],
    );
  }

  /**
   * Mark Payment Order as FAILED or REFUNDED
   */
  static async updatePaymentOrderStatus(
    paymentOrderId: string,
    status: string,
    metadata: any = {},
  ) {
    await dbPool.query(
      `UPDATE public.payment_orders
       SET status = $1::VARCHAR, metadata = metadata || $2::jsonb, updated_at = CURRENT_TIMESTAMP
       WHERE id = $3::VARCHAR;`,
      [status, JSON.stringify(metadata), paymentOrderId],
    );
  }

  /**
   * Call DB function get_wallet_transaction_history
   */
  static async getTransactionHistory(userId: string, limit = 50, offset = 0) {
    const res = await dbPool.query(
      "SELECT * FROM public.get_wallet_transaction_history($1::VARCHAR, $2::INT, $3::INT);",
      [userId, limit, offset],
    );
    return res.rows;
  }
}
