import bcrypt from 'bcryptjs';
import { dbPool } from '../config/db.config.js';
import { sendOTP } from './email.service.js';
import { ApiError } from '../utils/apiResponse.js';
import { logger } from '../utils/logger.js';

export const generateNumericOTP = (): string => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Generate OTP, store hash in otp_verifications DB table, and send via Email/Resend
 */
export const createAndSendOTP = async (
  identifier: string,
  purpose: 'REGISTRATION' | 'LOGIN' | 'WALLET_TOPUP' | 'PASSWORD_RESET' = 'LOGIN',
  userId?: string | null
): Promise<{ success: boolean; message: string }> => {
  const normalizedIdentifier = identifier.trim().toLowerCase();
  const rawOTP = generateNumericOTP();
  // Store plain numeric OTP in DB (not hashed) so it can be viewed directly
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry

  // Invalidate any existing unused OTPs for this identifier & purpose
  await dbPool.query(
    `UPDATE public.otp_verifications
     SET is_used = TRUE
     WHERE identifier = $1 AND purpose = $2 AND is_used = FALSE`,
    [normalizedIdentifier, purpose]
  );

  // Insert new OTP record with plain numeric OTP in otp_hash column
  await dbPool.query(
    `INSERT INTO public.otp_verifications
     (user_id, identifier, channel, purpose, otp_hash, attempt_count, max_attempts, is_used, expires_at)
     VALUES ($1, $2, 'EMAIL', $3, $4, 0, 5, FALSE, $5)`,
    [userId || null, normalizedIdentifier, purpose, rawOTP, expiresAt]
  );

  // Update latest_otp in public.users table in simple numeric format
  try {
    const digitsOnly = normalizedIdentifier.replace(/[^0-9]/g, '');
    await dbPool.query(
      `UPDATE public.users
       SET latest_otp = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
          OR LOWER(email) = $3
          OR phone = $4
          OR ($5 <> '' AND LENGTH($5) >= 10 AND RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 10) = RIGHT($5, 10))`,
      [rawOTP, userId || null, normalizedIdentifier, normalizedIdentifier, digitsOnly]
    );
    logger.info(`🔢 latest_otp (${rawOTP}) updated in public.users for: ${normalizedIdentifier}`);
  } catch (err: any) {
    logger.warn(`Failed to update latest_otp on users table: ${err.message}`);
  }

  // Send OTP via Resend API / Email
  await sendOTP(userId, normalizedIdentifier, rawOTP);

  return {
    success: true,
    message: `OTP sent successfully to ${normalizedIdentifier}`,
  };
};

/**
 * Verify OTP against database record
 */
export const verifyOTP = async (
  identifier: string,
  otp: string,
  purpose: 'REGISTRATION' | 'LOGIN' | 'WALLET_TOPUP' | 'PASSWORD_RESET' = 'LOGIN'
): Promise<boolean> => {
  const normalizedIdentifier = identifier.trim().toLowerCase();

  const queryRes = await dbPool.query(
    `SELECT * FROM public.otp_verifications
     WHERE identifier = $1 AND purpose = $2 AND is_used = FALSE AND expires_at > CURRENT_TIMESTAMP
     ORDER BY created_at DESC LIMIT 1`,
    [normalizedIdentifier, purpose]
  );

  if (queryRes.rows.length === 0) {
    throw new ApiError(400, 'Invalid or expired OTP. Please request a new code.');
  }

  const otpRecord = queryRes.rows[0];

  if (otpRecord.attempt_count >= otpRecord.max_attempts) {
    throw new ApiError(400, 'Maximum OTP attempts exceeded. Please request a new OTP.');
  }

  // Support plain text match directly, with bcrypt fallback
  const isMatch = otpRecord.otp_hash === otp || (await bcrypt.compare(otp, otpRecord.otp_hash).catch(() => false));

  if (!isMatch) {
    await dbPool.query(
      `UPDATE public.otp_verifications
       SET attempt_count = attempt_count + 1
       WHERE id = $1`,
      [otpRecord.id]
    );
    throw new ApiError(400, 'Incorrect OTP code');
  }

  // Mark OTP as used
  await dbPool.query(
    `UPDATE public.otp_verifications
     SET is_used = TRUE, used_at = CURRENT_TIMESTAMP
     WHERE id = $1`,
    [otpRecord.id]
  );

  logger.info(`✅ OTP verified successfully for ${normalizedIdentifier} (${purpose})`);
  return true;
};
