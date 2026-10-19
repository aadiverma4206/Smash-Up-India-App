import { Resend } from "resend";
import { env } from "../config/env.config.js";
import { logger } from "../utils/logger.js";
import { dbPool } from "../config/db.config.js";

let cachedResend: Resend | null = null;
let lastApiKey: string = "";

/**
 * Returns a configured Resend instance using current environment variables.
 * Dynamically reloads if process.env.RESEND_API_KEY changes in .env.
 */
export const getResendClient = (): Resend | null => {
  const currentKey = (
    process.env.RESEND_API_KEY ||
    env.RESEND_API_KEY ||
    ""
  ).trim();
  if (
    !currentKey ||
    currentKey.startsWith("re_1234") ||
    currentKey.includes("dummy")
  ) {
    return null;
  }
  if (!cachedResend || lastApiKey !== currentKey) {
    cachedResend = new Resend(currentKey);
    lastApiKey = currentKey;
  }
  return cachedResend;
};

/**
 * Direct export for Resend client proxy - preserves compatibility with direct Resend usage
 */
export const resend = new Proxy({} as Resend, {
  get(_target, prop) {
    const client = getResendClient();
    if (!client) {
      throw new Error(
        "Resend client is not configured. Please set RESEND_API_KEY in .env",
      );
    }
    return (client as any)[prop];
  },
});

/**
 * Resolves the sender email address from environment variables.
 * Supports both raw email ("zold@support.zold.in") and standard RFC format ("All Stars Arena <zold@support.zold.in>").
 */
export const getSenderEmail = (): string => {
  const configured = (
    process.env.EMAIL_FROM ||
    env.EMAIL_FROM ||
    "zold@support.zold.in"
  ).trim();
  if (!configured) {
    return "All Stars Arena <zold@support.zold.in>";
  }
  if (configured.includes("<") && configured.includes(">")) {
    return configured;
  }
  return `All Stars Arena <${configured}>`;
};

/**
 * Core email sending function using Resend API with comprehensive diagnostics
 */
export const sendEmail = async (
  to: string,
  subject: string,
  html: string,
): Promise<boolean> => {
  const client = getResendClient();
  const apiKey = (
    process.env.RESEND_API_KEY ||
    env.RESEND_API_KEY ||
    ""
  ).trim();

  if (client && apiKey && !apiKey.includes("dummy")) {
    try {
      const fromAddress = getSenderEmail();
      const { data, error } = await client.emails.send({
        from: fromAddress,
        to,
        subject,
        html,
      });

      if (error) {
        logger.error(
          { error },
          `❌ [Resend Error] Failed to send email to ${to}`,
        );
        if (
          (error as any).statusCode === 401 ||
          (error as any).message?.toLowerCase().includes("invalid")
        ) {
          logger.error(
            `⚠️ [API KEY ERROR] Your RESEND_API_KEY in .env is INVALID or EXPIRED.`,
          );
          logger.error(
            `💡 Solution: Replace RESEND_API_KEY in backend/.env with a valid key.`,
          );
        }
        return false;
      }

      logger.info(`✅ [Resend Success] Email sent to ${to} (ID: ${data?.id})`);
      return true;
    } catch (err: any) {
      logger.error(
        `❌ [Resend Exception] Error sending email to ${to}: ${err.message}`,
      );
      return false;
    }
  }

  // Fallback log for development when no valid Resend key is set
  logger.warn(
    `⚠️ [Email Warning] No active RESEND_API_KEY configured in .env. Falling back to dev logger.`,
  );
  logger.info(`\n========================================`);
  logger.info(`📧 [DEV EMAIL FALLBACK] To: ${to} | Subject: ${subject}`);
  logger.info(`========================================\n`);
  return true;
};

/**
 * Sends OTP verification email with custom styled HTML template.
 * Supports both (userEmail, otp) and (userId, userEmail, otp) signatures.
 */
