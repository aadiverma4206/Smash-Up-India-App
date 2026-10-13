import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import jwt, { SignOptions } from 'jsonwebtoken';
import { AuthRepository } from './auth.repository.js';
import { createAndSendOTP, verifyOTP } from '../../services/otp.service.js';
import { sendEmail } from '../../services/email.service.js';
import { env } from '../../config/env.config.js';
import { ApiError } from '../../utils/apiResponse.js';
import { logger } from '../../utils/logger.js';
import { dbPool } from '../../config/db.config.js';

export class AuthService {
  /**
   * Helper: Hash refresh token with SHA-256
   */
  private static hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * Step 1: Send Registration OTP
   */
  static async sendRegisterOtp(data: {
    name: string;
    email: string;
    phone: string;
    city?: string;
  }) {
    const normalizedEmail = data.email.trim().toLowerCase();
    const normalizedPhone = data.phone.trim();

    // Check duplicate email or phone in user_identity_history
    const existing = await AuthRepository.checkIdentityExists(normalizedEmail, normalizedPhone);
    if (existing.length > 0) {
      throw new ApiError(
        400,
        'An account with this email or phone number already exists',
        'DUPLICATE_ACCOUNT'
      );
    }

    // Send Email OTP
    await createAndSendOTP(normalizedEmail, 'REGISTRATION');

    // Also update users.latest_otp if user exists by phone
    try {
      const digitsOnly = normalizedPhone.replace(/[^0-9]/g, '');
      await dbPool.query(
        `UPDATE public.users
         SET latest_otp = (
           SELECT otp_hash FROM public.otp_verifications
           WHERE identifier = $1 AND purpose = 'REGISTRATION'
           ORDER BY created_at DESC LIMIT 1
         ), updated_at = CURRENT_TIMESTAMP
         WHERE LOWER(email) = $1
            OR phone = $2
            OR ($3 <> '' AND LENGTH($3) >= 10 AND RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 10) = RIGHT($3, 10))`,
        [normalizedEmail, normalizedPhone, digitsOnly]
      );
    } catch (err: any) {
      // Non-critical
    }

    return {
      message: 'Verification OTP sent to email and phone number',
      email: normalizedEmail,
      phone: normalizedPhone,
    };
  }

  /**
   * Resend OTP (Registration or Account Verification)
   */
  static async resendOtp(data: { email?: string; identifier?: string }) {
    const rawTarget = data.email || data.identifier || '';
    const normalizedTarget = rawTarget.trim().toLowerCase();

    if (!normalizedTarget) {
      throw new ApiError(400, 'Email is required');
    }

    const user = await AuthRepository.findUserByIdentifier(normalizedTarget);
    if (user) {
      await createAndSendOTP(user.email, 'LOGIN', user.id);
      return {
        message: 'OTP resent successfully to your email',
        email: user.email,
      };
    }

    await createAndSendOTP(normalizedTarget, 'REGISTRATION');
    return {
      message: 'Verification OTP resent to your email',
      email: normalizedTarget,
    };
  }

  /**
   * Step 2: Verify Registration OTP
   */
  static async verifyRegisterOtp(data: {
    email: string;
    phone: string;
    emailOtp: string;
  }) {
    const normalizedEmail = data.email.trim().toLowerCase();
    const normalizedPhone = data.phone.trim();

    // Verify Email OTP against DB
    await verifyOTP(normalizedEmail, data.emailOtp, 'REGISTRATION');

    // Generate Short-Lived Verification Token (15 minutes expiry)
    const signOptions: SignOptions = { expiresIn: '15m' };
    const verificationToken = jwt.sign(
      { email: normalizedEmail, phone: normalizedPhone, purpose: 'REGISTER_VERIFICATION' },
      env.JWT_SECRET,
      signOptions
    );

    return {
      message: 'OTP verified successfully',
      verificationToken,
    };
  }

