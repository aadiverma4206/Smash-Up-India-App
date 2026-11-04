import crypto from "crypto";
import bcrypt from "bcryptjs";
import jwt, { SignOptions } from "jsonwebtoken";
import { AuthRepository } from "./auth.repository.js";
import { createAndSendOTP, verifyOTP } from "../../services/otp.service.js";
import { sendEmail } from "../../services/email.service.js";
import { env } from "../../config/env.config.js";
import { ApiError } from "../../utils/apiResponse.js";
import { logger } from "../../utils/logger.js";
import { dbPool } from "../../config/db.config.js";

export class AuthService {
  private static hashToken(token: string): string {
    return crypto.createHash("sha256").update(token).digest("hex");
  }

  static async sendRegisterOtp(data: {
    name?: string;
    email: string;
    phone: string;
    city?: string;
  }) {
    const normalizedEmail = data.email.trim().toLowerCase();
    const normalizedPhone = data.phone.trim();

    const existing = await AuthRepository.checkIdentityExists(
      normalizedEmail,
      normalizedPhone,
    );
    if (existing.length > 0) {
      throw new ApiError(
        400,
        "An account with this email or phone number already exists",
        "DUPLICATE_ACCOUNT",
      );
    }

    await createAndSendOTP(normalizedEmail, "REGISTRATION");

    try {
      const digitsOnly = normalizedPhone.replace(/[^0-9]/g, "");
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
        [normalizedEmail, normalizedPhone, digitsOnly],
      );
    } catch (err: any) {}

