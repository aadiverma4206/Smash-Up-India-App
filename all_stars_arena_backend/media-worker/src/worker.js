import pg from 'pg';
import dotenv from 'dotenv';
import pino from 'pino';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { FfmpegRecorder } from './ffmpeg/recorder.js';

// Load env from multiple possible locations
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
dotenv.config({ path: path.resolve(process.cwd(), '../.env') });

const logger = pino({ level: 'info' });

const dbPool = new pg.Pool({
  connectionString:
    process.env.DATABASE_URL || 'postgresql://postgres:system@localhost:5432/all_stars_arena',
});

// Configure AWS S3 / MinIO Client
const s3Region = process.env.AWS_S3_REGION || process.env.AWS_REGION || 'ap-south-1';
const s3Bucket = process.env.AWS_S3_BUCKET_NAME || process.env.AWS_S3_BUCKET || 'all-stars-arena-recordings';
const s3AccessKey = process.env.AWS_S3_ACCESS_KEY_ID || process.env.AWS_ACCESS_KEY_ID;
const s3SecretKey = process.env.AWS_S3_SECRET_ACCESS_KEY || process.env.AWS_SECRET_ACCESS_KEY;
const s3Endpoint = process.env.AWS_S3_ENDPOINT;

const s3Client = new S3Client({
  region: s3Region,
  endpoint: s3Endpoint || undefined,
  forcePathStyle: Boolean(s3Endpoint),
  credentials:
    s3AccessKey && s3SecretKey
      ? {
          accessKeyId: s3AccessKey,
          secretAccessKey: s3SecretKey,
        }
      : undefined,
});

logger.info(`🎥 ALL STARS ARENA Isolated Media Worker Started (PID: ${process.pid})`);
logger.info(`📹 Default CCTV Host: ${process.env.CAMERA_HOST || '192.168.1.2'}:${process.env.CAMERA_RTSP_PORT || 554}`);

const activeSessions = new Map();

/**
 * Decrypts AES-256-GCM encrypted RTSP credentials
 */