export const sendOTP = async (
  userEmailOrUserId: string | null | undefined,
  otpOrEmail: string,
  maybeOtp?: string,
): Promise<boolean> => {
  let userId: string | null = null;
  let userEmail = "";
  let otp = "";

  if (maybeOtp !== undefined) {
    userId = userEmailOrUserId || null;
    userEmail = (otpOrEmail || "").trim().toLowerCase();
    otp = maybeOtp;
  } else {
    userEmail = (userEmailOrUserId || "").trim().toLowerCase();
    otp = otpOrEmail;
  }

  const subject = "⚽ All Stars Arena - Your Verification OTP";
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #0d1117; color: #ffffff; border-radius: 12px; overflow: hidden; border: 1px solid #30363d;">
      <div style="background: linear-gradient(135deg, #1f6feb 0%, #1158c7 100%); padding: 32px 24px; text-align: center;">
        <h1 style="margin: 0; font-size: 26px; font-weight: 700; color: #ffffff; letter-spacing: 1px;">⚽ ALL STARS ARENA</h1>
        <p style="margin: 6px 0 0 0; font-size: 14px; color: #e1e4e8;">Turf & Football Arena Management</p>
      </div>
      <div style="padding: 32px 24px;">
        <h2 style="margin-top: 0; color: #ffffff; font-size: 20px;">Email Verification Code</h2>
        <p style="color: #8b949e; font-size: 15px; line-height: 1.6;">
          Your One-Time Password (OTP) for verification is:
        </p>
        <div style="background-color: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 20px; text-align: center; margin: 28px 0;">
          <span style="font-size: 38px; font-weight: 800; letter-spacing: 10px; color: #58a6ff; font-family: monospace;">${otp}</span>
        </div>
        <p style="color: #8b949e; font-size: 14px; line-height: 1.5;">
          ⏱️ This code will expire in <strong>10 minutes</strong>. If you did not request this verification code, please ignore this email.
        </p>
        <hr style="border: none; border-top: 1px solid #30363d; margin: 28px 0;" />
        <p style="color: #6e7681; font-size: 12px; margin: 0; text-align: center;">
          Recipient: ${userEmail} • &copy; ${new Date().getFullYear()} All Stars Arena. All rights reserved.
        </p>
      </div>
    </div>
  `;

  if (process.env.NODE_ENV !== "production") {
    logger.info(`\n========================================`);
    logger.info(`🔑 DEV OTP for ${userEmail}: ${otp}`);
    logger.info(`========================================\n`);
  }

  // Update latest_otp in database if userId was provided
  if (userId) {
    try {
      await dbPool.query(
        `UPDATE public.users SET latest_otp = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`,
        [otp, userId],
      );
    } catch (err: any) {
      logger.warn(
        `Could not update users.latest_otp for userId ${userId}: ${err.message}`,
      );
    }
  }

  return await sendEmail(userEmail, subject, html);
};

export const sendPaymentConfirmationEmail = async (
  userEmail: string,
  amountRupees: number,
  txId: string,
): Promise<boolean> => {
  const subject = "⚽ All Stars Arena - Wallet Top-Up Successful!";
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #0d1117; color: #ffffff; border-radius: 12px; overflow: hidden; border: 1px solid #30363d;">
      <div style="background: linear-gradient(135deg, #2ea44f 0%, #238636 100%); padding: 32px 24px; text-align: center;">
        <h1 style="margin: 0; font-size: 26px; font-weight: 700; color: #ffffff; letter-spacing: 1px;">⚽ Payment Confirmed</h1>
        <p style="margin: 6px 0 0 0; font-size: 14px; color: #e1e4e8;">Wallet Top-Up Successful</p>
      </div>
      <div style="padding: 32px 24px;">
        <p style="font-size: 16px; color: #c9d1d9;">Your wallet top-up on All Stars Arena was completed successfully.</p>
        <div style="background-color: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 20px; margin: 20px 0;">
          <p style="margin: 6px 0; color: #8b949e;">Amount Added: <strong style="color: #58a6ff; font-size: 18px;">₹${amountRupees.toFixed(2)}</strong></p>
          <p style="margin: 6px 0; color: #8b949e;">Transaction ID: <span style="font-family: monospace; color: #f0f6fc;">${txId}</span></p>
        </div>
        <p style="color: #8b949e; margin-top: 20px;">Get ready for your next pitch match!</p>
      </div>
    </div>
  `;

  return await sendEmail(userEmail, subject, html);
};

export interface AdminDetails {
  name: string;
  email: string;
  phone?: string;
}

export const sendAdminApprovalEmail = async (
  adminDetails: AdminDetails,
  approvalLink: string,
): Promise<boolean> => {
  const subject = "⚽ All Stars Arena - Admin Approval Required";
  const html = `
    <div style="font-family: Arial, sans-serif; background-color: #0d1117; color: #ffffff; padding: 24px; border-radius: 8px;">
      <h2 style="color: #2ea44f;">⚽ New Admin Approval Request</h2>
      <p>A new user has registered and requested administrative access:</p>
      <p><strong>Name:</strong> ${adminDetails.name}</p>
      <p><strong>Email:</strong> ${adminDetails.email}</p>
      ${adminDetails.phone ? `<p><strong>Phone:</strong> ${adminDetails.phone}</p>` : ""}
      <br/>
      <p>Click below to approve:</p>
      <a href="${approvalLink}" style="padding: 12px 24px; background-color: #2ea44f; color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Approve Admin</a>
    </div>
  `;
  return await sendEmail(
    process.env.ADMIN_NOTIFY_EMAIL || "vikashchaudhari103@gmail.com",
    subject,
    html,
  );
};

export const sendApprovalNotificationToAdmin = async (
  adminEmail: string,
): Promise<boolean> => {
  const subject = "⚽ All Stars Arena - Admin Access Approved!";
  const html = `
    <div style="font-family: Arial, sans-serif; background-color: #0d1117; color: #ffffff; padding: 24px; border-radius: 8px;">
      <h2 style="color: #2ea44f;">⚽ Access Approved!</h2>
      <p>Your request for Admin access has been approved.</p>
      <p>You can now log in to the All Stars Arena Management Dashboard.</p>
    </div>
  `;
  return await sendEmail(adminEmail, subject, html);
};
