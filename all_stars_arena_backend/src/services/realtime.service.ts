import { getSocketIO, SOCKET_EVENTS } from '../config/socket.config.js';
import { dbPool } from '../config/db.config.js';
import { env } from '../config/env.config.js';
import { logger } from '../utils/logger.js';

export interface NotificationPayload {
  id?: string;
  title: string;
  message: string;
  type?: 'INFO' | 'SUCCESS' | 'WARNING' | 'ALERT';
  data?: any;
  timestamp?: string;
}

/**
 * Send real-time notification to a specific user
 */
export const sendUserNotification = (userId: string, notification: NotificationPayload) => {
  try {
    const io = getSocketIO();
    const payload = {
      ...notification,
      timestamp: notification.timestamp || new Date().toISOString(),
    };

    io.to(`user:${userId}`).emit(SOCKET_EVENTS.NOTIFICATION, payload);
    logger.info(`[Real-Time] Notification sent to user:${userId} - ${notification.title}`);

    // Persist to database asynchronously so it appears in notification screens
    dbPool.query(
      `INSERT INTO public.notifications (
         user_id, title, body, message, type, data, is_read
       ) VALUES ($1, $2, $3, $4, $5, $6, false);`,
      [
        userId,
        notification.title,
        notification.message,
        notification.message,
        notification.type || 'SYSTEM',
        JSON.stringify(notification.data || {}),
      ]
    ).catch((dbErr: any) => {
      logger.warn(`Failed to persist notification to DB for user:${userId}: ${dbErr.message}`);
    });
  } catch (err: any) {
    logger.error(`Failed to send real-time notification to user:${userId}:`, err.message);
  }
};

/**
 * Broadcast notification to all connected socket clients
 */
export const broadcastNotification = (notification: NotificationPayload) => {
  try {
    const io = getSocketIO();
    const payload = {
      ...notification,
      timestamp: notification.timestamp || new Date().toISOString(),
    };

    io.emit(SOCKET_EVENTS.NOTIFICATION, payload);
    logger.info(`[Real-Time] Global notification broadcasted - ${notification.title}`);
  } catch (err: any) {
    logger.error('Failed to broadcast global notification:', err.message);
  }
};

/**
 * Send real-time wallet balance / transaction update to user
 */
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
    logger.error(`Failed to send wallet update to user:${userId}:`, err.message);
  }
};

/**
 * Broadcast live football match score update to room and global feed
 */
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
    logger.error(`Failed to broadcast live match score for game ${gameId}:`, err.message);
  }
};
