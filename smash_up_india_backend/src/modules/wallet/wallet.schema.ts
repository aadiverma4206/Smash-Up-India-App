import { z } from "zod";

export const setWalletPinSchema = z.object({
  body: z.object({
    pin: z
      .string()
      .regex(/^\d{6}$/, "Wallet PIN must be exactly 6 numeric digits"),
  }),
});

export const changeWalletPinSchema = z.object({
  body: z.object({
    oldPin: z
      .string()
      .regex(/^\d{6}$/, "Old Wallet PIN must be exactly 6 numeric digits"),
    newPin: z
      .string()
      .regex(/^\d{6}$/, "New Wallet PIN must be exactly 6 numeric digits"),
  }),
});

export const verifyWalletPinSchema = z.object({
  body: z.object({
    pin: z
      .string()
      .regex(/^\d{6}$/, "Wallet PIN must be exactly 6 numeric digits"),
  }),
});

export const topupOrderSchema = z.object({
  body: z.object({
    amountRupees: z
      .number()
      .min(1, "Minimum top-up is ₹1")
      .max(200000, "Maximum single top-up is ₹2,00,000"),
    idempotencyKey: z.string().optional(),
    walletPin: z.string().optional(),
  }),
});

export const topupVerifySchema = z.object({
  body: z.object({
    paymentOrderId: z.string().optional(),
    razorpayPaymentId: z.string().min(1, "Razorpay payment ID is required"),
    razorpayOrderId: z.string().min(1, "Razorpay order ID is required"),
    razorpaySignature: z.string().optional(),
  }),
});

export const getTransactionsSchema = z.object({
  query: z.object({
    limit: z.coerce.number().int().min(1).max(200).default(50),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});
