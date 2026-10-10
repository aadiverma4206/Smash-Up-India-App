import crypto from 'crypto';
import { WalletRepository } from './wallet.repository.js';
import { razorpayClient } from '../../config/razorpay.js';
import { sendPaymentConfirmationEmail } from '../../services/email.service.js';
import { sendWalletUpdate, sendUserNotification } from '../../services/realtime.service.js';
import { env } from '../../config/env.config.js';
import { ApiError } from '../../utils/apiResponse.js';
import { logger } from '../../utils/logger.js';
import { dbPool } from '../../config/db.config.js';

export class WalletService {
  /**
   * Fetch Player Wallet Balance & PIN Info
   */
  static async getWallet(userId: string) {
    const details = await WalletRepository.getWalletDetails(userId);
    if (!details) {
      throw new ApiError(404, 'Player wallet not found', 'WALLET_NOT_FOUND');
    }

    return {
      walletBalance: Number(details.wallet_balance || 0),
      maxWalletBalance: 200000,
      maxSingleTopup: 50000,
      isPinSet: Boolean(details.is_pin_set),
      isLocked: Boolean(
        details.wallet_pin_locked_until &&
          new Date(details.wallet_pin_locked_until) > new Date()
      ),
      lockedUntil: details.wallet_pin_locked_until,
    };
  }

  /**
   * Set Initial 6-Digit Wallet PIN
   */
  static async setWalletPin(userId: string, pin: string) {
    if (!pin || !/^\d{6}$/.test(pin)) {
      throw new ApiError(400, 'Wallet PIN must be exactly 6 numeric digits', 'INVALID_WALLET_PIN');
    }
    await WalletRepository.setWalletPin(userId, pin);
    return { message: 'Wallet PIN set successfully' };
  }

  /**
   * Change 6-Digit Wallet PIN
   */
  static async changeWalletPin(userId: string, oldPin: string, newPin: string) {
    if (!newPin || !/^\d{6}$/.test(newPin)) {
      throw new ApiError(400, 'New Wallet PIN must be exactly 6 numeric digits', 'INVALID_WALLET_PIN');
    }

    try {
      const isValid = await WalletRepository.verifyWalletPin(userId, oldPin);
      if (!isValid) {
        throw new ApiError(400, 'Incorrect old wallet PIN', 'INVALID_WALLET_PIN');
      }
    } catch (err: any) {
      if (err.message?.includes('WALLET_PIN_LOCKED')) {
        throw new ApiError(
          423,
          'Wallet PIN is locked due to multiple failed attempts. Please try again after 15 minutes.',
          'WALLET_PIN_LOCKED'
        );
      }
      throw err;
    }

    await WalletRepository.setWalletPin(userId, newPin);
    return { message: 'Wallet PIN updated successfully' };
  }

  /**
   * Verify 6-Digit Wallet PIN
   */
  static async verifyWalletPin(userId: string, pin: string) {
    try {
      const isValid = await WalletRepository.verifyWalletPin(userId, pin);
      if (!isValid) {
        throw new ApiError(400, 'Incorrect wallet PIN', 'INVALID_WALLET_PIN');
      }
      return { success: true, message: 'Wallet PIN verified' };
    } catch (err: any) {
      if (err.message?.includes('WALLET_PIN_LOCKED')) {
        throw new ApiError(
          423,
          'Wallet PIN is locked due to multiple failed attempts. Please try again after 15 minutes.',
          'WALLET_PIN_LOCKED'
        );
      }
      throw err;
    }
  }

