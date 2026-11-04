import { dbPool } from "../../config/db.config.js";
import { logger } from "../../utils/logger.js";
import {
  sendUserNotification,
  NotificationPayload,
} from "../../services/realtime.service.js";

export interface CreateNotificationParams {
  userId: string;
  title: string;
  body?: string;
  message?: string;
  type?: string;
  data?: Record<string, any>;
  linkUrl?: string;
  clubId?: string;
  gameId?: string;
}

export interface FormattedNotification {
  id: string;
  title: string;
  body: string;
  type: string;
  data: Record<string, any> | null;
  isRead: boolean;
  createdAt: string;
}

export class NotificationService {
  static async getUserNotifications(
    userId: string,
    page: number = 1,
    limit: number = 20,
    type?: string,
    isRead?: boolean,
  ): Promise<{
    notifications: FormattedNotification[];
    unreadCount: number;
    totalCount: number;
  }> {
    const offset = Math.max(0, (page - 1) * limit);
    const conditions: string[] = ["user_id = $1"];
    const values: any[] = [userId];
    let idx = 2;

    if (type && type.toUpperCase() !== "ALL") {
      conditions.push(`type = $${idx++}`);
      values.push(type.toUpperCase());
    }

    if (isRead !== undefined) {
      conditions.push(`is_read = $${idx++}`);
      values.push(isRead);
    }

    const whereClause = conditions.join(" AND ");

    const query = `
      SELECT id, user_id, title, COALESCE(body, message, '') as body,
             type, data, link_url, game_id, club_id,
             is_read, created_at
      FROM public.notifications
      WHERE ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${idx++} OFFSET $${idx++};
    `;

    values.push(limit, offset);
    const result = await dbPool.query(query, values);

    const countRes = await dbPool.query(
      `SELECT COUNT(*) as unread_count FROM public.notifications WHERE user_id = $1 AND is_read = false;`,
      [userId],
    );
    const unreadCount = parseInt(countRes.rows[0]?.unread_count || "0", 10);

    const totalCountRes = await dbPool.query(
      `SELECT COUNT(*) as total_count FROM public.notifications WHERE ${whereClause};`,
      values.slice(0, values.length - 2),
    );
    const totalCount = parseInt(totalCountRes.rows[0]?.total_count || "0", 10);

    const formatted: FormattedNotification[] = result.rows.map((row) => {
      let finalData = row.data;
      if (typeof finalData === "string") {
        try {
          finalData = JSON.parse(finalData);
        } catch {
          finalData = {};
        }
      }
      if (!finalData) finalData = {};
      if (row.link_url && !finalData.link) finalData.link = row.link_url;
      if (row.game_id && !finalData.gameId) finalData.gameId = row.game_id;

      return {
        id: row.id,
        title: row.title || "Notification",
        body: row.body || row.message || "",
        type: row.type || "SYSTEM",
        data: Object.keys(finalData).length > 0 ? finalData : null,
        isRead: Boolean(row.is_read),
        createdAt: row.created_at
          ? new Date(row.created_at).toISOString()
          : new Date().toISOString(),
      };
    });

    return { notifications: formatted, unreadCount, totalCount };
  }

  static async createNotification(
    params: CreateNotificationParams,
  ): Promise<FormattedNotification> {
    const textBody = params.body || params.message || "";
    const textType = params.type || "SYSTEM";
    const jsonPayload = params.data || {};

    const insertRes = await dbPool.query(
      `INSERT INTO public.notifications (
         user_id, title, body, message, type, data, link_url, club_id, game_id, is_read
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, false)
       RETURNING id, user_id, title, COALESCE(body, message) as body, type, data, is_read, created_at;`,
      [
        params.userId,
        params.title,
        textBody,
        textBody,
        textType,
        JSON.stringify(jsonPayload),
        params.linkUrl || null,
        params.clubId || null,
        params.gameId || null,
      ],
    );

    const row = insertRes.rows[0];

    const socketPayload: NotificationPayload = {
      id: row.id,
      title: row.title,
      message: row.body,
      type: (textType.includes("ERROR") || textType.includes("CANCEL")
        ? "ALERT"
        : textType.includes("WARN")
          ? "WARNING"
          : "SUCCESS") as any,
      data: jsonPayload,
      timestamp: new Date(row.created_at).toISOString(),
    };
    sendUserNotification(params.userId, socketPayload, { skipDbInsert: true });

    return {
      id: row.id,
      title: row.title,
      body: row.body,
      type: row.type,
      data: Object.keys(jsonPayload).length > 0 ? jsonPayload : null,
      isRead: false,
      createdAt: new Date(row.created_at).toISOString(),
    };
  }

  static async notifyAdmins(params: {
    title: string;
    body: string;
    type:
      "USER_CREATED" | "MATCH_CREATED" | "MATCH_CANCELLED" | "MATCH_COMPLETED";
    data?: Record<string, any>;
    gameId?: string;
  }): Promise<void> {
    try {
      const adminRes = await dbPool.query(
        `SELECT id FROM public.users WHERE role_id = 1;`,
      );
      for (const row of adminRes.rows) {
        await this.createNotification({
          userId: row.id,
          title: params.title,
          body: params.body,
          type: params.type,
          data: params.data,
          gameId: params.gameId,
        });
      }
    } catch (err: any) {
      logger.error(`Failed to notify admins: ${err.message}`);
    }
  }

  static async markNotificationRead(
    notificationId: string,
    userId: string,
  ): Promise<boolean> {
    const res = await dbPool.query(
      `UPDATE public.notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING id;`,
      [notificationId, userId],
    );
    return (res.rowCount ?? 0) > 0;
  }

  static async markAllRead(userId: string): Promise<number> {
    const res = await dbPool.query(
      `UPDATE public.notifications SET is_read = true WHERE user_id = $1 AND is_read = false;`,
      [userId],
    );
    return res.rowCount ?? 0;
  }

  static async deleteNotification(
    notificationId: string,
    userId: string,
  ): Promise<boolean> {
    const res = await dbPool.query(
      `DELETE FROM public.notifications WHERE id = $1 AND user_id = $2;`,
      [notificationId, userId],
    );
    return (res.rowCount ?? 0) > 0;
  }

  static async deleteMultipleNotifications(
    notificationIds: string[],
    userId: string,
    deleteAll: boolean = false,
  ): Promise<number> {
    if (deleteAll) {
      const res = await dbPool.query(
        `DELETE FROM public.notifications WHERE user_id = $1;`,
        [userId],
      );
      return res.rowCount ?? 0;
    }

    if (!notificationIds || notificationIds.length === 0) return 0;

    const res = await dbPool.query(
      `DELETE FROM public.notifications WHERE user_id = $1 AND id = ANY($2::text[]);`,
      [userId, notificationIds],
    );
    return res.rowCount ?? 0;
  }
}
