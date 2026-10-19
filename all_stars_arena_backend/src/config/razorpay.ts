import Razorpay from "razorpay";
import { env } from "./env.config.js";

export const razorpayClient = new Razorpay({
  key_id: env.RAZORPAY_KEY_ID || "rzp_dummy",
  key_secret: env.RAZORPAY_KEY_SECRET || "rzp_dummy_secret",
});
