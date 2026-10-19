import { Server } from "socket.io";
import { env } from "./env.js";
import { logger } from "./logger.js";

let io = null;

export const SOCKET_EVENTS = {
  CONNECT: "connection",
  DISCONNECT: "disconnect",
  JOIN_USER_ROOM: "join:user",
  JOIN_GAME_ROOM: "join:game",
  LEAVE_GAME_ROOM: "leave:game",
  MATCH_SCORE_UPDATE: "match:score_update",
  MATCH_LIVE_FEED: "match:live_feed",
  CCTV_STATUS_UPDATE: "cctv:status_update",
  NOTIFICATION: "notification",
  WALLET_UPDATE: "wallet_update",
};

export const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGIN,
      methods: ["GET", "POST"],
      credentials: true,
    },
    transports: ["websocket", "polling"],
  });

  io.on(SOCKET_EVENTS.CONNECT, (socket) => {
    logger.info(`⚡ [Real-Time Socket Connected]: ID=${socket.id}`);

    socket.on(SOCKET_EVENTS.JOIN_USER_ROOM, (userId) => {
      if (userId) {
        socket.join(`user:${userId}`);
        logger.info(`Socket ${socket.id} joined user room: user:${userId}`);
      }
    });

    socket.on(SOCKET_EVENTS.JOIN_GAME_ROOM, (gameId) => {
      if (gameId) {
        socket.join(`game:${gameId}`);
        logger.info(`Socket ${socket.id} joined match room: game:${gameId}`);
      }
    });

    socket.on(SOCKET_EVENTS.LEAVE_GAME_ROOM, (gameId) => {
      if (gameId) {
        socket.leave(`game:${gameId}`);
        logger.info(`Socket ${socket.id} left match room: game:${gameId}`);
      }
    });

    socket.on(SOCKET_EVENTS.DISCONNECT, (reason) => {
      logger.info(
        `⚡ [Real-Time Socket Disconnected]: ID=${socket.id}, Reason=${reason}`,
      );
    });
  });

  return io;
};

export const getSocketIO = () => {
  if (!io) {
    throw new Error("Socket.io has not been initialized yet");
  }
  return io;
};