  /**
   * Step 3: Complete Player Registration (PLAYER ONLY)
   */
  static async registerPlayer(data: {
    name: string;
    email: string;
    phone: string;
    password: string;
    city: string;
    verificationToken: string;
  }) {
    // Verify Short-Lived Registration Verification Token
    try {
      const decoded = jwt.verify(data.verificationToken, env.JWT_SECRET) as any;
      if (
        decoded.purpose !== 'REGISTER_VERIFICATION' ||
        decoded.email !== data.email.trim().toLowerCase()
      ) {
        throw new ApiError(400, 'Invalid or expired registration verification token', 'INVALID_VERIFICATION_TOKEN');
      }
    } catch (err) {
      throw new ApiError(400, 'Invalid or expired registration verification token', 'INVALID_VERIFICATION_TOKEN');
    }

    const normalizedEmail = data.email.trim().toLowerCase();
    const normalizedPhone = data.phone.trim();

    // Double check if account exists before completing registration
    const existing = await AuthRepository.checkIdentityExists(normalizedEmail, normalizedPhone);
    if (existing.length > 0) {
      throw new ApiError(
        400,
        'An account with this email or phone number already exists',
        'DUPLICATE_ACCOUNT'
      );
    }

    // Hash Password with Bcrypt Cost Factor 12
    const passwordHash = await bcrypt.hash(data.password, 12);

    // Call DB Stored Function register_player (Role ID 3 = PLAYER only)
    const userId = await AuthRepository.registerPlayer({
      name: data.name.trim(),
      email: normalizedEmail,
      phone: normalizedPhone,
      passwordHash,
      city: data.city || 'Raipur',
    });

    if (!userId) {
      throw new ApiError(500, 'Failed to create player account');
    }

    // Set latest_otp on the newly registered player in public.users
    try {
      await dbPool.query(
        `UPDATE public.users
         SET latest_otp = (
           SELECT otp_hash FROM public.otp_verifications
           WHERE identifier = $1 AND purpose = 'REGISTRATION'
           ORDER BY created_at DESC LIMIT 1
         )
         WHERE id = $2;`,
        [data.email.trim().toLowerCase(), userId]
      );
    } catch (err: any) {
      // Non-critical
    }

    // Create Access & Refresh Tokens
    const tokenData = await this.generateTokensAndSession(userId, normalizedEmail, 3);
    const userProfile = await this.getMe(userId);

    return {
      user: userProfile,
      ...tokenData,
    };
  }

  /**
   * Login User (Email OR Phone + Password)
   */
  static async loginUser(
    identifier: string,
    password: string,
    deviceInfo = 'Mobile App',
    ipAddress = '127.0.0.1'
  ) {
    const user = await AuthRepository.findUserByIdentifier(identifier);

    if (!user) {
      throw new ApiError(401, 'Invalid credentials', 'INVALID_CREDENTIALS');
    }

    if (user.status === 'SUSPENDED') {
      throw new ApiError(403, 'Account is suspended. Please contact support.', 'ACCOUNT_SUSPENDED');
    }

    if (user.locked_until && new Date(user.locked_until) > new Date()) {
      throw new ApiError(
        429,
        `Account is locked due to too many failed attempts. Try again after ${user.locked_until}.`,
        'ACCOUNT_LOCKED'
      );
    }

    // Verify Password with Bcrypt
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      await dbPool.query('SELECT public.record_failed_login($1);', [user.id]);
      throw new ApiError(401, 'Invalid credentials', 'INVALID_CREDENTIALS');
    }

    // Record Successful Login
    await dbPool.query('SELECT public.record_successful_login($1);', [user.id]);

    // Build Role Payload
    let roleSpecificData: any = {};

    if (user.role_id === 1) {
      // ADMIN
      roleSpecificData = {
        adminType: user.admin_type,
        isOwner: Boolean(user.is_owner),
      };
    } else if (user.role_id === 2) {
      // MANAGER
      const clubIds = await AuthRepository.getManagerClubIds(user.id);
      roleSpecificData = {
        employeeCode: user.employee_code,
        assignedClubIds: clubIds,
      };
    } else if (user.role_id === 3) {
      // PLAYER
      const playerInfo = await AuthRepository.getPlayerInfo(user.id);
      roleSpecificData = {
        playerDetails: playerInfo.details,
        playerStats: playerInfo.stats,
      };
    }