    return {
      message: "Verification OTP sent to email and phone number",
      email: normalizedEmail,
      phone: normalizedPhone,
    };
  }

  static async resendOtp(data: { email?: string; identifier?: string }) {
    const rawTarget = data.email || data.identifier || "";
    const normalizedTarget = rawTarget.trim().toLowerCase();

    if (!normalizedTarget) {
      throw new ApiError(400, "Email is required");
    }

    const user = await AuthRepository.findUserByIdentifier(normalizedTarget);
    if (user) {
      await createAndSendOTP(user.email, "LOGIN", user.id);
      return {
        message: "OTP resent successfully to your email",
        email: user.email,
      };
    }

    await createAndSendOTP(normalizedTarget, "REGISTRATION");
    return {
      message: "Verification OTP resent to your email",
      email: normalizedTarget,
    };
  }

  static async verifyRegisterOtp(data: {
    email: string;
    phone: string;
    name?: string;
    emailOtp: string;
  }) {
    const normalizedEmail = data.email.trim().toLowerCase();
    const normalizedPhone = data.phone.trim();

    await verifyOTP(normalizedEmail, data.emailOtp, "REGISTRATION");

    const signOptions: SignOptions = { expiresIn: "15m" };
    const verificationToken = jwt.sign(
      {
        name: data.name ? data.name.trim() : undefined,
        email: normalizedEmail,
        phone: normalizedPhone,
        purpose: "REGISTER_VERIFICATION",
      },
      env.JWT_SECRET,
      signOptions,
    );

    return {
      message: "OTP verified successfully",
      verificationToken,
    };
  }

  /**
   * Generates a unique username derived from the user's email address prefix.
   * Extracts everything before the '@' sign.
   * If that username already exists or is unavailable, generates an alternative unique username.
   */
  static async generateUniqueUsername(email: string): Promise<string> {
    const atPart = (email.split("@")[0] || "").trim();
    const base = atPart.split("+")[0].trim().toLowerCase();
    let baseUsername = base.replace(/[^a-z0-9._-]/g, "");
    baseUsername = baseUsername.replace(/^[._-]+|[._-]+$/g, "");
    if (!baseUsername) {
      baseUsername = "player";
    }
    if (baseUsername.length > 50) {
      baseUsername = baseUsername.substring(0, 50);
    }

    const isTaken = async (candidate: string): Promise<boolean> => {
      const res = await dbPool.query(
        `SELECT 1 FROM public.users WHERE LOWER(name) = LOWER($1) LIMIT 1;`,
        [candidate],
      );
      return (res.rowCount ?? 0) > 0;
    };

    if (!(await isTaken(baseUsername))) {
      return baseUsername;
    }

    const endsWithDigit = /\d$/.test(baseUsername);
    let counter = 1;
    while (counter <= 100) {
      const candidate = endsWithDigit
        ? `${baseUsername}_${counter}`
        : `${baseUsername}${counter}`;
      if (!(await isTaken(candidate))) {
        return candidate;
      }
      counter++;
    }

    while (true) {
      const randomSuffix = Math.floor(1000 + Math.random() * 9000);
      const candidate = `${baseUsername}_${randomSuffix}`;
      if (!(await isTaken(candidate))) {
        return candidate;
      }
    }
  }

  static async registerPlayer(data: {
    name?: string;
    email: string;
    phone: string;
    password: string;
    city?: string;
    verificationToken: string;
  }) {
    let decoded: any;
    try {
      decoded = jwt.verify(data.verificationToken, env.JWT_SECRET) as any;
      if (
        decoded.purpose !== "REGISTER_VERIFICATION" ||
        decoded.email !== data.email.trim().toLowerCase()
      ) {
        throw new ApiError(
          400,
          "Invalid or expired registration verification token",
          "INVALID_VERIFICATION_TOKEN",
        );
      }
    } catch (err) {
      throw new ApiError(
        400,
        "Invalid or expired registration verification token",
        "INVALID_VERIFICATION_TOKEN",
      );
    }

    const normalizedEmail = data.email.trim().toLowerCase();
    const normalizedPhone = data.phone.trim();

    const existing = await AuthRepository.checkIdentityExists(
      normalizedEmail,
      normalizedPhone,
    );
    if (existing.length > 0) {
      throw new ApiError(
        400,
        "An account with this email or phone number already exists",
        "DUPLICATE_ACCOUNT",
      );
    }

    // Use the actual Full Name entered by the user during registration
    const userFullName =
      (data.name || "").trim() || (decoded.name || "").trim() || "Player";

    const passwordHash = await bcrypt.hash(data.password, 12);

    const userId = await AuthRepository.registerPlayer({
      name: userFullName,
      email: normalizedEmail,
      phone: normalizedPhone,
      passwordHash,
      city: data.city || "Raipur",
    });

    if (!userId) {
      throw new ApiError(500, "Failed to create player account");
    }

    try {
      await dbPool.query(
        `UPDATE public.users
         SET latest_otp = (
           SELECT otp_hash FROM public.otp_verifications
           WHERE identifier = $1 AND purpose = 'REGISTRATION'
           ORDER BY created_at DESC LIMIT 1
         )
         WHERE id = $2;`,
        [data.email.trim().toLowerCase(), userId],
      );
    } catch (err: any) {}

    const tokenData = await this.generateTokensAndSession(
      userId,
      normalizedEmail,
      3,
    );
    const userProfile = await this.getMe(userId);

    return {
      user: userProfile,
      ...tokenData,
    };
  }

  static async loginUser(
    identifier: string,
    password: string,
    deviceInfo = "Mobile App",
    ipAddress = "127.0.0.1",
  ) {
    const user = await AuthRepository.findUserByIdentifier(identifier);

    if (!user) {
      throw new ApiError(401, "Invalid credentials", "INVALID_CREDENTIALS");
    }

    if (user.status === "SUSPENDED") {
      throw new ApiError(
        403,
        "Account is suspended. Please contact support.",
        "ACCOUNT_SUSPENDED",
      );
    }

    if (user.locked_until && new Date(user.locked_until) > new Date()) {
      throw new ApiError(
        429,
        `Account is locked due to too many failed attempts. Try again after ${user.locked_until}.`,
        "ACCOUNT_LOCKED",
      );
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      await dbPool.query("SELECT public.record_failed_login($1);", [user.id]);
      throw new ApiError(401, "Invalid credentials", "INVALID_CREDENTIALS");
    }

    await dbPool.query("SELECT public.record_successful_login($1);", [user.id]);

    let roleSpecificData: any = {};

    if (user.role_id === 1) {
      roleSpecificData = {
        adminType: user.admin_type,
        isOwner: Boolean(user.is_owner),
      };
    } else if (user.role_id === 2) {
      const clubIds = await AuthRepository.getManagerClubIds(user.id);
      roleSpecificData = {
        employeeCode: user.employee_code,
        assignedClubIds: clubIds,
      };
    } else if (user.role_id === 3) {
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
      ipAddress,
    );

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        roleId: user.role_id,
        roleName:
          user.role_id === 1
            ? "ADMIN"
            : user.role_id === 2
              ? "MANAGER"
              : "PLAYER",
        status: user.status,
        city: user.city,
        profileImageUrl: user.profile_image_url,
        ...roleSpecificData,
      },
      ...tokenData,
    };
  }

  static async refreshTokens(refreshToken: string) {
    const refreshTokenHash = this.hashToken(refreshToken);
    const session = await AuthRepository.findSessionByHash(refreshTokenHash);

    if (!session) {
      throw new ApiError(401, "Invalid refresh token", "INVALID_REFRESH_TOKEN");
    }

    if (session.is_revoked) {
      logger.warn(
        `🚨 Refresh Token Reuse Detected! Revoking all sessions for user ${session.user_id}`,
      );
      await AuthRepository.revokeAllUserSessions(session.user_id);
      throw new ApiError(
        401,
        "Security Alert: Refresh token reuse detected. All sessions revoked.",
        "TOKEN_REUSE_DETECTED",
      );
    }

    if (new Date(session.expires_at) < new Date()) {
      throw new ApiError(401, "Refresh token expired", "EXPIRED_REFRESH_TOKEN");
    }

    await AuthRepository.revokeSession(session.id);

    const userRes = await dbPool.query(
      "SELECT email, role_id FROM public.users WHERE id = $1;",
      [session.user_id],
    );
    const user = userRes.rows[0];

    return await this.generateTokensAndSession(
      session.user_id,
      user.email,
      user.role_id,
      session.device_info,
      session.ip_address,
    );
  }

  private static async generateTokensAndSession(
    userId: string,
    email: string,
    roleId: number,
    deviceInfo = "Mobile App",
    ipAddress = "127.0.0.1",
  ) {
    const accessSignOptions: SignOptions = {
      expiresIn: (env.JWT_EXPIRES_IN || "7d") as any,
    };
    const accessToken = jwt.sign(
      { id: userId, email, roleId },
      env.JWT_SECRET,
      accessSignOptions,
    );

    const refreshSignOptions: SignOptions = {
      expiresIn: (env.JWT_REFRESH_EXPIRES_IN || "30d") as any,
    };
    const refreshToken = jwt.sign(
      { id: userId, email, nonce: crypto.randomUUID() },
      env.JWT_REFRESH_SECRET,
      refreshSignOptions,
    );

    const refreshTokenHash = this.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

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

  static async forgotPasswordSendOtp(identifier: string) {
    const user = await AuthRepository.findUserByIdentifier(identifier);
    if (!user) {
      return {
        message: "If an account exists, a password reset OTP has been sent.",
      };
    }

    await createAndSendOTP(user.email, "PASSWORD_RESET", user.id);
    return {
      message: "If an account exists, a password reset OTP has been sent.",
    };
  }

  static async forgotPasswordVerifyOtp(identifier: string, otp: string) {
    const user = await AuthRepository.findUserByIdentifier(identifier);
    if (!user) {
      throw new ApiError(400, "Invalid request", "INVALID_REQUEST");
    }

    await verifyOTP(user.email, otp, "PASSWORD_RESET");

    const signOptions: SignOptions = { expiresIn: "15m" };
    const resetToken = jwt.sign(
      { userId: user.id, purpose: "PASSWORD_RESET" },
      env.JWT_SECRET,
      signOptions,
    );

    return {
      message: "OTP verified successfully",
      resetToken,
    };
  }

  static async resetPassword(resetToken: string, newPassword: string) {
    let userId = "";
    try {
      const decoded = jwt.verify(resetToken, env.JWT_SECRET) as any;
      if (decoded.purpose !== "PASSWORD_RESET" || !decoded.userId) {
        throw new ApiError(
          400,
          "Invalid password reset token",
          "INVALID_RESET_TOKEN",
        );
      }
      userId = decoded.userId;
    } catch (err) {
      throw new ApiError(
        400,
        "Invalid or expired password reset token",
        "INVALID_RESET_TOKEN",
      );
    }

    const newPasswordHash = await bcrypt.hash(newPassword, 12);
    await AuthRepository.updatePassword(userId, newPasswordHash);

    logger.info(
      `🔑 Password reset completed for user ${userId}. All active sessions invalidated.`,
    );
    return {
      message:
        "Password reset successfully. Please log in with your new password.",
    };
  }

  static async getMe(userId: string) {
    const userRes = await dbPool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.role_id, u.status, u.city, u.profile_image_url,
              ad.admin_type, ad.is_owner, md.employee_code
       FROM public.users u
       LEFT JOIN public.admin_details ad ON ad.user_id = u.id
       LEFT JOIN public.manager_details md ON md.user_id = u.id
       WHERE u.id = $1;`,
      [userId],
    );

    if (userRes.rows.length === 0) {
      throw new ApiError(404, "User not found", "USER_NOT_FOUND");
    }

    const user = userRes.rows[0];
    let roleSpecificData: any = {};

    if (user.role_id === 1) {
      roleSpecificData = {
        adminType: user.admin_type,
        isOwner: Boolean(user.is_owner),
      };
    } else if (user.role_id === 2) {
      const clubIds = await AuthRepository.getManagerClubIds(userId);
      roleSpecificData = {
        employeeCode: user.employee_code,
        assignedClubIds: clubIds,
      };
    } else if (user.role_id === 3) {
      const playerInfo = await AuthRepository.getPlayerInfo(userId);
      roleSpecificData = {
        playerDetails: playerInfo.details,
        playerStats: playerInfo.stats,
      };
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      roleId: user.role_id,
      roleName:
        user.role_id === 1
          ? "ADMIN"
          : user.role_id === 2
            ? "MANAGER"
            : "PLAYER",
      status: user.status,
      city: user.city,
      profileImageUrl: user.profile_image_url,
      ...roleSpecificData,
    };
  }

  static async updateProfile(
    userId: string,
    data: {
      name?: string;
      phone?: string;
      city?: string;
      profileImageUrl?: string;
    },
  ) {
    const { name, phone, city, profileImageUrl } = data;
    const updates: string[] = [];
    const params: any[] = [userId];

    if (name !== undefined && name.trim().length > 0) {
      params.push(name.trim());
      updates.push(`name = $${params.length}`);
    }
    if (phone !== undefined && phone.trim().length > 0) {
      params.push(phone.trim());
      updates.push(`phone = $${params.length}`);
    }
    if (city !== undefined && city.trim().length > 0) {
      params.push(city.trim());
      updates.push(`city = $${params.length}`);
    }
    if (profileImageUrl !== undefined) {
      params.push(profileImageUrl.trim());
      updates.push(`profile_image_url = $${params.length}`);
    }

    if (updates.length > 0) {
      updates.push(`updated_at = CURRENT_TIMESTAMP`);
      await dbPool.query(
        `UPDATE public.users SET ${updates.join(", ")} WHERE id = $1;`,
        params,
      );
    }

    return await this.getMe(userId);
  }
}
