import crypto from "crypto";
import { WalletRepository } from "./wallet.repository.js";
import { razorpayClient } from "../../config/razorpay.js";
import { sendPaymentConfirmationEmail } from "../../services/email.service.js";
import {
  sendWalletUpdate,
  sendUserNotification,
} from "../../services/realtime.service.js";
import { env } from "../../config/env.config.js";
import { ApiError } from "../../utils/apiResponse.js";
import { logger } from "../../utils/logger.js";
import { dbPool } from "../../config/db.config.js";

export class WalletService {
  static async getWallet(userId: string) {
    const details = await WalletRepository.getWalletDetails(userId);
    if (!details) {
      throw new ApiError(404, "Player wallet not found", "WALLET_NOT_FOUND");
    }

    const isPinSetBool =
      details.is_pin_set === true ||
      details.is_pin_set === "true" ||
      details.is_pin_set === "t" ||
      details.is_pin_set === 1;

    return {
      walletBalance: Number(details.wallet_balance || 0),
      maxWalletBalance: 200000,
      maxSingleTopup: 50000,
      isPinSet: isPinSetBool,
      isLocked: Boolean(
        details.wallet_pin_locked_until &&
        new Date(details.wallet_pin_locked_until) > new Date(),
      ),
      lockedUntil: details.wallet_pin_locked_until,
    };
  }

  static async setWalletPin(userId: string, pin: string) {
    if (!pin || !/^\d{6}$/.test(pin)) {
      throw new ApiError(
        400,
        "Wallet PIN must be exactly 6 numeric digits",
        "INVALID_WALLET_PIN",
      );
    }
    await WalletRepository.setWalletPin(userId, pin);
    return { message: "Wallet PIN set successfully" };
  }

  static async changeWalletPin(userId: string, oldPin: string, newPin: string) {
    if (!newPin || !/^\d{6}$/.test(newPin)) {
      throw new ApiError(
        400,
        "New Wallet PIN must be exactly 6 numeric digits",
        "INVALID_WALLET_PIN",
      );
    }

    try {
      const isValid = await WalletRepository.verifyWalletPin(userId, oldPin);
      if (!isValid) {
        throw new ApiError(
          400,
          "Incorrect old wallet PIN",
          "INVALID_WALLET_PIN",
        );
      }
    } catch (err: any) {
      if (err.message?.includes("WALLET_PIN_LOCKED")) {
        throw new ApiError(
          423,
          "Wallet PIN is locked due to multiple failed attempts. Please try again after 15 minutes.",
          "WALLET_PIN_LOCKED",
        );
      }
      throw err;
    }

    await WalletRepository.setWalletPin(userId, newPin);
    return { message: "Wallet PIN updated successfully" };
  }

  static async verifyWalletPin(userId: string, pin: string) {
    try {
      const isValid = await WalletRepository.verifyWalletPin(userId, pin);
      if (!isValid) {
        throw new ApiError(400, "Incorrect wallet PIN", "INVALID_WALLET_PIN");
      }
      return { success: true, message: "Wallet PIN verified" };
    } catch (err: any) {
      if (err.message?.includes("WALLET_PIN_LOCKED")) {
        throw new ApiError(
          423,
          "Wallet PIN is locked due to multiple failed attempts. Please try again after 15 minutes.",
          "WALLET_PIN_LOCKED",
        );
      }
      throw err;
    }
  }