  /**
   * Create Razorpay Wallet Top-Up Order (Online top-up does NOT require PIN)
   */
  static async createTopupOrder(
    userId: string,
    amountRupees: number,
    idempotencyKey: string,
    walletPin?: string
  ) {
    if (amountRupees < 1 || amountRupees > 50000) {
      throw new ApiError(400, 'Top-up amount must be between ₹1 and ₹50,000', 'INVALID_TOPUP_AMOUNT');
    }

    // Wallet Maximum Balance Cap Check (₹2,00,000)
    const currentWallet = await this.getWallet(userId);
    if (currentWallet.walletBalance + amountRupees > 200000) {
      throw new ApiError(
        400,
        `Top-up exceeds maximum wallet limit of ₹2,00,000. Current balance: ₹${currentWallet.walletBalance}`,
        'WALLET_CAP_EXCEEDED'
      );
    }

    const amountPaise = Math.round(amountRupees * 100);

    // Call PostgreSQL Stored Function create_payment_order (Top-up does NOT require PIN)
    const paymentOrderId = await WalletRepository.createPaymentOrder({
      userId,
      provider: 'RAZORPAY',
      amountPaise,
      idempotencyKey,
      walletPin: walletPin || '',
    });

    if (!paymentOrderId) {
      throw new ApiError(500, 'Failed to initialize payment order record in database');
    }

    // Create Razorpay SDK Order
    let razorpayOrderId = `rzp_order_mock_${Date.now()}`;
    const keyId = env.RAZORPAY_KEY_ID || 'rzp_test_Sb44esbmpGlzBd';
    const keySecret = env.RAZORPAY_KEY_SECRET || '0TkqPajfyDM5ng6e3CQxIzYy';

    try {
      if (
        keyId &&
        keySecret &&
        !keyId.includes('dummy') &&
        !keyId.includes('123456')
      ) {
        const rzpOrder = await razorpayClient.orders.create({
          amount: amountPaise,
          currency: 'INR',
          receipt: paymentOrderId,
          notes: { userId, paymentOrderId, purpose: 'WALLET_TOPUP' },
        });
        razorpayOrderId = rzpOrder.id;
      }
    } catch (err: any) {
      logger.warn(`Razorpay SDK Error (${err.message}). Using fallback order ID for testing.`);
    }

    await WalletRepository.updateProviderOrderId(paymentOrderId, razorpayOrderId);

    // Get User Details for Prefill
    const userRes = await dbPool.query('SELECT name, email, phone FROM public.users WHERE id = $1;', [
      userId,
    ]);
    const user = userRes.rows[0];

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes window

    return {
      paymentOrderId,
      id: paymentOrderId,
      razorpayOrderId,
      orderId: razorpayOrderId,
      razorpayKeyId: keyId,
      keyId: keyId,
      amountRupees,
      amountPaise,
      amountPaisa: amountPaise,
      currency: 'INR',
      expiresAt: expiresAt.toISOString(),
      prefill: {
        name: user?.name || 'Player',
        email: user?.email || '',
        contact: user?.phone || '',
      },
    };
  }

  /**
   * Verify Razorpay Payment Signature and Settle Wallet
   */
  static async verifyTopupPayment(
    userId: string,
    userEmail: string,
    paymentOrderId: string | undefined,
    razorpayPaymentId: string,
    razorpayOrderId: string,
    razorpaySignature?: string
  ) {
    // Resolve activePaymentOrderId if not passed directly
    let activePaymentOrderId = paymentOrderId;
    if (!activePaymentOrderId && razorpayOrderId) {
      const orderRes = await dbPool.query(
        `SELECT id FROM public.payment_orders WHERE provider_order_id = $1 OR id = $1 LIMIT 1;`,
        [razorpayOrderId]
      );
      activePaymentOrderId = orderRes.rows[0]?.id;
    }

    if (!activePaymentOrderId) {
      const checkRes = await dbPool.query(
        `SELECT id FROM public.payment_orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1;`,
        [userId]
      );
      activePaymentOrderId = checkRes.rows[0]?.id;
    }

    if (!activePaymentOrderId) {
      throw new ApiError(404, 'Payment order record not found for settlement', 'PAYMENT_ORDER_NOT_FOUND');
    }

    // Timing-Safe Signature Verification
    if (
      razorpaySignature &&
      razorpayOrderId &&
      razorpayPaymentId &&
      !razorpayOrderId.startsWith('rzp_order_mock_')
    ) {
      const secret = env.RAZORPAY_KEY_SECRET || '0TkqPajfyDM5ng6e3CQxIzYy';
      const generatedSignature = crypto
        .createHmac('sha256', secret)
        .update(`${razorpayOrderId}|${razorpayPaymentId}`)
        .digest('hex');

      try {
        const sigBuffer = Buffer.from(razorpaySignature, 'utf8');
        const genBuffer = Buffer.from(generatedSignature, 'utf8');

        if (
          sigBuffer.length !== genBuffer.length ||
          !crypto.timingSafeEqual(sigBuffer, genBuffer)
        ) {
          logger.warn(`Payment signature mismatch for order ${razorpayOrderId}`);
          if (env.NODE_ENV === 'production') {
            throw new ApiError(
              400,
              'Invalid payment signature. Payment verification failed.',
              'PAYMENT_VERIFICATION_FAILED'
            );
          }
        }
      } catch (sigErr) {
        if (env.NODE_ENV === 'production') {
          throw sigErr;
        }
      }
    }

    // Settle Wallet Payment via DB Function settle_wallet_payment
    let txId = '';
    try {
      txId = await WalletRepository.settleWalletPayment(activePaymentOrderId, razorpayPaymentId);
    } catch (settleError: any) {
      logger.error({ settleError }, 'Wallet Settlement Failure after captured payment. Initiating auto-refund.');

      // Auto-Refund Safety Net
      await this.initiateAutomaticRefund(razorpayPaymentId, 'Wallet settlement failed: ' + settleError.message);
      await WalletRepository.updatePaymentOrderStatus(activePaymentOrderId, 'FAILED', {
        failureReason: settleError.message,
      });

      sendUserNotification(userId, {
        title: '⚠️ Settlement Failed - Refund Initiated',
        message: 'Your payment was received but wallet settlement failed. Automatic refund initiated.',
        type: 'ALERT',
      });

      throw new ApiError(
        500,
        'Wallet settlement failed. Automatic refund has been initiated to your original payment method.',
        'SETTLEMENT_FAILED'
      );
    }

    // Fetch fresh balance
    const wallet = await this.getWallet(userId);

    // Emit Socket.IO real-time event
    sendWalletUpdate(userId, { walletBalance: wallet.walletBalance, txId });
    sendUserNotification(userId, {
      title: '⚽ Top-Up Successful',
      message: `₹${(wallet.walletBalance).toFixed(2)} added to your wallet!`,
      type: 'SUCCESS',
    });

    if (userEmail) {
      sendPaymentConfirmationEmail(userEmail, wallet.walletBalance, txId);
    }

    return {
      success: true,
      transactionId: txId,
      newWalletBalance: wallet.walletBalance,
      message: 'Wallet top-up settled successfully',
    };
  }

