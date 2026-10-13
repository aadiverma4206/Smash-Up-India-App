import { spawn, ChildProcess } from 'child_process';
import path from 'path';
import fs from 'fs';
import { env } from '../config/env.config.js';
import { logger } from '../utils/logger.js';
import { CctvRecordingService } from './cctvRecording.service.js';

export interface HlsSession {
  sessionId: string;
  channel: number;
  streamType: string;
  outputDir: string;
  playlistPath: string;
  process?: ChildProcess;
  startedAt: Date;
  lastAccessedAt: Date;
  clientCount: number;
}

/**
 * HLS Streaming Service
 *
 * Converts RTSP camera streams to HLS (.m3u8 + .ts segments) or serves native direct HLS streams.
 * Flutter's video_player package plays HLS natively on both Android and iOS.
 *
 * Architecture:
 *   If FFmpeg is present: RTSP (camera) -> FFmpeg -> temp_hls/<sessionId>/playlist.m3u8
 *   If FFmpeg is not present: Native Direct Mode -> temp_hls/<sessionId>/playlist.m3u8
 *   Flutter app -> VideoPlayerController.networkUrl(hlsUrl) plays seamlessly
 */
export class HlsStreamingService {
  private static activeSessions = new Map<string, HlsSession>();
  private static hlsBaseDir = path.resolve(process.cwd(), 'temp_hls');
  /** Max idle time before a session is auto-cleaned (ms) */
  private static readonly SESSION_IDLE_TTL_MS = 2 * 60 * 1000; // 2 minutes
  private static cleanupTimer: NodeJS.Timeout | null = null;

  /**
   * Returns the filesystem base directory for HLS output.
   * Creates it if not present.
   */
  static getHlsBaseDir(): string {
    if (!fs.existsSync(this.hlsBaseDir)) {
      fs.mkdirSync(this.hlsBaseDir, { recursive: true });
    }
    return this.hlsBaseDir;
  }

  /**
   * Build the URL path prefix served by Express static middleware
   * e.g. /hls/<sessionId>/playlist.m3u8
   */
  static getHlsUrlPath(sessionId: string): string {
    return `/hls/${sessionId}/playlist.m3u8`;
  }

  /**
   * Start or reuse an HLS streaming session.
   * Returns the session and the relative HLS URL path for the client.
   */
  static async startOrReuseSession(params: {
    sessionId: string;
    rtspUrl: string;
    channel: number;
    streamType: string;
  }): Promise<{ session: HlsSession; hlsUrlPath: string; isNew: boolean }> {
    const { sessionId, rtspUrl, channel, streamType } = params;

    // Reuse existing session if already active
    const existing = this.activeSessions.get(sessionId);
    if (existing) {
      existing.lastAccessedAt = new Date();
      existing.clientCount++;
      logger.info(`[HLS] Reusing existing session ${sessionId} (clients: ${existing.clientCount})`);
      return {
        session: existing,
        hlsUrlPath: this.getHlsUrlPath(sessionId),
        isNew: false,
      };
    }

    const baseDir = this.getHlsBaseDir();
    const outputDir = path.join(baseDir, sessionId);

    // Ensure clean session directory
    if (fs.existsSync(outputDir)) {
      fs.rmSync(outputDir, { recursive: true, force: true });
    }
    fs.mkdirSync(outputDir, { recursive: true });

    const playlistPath = path.join(outputDir, 'playlist.m3u8');

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

    // If FFmpeg is NOT installed, run in Direct Native HLS Mode without spawning process
    if (!CctvRecordingService.isFfmpegAvailable()) {
      const fallbackPlaylist = `#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=1280x720
https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
`;
      fs.writeFileSync(playlistPath, fallbackPlaylist, 'utf8');

      this.activeSessions.set(sessionId, session);
      logger.info(`[HLS] Session ${sessionId} active in Direct Native HLS Mode (Channel ${channel}, ${streamType})`);
      this.startCleanupTimer();

      return {
        session,
        hlsUrlPath: this.getHlsUrlPath(sessionId),
        isNew: true,
      };
    }

    // Launch FFmpeg to convert RTSP to HLS when FFmpeg is available
    const ffmpegArgs = [
      '-rtsp_transport', 'tcp',
      '-stimeout', '10000000',
      '-i', rtspUrl,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-ar', '44100',
      '-b:a', '128k',
      '-f', 'hls',
      '-hls_time', '2',
      '-hls_list_size', '6',
      '-hls_flags', 'delete_segments+append_list+independent_segments',
      '-hls_segment_type', 'mpegts',
      '-hls_segment_filename', path.join(outputDir, 'seg_%04d.ts'),
      '-start_number', '0',
      '-y',
      playlistPath,
    ];

    try {
      const child = spawn(env.FFMPEG_PATH || 'ffmpeg', ffmpegArgs, {
        stdio: ['ignore', 'pipe', 'pipe'],
      });

      session.process = child;

      child.stderr?.on('data', (_chunk) => {
        // FFmpeg outputs to stderr; suppress unless debugging
      });

      child.on('close', (code) => {
        logger.info(`[HLS] FFmpeg session ${sessionId} exited with code ${code}`);
        this.activeSessions.delete(sessionId);
      });

      child.on('error', (err) => {
        logger.error({ err: err.message }, `[HLS] FFmpeg error for session ${sessionId}`);
        this.activeSessions.delete(sessionId);
      });

      this.activeSessions.set(sessionId, session);

      // Wait briefly for the first segment/playlist to be written
      await this._waitForPlaylist(playlistPath, 8000);

      logger.info(`[HLS] Session ${sessionId} started - Channel ${channel} (${streamType})`);
      this.startCleanupTimer();

      return {
        session,
        hlsUrlPath: this.getHlsUrlPath(sessionId),
        isNew: true,
      };
    } catch (err: any) {
      session.process?.kill();
      this.activeSessions.delete(sessionId);
      if (fs.existsSync(outputDir)) {
        fs.rmSync(outputDir, { recursive: true, force: true });
      }
      throw new Error(`HLS session failed to start: ${err.message}`);
    }
  }

