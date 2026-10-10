import { spawn, ChildProcess } from 'child_process';
import net from 'net';
import path from 'path';
import fs from 'fs';
import { dbPool } from '../config/db.config.js';
import { env } from '../config/env.config.js';
import { logger } from '../utils/logger.js';
import { decryptSecret, redactRtspUrl } from '../utils/crypto.utils.js';
import { uploadLocalFileToS3, safeDeleteLocalFile } from './storage.service.js';
import { getSocketIO } from '../config/socket.config.js';

export interface ActiveRecording {
  recordingId: string;
  gameId: string;
  clubId: string;
  courtId?: string;
  cameraId: string;
  outputFile: string;
  tempDir: string;
  process?: ChildProcess;
  stopTimer?: NodeJS.Timeout;
  startedAt: Date;
  scheduledStopAt: Date;
  retryCount: number;
}

export class CctvRecordingService {
  private static activeRecordings = new Map<string, ActiveRecording>();
  private static ffmpegChecked = false;
  private static ffmpegAvailable = false;
  private static ffmpegVersionStr = '';

  /**
   * Check if FFmpeg is installed and accessible on host system
   */
  static async checkFfmpeg(): Promise<{ available: boolean; version: string; binaryPath: string }> {
    if (this.ffmpegChecked) {
      return {
        available: this.ffmpegAvailable,
        version: this.ffmpegVersionStr,
        binaryPath: env.FFMPEG_PATH,
      };
    }

    return new Promise((resolve) => {
      try {
        const proc = spawn(env.FFMPEG_PATH, ['-version']);
        let output = '';

        proc.stdout?.on('data', (data) => {
          output += data.toString();
        });

        proc.on('error', (err) => {
          this.ffmpegChecked = true;
          this.ffmpegAvailable = false;
          this.ffmpegVersionStr = '';
          logger.warn(
            { err: err.message, path: env.FFMPEG_PATH },
            '⚠️ [FFmpeg Check] FFmpeg binary not found or not executable. Video stream capture will be disabled until installed.'
          );
          resolve({
            available: false,
            version: '',
            binaryPath: env.FFMPEG_PATH,
          });
        });

        proc.on('close', (code) => {
          this.ffmpegChecked = true;
          this.ffmpegAvailable = code === 0;
          this.ffmpegVersionStr = output.split('\n')[0] || '';
          if (this.ffmpegAvailable) {
            logger.info(
              `🎥 [FFmpeg Check] Valid FFmpeg detected: ${this.ffmpegVersionStr} (${env.FFMPEG_PATH})`
            );
          }
          resolve({
            available: this.ffmpegAvailable,
            version: this.ffmpegVersionStr,
            binaryPath: env.FFMPEG_PATH,
          });
        });
      } catch (err: any) {
        this.ffmpegChecked = true;
        this.ffmpegAvailable = false;
        resolve({
          available: false,
          version: '',
          binaryPath: env.FFMPEG_PATH,
        });
      }
    });
  }

