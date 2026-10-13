import { dbPool } from '../../config/db.config.js';

export class AuthRepository {
  /**
   * Check if email or phone exists in identity history or users table
   */
  static async checkIdentityExists(normalizedEmail: string, normalizedPhone: string) {
    const rawTrim = normalizedPhone.trim();
    const digitsOnly = rawTrim.replace(/\D/g, '');

    const res = await dbPool.query(
      `SELECT id FROM public.users
       WHERE LOWER(TRIM(email)) = $1
          OR TRIM(phone) = $2
          OR TRIM(phone) = $3
          OR ($4 <> '' AND LENGTH($4) >= 10 AND RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 10) = RIGHT($4, 10))
       UNION
       SELECT id::text FROM public.user_identity_history
       WHERE (identity_type = 'EMAIL' AND LOWER(TRIM(normalized_value)) = $1)
          OR (identity_type = 'PHONE' AND TRIM(normalized_value) = $2)
          OR (identity_type = 'PHONE' AND TRIM(normalized_value) = $3)
          OR ($4 <> '' AND LENGTH($4) >= 10 AND identity_type = 'PHONE' AND RIGHT(REGEXP_REPLACE(normalized_value, '[^0-9]', '', 'g'), 10) = RIGHT($4, 10));`,
      [
        normalizedEmail,
        rawTrim,
        rawTrim.startsWith('+91') ? rawTrim.substring(3) : `+91${rawTrim}`,
        digitsOnly,
      ]
    );
    return res.rows;
  }

  /**
   * Resolve user by email OR phone (supports flexible 10-digit phone matching)
   */
  static async findUserByIdentifier(identifier: string) {
    const normalized = identifier.trim().toLowerCase();
    const rawTrim = identifier.trim();
    const digitsOnly = rawTrim.replace(/\D/g, '');

    const res = await dbPool.query(
      `SELECT u.*,
              ad.admin_type, ad.is_owner,
              md.employee_code
       FROM public.users u
       LEFT JOIN public.admin_details ad ON ad.user_id = u.id
       LEFT JOIN public.manager_details md ON md.user_id = u.id
       WHERE LOWER(TRIM(u.email)) = $1
          OR TRIM(u.phone) = $2
          OR TRIM(u.phone) = $3
          OR ($4 <> '' AND LENGTH($4) >= 10 AND RIGHT(REGEXP_REPLACE(u.phone, '[^0-9]', '', 'g'), 10) = RIGHT($4, 10))
       LIMIT 1;`,
      [
        normalized,
        rawTrim,
        rawTrim.startsWith('+91') ? rawTrim.substring(3) : `+91${rawTrim}`,
        digitsOnly,
      ]
    );

    return res.rows[0] || null;
  }

  /**
   * Fetch Manager Assigned Club IDs
   */
  static async getManagerClubIds(userId: string) {
    const res = await dbPool.query(
      `SELECT club_id FROM public.club_managers WHERE user_id = $1;`,
      [userId]
    );
    return res.rows.map((row) => row.club_id);
  }

  /**
   * Fetch Player Details & Stats
   */
  static async getPlayerInfo(userId: string) {
    const detailsRes = await dbPool.query(
      `SELECT * FROM public.player_details WHERE user_id = $1;`,
      [userId]
    );
    const statsRes = await dbPool.query(
      `SELECT * FROM public.player_stats WHERE user_id = $1;`,
      [userId]
    );
    return {
      details: detailsRes.rows[0] || null,
      stats: statsRes.rows[0] || null,
    };
  }

  /**
   * Call PostgreSQL Stored Function register_player
   */
  static async registerPlayer(data: {
    name: string;
    email: string;
    phone: string;
    passwordHash: string;
    city: string;
  }) {
    const res = await dbPool.query(
      `SELECT public.register_player($1, $2, $3, $4, $5) as user_id;`,
      [data.name, data.email, data.phone, data.passwordHash, data.city]
    );
    return res.rows[0]?.user_id;
  }

