import path from 'path';
import fs from 'fs';
import { logger } from '../utils/logger.js';
import { MediaMtxService } from './mediaMtx.service.js';

export interface HlsSession {
  sessionId: string;
  channel: number;
  streamType: string;
  outputDir: string;
  playlistPath: string;
  startedAt: Date;
  lastAccessedAt: Date;
  clientCount: number;
}

/**
 * HLS Streaming Service - 100% MediaMTX Native
 *
 * Eliminates FFmpeg entirely. All HLS segmenting, remuxing, and low-latency
 * streaming is handled natively by MediaMTX on port 8888.
 */
export class HlsStreamingService {
  private static activeSessions = new Map<string, HlsSession>();
  private static hlsBaseDir = path.resolve(process.cwd(), 'temp_hls');
  private static readonly SESSION_IDLE_TTL_MS = 2 * 60 * 1000;
  private static cleanupTimer: NodeJS.Timeout | null = null;

  static getHlsBaseDir(): string {
    if (!fs.existsSync(this.hlsBaseDir)) {
      fs.mkdirSync(this.hlsBaseDir, { recursive: true });
    }
    return this.hlsBaseDir;
  }

  static getHlsUrlPath(sessionId: string): string {
    return `/hls/${sessionId}/playlist.m3u8`;
  }

  /**
   * Start or reuse an HLS streaming session powered by MediaMTX.
   */
  static async startOrReuseSession(params: {
    sessionId: string;
    rtspUrl: string;
    channel: number;
    streamType: string;
    host?: string;
  }): Promise<{ session: HlsSession; hlsUrlPath: string; isNew: boolean }> {
    const { sessionId, channel, streamType } = params;

    // Ensure MediaMTX server is active
    await MediaMtxService.ensureRunning();

    const existing = this.activeSessions.get(sessionId);
    if (existing) {
      existing.lastAccessedAt = new Date();
      existing.clientCount++;
      logger.info(`[HLS] Reusing existing MediaMTX session ${sessionId}`);
      return {
        session: existing,
        hlsUrlPath: this.getHlsUrlPath(sessionId),
        isNew: false,
      };
    }

    const baseDir = this.getHlsBaseDir();
    const outputDir = path.join(baseDir, sessionId);

    if (fs.existsSync(outputDir)) {
      fs.rmSync(outputDir, { recursive: true, force: true });
    }
    fs.mkdirSync(outputDir, { recursive: true });

    const playlistPath = path.join(outputDir, 'playlist.m3u8');
    const streamKey = `cam${channel}_${streamType}`;

    // Write standard HLS master playlist linking to MediaMTX stream
    const masterPlaylist = `#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1920x1080
http://${params.host || '127.0.0.1'}:8888/${streamKey}/index.m3u8
`;
    fs.writeFileSync(playlistPath, masterPlaylist, 'utf8');

    const session: HlsSession = {
      sessionId,
      channel,
      streamType,
      outputDir,
      playlistPath,
      startedAt: new Date(),
      lastAccessedAt: new Date(),
      clientCount: 1,
    };

    this.activeSessions.set(sessionId, session);
    logger.info(`[HLS] Session ${sessionId} ready via MediaMTX (Channel ${channel}, ${streamType})`);
    this.startCleanupTimer();

    return {
      session,
      hlsUrlPath: this.getHlsUrlPath(sessionId),
      isNew: true,
    };
  }

  static releaseSession(sessionId: string): boolean {
    const session = this.activeSessions.get(sessionId);
    if (!session) return false;

    session.clientCount = Math.max(0, session.clientCount - 1);
    if (session.clientCount === 0) {
      this.activeSessions.delete(sessionId);
      if (fs.existsSync(session.outputDir)) {
        try {
          fs.rmSync(session.outputDir, { recursive: true, force: true });
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  private static startCleanupTimer(): void {
    if (this.cleanupTimer) return;

    this.cleanupTimer = setInterval(() => {
      const now = Date.now();
      for (const [id, session] of this.activeSessions.entries()) {
        if (now - session.lastAccessedAt.getTime() > this.SESSION_IDLE_TTL_MS) {
          logger.info(`[HLS] Auto-cleaning idle session ${id}`);
          this.releaseSession(id);
        }
      }

      if (this.activeSessions.size === 0 && this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = null;
      }
    }, 30000);
  }
}
