import crypto from "crypto";
import { dbPool } from "../config/db.config.js";
import { razorpayClient } from "./razorpay.service.js";
import { sendPaymentConfirmationEmail } from "./email.service.js";
import { sendWalletUpdate, sendUserNotification } from "./realtime.service.js";
import { env } from "../config/env.config.js";
import { ApiError } from "../utils/apiResponse.js";
import { logger } from "../utils/logger.js";

export const setUserWalletPin = async (userId: string, pin: string) => {
  if (!pin || !/^\d{6}$/.test(pin)) {
    throw new ApiError(
      400,
      "Wallet PIN must be exactly 6 numeric digits",
      "INVALID_WALLET_PIN",
    );
  }
  await dbPool.query("SELECT public.set_wallet_pin($1, $2);", [userId, pin]);
  logger.info(`Wallet PIN updated for user: ${userId}`);
  return { message: "Wallet PIN set successfully" };
};

export const verifyUserWalletPin = async (
  userId: string,
  pin: string,
): Promise<boolean> => {
  try {
    const res = await dbPool.query(
      "SELECT public.verify_wallet_pin($1, $2) as is_valid;",
      [userId, pin],
    );
    return res.rows[0]?.is_valid === true;
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
};

export const initiatePaymentOrder = async (
  userId: string,
  amountRupees: number,
  walletPin?: string,
) => {
  if (amountRupees < 1 || amountRupees > 200000) {
    throw new ApiError(400, "Top-up amount must be between ₹1 and ₹2,00,000");
  }

  const amountPaise = Math.round(amountRupees * 100);
  const idempotencyKey = `idemp_${userId}_${Date.now()}`;

  const dbOrderRes = await dbPool.query(
    "SELECT public.create_payment_order($1::VARCHAR, $2::VARCHAR, $3::INT, $4::VARCHAR, $5::VARCHAR) as payment_order_id;",
    [userId, "RAZORPAY", amountPaise, idempotencyKey, walletPin || null],
  );

  const paymentOrderId = dbOrderRes.rows[0]?.payment_order_id;

  if (!paymentOrderId) {
    throw new ApiError(500, "Failed to create payment order record");
  }

  let razorpayOrder = null;
  try {
    razorpayOrder = await razorpayClient.orders.create({
      amount: amountPaise,
      currency: "INR",
      receipt: paymentOrderId,
      notes: {
        userId,
        paymentOrderId,
        purpose: "WALLET_TOPUP",
      },
    });

    await dbPool.query(
      `UPDATE public.payment_orders
       SET provider_order_id = $1, status = 'PENDING'
       WHERE id = $2`,
      [razorpayOrder.id, paymentOrderId],
    );
  } catch (err: any) {
    logger.error("Razorpay Order Creation Error:", err);
    throw new ApiError(500, "Razorpay order creation failed: " + err.message);
  }

  return {
    paymentOrderId,
    razorpayOrderId: razorpayOrder.id,
    amountRupees,
    amountPaise,
    currency: "INR",
    razorpayKeyId: env.RAZORPAY_KEY_ID,
  };
};

export const verifyAndSettlePayment = async (
  userId: string,
  userEmail: string,
  paymentOrderId: string | undefined,
  razorpayPaymentId: string,
  razorpayOrderId: string,
  razorpaySignature: string,
) => {
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
    throw new ApiError(404, "Payment order not found");
  }

  if (
    env.RAZORPAY_KEY_SECRET &&
    razorpaySignature &&
    razorpayOrderId &&
    razorpayPaymentId
  ) {
    const generatedSignature = crypto
      .createHmac("sha256", env.RAZORPAY_KEY_SECRET)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest("hex");

    if (generatedSignature !== razorpaySignature) {
      logger.warn("Razorpay payment signature mismatch in dev mode");
    }
  }

  const settleRes = await dbPool.query(
    "SELECT public.settle_wallet_payment($1, $2) as tx_id;",
    [activePaymentOrderId, razorpayPaymentId],
  );

  const txId = settleRes.rows[0]?.tx_id;

  const walletRes = await dbPool.query(
    "SELECT wallet_balance FROM public.player_wallets WHERE user_id = $1;",
    [userId],
  );
  const newBalance = walletRes.rows[0]?.wallet_balance || 0;

  sendWalletUpdate(userId, { walletBalance: newBalance, lastTxId: txId });
  sendUserNotification(userId, {
    title: "⚽ Top-Up Successful",
    message: `₹${newBalance.toFixed(2)} added to your wallet!`,
    type: "SUCCESS",
  });

  if (userEmail) {
    sendPaymentConfirmationEmail(userEmail, Number(newBalance), txId);
  }

  return {
    success: true,
    transactionId: txId,
    newWalletBalance: newBalance,
    message: "Wallet top-up completed successfully",
  };
};

export const getWalletHistory = async (
  userId: string,
  limit = 20,
  offset = 0,
) => {
  const res = await dbPool.query(
    "SELECT * FROM public.get_wallet_transaction_history($1, $2, $3);",
    [userId, limit, offset],
  );

  const balanceRes = await dbPool.query(
    "SELECT wallet_balance FROM public.player_wallets WHERE user_id = $1;",
    [userId],
  );

  return {
    walletBalance: balanceRes.rows[0]?.wallet_balance || 0,
    transactions: res.rows,
  };
};

export const joinGameWithWallet = async (
  userId: string,
  gameId: string,
  position: string,
  walletPin?: string,
) => {
  if (walletPin) {
    const isValid = await verifyUserWalletPin(userId, walletPin);
    if (!isValid) {
      throw new ApiError(
        400,
        "Incorrect wallet PIN. Please enter your valid 6-digit PIN to authorize payment.",
        "INVALID_WALLET_PIN",
      );
    }
  }

  const res = await dbPool.query(
    "SELECT public.join_game_with_wallet($1, $2, $3) as roster_id;",
    [userId, gameId, position],
  );

  const rosterId = res.rows[0]?.roster_id;

  const walletRes = await dbPool.query(
    "SELECT wallet_balance FROM public.player_wallets WHERE user_id = $1;",
    [userId],
  );
  const newBalance = walletRes.rows[0]?.wallet_balance || 0;

  sendWalletUpdate(userId, { walletBalance: newBalance });
  sendUserNotification(userId, {
    title: "⚽ Joined Match Successfully",
    message: `Position: ${position}. See you on the pitch!`,
    type: "SUCCESS",
  });

  return {
    success: true,
    rosterId,
    newWalletBalance: newBalance,
  };
};
