import net from 'net';
import { CctvRepository } from './cctv.repository.js';
import { encryptSecret, decryptSecret } from '../../utils/crypto.utils.js';
import { getSignedPlaybackUrl } from '../../services/storage.service.js';
import { ApiError } from '../../utils/apiResponse.js';
import { logger } from '../../utils/logger.js';
import { dbPool } from '../../config/db.config.js';

// Map of active recording stop timers
const activeRecordingTimers = new Map<string, NodeJS.Timeout>();

export class CctvService {
  /**
   * Add CCTV Camera with encrypted RTSP credentials
   */
  static async addCamera(
    managerId: string,
    managerName: string,
    data: {
      clubId: string;
      courtId?: string;
      name: string;
      rtspUrl: string;
      ipAddress?: string;
      port?: number;
    }
  ) {
    const encryptedRtsp = encryptSecret(data.rtspUrl);

    const camera = await CctvRepository.createCamera({
      clubId: data.clubId,
      courtId: data.courtId,
      name: data.name,
      rtspUrlEncrypted: encryptedRtsp,
      ipAddress: data.ipAddress,
      port: data.port,
    });

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'ADD_CCTV_CAMERA',
      target: `Camera:${camera.id}`,
      details: `Added CCTV Camera '${data.name}' for Club '${data.clubId}'`,
    });

    return {
      id: camera.id,
      clubId: camera.club_id,
      courtId: camera.court_id,
      name: camera.name,
      ipAddress: camera.ip_address,
      port: camera.port,
      isEnabled: camera.is_enabled,
      status: camera.status,
    };
  }

  /**
   * Edit CCTV Camera
   */
  static async editCamera(
    managerId: string,
    managerName: string,
    cameraId: string,
    data: {
      name?: string;
      courtId?: string;
      rtspUrl?: string;
      ipAddress?: string;
      port?: number;
      isEnabled?: boolean;
    }
  ) {
    const camera = await CctvRepository.getCameraById(cameraId);
    if (!camera) {
      throw new ApiError(404, 'CCTV Camera not found', 'CAMERA_NOT_FOUND');
    }

    const encryptedRtsp = data.rtspUrl ? encryptSecret(data.rtspUrl) : undefined;

    const updated = await CctvRepository.updateCamera(cameraId, {
      name: data.name,
      courtId: data.courtId,
      rtspUrlEncrypted: encryptedRtsp,
      ipAddress: data.ipAddress,
      port: data.port,
      isEnabled: data.isEnabled,
    });

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'UPDATE_CCTV_CAMERA',
      target: `Camera:${cameraId}`,
      details: `Updated CCTV Camera '${updated.name}'`,
    });

    return {
      id: updated.id,
      clubId: updated.club_id,
      courtId: updated.court_id,
      name: updated.name,
      ipAddress: updated.ip_address,
      port: updated.port,
      isEnabled: updated.is_enabled,
      status: updated.status,
    };
  }

  /**
   * Test Camera RTSP Connection
   */
  static async testCameraConnection(cameraId: string) {
    const camera = await CctvRepository.getCameraById(cameraId);
    if (!camera) {
      throw new ApiError(404, 'CCTV Camera not found', 'CAMERA_NOT_FOUND');
    }

    const decryptedRtsp = decryptSecret(camera.rtsp_url_encrypted);
    const host = camera.ip_address || new URL(decryptedRtsp).hostname || 'localhost';
    const port = camera.port || 554;

    return new Promise((resolve) => {
      const socket = new net.Socket();
      socket.setTimeout(4000);

      socket.on('connect', async () => {
        socket.destroy();
        await CctvRepository.updateCamera(cameraId, {
          status: 'ONLINE',
        });
        resolve({
          cameraId,
          status: 'ONLINE',
          message: 'Camera stream connection successful',
        });
      });

      socket.on('error', async (err) => {
        socket.destroy();
        await CctvRepository.updateCamera(cameraId, {
          status: 'OFFLINE',
        });
        resolve({
          cameraId,
          status: 'OFFLINE',
          message: `Camera connection failed: ${err.message}`,
        });
      });

      socket.on('timeout', async () => {
        socket.destroy();
        await CctvRepository.updateCamera(cameraId, {
          status: 'OFFLINE',
        });
        resolve({
          cameraId,
          status: 'OFFLINE',
          message: 'Camera connection timed out',
        });
      });

      socket.connect(port, host);
    });
  }

  /**
   * Get Cameras by Club
   */
  static async getClubCameras(clubId: string) {
    const cameras = await CctvRepository.getCamerasByClub(clubId);
    return cameras.map((cam) => ({
      id: cam.id,
      clubId: cam.club_id,
      courtId: cam.court_id,
      courtName: cam.court_name,
      name: cam.name,
      ipAddress: cam.ip_address,
      port: cam.port,
      isEnabled: cam.is_enabled,
      status: cam.status,
      createdAt: cam.created_at,
    }));
  }

  /**
   * Start Match Recording
   */
  static async startMatchRecording(
    managerId: string,
    managerName: string,
    gameId: string,
    cameraId: string
  ) {
    // Verify Game
    const gameRes = await dbPool.query('SELECT * FROM public.games WHERE id = $1;', [
      gameId,
    ]);
    if (gameRes.rows.length === 0) {
      throw new ApiError(404, 'Match game not found', 'MATCH_NOT_FOUND');
    }
    const game = gameRes.rows[0];

    // Verify Camera
    const camera = await CctvRepository.getCameraById(cameraId);
    if (!camera || !camera.is_enabled) {
      throw new ApiError(400, 'CCTV Camera is disabled or not found', 'CAMERA_DISABLED');
    }

    // Check if recording already exists for this game
    const existingRec = await CctvRepository.getRecordingByGame(gameId);
    if (existingRec && existingRec.status === 'RECORDING') {
      return existingRec;
    }

    // Calculate match scheduled end and deadline (scheduled end + 15 minutes)
    const now = new Date();
    const matchEndTime = new Date(now.getTime() + 90 * 60 * 1000); // Default 90 mins match
    const stopDeadline = new Date(matchEndTime.getTime() + 15 * 60 * 1000); // scheduled + 15m

    const s3ObjectKey = `recordings/${game.club_id}/${gameId}_${Date.now()}.mp4`;

    const recording = await CctvRepository.createRecording({
      gameId,
      clubId: game.club_id,
      courtId: game.court_id,
      cameraId,
      scheduledMatchEnd: matchEndTime,
      stopDeadline,
      s3ObjectKey,
    });

    // Schedule automatic stop at stopDeadline (scheduled match end + 15 minutes)
    const delayMs = stopDeadline.getTime() - Date.now();
    const timer = setTimeout(() => {
      this.autoStopRecording(recording.id, 'SCHEDULED_DEADLINE_EXPIRED');
    }, Math.max(delayMs, 1000));

    activeRecordingTimers.set(recording.id, timer);

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'START_CCTV_RECORDING',
      target: `Recording:${recording.id}`,
      details: `Started CCTV Recording for Game '${gameId}' with deadline '${stopDeadline.toISOString()}'`,
    });

    return {
      recordingId: recording.id,
      gameId: recording.game_id,
      cameraId: recording.camera_id,
      status: recording.status,
      startTime: recording.start_time,
      scheduledMatchEnd: recording.scheduled_match_end,
      stopDeadline: recording.stop_deadline,
    };
  }

  /**
   * Stop Match Recording Manually or Automatically
   */
  static async stopMatchRecording(
    managerId: string,
    managerName: string,
    recordingId: string
  ) {
    const recording = await CctvRepository.getRecordingById(recordingId);
    if (!recording) {
      throw new ApiError(404, 'CCTV Recording not found', 'RECORDING_NOT_FOUND');
    }

    if (recording.status === 'COMPLETED' || recording.status === 'STOPPED') {
      return recording;
    }

    // Clear auto-stop timer if manual stop triggered
    if (activeRecordingTimers.has(recordingId)) {
      clearTimeout(activeRecordingTimers.get(recordingId));
      activeRecordingTimers.delete(recordingId);
    }

    const updated = await CctvRepository.updateRecordingStatus(
      recordingId,
      'COMPLETED',
      new Date()
    );

    // Save video metadata in game_videos
    await CctvRepository.saveGameVideoMetadata({
      gameId: recording.game_id,
      clubId: recording.club_id,
      courtId: recording.court_id,
      title: `Match Recording - Game ${recording.game_id}`,
      s3ObjectKey: recording.s3_object_key,
      uploadedById: managerId,
    });

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'STOP_CCTV_RECORDING',
      target: `Recording:${recordingId}`,
      details: `Stopped CCTV Recording for Game '${recording.game_id}'`,
    });

    return updated;
  }

  /**
   * Automatic Stop Callback
   */
  static async autoStopRecording(recordingId: string, reason: string) {
    try {
      logger.info(`Auto-stopping CCTV Recording ${recordingId}. Reason: ${reason}`);
      await this.stopMatchRecording('SYSTEM_WORKER', 'Auto Worker', recordingId);
    } catch (err) {
      logger.error({ err }, `Error auto-stopping recording ${recordingId}`);
    }
  }

  /**
   * Extend Recording Deadline (Up to 60 minutes)
   */
  static async extendRecording(
    managerId: string,
    managerName: string,
    recordingId: string,
    additionalMinutes: number
  ) {
    const recording = await CctvRepository.getRecordingById(recordingId);
    if (!recording || recording.status !== 'RECORDING') {
      throw new ApiError(
        400,
        'Active recording not found to extend',
        'INVALID_RECORDING_STATE'
      );
    }

    const currentDeadline = new Date(recording.stop_deadline);
    const newStopDeadline = new Date(
      currentDeadline.getTime() + additionalMinutes * 60 * 1000
    );

    const updated = await CctvRepository.extendRecordingDeadline(
      recordingId,
      newStopDeadline
    );

    // Reschedule timer
    if (activeRecordingTimers.has(recordingId)) {
      clearTimeout(activeRecordingTimers.get(recordingId));
    }

    const delayMs = newStopDeadline.getTime() - Date.now();
    const timer = setTimeout(() => {
      this.autoStopRecording(recordingId, 'EXTENDED_DEADLINE_EXPIRED');
    }, Math.max(delayMs, 1000));

    activeRecordingTimers.set(recordingId, timer);

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'EXTEND_CCTV_RECORDING',
      target: `Recording:${recordingId}`,
      details: `Extended recording by ${additionalMinutes} minutes. New deadline: '${newStopDeadline.toISOString()}'`,
    });

    return updated;
  }

  /**
   * Get Short-Lived Signed Playback URL for Match Video
   */
  static async getMatchVideoPlaybackUrl(gameId: string) {
    const videoRes = await dbPool.query(
      `SELECT * FROM public.game_videos WHERE game_id = $1 ORDER BY created_at DESC LIMIT 1;`,
      [gameId]
    );

    if (videoRes.rows.length === 0) {
      throw new ApiError(404, 'No recorded video available for this match', 'VIDEO_NOT_FOUND');
    }

    const video = videoRes.rows[0];
    const signedUrl = await getSignedPlaybackUrl(video.video_url, 3600); // 1 hour signed URL

    return {
      gameId,
      title: video.title,
      playbackUrl: signedUrl,
      expiresInSeconds: 3600,
    };
  }
}