  static async createTopupOrder(
    userId: string,
    amountRupees: number,
    idempotencyKey: string,
    walletPin?: string,
  ) {
    if (amountRupees < 1 || amountRupees > 50000) {
      throw new ApiError(
        400,
        "Top-up amount must be between ₹1 and ₹50,000",
        "INVALID_TOPUP_AMOUNT",
      );
    }

    const currentWallet = await this.getWallet(userId);
    if (!currentWallet.isPinSet) {
      throw new ApiError(
        400,
        "Please set up a 6-digit Wallet PIN first before adding money.",
        "WALLET_PIN_REQUIRED",
      );
    }

    if (currentWallet.walletBalance + amountRupees > 200000) {
      throw new ApiError(
        400,
        `Top-up exceeds maximum wallet limit of ₹2,00,000. Current balance: ₹${currentWallet.walletBalance}`,
        "WALLET_CAP_EXCEEDED",
      );
    }

    const amountPaise = Math.round(amountRupees * 100);

    const paymentOrderId = await WalletRepository.createPaymentOrder({
      userId,
      provider: "RAZORPAY",
      amountPaise,
      idempotencyKey,
      walletPin: walletPin || "",
    });

    if (!paymentOrderId) {
      throw new ApiError(
        500,
        "Failed to initialize payment order record in database",
      );
    }

    let razorpayOrderId = `rzp_order_mock_${Date.now()}`;
    const keyId = env.RAZORPAY_KEY_ID || "rzp_test_Sb44esbmpGlzBd";
    const keySecret = env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";

    try {
      if (
        keyId &&
        keySecret &&
        !keyId.includes("dummy") &&
        !keyId.includes("123456")
      ) {
        const rzpOrder = await razorpayClient.orders.create({
          amount: amountPaise,
          currency: "INR",
          receipt: paymentOrderId,
          notes: { userId, paymentOrderId, purpose: "WALLET_TOPUP" },
        });
        razorpayOrderId = rzpOrder.id;
      }
    } catch (err: any) {
      logger.warn(
        `Razorpay SDK Error (${err.message}). Using fallback order ID for testing.`,
      );
    }

    await WalletRepository.updateProviderOrderId(
      paymentOrderId,
      razorpayOrderId,
    );

    const userRes = await dbPool.query(
      "SELECT name, email, phone FROM public.users WHERE id = $1;",
      [userId],
    );
    const user = userRes.rows[0];

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

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
      currency: "INR",
      expiresAt: expiresAt.toISOString(),
      prefill: {
        name: user?.name || "Player",
        email: user?.email || "",
        contact: user?.phone || "",
      },
    };
  }

  static async verifyTopupPayment(
    userId: string,
    userEmail: string,
    paymentOrderId: string | undefined,
    razorpayPaymentId: string,
    razorpayOrderId: string,
    razorpaySignature?: string,
  ) {
    let activePaymentOrderId = paymentOrderId;
    if (!activePaymentOrderId && razorpayOrderId) {
      const orderRes = await dbPool.query(
        `SELECT id FROM public.payment_orders WHERE provider_order_id = $1 OR id = $1 LIMIT 1;`,
        [razorpayOrderId],
      );
      activePaymentOrderId = orderRes.rows[0]?.id;
    }

    if (!activePaymentOrderId) {
      const checkRes = await dbPool.query(
        `SELECT id FROM public.payment_orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1;`,
        [userId],
      );
      activePaymentOrderId = checkRes.rows[0]?.id;
    }

    if (!activePaymentOrderId) {
      throw new ApiError(
        404,
        "Payment order record not found for settlement",
        "PAYMENT_ORDER_NOT_FOUND",
      );
    }

    const orderPurposeRes = await dbPool.query(
      `SELECT purpose, user_id, amount_paise FROM public.payment_orders WHERE id = $1;`,
      [activePaymentOrderId],
    );
    if (orderPurposeRes.rows.length === 0) {
      throw new ApiError(
        404,
        "Payment order record not found for settlement",
        "PAYMENT_ORDER_NOT_FOUND",
      );
    }
    if (orderPurposeRes.rows[0]?.user_id !== userId) {
      throw new ApiError(
        403,
        "Payment order belongs to another player",
        "FORBIDDEN",
      );
    }
    if (orderPurposeRes.rows[0]?.purpose !== "WALLET_TOPUP") {
      throw new ApiError(
        400,
        "This payment order is not a wallet top-up and cannot credit the wallet",
        "INVALID_PAYMENT_PURPOSE",
      );
    }

    if (
      razorpaySignature &&
      razorpayOrderId &&
      razorpayPaymentId &&
      !razorpayOrderId.startsWith("rzp_order_mock_")
    ) {
      const secret = env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";
      const generatedSignature = crypto
        .createHmac("sha256", secret)
        .update(`${razorpayOrderId}|${razorpayPaymentId}`)
        .digest("hex");

      try {
        const sigBuffer = Buffer.from(razorpaySignature, "utf8");
        const genBuffer = Buffer.from(generatedSignature, "utf8");

        if (
          sigBuffer.length !== genBuffer.length ||
          !crypto.timingSafeEqual(sigBuffer, genBuffer)
        ) {
          logger.warn(
            `Payment signature mismatch for order ${razorpayOrderId}`,
          );
          throw new ApiError(
            400,
            "Invalid payment signature. Payment verification failed.",
            "PAYMENT_VERIFICATION_FAILED",
          );
        }
      } catch (sigErr) {
        if (sigErr instanceof ApiError) throw sigErr;
        throw new ApiError(
          400,
          "Invalid payment signature format.",
          "PAYMENT_VERIFICATION_FAILED",
        );
      }
    }

    let txId = "";
    try {
      txId = await WalletRepository.settleWalletPayment(
        activePaymentOrderId,
        razorpayPaymentId,
      );
    } catch (settleError: any) {
      logger.error(
        { settleError },
        "Wallet Settlement Failure after captured payment. Initiating auto-refund.",
      );

      await this.initiateAutomaticRefund(
        razorpayPaymentId,
        "Wallet settlement failed: " + settleError.message,
      );
      await WalletRepository.updatePaymentOrderStatus(
        activePaymentOrderId,
        "FAILED",
        {
          failureReason: settleError.message,
        },
      );

      sendUserNotification(userId, {
        title: "⚠️ Settlement Failed - Refund Initiated",
        message:
          "Your payment was received but wallet settlement failed. Automatic refund initiated.",
        type: "ALERT",
      });

      throw new ApiError(
        500,
        "Wallet settlement failed. Automatic refund has been initiated to your original payment method.",
        "SETTLEMENT_FAILED",
      );
    }

    const wallet = await this.getWallet(userId);

    const topupAmount = (
      Number(orderPurposeRes.rows[0]?.amount_paise || 0) / 100
    ).toFixed(2);
    sendWalletUpdate(userId, { walletBalance: wallet.walletBalance, txId });
    sendUserNotification(userId, {
      title: "⚽ Top-Up Successful",
      message: `₹${topupAmount} added to your wallet! New balance: ₹${wallet.walletBalance.toFixed(2)}`,
      type: "SUCCESS",
    });

    if (userEmail) {
      sendPaymentConfirmationEmail(userEmail, wallet.walletBalance, txId);
    }

    return {
      success: true,
      transactionId: txId,
      newWalletBalance: wallet.walletBalance,
      message: "Wallet top-up settled successfully",
    };
  }

  static async initiateAutomaticRefund(paymentId: string, reason: string) {
    try {
      if (
        razorpayClient &&
        razorpayClient.payments &&
        env.RAZORPAY_KEY_SECRET &&
        !env.RAZORPAY_KEY_SECRET.includes("test_secret")
      ) {
        const refund = await razorpayClient.payments.refund(paymentId, {
          notes: { reason },
        });
        logger.info(
          `✅ Auto-Refund initiated for payment ${paymentId}: Refund ID ${refund.id}`,
        );
        return refund;
      }
    } catch (err) {
      logger.error({ err }, `❌ Auto-Refund error for payment ${paymentId}`);
    }
    return null;
  }

  static async processRazorpayWebhook(
    rawBody: string,
    signature: string,
    eventPayload: any,
  ) {
    if (signature && env.RAZORPAY_WEBHOOK_SECRET) {
      const expectedSignature = crypto
        .createHmac("sha256", env.RAZORPAY_WEBHOOK_SECRET)
        .update(rawBody)
        .digest("hex");

      const sigBuf = Buffer.from(signature, "utf8");
      const expBuf = Buffer.from(expectedSignature, "utf8");

      if (
        sigBuf.length !== expBuf.length ||
        !crypto.timingSafeEqual(sigBuf, expBuf)
      ) {
        throw new ApiError(
          400,
          "Invalid webhook signature",
          "INVALID_WEBHOOK_SIGNATURE",
        );
      }
    }

    const eventId = eventPayload.event_id || `evt_${Date.now()}`;
    const eventType = eventPayload.event;
    const paymentEntity = eventPayload.payload?.payment?.entity;
    let paymentOrderId = paymentEntity?.notes?.paymentOrderId;

    if (paymentOrderId) {
      const checkRes = await dbPool.query(
        `SELECT id FROM public.payment_orders WHERE id = $1;`,
        [paymentOrderId],
      );
      if (checkRes.rows.length === 0) {
        paymentOrderId = null;
      }
    }

    const recordedId = await WalletRepository.recordWebhookEvent({
      provider: "RAZORPAY",
      eventId,
      eventType,
      paymentOrderId,
      signatureVerified: true,
      payload: eventPayload,
    });

    if (!recordedId) {
      logger.info(`Webhook event ${eventId} already processed (deduplicated)`);
      return { status: "IGNORED_DUPLICATE" };
    }

    try {
      if (eventType === "payment.captured" || eventType === "order.paid") {
        const paymentId = paymentEntity.id;
        const userId = paymentEntity.notes?.userId;

        if (paymentOrderId && paymentId) {
          try {
            const orderRes = await dbPool.query(
              `SELECT purpose, user_id FROM public.payment_orders WHERE id = $1;`,
              [paymentOrderId],
            );
            if (orderRes.rows[0]?.purpose === "WALLET_TOPUP") {
              await WalletRepository.settleWalletPayment(
                paymentOrderId,
                paymentId,
              );
              const targetUserId = userId || orderRes.rows[0]?.user_id;
              if (targetUserId) {
                const wallet = await this.getWallet(targetUserId);
                sendWalletUpdate(targetUserId, {
                  walletBalance: wallet.walletBalance,
                });
              }
            } else {
              logger.info(
                `Razorpay Webhook for order ${paymentOrderId} has purpose ${orderRes.rows[0]?.purpose || "UNKNOWN"} - not a wallet top-up, skipping wallet settlement.`,
              );
            }
          } catch (settleErr: any) {
            logger.error(
              { settleErr },
              `Webhook settlement failed for payment ${paymentId}. Refunding...`,
            );
            await this.initiateAutomaticRefund(paymentId, settleErr.message);
          }
        }
      } else if (eventType === "payment.failed") {
        if (paymentOrderId) {
          await WalletRepository.updatePaymentOrderStatus(
            paymentOrderId,
            "FAILED",
            {
              webhookEvent: eventType,
            },
          );
        }
      }

      await WalletRepository.updateWebhookStatus(eventId, "PROCESSED");
      return { status: "PROCESSED" };
    } catch (err: any) {
      await WalletRepository.updateWebhookStatus(eventId, "FAILED");
      logger.error({ err }, `Error processing webhook event ${eventId}`);
      throw err;
    }
  }
  static async getTransactions(userId: string, limit = 50, offset = 0) {
    const transactions = await WalletRepository.getTransactionHistory(
      userId,
      limit,
      offset,
    );
    const wallet = await this.getWallet(userId);

    return {
      walletBalance: wallet.walletBalance,
      transactions,
    };
  }
}
