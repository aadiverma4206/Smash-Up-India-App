import { createServer } from "http";
import net from "net";
import { execSync } from "child_process";
import app from "./app.js";
import { env } from "./config/env.config.js";
import { dbPool, initDbTables } from "./config/db.config.js";
import { initSocket } from "./config/socket.config.js";
import { initFirebaseAdmin } from "./config/firebase.config.js";
import { logger } from "./utils/logger.js";
import {
  startMatchLifecycleWorker,
  startPaymentExpiryJob,
  startPaymentReconciliationJob,
} from "./jobs/index.js";
import { CctvRecordingService } from "./services/cctvRecording.service.js";
import { MediaMtxService } from "./services/mediaMtx.service.js";
import { TunnelService } from "./services/tunnel.service.js";

process.on("uncaughtException", (err: Error) => {
  logger.fatal(
    { err },
    "💥 FATAL: Uncaught Exception detected! Cleaning up before exit...",
  );
  setTimeout(() => {
    process.exit(1);
  }, 1000).unref();
});

process.on("unhandledRejection", (reason: any) => {
  logger.error(
    { reason },
    "🚨 WARNING: Unhandled Promise Rejection detected in runtime!",
  );
});

const PORT = env.PORT || "8599";

export const isPortInUse = (
  port: number,
  host = "0.0.0.0",
): Promise<boolean> => {
  return new Promise((resolve) => {
    const tester = net
      .createServer()
      .once("error", (err: any) => {
        if (err.code === "EADDRINUSE" || err.code === "EACCES") {
          resolve(true);
        } else {
          resolve(false);
        }
      })
      .once("listening", () => {
        tester.once("close", () => resolve(false)).close();
      })
      .listen(port, host);
  });
};

const freePortIfOccupied = async (port: number): Promise<boolean> => {
  const inUse = await isPortInUse(port);
  if (!inUse) {
    return true;
  }

  logger.info(
    `🔍 Port ${port} is currently occupied. Attempting to auto-free port...`,
  );

  if (process.platform === "win32") {
    try {
      const output = execSync(`netstat -ano | findstr :${port}`, {
        encoding: "utf8",
      });
      const lines = output.trim().split("\n");
      const killedPids = new Set<string>();

      for (const line of lines) {
        const parts = line.trim().split(/\s+/);
        if (
          parts.length >= 5 &&
          parts[1].endsWith(`:${port}`) &&
          parts[3] === "LISTENING"
        ) {
          const pid = parts[4].trim();
          if (
            pid &&
            pid !== String(process.pid) &&
            pid !== "0" &&
            !killedPids.has(pid)
          ) {
            killedPids.add(pid);
            logger.info(
              `🛑 Terminating stale process holding port ${port} (PID ${pid})...`,
            );
            try {
              execSync(`taskkill /PID ${pid} /F`, { stdio: "ignore" });
              logger.info(`✅ Terminated process PID ${pid}.`);
            } catch (kErr: any) {
              logger.warn(
                { err: kErr.message },
                `Could not terminate PID ${pid}`,
              );
            }
          }
        }
      }
    } catch (netErr: any) {
      logger.warn(
        `No process found or netstat lookup failed: ${netErr.message}`,
      );
    }
  } else {
    try {
      execSync(`lsof -ti :${port} | xargs kill -9`, { stdio: "ignore" });
    } catch (_) {
      try {
        execSync(`fuser -k ${port}/tcp`, { stdio: "ignore" });
      } catch (_) {}
    }
  }

  // Poll until the port is confirmed free by the operating system (up to 4 seconds)
  const startTime = Date.now();
  while (Date.now() - startTime < 4000) {
    await new Promise((r) => setTimeout(r, 200));
    const stillInUse = await isPortInUse(port);
    if (!stillInUse) {
      logger.info(
        `✨ Port ${port} is now free and verified available for binding.`,
      );
      return true;
    }
  }

  logger.warn(
    `⚠️ Port ${port} could not be confirmed free within timeout. Proceeding with retry mechanism...`,
  );
  return false;
};

