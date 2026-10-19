import { Server as HttpServer } from "http";
import { Server, Socket } from "socket.io";
import jwt from "jsonwebtoken";
import { env } from "./env.config.js";
import { logger } from "../utils/logger.js";
import { UserPayload } from "../types/index.js";

let io: Server | null = null;

export const SOCKET_EVENTS = {
  CONNECT: "connection",
  DISCONNECT: "disconnect",
  JOIN_USER_ROOM: "join:user",
  JOIN_GAME_ROOM: "join:game",
  LEAVE_GAME_ROOM: "leave:game",
  MATCH_SCORE_UPDATE: "match:score_update",
  MATCH_LIVE_FEED: "match:live_feed",
  NOTIFICATION: "notification",
  WALLET_UPDATE: "wallet_update",
  ORDER_UPDATE: "order_update",
};

export const initSocket = (httpServer: HttpServer): Server => {
  io = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGIN,
      methods: ["GET", "POST"],
      credentials: true,
    },
    transports: ["websocket", "polling"],
  });

  // JWT Middleware for Socket Connections
  io.use((socket: Socket, next) => {
    try {
      const authHeader =
        socket.handshake.auth?.token || socket.handshake.headers?.authorization;

      if (!authHeader) {
        // Allow unauthenticated socket connection for public match live streams if needed,
        // but mark user data as null
        socket.data.user = null;
        return next();
      }

      const token = authHeader.startsWith("Bearer ")
        ? authHeader.split(" ")[1]
        : authHeader;

      if (token) {
        const decoded = jwt.verify(token, env.JWT_SECRET) as UserPayload;
        socket.data.user = decoded;
      }
      next();
    } catch (err: any) {
      logger.warn(`Socket authentication notice: ${err.message}`);
      socket.data.user = null;
      next();
    }
  });

  io.on(SOCKET_EVENTS.CONNECT, (socket: Socket) => {
    const authUser = socket.data.user as UserPayload | null;
    logger.info(
      `⚡ [Real-Time Socket Connected]: ID=${socket.id}, User=${authUser ? authUser.id : "ANONYMOUS"}`,
    );

    // Join specific user notification room (Protected: Users can only join their own room or Admins)
    socket.on(SOCKET_EVENTS.JOIN_USER_ROOM, (targetUserId: string) => {
      if (!targetUserId) return;

      if (authUser && (authUser.id === targetUserId || authUser.roleId === 1)) {
        socket.join(`user:${targetUserId}`);
        logger.info(
          `Socket ${socket.id} joined authenticated user room: user:${targetUserId}`,
        );
      } else {
        logger.warn(
          `Unauthorized socket room join attempt by socket ${socket.id} for user:${targetUserId}`,
        );
        socket.emit(SOCKET_EVENTS.NOTIFICATION, {
          title: "⚠️ Unauthorized Room Access",
          message:
            "You can only subscribe to your own private notification channel.",
          type: "WARNING",
          timestamp: new Date().toISOString(),
        });
      }
    });

    // Join specific match/game room for live score updates
    socket.on(SOCKET_EVENTS.JOIN_GAME_ROOM, (gameId: string) => {
      if (gameId) {
        socket.join(`game:${gameId}`);
        logger.info(`Socket ${socket.id} joined match room: game:${gameId}`);
      }
    });

    socket.on(SOCKET_EVENTS.LEAVE_GAME_ROOM, (gameId: string) => {
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

export const getSocketIO = (): Server => {
  if (!io) {
    throw new Error("Socket.io has not been initialized yet");
  }
  return io;
};