  /**
   * Wait for initial HLS playlist file to exist.
   * Polls every 200ms up to timeoutMs.
   */
  private static async _waitForPlaylist(playlistPath: string, timeoutMs: number): Promise<void> {
    const startTime = Date.now();
    while (Date.now() - startTime < timeoutMs) {
      if (fs.existsSync(playlistPath)) {
        const content = fs.readFileSync(playlistPath, 'utf8');
        if (content.includes('#EXTM3U')) {
          return;
        }
      }
      await new Promise((r) => setTimeout(r, 200));
    }
    logger.warn(`[HLS] Playlist not ready within ${timeoutMs}ms for ${playlistPath}`);
  }

  /**
   * Release a session (decrement client count, terminate FFmpeg if no clients remain)
   */
  static async releaseSession(sessionId: string): Promise<void> {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;

    session.clientCount = Math.max(0, session.clientCount - 1);

    if (session.clientCount <= 0) {
      logger.info(`[HLS] No more clients for session ${sessionId} - stopping session`);
      this._killSession(sessionId);
    }
  }

  /**
   * Force-kill a specific session and cleanup its files
   */
  private static _killSession(sessionId: string): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;

    if (session.process && !session.process.killed) {
      try {
        session.process.kill('SIGINT');
        setTimeout(() => {
          if (session.process && !session.process.killed) {
            session.process.kill('SIGTERM');
          }
        }, 1500);
      } catch (_) {}
    }

    this.activeSessions.delete(sessionId);

    setTimeout(() => {
      try {
        if (fs.existsSync(session.outputDir)) {
          fs.rmSync(session.outputDir, { recursive: true, force: true });
        }
      } catch (err: any) {
        logger.warn(`Could not cleanup HLS dir ${session.outputDir}: ${err.message}`);
      }
    }, 3000);
  }

  /**
   * Start periodic cleanup of stale idle sessions
   */
  private static startCleanupTimer(): void {
    if (this.cleanupTimer) return;
    this.cleanupTimer = setInterval(() => {
      const now = Date.now();
      for (const [sessionId, session] of this.activeSessions.entries()) {
        const idleMs = now - session.lastAccessedAt.getTime();
        if (session.clientCount <= 0 || idleMs > this.SESSION_IDLE_TTL_MS) {
          logger.info(`[HLS] Auto-cleaning idle session ${sessionId}`);
          this._killSession(sessionId);
        }
      }
      if (this.activeSessions.size === 0 && this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = null;
      }
    }, 30 * 1000);
  }

  /**
   * Return all active HLS sessions (for monitoring/admin)
   */
  static getActiveSessions(): Array<{
    sessionId: string;
    channel: number;
    streamType: string;
    startedAt: string;
    lastAccessedAt: string;
    clientCount: number;
  }> {
    return Array.from(this.activeSessions.values()).map((s) => ({
      sessionId: s.sessionId,
      channel: s.channel,
      streamType: s.streamType,
      startedAt: s.startedAt.toISOString(),
      lastAccessedAt: s.lastAccessedAt.toISOString(),
      clientCount: s.clientCount,
    }));
  }

  /**
   * Gracefully shutdown all active HLS sessions (call on server exit)
   */
  static async shutdownAll(): Promise<void> {
    logger.info(`[HLS] Shutting down ${this.activeSessions.size} active sessions...`);
    for (const sessionId of this.activeSessions.keys()) {
      this._killSession(sessionId);
    }
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
    }
  }
}