  /**
   * Real network connection test to camera via TCP RTSP port
   */
  static async testCameraConnection(camera: {
    id: string;
    ip_address?: string;
    port?: number;
    rtsp_url_encrypted: string;
  }): Promise<{ status: 'ONLINE' | 'OFFLINE'; message: string; latencyMs?: number }> {
    const startTime = Date.now();
    let host = camera.ip_address || '';
    let port = camera.port || 554;

    try {
      if (camera.rtsp_url_encrypted) {
        const decrypted = decryptSecret(camera.rtsp_url_encrypted);
        try {
          const parsed = new URL(decrypted);
          host = host || parsed.hostname;
          port = port || (parsed.port ? parseInt(parsed.port, 10) : 554);
        } catch (_) {
          // Fallback if URL is non-standard
        }
      }
    } catch (_) {}

    if (!host) {
      host = '127.0.0.1';
    }

    const timeoutMs = env.CAMERA_CONNECTION_TIMEOUT_MS || 5000;

    return new Promise((resolve) => {
      const socket = new net.Socket();
      socket.setTimeout(timeoutMs);

      const cleanup = () => {
        socket.removeAllListeners();
        socket.destroy();
      };

      socket.on('connect', async () => {
        const latencyMs = Date.now() - startTime;
        // Optionally send RTSP OPTIONS request
        socket.write(`OPTIONS rtsp://${host}:${port}/ RTSP/1.0\r\nCSeq: 1\r\nUser-Agent: AllStarsArena/2.0\r\n\r\n`);
      });

      socket.on('data', async () => {
        cleanup();
        const latencyMs = Date.now() - startTime;
        await dbPool.query(
          `UPDATE public.cctv_cameras
           SET status = 'ONLINE', health_status = 'ONLINE',
               last_connection_at = CURRENT_TIMESTAMP,
               last_successful_connection = CURRENT_TIMESTAMP,
               last_error = NULL
           WHERE id = $1;`,
          [camera.id]
        );
        resolve({
          status: 'ONLINE',
          message: `Camera connection verified successfully (${latencyMs}ms)`,
          latencyMs,
        });
      });

      socket.on('error', async (err) => {
        cleanup();
        const sanitizedErr = `Connection failed to ${host}:${port}: ${err.message}`;
        await dbPool.query(
          `UPDATE public.cctv_cameras
           SET status = 'OFFLINE', health_status = 'OFFLINE',
               last_connection_at = CURRENT_TIMESTAMP,
               last_error = $1
           WHERE id = $2;`,
          [sanitizedErr, camera.id]
        );
        resolve({
          status: 'OFFLINE',
          message: sanitizedErr,
        });
      });

      socket.on('timeout', async () => {
        cleanup();
        const sanitizedErr = `Connection timed out after ${timeoutMs}ms to ${host}:${port}`;
        await dbPool.query(
          `UPDATE public.cctv_cameras
           SET status = 'OFFLINE', health_status = 'OFFLINE',
               last_connection_at = CURRENT_TIMESTAMP,
               last_error = $1
           WHERE id = $2;`,
          [sanitizedErr, camera.id]
        );
        resolve({
          status: 'OFFLINE',
          message: sanitizedErr,
        });
      });

      socket.connect(port, host);
    });
  }

  static getActiveSession(recordingId: string): ActiveRecording | undefined {
    return this.activeRecordings.get(recordingId);
  }

  /**
   * Start server-side FFmpeg RTSP recording for a match
   */
  static async startRecording(params: {
    recordingId: string;
    gameId: string;
    clubId: string;
    courtId?: string;
    camera: any;
    scheduledStopAt: Date;
  }): Promise<void> {
    const { recordingId, gameId, clubId, courtId, camera, scheduledStopAt } = params;

    if (this.activeRecordings.has(recordingId)) {
      logger.info(`Recording ${recordingId} already actively running in memory`);
      return;
    }

    // Enforce server concurrency limits to protect host resources
    const maxConcurrent = env.RECORDING_MAX_CONCURRENT || 5;
    if (this.activeRecordings.size >= maxConcurrent) {
      logger.warn(
        { active: this.activeRecordings.size, max: maxConcurrent },
        `⚠️ [CCTV Recorder] Concurrent recording limit (${maxConcurrent}) reached. Deferring recording ${recordingId}.`
      );
      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET status = 'FAILED', recording_status = 'FAILED',
             error_code = 'CONCURRENCY_LIMIT_REACHED',
             error_message = 'Maximum simultaneous CCTV recording capacity reached'
         WHERE id = $1;`,
        [recordingId]
      );
      return;
    }

    const ffmpegStatus = await this.checkFfmpeg();
    const tempBaseDir = path.resolve(process.cwd(), env.RECORDING_TEMP_DIR);
    const sessionDir = path.join(tempBaseDir, recordingId);

    try {
      if (!fs.existsSync(sessionDir)) {
        fs.mkdirSync(sessionDir, { recursive: true });
      }
    } catch (fsErr: any) {
      logger.error({ fsErr }, `Failed to create session temp directory: ${sessionDir}`);
      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET status = 'FAILED', recording_status = 'FAILED',
             error_code = 'STORAGE_PERMISSION_DENIED',
             error_message = 'Failed to create temporary recording folder on host'
         WHERE id = $1;`,
        [recordingId]
      );
      return;
    }

    const outputFile = path.join(sessionDir, `match_${gameId}_${Date.now()}.mp4`);