const decryptSecret = (encryptedText) => {
  if (!encryptedText) return '';
  const keyHex =
    process.env.CCTV_CREDENTIAL_ENCRYPTION_KEY ||
    process.env.CAMERA_CREDENTIAL_ENCRYPTION_KEY ||
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  let keyBuffer;
  if (/^[0-9a-fA-F]{64}$/.test(keyHex)) {
    keyBuffer = Buffer.from(keyHex, 'hex');
  } else {
    keyBuffer = crypto.createHash('sha256').update(keyHex, 'utf8').digest();
  }

  const parts = encryptedText.split(':');
  if (parts.length !== 3) return '';

  const iv = Buffer.from(parts[0], 'hex');
  const authTag = Buffer.from(parts[1], 'hex');
  const encrypted = parts[2];

  const decipher = crypto.createDecipheriv('aes-256-gcm', keyBuffer, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
};

/**
 * Constructs a default Dahua / XVR RTSP URL from environment configuration
 */
const getDefaultRtspUrl = (channel = 1, subtype = 0) => {
  const host = process.env.CAMERA_HOST || '192.168.1.2';
  const port = process.env.CAMERA_RTSP_PORT || 554;
  const username = process.env.CAMERA_USERNAME || 'admin';
  const password = process.env.CAMERA_PASSWORD || 'admin@123';
  const pathStr = process.env.CAMERA_RTSP_PATH || `/cam/realmonitor?channel=${channel}&subtype=${subtype}`;
  const protocol = process.env.CAMERA_PROTOCOL || 'rtsp';

  const auth = username ? `${username}:${encodeURIComponent(password)}@` : '';
  const formattedPath = pathStr.startsWith('/') ? pathStr : `/${pathStr}`;
  return `${protocol}://${auth}${host}:${port}${formattedPath}`;
};

/**
 * Main polling loop to trigger pending RTSP stream recording sessions
 */
const processPendingRecordings = async () => {
  try {
    const res = await dbPool.query(
      `SELECT rec.*, cam.rtsp_url_encrypted, cam.ip_address, cam.port
       FROM public.cctv_recordings rec
       LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
       WHERE rec.status = 'STARTING' OR rec.recording_status = 'STARTING'
       LIMIT 5;`
    );

    for (const rec of res.rows) {
      if (activeSessions.has(rec.id)) continue;

      logger.info(`Starting CCTV Media Recording Process for Game ${rec.game_id} (Recording ID: ${rec.id})`);

      let rtspUrl = '';
      if (rec.rtsp_url_encrypted) {
        try {
          rtspUrl = decryptSecret(rec.rtsp_url_encrypted);
        } catch (_) {}
      }

      if (!rtspUrl) {
        rtspUrl = getDefaultRtspUrl();
      }

      const outputDir = path.resolve(
        process.cwd(),
        process.env.RECORDING_OUTPUT_DIR || process.env.RECORDING_TEMP_DIR || './recordings'
      );

      const recorder = new FfmpegRecorder(rec.id, rtspUrl, outputDir);
      const outputFile = recorder.start();

      activeSessions.set(rec.id, {
        recordingId: rec.id,
        gameId: rec.game_id,
        clubId: rec.club_id,
        courtId: rec.court_id,
        recorder,
        outputFile,
        stopDeadline: new Date(rec.stop_deadline || Date.now() + 120 * 60 * 1000),
      });

      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET status = 'RECORDING', recording_status = 'RECORDING',
             local_temp_path = $1
         WHERE id = $2;`,
        [outputFile, rec.id]
      );

      await dbPool.query(
        `INSERT INTO public.cctv_recording_events (recording_id, event_type, metadata)
         VALUES ($1, 'RECORDING_STARTED', $2);`,
        [rec.id, JSON.stringify({ workerPid: process.pid, outputFile })]
      );
    }
  } catch (err) {
    logger.error({ err }, 'Media Worker loop error');
  }
};

/**
 * Checks for expired recordings and finalizes file output & S3 upload
 */
const processExpiredRecordings = async () => {
  try {
    const res = await dbPool.query(
      `SELECT rec.id, rec.game_id, rec.club_id, rec.court_id, rec.camera_id, rec.local_temp_path, rec.s3_object_key
       FROM public.cctv_recordings rec
       WHERE (rec.status = 'RECORDING' OR rec.recording_status IN ('RECORDING', 'POST_MATCH'))
         AND (
           rec.stop_deadline <= CURRENT_TIMESTAMP
           OR rec.post_match_stop_at <= CURRENT_TIMESTAMP
         );`
    );

    for (const rec of res.rows) {
      logger.info(`Finalizing expired recording ${rec.id} for Game ${rec.game_id}`);

      const session = activeSessions.get(rec.id);
      let localFile = rec.local_temp_path;

      if (session) {
        localFile = await session.recorder.stop();
        activeSessions.delete(rec.id);
      }

      const s3ObjectKey = rec.s3_object_key || `recordings/${rec.club_id}/${rec.game_id}_${Date.now()}.mp4`;
      let uploadSuccess = false;

      if (localFile && fs.existsSync(localFile)) {
        try {
          const stats = await fs.promises.stat(localFile);
          if (stats.size > 0) {
            const fileBuffer = await fs.promises.readFile(localFile);
            const putCmd = new PutObjectCommand({
              Bucket: s3Bucket,
              Key: s3ObjectKey,
              Body: fileBuffer,
              ContentType: 'video/mp4',
            });
            await s3Client.send(putCmd);
            uploadSuccess = true;
            logger.info(`Uploaded recording ${rec.id} to S3 bucket ${s3Bucket} key ${s3ObjectKey}`);
          }
        } catch (s3Err) {
          logger.error({ s3Err }, `Failed to upload recording ${rec.id} to S3`);
        }
      }

      await dbPool.query(
        `UPDATE public.cctv_recordings
         SET status = 'COMPLETED', recording_status = 'COMPLETED',
             actual_stop_time = CURRENT_TIMESTAMP,
             playback_status = $1
         WHERE id = $2;`,
        [uploadSuccess ? 'READY' : 'PROCESSING', rec.id]
      );

      await dbPool.query(
        `INSERT INTO public.game_videos (game_id, club_id, court_id, cctv_id, title, video_url, status)
         VALUES ($1, $2, $3, $4, $5, $6, 'AVAILABLE')
         ON CONFLICT DO NOTHING;`,
        [
          rec.game_id,
          rec.club_id,
          rec.court_id,
          rec.camera_id || null,
          `Match Recording - Game ${rec.game_id}`,
          s3ObjectKey,
        ]
      );

      await dbPool.query(
        `INSERT INTO public.cctv_recording_events (recording_id, event_type, metadata)
         VALUES ($1, 'RECORDING_COMPLETED', $2);`,
        [rec.id, JSON.stringify({ uploadSuccess, s3ObjectKey })]
      );
    }
  } catch (err) {
    logger.error({ err }, 'Error in media worker expired recordings processor');
  }
};

setInterval(processPendingRecordings, 5000);
setInterval(processExpiredRecordings, 10000);