const httpServer = createServer(app);

initSocket(httpServer);

const listenWithRetry = (
  server: any,
  port: number,
  host: string,
  maxRetries = 3,
): Promise<void> => {
  return new Promise((resolve, reject) => {
    let attempts = 0;

    const attemptListen = async () => {
      attempts++;

      const onError = async (err: any) => {
        server.removeListener("listening", onListening);
        server.removeListener("error", onError);

        if (err.code === "EADDRINUSE") {
          logger.warn(
            `⚠️ Port ${port} is currently in use (EADDRINUSE). Retrying (attempt ${attempts}/${maxRetries})...`,
          );
          if (env.AUTO_FREE_PORT !== "false" && attempts <= maxRetries) {
            await freePortIfOccupied(port);
            await new Promise((r) => setTimeout(r, 800));
            return attemptListen();
          }
          logger.error(
            `❌ Port ${port} is already in use (EADDRINUSE). Another instance of the backend is running.`,
          );
          logger.info(
            `💡 Tip: Ensure AUTO_FREE_PORT=true in .env, or run "netstat -ano | findstr :${port}" and "taskkill /PID <PID> /F", or change PORT in .env.`,
          );
          return reject(err);
        }

        logger.error({ err }, "❌ HTTP server error occurred");
        reject(err);
      };

      const onListening = () => {
        server.removeListener("error", onError);
        resolve();
      };

      server.once("error", onError);
      server.once("listening", onListening);
      server.listen(port, host);
    };

    attemptListen();
  });
};

const startServer = async () => {
  const portNum = Number(PORT) || 8599;

  // 1. Free port if AUTO_FREE_PORT is enabled
  if (env.AUTO_FREE_PORT !== "false" && env.NODE_ENV !== "production") {
    await freePortIfOccupied(portNum);
  }

  // 2. Initialize database schema safely
  try {
    await initDbTables();
  } catch (err) {
    logger.error({ err }, "❌ Database table initialization failed on startup");
  }

  // 2b. Initialize Firebase Admin SDK safely
  try {
    initFirebaseAdmin();
  } catch (fbErr: any) {
    logger.warn(
      { fbErr },
      "⚠️ Firebase Admin SDK initialization notice on startup",
    );
  }

  // 3. Start HTTP server with resilient retries
  try {
    await listenWithRetry(httpServer, portNum, "0.0.0.0");
  } catch (err) {
    logger.fatal({ err }, `Failed to bind server to port ${portNum}`);
    process.exit(1);
  }

  logger.info(
    `🏏 SMASH UP INDIA Backend Server running in ${env.NODE_ENV} mode on port ${portNum}`,
  );
  logger.info(
    `⚡ Socket.io Real-Time engine active on ws://localhost:${portNum}`,
  );
  logger.info(
    `🌐 REST API endpoints active on http://localhost:${portNum}/api/v1`,
  );

  try {
    startMatchLifecycleWorker();
    startPaymentExpiryJob();
    startPaymentReconciliationJob();

    CctvRecordingService.checkFfmpeg().catch((err) => {
      logger.info({ err }, "CCTV system operational (FFmpeg optional)");
    });
    CctvRecordingService.reconcileOnBoot().catch((err) => {
      logger.error({ err }, "CCTV boot reconciliation failed");
    });

    MediaMtxService.ensureRunning().catch((err) => {
      logger.warn({ err }, "MediaMTX auto-start check skipped");
    });

    TunnelService.start(portNum).catch((err) => {
      logger.warn({ err }, "Cloudflare Tunnel start skipped");
    });
  } catch (workerErr: any) {
    logger.error({ workerErr }, "Failed to start background worker jobs");
  }

  return httpServer;
};

const server = await startServer();

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

  setTimeout(() => {
    logger.error(
      "⚠️ Graceful shutdown timed out (10s limit). Forcing immediate termination.",
    );
    process.exit(1);
  }, 10000).unref();
};

process.on("SIGTERM", () => handleGracefulShutdown("SIGTERM"));
process.on("SIGINT", () => handleGracefulShutdown("SIGINT"));
