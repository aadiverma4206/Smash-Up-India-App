import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import { env } from './env.config.js';
import { logger } from '../utils/logger.js';

let io: Server | null = null;

export const SOCKET_EVENTS = {
  CONNECT: 'connection',
  DISCONNECT: 'disconnect',
  JOIN_USER_ROOM: 'join:user',
  JOIN_GAME_ROOM: 'join:game',
  LEAVE_GAME_ROOM: 'leave:game',
  MATCH_SCORE_UPDATE: 'match:score_update',
  MATCH_LIVE_FEED: 'match:live_feed',
  NOTIFICATION: 'notification',
  WALLET_UPDATE: 'wallet_update',
  ORDER_UPDATE: 'order_update',
};

export const initSocket = (httpServer: HttpServer): Server => {
  io = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGIN,
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  io.on(SOCKET_EVENTS.CONNECT, (socket: Socket) => {
    logger.info(`⚡ [Real-Time Football Socket Connected]: ID=${socket.id}`);

    // Join specific user notification room
    socket.on(SOCKET_EVENTS.JOIN_USER_ROOM, (userId: string) => {
      if (userId) {
        socket.join(`user:${userId}`);
        logger.info(`Socket ${socket.id} joined user room: user:${userId}`);
      }
    });

    // Join specific match/game room for live score updates
    socket.on(SOCKET_EVENTS.JOIN_GAME_ROOM, (gameId: string) => {
      if (gameId) {
        socket.join(`game:${gameId}`);
        logger.info(`Socket ${socket.id} joined match room: game:${gameId}`);
        socket.emit(SOCKET_EVENTS.NOTIFICATION, {
          title: '⚽ Match Room Joined',
          message: `Listening to live score stream for game ${gameId}`,
          timestamp: new Date().toISOString(),
        });
      }
    });

    socket.on(SOCKET_EVENTS.LEAVE_GAME_ROOM, (gameId: string) => {
      if (gameId) {
        socket.leave(`game:${gameId}`);
        logger.info(`Socket ${socket.id} left match room: game:${gameId}`);
      }
    });

    socket.on(SOCKET_EVENTS.DISCONNECT, (reason) => {
      logger.info(`⚡ [Real-Time Socket Disconnected]: ID=${socket.id}, Reason=${reason}`);
    });
  });

  return io;
};

export const getSocketIO = (): Server => {
  if (!io) {
    throw new Error('Socket.io has not been initialized yet');
  }
  return io;
};
