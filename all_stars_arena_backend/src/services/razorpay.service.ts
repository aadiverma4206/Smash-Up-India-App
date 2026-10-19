import Razorpay from "razorpay";
import { env } from "../config/env.config.js";

export const razorpayClient = new Razorpay({
  key_id: env.RAZORPAY_KEY_ID,
  key_secret: env.RAZORPAY_KEY_SECRET,
});

export const createRazorpayOrder = async (
  amount: number,
  currency = "INR",
  receipt?: string,
) => {
  const options = {
    amount: amount * 100, // Amount in paise
    currency,
    receipt: receipt || `receipt_${Date.now()}`,
  };

  return await razorpayClient.orders.create(options);
};
