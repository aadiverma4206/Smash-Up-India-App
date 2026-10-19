import { createServer } from "http";
import { execSync } from "child_process";
import app from "./app.js";
import { env } from "./config/env.config.js";
import { dbPool, initDbTables } from "./config/db.config.js";
import { initSocket } from "./config/socket.config.js";
import { logger } from "./utils/logger.js";
import {
  startMatchLifecycleWorker,
  startPaymentExpiryJob,
  startPaymentReconciliationJob,
} from "./jobs/index.js";
import { CctvRecordingService } from "./services/cctvRecording.service.js";
import { MediaMtxService } from "./services/mediaMtx.service.js";
import { TunnelService } from "./services/tunnel.service.js";

// Catch unhandled synchronous exceptions
process.on("uncaughtException", (err: Error) => {
  logger.fatal(
    { err },
    "💥 FATAL: Uncaught Exception detected! Cleaning up before exit...",
  );
  setTimeout(() => {
    process.exit(1);
  }, 1000).unref();
});

// Catch unhandled asynchronous promise rejections
process.on("unhandledRejection", (reason: any) => {
  logger.error(
    { reason },
    "🚨 WARNING: Unhandled Promise Rejection detected in runtime!",
  );
});

const PORT = env.PORT || "5000";

/**
 * Auto-free port if occupied by a previous stale Node/server process in development.
 * Controlled via AUTO_FREE_PORT in .env (default: true).
 */
const freePortIfOccupied = (port: number): void => {
  if (process.platform === "win32") {
    try {
      const output = execSync(`netstat -ano | findstr :${port}`, {
        encoding: "utf8",
      });
      const lines = output.trim().split("\n");
      for (const line of lines) {
        const parts = line.trim().split(/\s+/);
        if (
          parts.length >= 5 &&
          parts[1].endsWith(`:${port}`) &&
          parts[3] === "LISTENING"
        ) {
          const pid = parts[4].trim();
          if (pid && pid !== String(process.pid) && pid !== "0") {
            logger.info(
              `🔍 Port ${port} is occupied by PID ${pid}. Auto-freeing port as requested in .env (AUTO_FREE_PORT=true)...`,
            );
            try {
              execSync(`taskkill /PID ${pid} /F`, { stdio: "ignore" });
              logger.info(
                `✅ Terminated stale process PID ${pid}. Port ${port} is now free.`,
              );
              const start = Date.now();
              while (Date.now() - start < 500) {
                // Short sync pause for OS socket recycling
              }
            } catch (kErr) {
              logger.warn({ kErr }, `Could not auto-kill PID ${pid}`);
            }
          }
        }
      }
    } catch {
      // Port is clear
    }
  }
};

const httpServer = createServer(app);

// Handle server listen errors (e.g. EADDRINUSE) gracefully
httpServer.on("error", (err: any) => {
  if (err.code === "EADDRINUSE") {
    logger.error(
      `❌ Port ${PORT} is already in use (EADDRINUSE). Another instance of the backend is already running on port ${PORT}.`,
    );
    logger.info(
      `💡 Tip: Ensure AUTO_FREE_PORT=true in .env, or run "netstat -ano | findstr :${PORT}" and "taskkill /PID <PID> /F" to stop it.`,
    );
  } else {
    logger.error({ err }, "❌ HTTP server error occurred");
  }
  process.exit(1);
});

// Initialize Socket.io Real-Time Football Engine
initSocket(httpServer);

const startServer = async () => {
  // 1. Verify / Initialize DB Tables with robust error catch
  try {
    await initDbTables();
  } catch (err) {
    logger.error({ err }, "❌ Database table initialization failed on startup");
  }

  const portNum = Number(PORT) || 5000;
  if (env.AUTO_FREE_PORT !== "false" && env.NODE_ENV !== "production") {
    freePortIfOccupied(portNum);
  }

  // 2. Start HTTP server listening on 0.0.0.0 (all interfaces for mobile device access)
  const server = httpServer.listen(portNum, "0.0.0.0", () => {
    logger.info(
      `⚽ ALL STARS ARENA Server running in ${env.NODE_ENV} mode on port ${PORT}`,
    );
    logger.info(
      `⚡ Socket.io Real-Time engine active on ws://localhost:${PORT}`,
    );

    // Start Background Workers & Schedulers
    try {
      startMatchLifecycleWorker();
      startPaymentExpiryJob();
      startPaymentReconciliationJob();

      // Initialize CCTV system (FFmpeg optional) & reconcile active recordings on boot
      CctvRecordingService.checkFfmpeg().catch((err) => {
        logger.info({ err }, "CCTV system operational (FFmpeg optional)");
      });
      CctvRecordingService.reconcileOnBoot().catch((err) => {
        logger.error({ err }, "CCTV boot reconciliation failed");
      });

      // Ensure MediaMTX streaming server is active
      MediaMtxService.ensureRunning().catch((err) => {
        logger.warn({ err }, "MediaMTX auto-start check skipped");
      });

      // Ensure Cloudflare Tunnel is active for universal outside-network streaming
      TunnelService.start(Number(PORT) || 5000).catch((err) => {
        logger.warn({ err }, "Cloudflare Tunnel start skipped");
      });
    } catch (workerErr: any) {
      logger.error({ workerErr }, "Failed to start background worker jobs");
    }
  });

  return server;
};

const server = await startServer();

// Graceful Shutdown Handler
const handleGracefulShutdown = async (signal: string) => {
  logger.info(`📡 Received ${signal}. Starting graceful shutdown...`);

  TunnelService.stop();

  try {
    await CctvRecordingService.stopAllActiveRecordings("SERVER_SHUTDOWN");
  } catch (recErr: any) {
    logger.error({ recErr }, "Error stopping active recordings on shutdown");
  }

  server.close(async () => {
    logger.info("🛑 HTTP server closed to new connections.");
    try {
      await dbPool.end();
      logger.info("🔌 PostgreSQL database connection pool closed.");
    } catch (err: any) {
      logger.error({ err }, "Error closing database pool during shutdown");
    }
    process.exit(0);
  });

  // Force close if graceful shutdown hangs
  setTimeout(() => {
    logger.error(
      "⚠️ Graceful shutdown timed out (10s limit). Forcing immediate termination.",
    );
    process.exit(1);
  }, 10000).unref();
};

process.on("SIGTERM", () => handleGracefulShutdown("SIGTERM"));
process.on("SIGINT", () => handleGracefulShutdown("SIGINT"));
