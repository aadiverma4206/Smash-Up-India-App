import { createServer } from 'http';
import app from './app.js';
import { env } from './config/env.config.js';
import { dbPool, initDbTables } from './config/db.config.js';
import { initSocket } from './config/socket.config.js';
import { logger } from './utils/logger.js';
import { startMatchLifecycleWorker, startPaymentExpiryJob, startPaymentReconciliationJob } from './jobs/index.js';
import { CctvRecordingService } from './services/cctvRecording.service.js';
import { MediaMtxService } from './services/mediaMtx.service.js';

// Catch unhandled synchronous exceptions
process.on('uncaughtException', (err: Error) => {
  logger.fatal({ err }, '💥 FATAL: Uncaught Exception detected! Cleaning up before exit...');
  // Ensure logs flush and exit
  setTimeout(() => {
    process.exit(1);
  }, 1000).unref();
});

// Catch unhandled asynchronous promise rejections
process.on('unhandledRejection', (reason: any) => {
  logger.error({ reason }, '🚨 WARNING: Unhandled Promise Rejection detected in runtime!');
});

const httpServer = createServer(app);

// Initialize Socket.io Real-Time Football Engine
initSocket(httpServer);

const PORT = env.PORT;

const startServer = async () => {
  // 1. Verify / Initialize DB Tables with robust error catch
  try {
    await initDbTables();
  } catch (err) {
    logger.error({ err }, '❌ Database table initialization failed on startup');
  }

  // 2. Start HTTP server
  const server = httpServer.listen(PORT, () => {
    logger.info(`⚽ ALL STARS ARENA Server running in ${env.NODE_ENV} mode on port ${PORT}`);
    logger.info(`⚡ Socket.io Real-Time engine active on ws://localhost:${PORT}`);

    // Start Background Workers & Schedulers
    try {
      startMatchLifecycleWorker();
      startPaymentExpiryJob();
      startPaymentReconciliationJob();

      // Initialize CCTV system (FFmpeg optional) & reconcile active recordings on boot
      CctvRecordingService.checkFfmpeg().catch((err) => {
        logger.info({ err }, 'CCTV system operational (FFmpeg optional)');
      });
      CctvRecordingService.reconcileOnBoot().catch((err) => {
        logger.error({ err }, 'CCTV boot reconciliation failed');
      });

      // Ensure MediaMTX streaming server is active
      MediaMtxService.ensureRunning().catch((err) => {
        logger.warn({ err }, 'MediaMTX auto-start check skipped');
      });
    } catch (workerErr: any) {
      logger.error({ workerErr }, 'Failed to start background worker jobs');
    }
  });

  return server;
};

const server = await startServer();

// Graceful Shutdown Handler
const handleGracefulShutdown = (signal: string) => {
  logger.info(`📡 Received ${signal}. Starting graceful shutdown...`);

  server.close(async () => {
    logger.info('🛑 HTTP server closed to new connections.');
    try {
      await dbPool.end();
      logger.info('🔌 PostgreSQL database connection pool closed.');
    } catch (err: any) {
      logger.error({ err }, 'Error closing database pool during shutdown');
    }
    process.exit(0);
  });

  // Force close if graceful shutdown hangs
  setTimeout(() => {
    logger.error('⚠️ Graceful shutdown timed out (10s limit). Forcing immediate termination.');
    process.exit(1);
  }, 10000).unref();
};

process.on('SIGTERM', () => handleGracefulShutdown('SIGTERM'));
process.on('SIGINT', () => handleGracefulShutdown('SIGINT'));
