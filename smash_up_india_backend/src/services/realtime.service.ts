import { getSocketIO, SOCKET_EVENTS } from "../config/socket.config.js";
import { dbPool } from "../config/db.config.js";
import { logger } from "../utils/logger.js";
import { getFirebaseMessaging } from "../config/firebase.config.js";

export interface NotificationPayload {
  id?: string;
  title: string;
  message: string;
  type?: "INFO" | "SUCCESS" | "WARNING" | "ALERT" | string;
  data?: any;
  timestamp?: string;
}

export interface SendNotificationOptions {
  skipDbInsert?: boolean;
}

export const sendUserNotification = async (
  userId: string,
  notification: NotificationPayload,
  options?: SendNotificationOptions,
) => {
  try {
    const payload = {
      ...notification,
      timestamp: notification.timestamp || new Date().toISOString(),
    };

    try {
      const io = getSocketIO();
      io.to(`user:${userId}`).emit(SOCKET_EVENTS.NOTIFICATION, payload);
      logger.info(
        `[Real-Time Socket] Notification emitted to user:${userId} - ${notification.title}`,
      );
    } catch (socketErr: any) {
      logger.warn(
        `Socket.IO emit skipped or failed for user:${userId}: ${socketErr.message}`,
      );
    }

    if (!options?.skipDbInsert) {
      dbPool
        .query(
          `INSERT INTO public.notifications (
             user_id, title, body, message, type, data, is_read
           ) VALUES ($1, $2, $3, $4, $5, $6, false);`,
          [
            userId,
            notification.title,
            notification.message,
            notification.message,
            notification.type || "SYSTEM",
            JSON.stringify(notification.data || {}),
          ],
        )
        .catch((dbErr: any) => {
          logger.warn(
            `Failed to persist notification to DB for user:${userId}: ${dbErr.message}`,
          );
        });
    }

    dispatchFcmPushNotification(userId, notification).catch((fcmErr) => {
      logger.warn(
        `FCM async dispatch notice for user:${userId}: ${fcmErr.message}`,
      );
    });
  } catch (err: any) {
    logger.error(
      `Failed to send user notification to user:${userId}:`,
      err.message,
    );
  }
};

async function dispatchFcmPushNotification(
  userId: string,
  notification: NotificationPayload,
) {
  const messaging = getFirebaseMessaging();
  if (!messaging) return;

  const tokenRes = await dbPool.query(
    `SELECT device_token FROM public.user_device_tokens WHERE user_id = $1 AND is_active = true;`,
    [userId],
  );

  if (tokenRes.rows.length === 0) {
    logger.debug(`No active FCM device tokens for user:${userId}`);
    return;
  }

  const tokens: string[] = tokenRes.rows.map((r) => r.device_token);

  const routePath =
    notification.data?.route ||
    (notification.data?.link ? notification.data.link : "/notifications");

  const payloadData: Record<string, string> = {
    id: notification.id || "",
    type: notification.type || "SYSTEM",
    title: notification.title || "",
    body: notification.message || "",
    route: String(routePath),
  };

  if (notification.data && typeof notification.data === "object") {
    for (const [k, v] of Object.entries(notification.data)) {
      if (v !== undefined && v !== null) {
        payloadData[k] = typeof v === "object" ? JSON.stringify(v) : String(v);
      }
    }
  }

  const multicastMessage = {
    tokens,
    notification: {
      title: notification.title,
      body: notification.message,
    },
    data: payloadData,
    android: {
      priority: "high" as const,
      notification: {
        title: notification.title,
        body: notification.message,
        sound: "default",
        channelId: "high_importance_channel",
        priority: "high" as const,
        visibility: "public" as const,
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        defaultSound: true,
        defaultVibrateTimings: true,
        notificationCount: 1,
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
      headers: {
        "apns-priority": "10",
      },
    },
  };

  try {
    const response = await messaging.sendEachForMulticast(multicastMessage);
    logger.info(
      `🔥 [FCM Push] Sent to user:${userId} | Success: ${response.successCount}/${tokens.length}`,
    );

    if (response.failureCount > 0) {
      const tokensToRemove: string[] = [];
      response.responses.forEach((resp: any, idx: number) => {
        if (!resp.success && resp.error) {
          const code = resp.error.code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            tokensToRemove.push(tokens[idx]!);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        await dbPool.query(
          `UPDATE public.user_device_tokens SET is_active = false WHERE user_id = $1 AND device_token = ANY($2::text[]);`,
          [userId, tokensToRemove],
        );
        logger.info(
          `Cleaned up ${tokensToRemove.length} inactive FCM tokens for user:${userId}`,
        );
      }
    }
  } catch (pushErr: any) {
    logger.warn(
      `Failed to dispatch FCM multicast push for user:${userId}: ${pushErr.message}`,
    );
  }
}

export const broadcastNotification = (notification: NotificationPayload) => {
  try {
    const io = getSocketIO();
    const payload = {
      ...notification,
      timestamp: notification.timestamp || new Date().toISOString(),
    };

    io.emit(SOCKET_EVENTS.NOTIFICATION, payload);
    logger.info(
      `[Real-Time] Global notification broadcasted - ${notification.title}`,
    );
  } catch (err: any) {
    logger.error("Failed to broadcast global notification:", err.message);
  }
};

export const sendWalletUpdate = (userId: string, walletData: any) => {
  try {
    const io = getSocketIO();
    io.to(`user:${userId}`).emit(SOCKET_EVENTS.WALLET_UPDATE, {
      userId,
      ...walletData,
      timestamp: new Date().toISOString(),
    });
    logger.info(`[Real-Time] Wallet update sent to user:${userId}`);
  } catch (err: any) {
    logger.error(
      `Failed to send wallet update to user:${userId}:`,
      err.message,
    );
  }
};

export const broadcastLiveMatchScore = (gameId: string, scoreData: any) => {
  try {
    const io = getSocketIO();
    const payload = {
      gameId,
      ...scoreData,
      timestamp: new Date().toISOString(),
    };

    io.to(`game:${gameId}`).emit(SOCKET_EVENTS.MATCH_SCORE_UPDATE, payload);
    io.emit(SOCKET_EVENTS.MATCH_LIVE_FEED, payload);

    logger.info(`⚽ [Real-Time Score Broadcast] Game ${gameId}`);
  } catch (err: any) {
    logger.error(
      `Failed to broadcast live match score for game ${gameId}:`,
      err.message,
    );
  }
};