    const tokenData = await this.generateTokensAndSession(
      user.id,
      user.email,
      user.role_id,
      deviceInfo,
      ipAddress
    );

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        roleId: user.role_id,
        roleName: user.role_id === 1 ? 'ADMIN' : user.role_id === 2 ? 'MANAGER' : 'PLAYER',
        status: user.status,
        city: user.city,
        profileImageUrl: user.profile_image_url,
        ...roleSpecificData,
      },
      ...tokenData,
    };
  }

  /**
   * Refresh Access & Rotating Refresh Token
   */
  static async refreshTokens(refreshToken: string) {
    const refreshTokenHash = this.hashToken(refreshToken);
    const session = await AuthRepository.findSessionByHash(refreshTokenHash);

    if (!session) {
      throw new ApiError(401, 'Invalid refresh token', 'INVALID_REFRESH_TOKEN');
    }

    // Reuse Detection: If session was already revoked, revoke ENTIRE session family
    if (session.is_revoked) {
      logger.warn(`🚨 Refresh Token Reuse Detected! Revoking all sessions for user ${session.user_id}`);
      await AuthRepository.revokeAllUserSessions(session.user_id);
      throw new ApiError(
        401,
        'Security Alert: Refresh token reuse detected. All sessions revoked.',
        'TOKEN_REUSE_DETECTED'
      );
    }

    if (new Date(session.expires_at) < new Date()) {
      throw new ApiError(401, 'Refresh token expired', 'EXPIRED_REFRESH_TOKEN');
    }

    // Revoke current session (Rotation)
    await AuthRepository.revokeSession(session.id);

    // Fetch User
    const userRes = await dbPool.query('SELECT email, role_id FROM public.users WHERE id = $1;', [
      session.user_id,
    ]);
    const user = userRes.rows[0];

    // Issue New Rotating Tokens
    return await this.generateTokensAndSession(
      session.user_id,
      user.email,
      user.role_id,
      session.device_info,
      session.ip_address
    );
  }

  /**
   * Helper: Generate Access Token + Rotating Refresh Token & Session
   */
  private static async generateTokensAndSession(
    userId: string,
    email: string,
    roleId: number,
    deviceInfo = 'Mobile App',
    ipAddress = '127.0.0.1'
  ) {
    const accessSignOptions: SignOptions = { expiresIn: (env.JWT_EXPIRES_IN || '7d') as any };
    const accessToken = jwt.sign(
      { id: userId, email, roleId },
      env.JWT_SECRET,
      accessSignOptions
    );

    const refreshSignOptions: SignOptions = { expiresIn: (env.JWT_REFRESH_EXPIRES_IN || '30d') as any };
    const refreshToken = jwt.sign(
      { id: userId, email, nonce: crypto.randomUUID() },
      env.JWT_REFRESH_SECRET,
      refreshSignOptions
    );

    const refreshTokenHash = this.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await AuthRepository.createSession({
      userId,
      refreshTokenHash,
      deviceInfo,
      ipAddress,
      expiresAt,
    });

    return {
      accessToken,
      refreshToken,
      expiresInSeconds: 7 * 24 * 60 * 60,
    };
  }

  /**
   * Forgot Password - Step 1: Send OTP
   */
  static async forgotPasswordSendOtp(identifier: string) {
    const user = await AuthRepository.findUserByIdentifier(identifier);
    if (!user) {
      // Generic response to prevent account enumeration
      return { message: 'If an account exists, a password reset OTP has been sent.' };
    }

    await createAndSendOTP(user.email, 'PASSWORD_RESET', user.id);
    return { message: 'If an account exists, a password reset OTP has been sent.' };
  }

  /**
   * Forgot Password - Step 2: Verify OTP & Return Reset Token
   */
  static async forgotPasswordVerifyOtp(identifier: string, otp: string) {
    const user = await AuthRepository.findUserByIdentifier(identifier);
    if (!user) {
      throw new ApiError(400, 'Invalid request', 'INVALID_REQUEST');
    }

    await verifyOTP(user.email, otp, 'PASSWORD_RESET');

    const signOptions: SignOptions = { expiresIn: '15m' };
    const resetToken = jwt.sign(
      { userId: user.id, purpose: 'PASSWORD_RESET' },
      env.JWT_SECRET,
      signOptions
    );

    return {
      message: 'OTP verified successfully',
      resetToken,
    };
  }

  /**
   * Forgot Password - Step 3: Reset Password (Invalidates all active user sessions)
   */
  static async resetPassword(resetToken: string, newPassword: string) {
    let userId = '';
    try {
      const decoded = jwt.verify(resetToken, env.JWT_SECRET) as any;
      if (decoded.purpose !== 'PASSWORD_RESET' || !decoded.userId) {
        throw new ApiError(400, 'Invalid password reset token', 'INVALID_RESET_TOKEN');
      }
      userId = decoded.userId;
    } catch (err) {
      throw new ApiError(400, 'Invalid or expired password reset token', 'INVALID_RESET_TOKEN');
    }

    const newPasswordHash = await bcrypt.hash(newPassword, 12);
    await AuthRepository.updatePassword(userId, newPasswordHash);

    logger.info(`🔑 Password reset completed for user ${userId}. All active sessions invalidated.`);
    return { message: 'Password reset successfully. Please log in with your new password.' };
  }

  /**
   * Get User Profile (`/auth/me`)
   */
  static async getMe(userId: string) {
    const userRes = await dbPool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.role_id, u.status, u.city, u.profile_image_url,
              ad.admin_type, ad.is_owner, md.employee_code
       FROM public.users u
       LEFT JOIN public.admin_details ad ON ad.user_id = u.id
       LEFT JOIN public.manager_details md ON md.user_id = u.id
       WHERE u.id = $1;`,
      [userId]
    );

    if (userRes.rows.length === 0) {
      throw new ApiError(404, 'User not found', 'USER_NOT_FOUND');
    }

    const user = userRes.rows[0];
    let roleSpecificData: any = {};

    if (user.role_id === 1) {
      roleSpecificData = { adminType: user.admin_type, isOwner: Boolean(user.is_owner) };
    } else if (user.role_id === 2) {
      const clubIds = await AuthRepository.getManagerClubIds(userId);
      roleSpecificData = { employeeCode: user.employee_code, assignedClubIds: clubIds };
    } else if (user.role_id === 3) {
      const playerInfo = await AuthRepository.getPlayerInfo(userId);
      roleSpecificData = { playerDetails: playerInfo.details, playerStats: playerInfo.stats };
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      roleId: user.role_id,
      roleName: user.role_id === 1 ? 'ADMIN' : user.role_id === 2 ? 'MANAGER' : 'PLAYER',
      status: user.status,
      city: user.city,
      profileImageUrl: user.profile_image_url,
      ...roleSpecificData,
    };
  }
}