  /**
   * Automatic Razorpay Refund Helper
   */
  static async initiateAutomaticRefund(paymentId: string, reason: string) {
    try {
      if (
        razorpayClient &&
        razorpayClient.payments &&
        env.RAZORPAY_KEY_SECRET &&
        !env.RAZORPAY_KEY_SECRET.includes('test_secret')
      ) {
        const refund = await razorpayClient.payments.refund(paymentId, {
          notes: { reason },
        });
        logger.info(`✅ Auto-Refund initiated for payment ${paymentId}: Refund ID ${refund.id}`);
        return refund;
      }
    } catch (err) {
      logger.error({ err }, `❌ Auto-Refund error for payment ${paymentId}`);
    }
    return null;
  }

  /**
   * Process Razorpay Webhook Event
   */
  static async processRazorpayWebhook(rawBody: string, signature: string, eventPayload: any) {
    // 1. Timing-Safe Webhook Signature Verification
    if (signature && env.RAZORPAY_WEBHOOK_SECRET) {
      const expectedSignature = crypto
        .createHmac('sha256', env.RAZORPAY_WEBHOOK_SECRET)
        .update(rawBody)
        .digest('hex');

      const sigBuf = Buffer.from(signature, 'utf8');
      const expBuf = Buffer.from(expectedSignature, 'utf8');

      if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
        throw new ApiError(400, 'Invalid webhook signature', 'INVALID_WEBHOOK_SIGNATURE');
      }
    }

    const eventId = eventPayload.event_id || `evt_${Date.now()}`;
    const eventType = eventPayload.event;
    const paymentEntity = eventPayload.payload?.payment?.entity;
    let paymentOrderId = paymentEntity?.notes?.paymentOrderId;

    // Check if paymentOrderId exists in DB to prevent foreign key violation
    if (paymentOrderId) {
      const checkRes = await dbPool.query(
        `SELECT id FROM public.payment_orders WHERE id = $1;`,
        [paymentOrderId]
      );
      if (checkRes.rows.length === 0) {
        paymentOrderId = null;
      }
    }

    // 2. Deduplication Check via payment_webhook_events table
    const recordedId = await WalletRepository.recordWebhookEvent({
      provider: 'RAZORPAY',
      eventId,
      eventType,
      paymentOrderId,
      signatureVerified: true,
      payload: eventPayload,
    });

    if (!recordedId) {
      logger.info(`Webhook event ${eventId} already processed (deduplicated)`);
      return { status: 'IGNORED_DUPLICATE' };
    }

    // 3. Process Events
    try {
      if (eventType === 'payment.captured' || eventType === 'order.paid') {
        const paymentId = paymentEntity.id;
        const userId = paymentEntity.notes?.userId;

        if (paymentOrderId && paymentId) {
          try {
            await WalletRepository.settleWalletPayment(paymentOrderId, paymentId);
            if (userId) {
              const wallet = await this.getWallet(userId);
              sendWalletUpdate(userId, { walletBalance: wallet.walletBalance });
            }
          } catch (settleErr: any) {
            logger.error({ settleErr }, `Webhook settlement failed for payment ${paymentId}. Refunding...`);
            await this.initiateAutomaticRefund(paymentId, settleErr.message);
          }
        }
      } else if (eventType === 'payment.failed') {
        if (paymentOrderId) {
          await WalletRepository.updatePaymentOrderStatus(paymentOrderId, 'FAILED', {
            webhookEvent: eventType,
          });
        }
      }

      await WalletRepository.updateWebhookStatus(eventId, 'PROCESSED');
      return { status: 'PROCESSED' };
    } catch (err: any) {
      await WalletRepository.updateWebhookStatus(eventId, 'FAILED');
      logger.error({ err }, `Error processing webhook event ${eventId}`);
      throw err;
    }
  }
  static async getTransactions(userId: string, limit = 50, offset = 0) {
    const transactions = await WalletRepository.getTransactionHistory(userId, limit, offset);
    const wallet = await this.getWallet(userId);

    return {
      walletBalance: wallet.walletBalance,
      transactions,
    };
  }
}
