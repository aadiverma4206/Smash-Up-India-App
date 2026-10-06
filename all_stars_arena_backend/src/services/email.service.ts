import { Resend } from 'resend';
import { env } from '../config/env.config.js';
import { logger } from '../utils/logger.js';

const resend = env.RESEND_API_KEY ? new Resend(env.RESEND_API_KEY) : null;

export const sendEmail = async (to: string, subject: string, html: string): Promise<boolean> => {
  if (resend && env.RESEND_API_KEY && !env.RESEND_API_KEY.includes('dummy')) {
    try {
      const { data, error } = await resend.emails.send({
        from: env.EMAIL_FROM,
        to,
        subject,
        html,
      });

      if (error) {
        logger.error({ error }, `❌ [Resend API Error] Failed to send email to ${to}`);
        return false;
      }

      logger.info(`✅ [Resend API Success] Email sent to ${to} (ID: ${data?.id})`);
      return true;
    } catch (err: any) {
      logger.error(`❌ [Resend Exception] Error sending email to ${to}:`, err.message);
      return false;
    }
  }

  // Fallback log for development
  logger.info(`\n========================================`);
  logger.info(`📧 [EMAIL LOG - DEV] To: ${to} | Subject: ${subject}`);
  logger.info(`========================================\n`);
  return true;
};

export const sendOTP = async (userEmail: string, otp: string): Promise<boolean> => {
  const subject = '⚽ All Stars Arena - Your OTP Verification Code';
  const html = `
    <div style="font-family: Arial, sans-serif; background-color: #0d1117; color: #ffffff; padding: 20px; border-radius: 8px;">
      <h2 style="color: #2ea44f;">⚽ All Stars Arena Football</h2>
      <p>Use the following One-Time Password (OTP) to complete your verification:</p>
      <div style="background-color: #161b22; padding: 15px; border-radius: 6px; text-align: center; margin: 20px 0;">
        <h1 style="color: #58a6ff; letter-spacing: 6px; font-size: 32px; margin: 0;">${otp}</h1>
      </div>
      <p style="color: #8b949e; font-size: 14px;">This code is valid for 10 minutes. Do not share this OTP with anyone.</p>
    </div>
  `;

  logger.info(`🔑 DEV OTP for ${userEmail}: ${otp}`);
  return await sendEmail(userEmail, subject, html);
};

export const sendPaymentConfirmationEmail = async (
  userEmail: string,
  amountRupees: number,
  txId: string
): Promise<boolean> => {
  const subject = '⚽ All Stars Arena - Wallet Top-Up Successful!';
  const html = `
    <div style="font-family: Arial, sans-serif; background-color: #0d1117; color: #ffffff; padding: 20px; border-radius: 8px;">
      <h2 style="color: #2ea44f;">⚽ Payment Confirmed</h2>
      <p>Your wallet top-up on All Stars Arena was successful!</p>
      <p><strong>Amount Added:</strong> ₹${amountRupees.toFixed(2)}</p>
      <p><strong>Transaction ID:</strong> ${txId}</p>
      <p style="color: #8b949e; margin-top: 20px;">Get ready for your next pitch match!</p>
    </div>
  `;

  return await sendEmail(userEmail, subject, html);
};