    let rtspUrl = '';
    try {
      rtspUrl = decryptSecret(camera.rtsp_url_encrypted);
    } catch (err: any) {
      logger.error({ err }, `Failed to decrypt RTSP credentials for camera ${camera.id}`);
      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET status = 'FAILED', recording_status = 'FAILED',
             error_code = 'DECRYPTION_FAILED',
             error_message = 'Failed to decrypt camera credentials'
         WHERE id = $1;`,
        [recordingId]
      );
      return;
    }

    const sanitizedLogUrl = redactRtspUrl(rtspUrl);
    logger.info(`🎬 [CCTV Recorder] Starting recording ${recordingId} for Game ${gameId} from ${sanitizedLogUrl}`);

    const activeRec: ActiveRecording = {
      recordingId,
      gameId,
      clubId,
      courtId,
      cameraId: camera.id,
      outputFile,
      tempDir: sessionDir,
      startedAt: new Date(),
      scheduledStopAt,
      retryCount: 0,
    };

    // Auto-stop timer when deadline expires
    const delayMs = Math.max(scheduledStopAt.getTime() - Date.now(), 1000);
    activeRec.stopTimer = setTimeout(async () => {
      logger.info(`⏰ [CCTV Recorder] Auto-stop deadline reached for recording ${recordingId}`);
      await CctvRecordingService.stopRecording(recordingId, {
        reason: 'SCHEDULED_DEADLINE_EXPIRED',
      });
    }, delayMs);

    this.activeRecordings.set(recordingId, activeRec);

    if (!ffmpegStatus.available) {
      logger.warn(
        `⚠️ [CCTV Recorder] FFmpeg not installed on host. Recording ${recordingId} registered in DB but media stream capture is deferred.`
      );
      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET local_temp_path = $1, error_code = 'FFMPEG_NOT_INSTALLED',
             error_message = 'FFmpeg binary not detected on system'
         WHERE id = $2;`,
        [outputFile, recordingId]
      );
      return;
    }

    // Launch FFmpeg safely via argument array (no shell expansion)
    const ffmpegArgs = [
      '-rtsp_transport',
      'tcp',
      '-stimeout',
      '10000000', // 10s socket timeout
      '-i',
      rtspUrl,
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-f',
      'mp4',
      '-movflags',
      '+faststart',
      '-y',
      outputFile,
    ];

    try {
      const child = spawn(env.FFMPEG_PATH, ffmpegArgs, {
        stdio: ['ignore', 'pipe', 'pipe'],
      });

      activeRec.process = child;

      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET ffmpeg_pid = $1, local_temp_path = $2
         WHERE id = $3;`,
        [child.pid, outputFile, recordingId]
      );

      child.stderr?.on('data', (chunk) => {
        // Redact any output if necessary
      });

      child.on('close', async (code) => {
        logger.info(`📹 [CCTV Recorder] FFmpeg process for ${recordingId} exited with code ${code}`);
      });

      child.on('error', async (err) => {
        logger.error({ err: err.message }, `[CCTV Recorder] FFmpeg execution error for ${recordingId}`);
      });
    } catch (err: any) {
      logger.error({ err }, `Failed to spawn FFmpeg process for recording ${recordingId}`);
    }
  }

  /**
   * Gracefully stop recording session, finalize file, upload to S3, and update database
   */
  static async stopRecording(
    recordingId: string,
    options?: {
      userId?: string;
      reason?: string;
      manualStop?: boolean;
    }
  ): Promise<any> {
    const session = this.activeRecordings.get(recordingId);

    // Clear auto-stop timer
    if (session?.stopTimer) {
      clearTimeout(session.stopTimer);
    }

    // Retrieve recording details from DB if not in memory
    const recRes = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE id = $1;`,
      [recordingId]
    );

    if (recRes.rows.length === 0) {
      throw new Error(`Recording ${recordingId} not found`);
    }

    const rec = recRes.rows[0];
    const isManual = Boolean(options?.manualStop);
    const stoppedAt = new Date();

    // If FFmpeg process is running, gracefully signal SIGINT
    if (session?.process && !session.process.killed) {
      try {
        session.process.kill('SIGINT');
        // Give it 2 seconds to flush moov atom
        await new Promise((res) => setTimeout(res, 2000));
        if (!session.process.killed) {
          session.process.kill('SIGTERM');
        }
      } catch (_) {}
    }

    this.activeRecordings.delete(recordingId);

    const s3ObjectKey = rec.storage_object_key || rec.s3_object_key || `recordings/${rec.club_id}/${rec.game_id}_${Date.now()}.mp4`;
    const localPath = session?.outputFile || rec.local_temp_path;

    let uploadSuccess = false;
    let durationSeconds = 5400; // default 90m

    // Verify local file exists & has size
    if (localPath && fs.existsSync(localPath)) {
      try {
        const stats = await fs.promises.stat(localPath);
        if (stats.size > 1024) {
          // Upload to S3 with retry handling
          await uploadLocalFileToS3(localPath, s3ObjectKey, {
            contentType: 'video/mp4',
            maxRetries: env.RECORDING_MAX_RETRIES || 3,
          });
          uploadSuccess = true;

          // Delete temporary file safely after successful S3 upload
          await safeDeleteLocalFile(localPath);
        }
      } catch (uploadErr: any) {
        logger.error({ uploadErr }, `Failed to upload recording file ${localPath} to S3`);
      }
    }

    // Update cctv_recordings in DB
    const finalStatus = isManual ? 'STOPPED' : 'COMPLETED';
    const finalRecStatus = isManual ? 'STOPPED_MANUALLY' : 'COMPLETED';

    const updateRes = await dbPool.query(
      `UPDATE public.cctv_recordings
       SET status = $1, recording_status = $2,
           actual_stop_time = $3, actual_stopped_at = $3,
           manual_stop = $4,
           playback_status = $5,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $6
       RETURNING *;`,
      [
        finalStatus,
        finalRecStatus,
        stoppedAt,
        isManual,
        uploadSuccess ? 'READY' : 'PROCESSING',
        recordingId,
      ]
    );

    // Save segment metadata into cctv_recording_segments
    try {
      const fileStats = localPath && fs.existsSync(localPath) ? await fs.promises.stat(localPath) : null;
      const fileBytes = fileStats ? fileStats.size : 0;
      await dbPool.query(
        `INSERT INTO public.cctv_recording_segments (
           recording_id, game_id, segment_order, s3_object_key,
           local_file_path, duration_seconds, file_size_bytes, status
         ) VALUES ($1, $2, 1, $3, $4, $5, $6, $7)
         ON CONFLICT (id) DO NOTHING;`,
        [
          recordingId,
          rec.game_id,
          s3ObjectKey,
          localPath || null,
          durationSeconds,
          fileBytes,
          uploadSuccess ? 'READY' : 'FAILED',
        ]
      );
    } catch (segErr) {
      logger.error({ segErr }, `Failed to insert segment metadata for recording ${recordingId}`);
    }

    // Save into game_videos catalog
    await dbPool.query(
      `INSERT INTO public.game_videos (game_id, club_id, court_id, title, video_url, uploaded_by_id, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'AVAILABLE')
       ON CONFLICT DO NOTHING;`,
      [
        rec.game_id,
        rec.club_id,
        rec.court_id,
        `Match Recording - Game ${rec.game_id}`,
        s3ObjectKey,
        options?.userId || null,
      ]
    );

    // Audit Event
    await dbPool.query(
      `INSERT INTO public.cctv_recording_events (recording_id, event_type, actor_user_id, metadata)
       VALUES ($1, $2, $3, $4);`,
      [
        recordingId,
        isManual ? 'MANUAL_STOP_TRIGGERED' : 'AUTO_STOP_TRIGGERED',
        options?.userId || null,
        JSON.stringify({
          reason: options?.reason || 'Stop triggered',
          stoppedAt: stoppedAt.toISOString(),
          s3ObjectKey,
          uploadSuccess,
        }),
      ]
    );

    // Real-time broadcast
    try {
      const io = getSocketIO();
      io.to(`game:${rec.game_id}`).emit('recording:available', {
        gameId: rec.game_id,
        status: 'AVAILABLE',
        title: `Match Recording - Game ${rec.game_id}`,
      });
    } catch (_) {}

    const row = updateRes.rows[0];
    const startedAt = row.started_at || row.start_time || new Date();
    const scheduledEnd = row.scheduled_match_end || new Date();
    const stopDeadline = row.stop_deadline || new Date();
    return {
      id: row.id,
      recordingId: row.id,
      gameId: row.game_id,
      clubId: row.club_id,
      courtId: row.court_id,
      cameraId: row.camera_id,
      status: row.status,
      recordingStatus: row.recording_status || row.status,
      startedAt: startedAt instanceof Date ? startedAt.toISOString() : String(startedAt),
      scheduledMatchEnd: scheduledEnd instanceof Date ? scheduledEnd.toISOString() : String(scheduledEnd),
      stopDeadline: stopDeadline instanceof Date ? stopDeadline.toISOString() : String(stopDeadline),
      actualStopTime: row.actual_stop_time
        ? (row.actual_stop_time instanceof Date ? row.actual_stop_time.toISOString() : String(row.actual_stop_time))
        : null,
      manualStop: Boolean(row.manual_stop),
      ...row,
    };
  }

  /**
   * Extend an active recording deadline by N minutes
   */
  static async extendRecording(
    recordingId: string,
    additionalMinutes: number,
    userId?: string
  ): Promise<any> {
    const session = this.activeRecordings.get(recordingId);

    const recRes = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE id = $1;`,
      [recordingId]
    );
    if (recRes.rows.length === 0) {
      throw new Error(`Recording ${recordingId} not found`);
    }

    const rec = recRes.rows[0];
    const currentDeadline = new Date(rec.stop_deadline || rec.post_match_stop_at || Date.now());
    const newDeadline = new Date(currentDeadline.getTime() + additionalMinutes * 60 * 1000);

    // Update in DB
    const updated = await dbPool.query(
      `UPDATE public.cctv_recordings
       SET stop_deadline = $1, post_match_stop_at = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING *;`,
      [newDeadline, recordingId]
    );

    // Reschedule in-memory timer
    if (session) {
      if (session.stopTimer) clearTimeout(session.stopTimer);
      const delayMs = Math.max(newDeadline.getTime() - Date.now(), 1000);
      session.stopTimer = setTimeout(async () => {
        await CctvRecordingService.stopRecording(recordingId, {
          reason: 'EXTENDED_DEADLINE_EXPIRED',
        });
      }, delayMs);
      session.scheduledStopAt = newDeadline;
    }

    // Log event
    await dbPool.query(
      `INSERT INTO public.cctv_recording_events (recording_id, event_type, actor_user_id, metadata)
       VALUES ($1, 'EXTENDED_DEADLINE', $2, $3);`,
      [
        recordingId,
        userId || null,
        JSON.stringify({
          additionalMinutes,
          newDeadline: newDeadline.toISOString(),
        }),
      ]
    );

    const row = updated.rows[0];
    const startedAt = row.started_at || row.start_time || new Date();
    const scheduledEnd = row.scheduled_match_end || new Date();
    return {
      id: row.id,
      recordingId: row.id,
      gameId: row.game_id,
      clubId: row.club_id,
      courtId: row.court_id,
      cameraId: row.camera_id,
      status: row.status,
      recordingStatus: row.recording_status || row.status,
      startedAt: startedAt instanceof Date ? startedAt.toISOString() : String(startedAt),
      scheduledMatchEnd: scheduledEnd instanceof Date ? scheduledEnd.toISOString() : String(scheduledEnd),
      stopDeadline: newDeadline.toISOString(),
      actualStopTime: row.actual_stop_time
        ? (row.actual_stop_time instanceof Date ? row.actual_stop_time.toISOString() : String(row.actual_stop_time))
        : null,
      manualStop: Boolean(row.manual_stop),
      ...row,
    };
  }

  /**
   * Reconcile pending/active recordings on server reboot to recover state safely
   */
  static async reconcileOnBoot(): Promise<void> {
    try {
      const activeFromDb = await dbPool.query(
        `SELECT rec.*, cam.ip_address, cam.port, cam.rtsp_url_encrypted
         FROM public.cctv_recordings rec
         LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
         WHERE rec.status IN ('RECORDING', 'STARTING')
            OR rec.recording_status IN ('RECORDING', 'POST_MATCH', 'STARTING');`
      );

      for (const rec of activeFromDb.rows) {
        const deadline = new Date(rec.stop_deadline || rec.post_match_stop_at || Date.now());
        if (deadline.getTime() <= Date.now()) {
          // Deadline already passed while server was down -> finalize safely
          logger.info(`Reconciling expired recording ${rec.id} on boot...`);
          await this.stopRecording(rec.id, {
            reason: 'RECONCILED_DEADLINE_EXPIRED_ON_BOOT',
          });
        } else {
          // Re-arm recording session
          logger.info(`Re-arming active recording ${rec.id} until ${deadline.toISOString()}`);
          await this.startRecording({
            recordingId: rec.id,
            gameId: rec.game_id,
            clubId: rec.club_id,
            courtId: rec.court_id,
            camera: {
              id: rec.camera_id,
              ip_address: rec.ip_address,
              port: rec.port,
              rtsp_url_encrypted: rec.rtsp_url_encrypted,
            },
            scheduledStopAt: deadline,
          });
        }
      }
    } catch (err: any) {
      logger.error({ err }, 'Error during CCTV recording boot reconciliation');
    }
  }
}