  /**
   * Store Refresh Token Session with SHA-256 Hash
   */
  static async createSession(data: {
    userId: string;
    refreshTokenHash: string;
    deviceInfo?: string;
    ipAddress?: string;
    expiresAt: Date;
  }) {
    const res = await dbPool.query(
      `INSERT INTO public.user_sessions
       (user_id, refresh_token_hash, device_info, ip_address, is_revoked, expires_at)
       VALUES ($1, $2, $3, $4, false, $5)
       RETURNING *;`,
      [
        data.userId,
        data.refreshTokenHash,
        data.deviceInfo || 'Unknown Device',
        data.ipAddress || '127.0.0.1',
        data.expiresAt,
      ]
    );
    return res.rows[0];
  }

  /**
   * Find Session by Refresh Token Hash
   */
  static async findSessionByHash(refreshTokenHash: string) {
    const res = await dbPool.query(
      `SELECT * FROM public.user_sessions WHERE refresh_token_hash = $1;`,
      [refreshTokenHash]
    );
    return res.rows[0] || null;
  }

  /**
   * Revoke Session
   */
  static async revokeSession(sessionId: string) {
    await dbPool.query(
      `UPDATE public.user_sessions SET is_revoked = true WHERE id = $1;`,
      [sessionId]
    );
  }

  /**
   * Revoke All Sessions for User (Session Family Revocation)
   */
  static async revokeAllUserSessions(userId: string) {
    const res = await dbPool.query(
      `SELECT public.logout_all_sessions($1) as revoked_count;`,
      [userId]
    );
    return res.rows[0]?.revoked_count || 0;
  }

  /**
   * Update User Password & Invalidate Sessions
   */
  static async updatePassword(userId: string, newPasswordHash: string) {
    await dbPool.query(
      `UPDATE public.users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2;`,
      [newPasswordHash, userId]
    );
    // Invalidate all active user sessions upon password reset
    await this.revokeAllUserSessions(userId);
  }

  /**
   * Fetch Active User Sessions
   */
  static async getUserActiveSessions(userId: string) {
    const res = await dbPool.query(
      `SELECT id, device_info, ip_address, created_at, expires_at
       FROM public.user_sessions
       WHERE user_id = $1 AND is_revoked = false AND expires_at > CURRENT_TIMESTAMP
       ORDER BY created_at DESC;`,
      [userId]
    );
    return res.rows;
  }

  /**
   * Upsert Device FCM Token
   */
  static async upsertDeviceToken(userId: string, token: string, platform = 'ANDROID', deviceInfo?: string) {
    try {
      // 1. Clear any existing entry for this token if assigned to another user
      await dbPool.query(
        `DELETE FROM public.user_device_tokens WHERE device_token = $1 AND user_id <> $2;`,
        [token, userId]
      );

      // 2. Upsert token for current user
      await dbPool.query(
        `INSERT INTO public.user_device_tokens (user_id, device_token, device_type, is_active)
         VALUES ($1, $2, $3, true)
         ON CONFLICT (user_id, device_token)
         DO UPDATE SET is_active = true, device_type = EXCLUDED.device_type, updated_at = CURRENT_TIMESTAMP;`,
        [userId, token, platform]
      );
    } catch (err: any) {
      // Fallback if the ON CONFLICT constraint specification is missing in DB schema
      try {
        await dbPool.query(
          `UPDATE public.user_device_tokens SET is_active = true, device_type = $3, updated_at = CURRENT_TIMESTAMP
           WHERE user_id = $1 AND device_token = $2;`,
          [userId, token, platform]
        );
        await dbPool.query(
          `INSERT INTO public.user_device_tokens (user_id, device_token, device_type, is_active)
           SELECT $1, $2, $3, true
           WHERE NOT EXISTS (
             SELECT 1 FROM public.user_device_tokens WHERE user_id = $1 AND device_token = $2
           );`,
          [userId, token, platform]
        );
      } catch (_) {}
    }
  }

  /**
   * Delete Device FCM Token
   */
  static async deleteDeviceToken(userId: string, token: string) {
    try {
      await dbPool.query(
        `DELETE FROM public.user_device_tokens WHERE user_id = $1 AND device_token = $2;`,
        [userId, token]
      );
    } catch (_) {}
  }
}
