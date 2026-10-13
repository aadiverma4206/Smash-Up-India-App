import { CctvRepository } from './cctv.repository.js';
import { CctvRecordingService } from '../../services/cctvRecording.service.js';
import { encryptSecret, decryptSecret, redactRtspUrl } from '../../utils/crypto.utils.js';
import { getSignedPlaybackUrl } from '../../services/storage.service.js';
import { ApiError } from '../../utils/apiResponse.js';
import { logger } from '../../utils/logger.js';
import { dbPool } from '../../config/db.config.js';
import { env, getDefaultRtspUrl } from '../../config/env.config.js';

function formatRecordingResponse(rec: any) {
  if (!rec) return null;
  const startedAt = rec.started_at || rec.start_time || new Date();
  const scheduledEnd = rec.scheduled_match_end || new Date();
  const stopDeadline = rec.stop_deadline || new Date();
  const actualStopTime = rec.actual_stop_time;
  return {
    ...rec,
    id: rec.id,
    recordingId: rec.id,
    gameId: rec.game_id,
    clubId: rec.club_id,
    courtId: rec.court_id || null,
    cameraId: rec.camera_id || null,
    status: rec.status,
    recordingStatus: rec.recording_status || rec.status,
    startedAt: startedAt instanceof Date ? startedAt.toISOString() : String(startedAt),
    startTime: startedAt instanceof Date ? startedAt.toISOString() : String(startedAt),
    scheduledMatchEnd: scheduledEnd instanceof Date ? scheduledEnd.toISOString() : String(scheduledEnd),
    stopDeadline: stopDeadline instanceof Date ? stopDeadline.toISOString() : String(stopDeadline),
    actualStopTime: actualStopTime
      ? (actualStopTime instanceof Date ? actualStopTime.toISOString() : String(actualStopTime))
      : null,
    manualStop: Boolean(rec.manual_stop),
  };
}

export class CctvService {
  /**
   * Add CCTV Camera with AES-256-GCM encrypted RTSP credentials
   */
  static async addCamera(
    managerId: string,
    managerName: string,
    userRole: number,
    data: {
      clubId: string;
      courtId?: string;
      name: string;
      rtspUrl: string;
      ipAddress?: string;
      port?: number;
      serialNumber?: string;
      protocol?: string;
    }
  ) {
    if (userRole === 2) {
      const isAuthorized = await CctvRepository.isClubManager(data.clubId, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not have management access to this club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    if (data.courtId) {
      const validCourt = await CctvRepository.isCourtInClub(data.courtId, data.clubId);
      if (!validCourt) {
        throw new ApiError(400, 'Invalid court: Selected court does not belong to this club', 'INVALID_COURT');
      }
    }

    const encryptedRtsp = encryptSecret(data.rtspUrl);

    const camera = await CctvRepository.createCamera({
      clubId: data.clubId,
      courtId: data.courtId,
      name: data.name,
      rtspUrlEncrypted: encryptedRtsp,
      ipAddress: data.ipAddress,
      port: data.port || 554,
      serialNumber: data.serialNumber,
      protocol: data.protocol || 'rtsp',
      createdBy: managerId,
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
      protocol: camera.protocol || 'rtsp',
      serialNumber: camera.serial_number,
      isEnabled: camera.is_enabled,
      status: camera.status,
      healthStatus: camera.health_status,
      createdAt: camera.created_at,
    };
  }

  /**
   * Edit CCTV Camera metadata and configuration
   */
  static async editCamera(
    managerId: string,
    managerName: string,
    userRole: number,
    cameraId: string,
    data: {
      name?: string;
      courtId?: string;
      rtspUrl?: string;
      ipAddress?: string;
      port?: number;
      serialNumber?: string;
      protocol?: string;
      isEnabled?: boolean;
    }
  ) {
    const camera = await CctvRepository.getCameraById(cameraId);
    if (!camera) {
      throw new ApiError(404, 'CCTV Camera not found', 'CAMERA_NOT_FOUND');
    }

    if (userRole === 2) {
      const isAuthorized = await CctvRepository.isClubManager(camera.club_id, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not have management access to this camera', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    if (data.courtId) {
      const validCourt = await CctvRepository.isCourtInClub(data.courtId, camera.club_id);
      if (!validCourt) {
        throw new ApiError(400, 'Invalid court: Court does not belong to this camera club', 'INVALID_COURT');
      }
    }

    const encryptedRtsp = data.rtspUrl ? encryptSecret(data.rtspUrl) : undefined;

    const updated = await CctvRepository.updateCamera(cameraId, {
      name: data.name,
      courtId: data.courtId,
      rtspUrlEncrypted: encryptedRtsp,
      ipAddress: data.ipAddress,
      port: data.port,
      serialNumber: data.serialNumber,
      protocol: data.protocol,
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
      protocol: updated.protocol || 'rtsp',
      serialNumber: updated.serial_number,
      isEnabled: updated.is_enabled,
      status: updated.status,
      healthStatus: updated.health_status,
      updatedAt: updated.updated_at,
    };
  }

  /**
   * Toggle Camera active/disabled state
   */
  static async toggleCamera(
    managerId: string,
    managerName: string,
    userRole: number,
    cameraId: string,
    isEnabled: boolean
  ) {
    const camera = await CctvRepository.getCameraById(cameraId);
    if (!camera) {
      throw new ApiError(404, 'CCTV Camera not found', 'CAMERA_NOT_FOUND');
    }

    if (userRole === 2) {
      const isAuthorized = await CctvRepository.isClubManager(camera.club_id, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not manage this club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    const updated = await CctvRepository.updateCamera(cameraId, {
      isEnabled,
    });

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: isEnabled ? 'ENABLE_CCTV_CAMERA' : 'DISABLE_CCTV_CAMERA',
      target: `Camera:${cameraId}`,
      details: `${isEnabled ? 'Enabled' : 'Disabled'} CCTV Camera '${camera.name}'`,
    });

    return {
      id: updated.id,
      isEnabled: updated.is_enabled,
      status: updated.status,
    };
  }

  /**
   * Real connection test to camera via network socket probe
   */
  static async testCameraConnection(cameraId: string, managerId?: string, userRole?: number) {
    const camera = await CctvRepository.getCameraById(cameraId);
    if (!camera) {
      throw new ApiError(404, 'CCTV Camera not found', 'CAMERA_NOT_FOUND');
    }

    if (userRole === 2 && managerId) {
      const isAuthorized = await CctvRepository.isClubManager(camera.club_id, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not manage this camera club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    const result = await CctvRecordingService.testCameraConnection(camera);

    return {
      cameraId,
      name: camera.name,
      status: result.status,
      message: result.message,
      latencyMs: result.latencyMs,
    };
  }

  /**
   * Get Cameras by Club
   */
  static async getClubCameras(clubId: string, managerId?: string, userRole?: number) {
    if (userRole === 2 && managerId) {
      const isAuthorized = await CctvRepository.isClubManager(clubId, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not have access to view cameras for this club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    const cameras = await CctvRepository.getCamerasByClub(clubId);
    return cameras.map((cam: any) => ({
      id: cam.id,
      clubId: cam.club_id,
      courtId: cam.court_id,
      courtName: cam.court_name,
      name: cam.name,
      cameraType: cam.camera_type || 'RTSP_DOME',
      connectionType: cam.connection_type || 'RTSP',
      ipAddress: cam.ip_address,
      port: cam.port || 554,
      isEnabled: cam.is_enabled,
      status: cam.status || 'ONLINE',
      healthStatus: cam.health_status || cam.status || 'ONLINE',
      lastSeenAt: cam.last_seen_at ? (cam.last_seen_at instanceof Date ? cam.last_seen_at.toISOString() : String(cam.last_seen_at)) : null,
      ...cam,
    }));
  }

  /**
   * Start Match Recording
   */
  static async startMatchRecording(
    managerId: string,
    managerName: string,
    userRoleOrGameId: number | string,
    gameIdOrCameraId?: string,
    cameraIdParam?: string
  ) {
    let userRole = 2;
    let gameId = '';
    let cameraId: string | undefined = cameraIdParam;

    if (typeof userRoleOrGameId === 'number') {
      userRole = userRoleOrGameId;
      gameId = gameIdOrCameraId || '';
    } else {
      userRole = 2;
      gameId = userRoleOrGameId;
      cameraId = gameIdOrCameraId;
    }

    const gameRes = await dbPool.query('SELECT * FROM public.games WHERE id = $1;', [gameId]);
    if (gameRes.rows.length === 0) {
      throw new ApiError(404, 'Match game not found', 'MATCH_NOT_FOUND');
    }
    const game = gameRes.rows[0];

    if (userRole === 2) {
      const isAuthorized = await CctvRepository.isClubManager(game.club_id, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not manage the club hosting this match', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    if (game.approval_status && game.approval_status !== 'APPROVED') {
      throw new ApiError(400, 'Cannot record a match that is not approved by manager', 'MATCH_NOT_APPROVED');
    }

    let camera: any = null;
    if (cameraId) {
      camera = await CctvRepository.getCameraById(cameraId);
    } else {
      camera = await CctvRepository.getActiveCameraForCourt(game.court_id, game.club_id);
    }

    if (!camera || !camera.is_enabled) {
      throw new ApiError(400, 'CCTV Camera is disabled or not found for this court/club', 'CAMERA_DISABLED');
    }

    if (camera.club_id !== game.club_id) {
      throw new ApiError(400, 'Camera does not belong to the club hosting this match', 'INVALID_CAMERA_CLUB');
    }

    const existingRec = await CctvRepository.getRecordingByGame(gameId);
    if (existingRec && (existingRec.status === 'RECORDING' || existingRec.recording_status === 'RECORDING')) {
      return existingRec;
    }

    const now = new Date();
    const postMatchMins = env.RECORDING_POST_MATCH_MINUTES || 15;
    let matchEndMs = now.getTime() + 90 * 60 * 1000;
    if (game.end_time) {
      let datePart = '';
      if (game.match_date instanceof Date) {
        const year = game.match_date.getFullYear();
        const month = String(game.match_date.getMonth() + 1).padStart(2, '0');
        const day = String(game.match_date.getDate()).padStart(2, '0');
        datePart = `${year}-${month}-${day}`;
      } else {
        datePart = String(game.match_date).slice(0, 10);
      }
      const timeStr = String(game.end_time).length === 5 ? `${game.end_time}:00` : String(game.end_time);
      const parsed = new Date(`${datePart}T${timeStr}`).getTime();
      if (!isNaN(parsed)) {
        matchEndMs = parsed;
      }
    }

    const scheduledMatchEnd = new Date(Math.max(matchEndMs, now.getTime() + 60 * 60 * 1000));
    const stopDeadline = new Date(scheduledMatchEnd.getTime() + postMatchMins * 60 * 1000);

    const s3ObjectKey = `recordings/${game.club_id}/${gameId}_${Date.now()}.mp4`;

    const recording = await CctvRepository.createRecording({
      gameId,
      clubId: game.club_id,
      courtId: game.court_id,
      cameraId: camera.id,
      scheduledMatchEnd,
      stopDeadline,
      s3ObjectKey,
    });

    await CctvRecordingService.startRecording({
      recordingId: recording.id,
      gameId,
      clubId: game.club_id,
      courtId: game.court_id,
      camera,
      scheduledStopAt: stopDeadline,
    });

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'START_CCTV_RECORDING',
      target: `Recording:${recording.id}`,
      details: `Started CCTV Recording for Game '${gameId}' with deadline '${stopDeadline.toISOString()}'`,
    });

    return formatRecordingResponse(recording);
  }

  /**
   * Stop Match Recording
   */
  static async stopMatchRecording(
    managerId: string,
    managerName: string,
    userRoleOrRecordingId: number | string,
    recordingIdOrReason?: string,
    reasonParam?: string
  ) {
    let userRole = 2;
    let recordingId = '';
    let reason = 'Manual stop requested by manager';

    if (typeof userRoleOrRecordingId === 'number') {
      userRole = userRoleOrRecordingId;
      recordingId = recordingIdOrReason || '';
      reason = reasonParam || reason;
    } else {
      userRole = 2;
      recordingId = userRoleOrRecordingId;
      reason = recordingIdOrReason || reason;
    }

    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden: Players cannot stop match recordings', 'FORBIDDEN_STOP_AUTHORITY');
    }

    const recording = await CctvRepository.getRecordingById(recordingId);
    if (!recording) {
      throw new ApiError(404, 'CCTV Recording not found', 'RECORDING_NOT_FOUND');
    }

    if (userRole === 2) {
      const isAuthorized = await CctvRepository.isClubManager(recording.club_id, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not manage the club hosting this recording', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    if (recording.status === 'COMPLETED' || recording.status === 'STOPPED') {
      return recording;
    }

    const updated = await CctvRecordingService.stopRecording(recordingId, {
      userId: managerId,
      reason,
      manualStop: true,
    });

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'STOP_CCTV_RECORDING',
      target: `Recording:${recordingId}`,
      details: `Manually stopped CCTV Recording for Game '${recording.game_id}'. Reason: ${reason}`,
    });

    return updated;
  }

  /**
   * Extend Recording Deadline
   */
  static async extendRecording(
    managerId: string,
    managerName: string,
    userRoleOrRecordingId: number | string,
    recordingIdOrMinutes: string | number,
    additionalMinutesParam?: number
  ) {
    let userRole = 2;
    let recordingId = '';
    let additionalMinutes = 15;

    if (typeof userRoleOrRecordingId === 'number') {
      userRole = userRoleOrRecordingId;
      recordingId = recordingIdOrMinutes as string;
      additionalMinutes = Number(additionalMinutesParam || 15);
    } else {
      userRole = 2;
      recordingId = userRoleOrRecordingId;
      additionalMinutes = Number(recordingIdOrMinutes || 15);
    }

    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden: Players cannot extend match recordings', 'FORBIDDEN_EXTEND_AUTHORITY');
    }

    const recording = await CctvRepository.getRecordingById(recordingId);
    if (!recording || (recording.status !== 'RECORDING' && recording.recording_status !== 'RECORDING')) {
      throw new ApiError(400, 'Active recording not found to extend', 'INVALID_RECORDING_STATE');
    }

    if (userRole === 2) {
      const isAuthorized = await CctvRepository.isClubManager(recording.club_id, managerId);
      if (!isAuthorized) {
        throw new ApiError(403, 'Forbidden: You do not manage this match club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    const updated = await CctvRecordingService.extendRecording(
      recordingId,
      additionalMinutes,
      managerId
    );

    await CctvRepository.logAudit({
      adminId: managerId,
      adminName: managerName,
      action: 'EXTEND_CCTV_RECORDING',
      target: `Recording:${recordingId}`,
      details: `Extended recording by ${additionalMinutes} minutes. New deadline: '${updated.stop_deadline}'`,
    });

    return updated;
  }

  /**
   * Get recording session status for a game
   */
  static async getGameRecording(gameId: string, userId: string, userRole: number) {
    const gameRes = await dbPool.query('SELECT * FROM public.games WHERE id = $1;', [gameId]);
    if (gameRes.rows.length === 0) {
      throw new ApiError(404, 'Match not found', 'MATCH_NOT_FOUND');
    }
    const game = gameRes.rows[0];

    if (userRole === 3) {
      const isPlayer = await dbPool.query(
        'SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;',
        [gameId, userId]
      );
      if (isPlayer.rows.length === 0) {
        throw new ApiError(403, 'Forbidden: You are not a participant in this match', 'FORBIDDEN_RECORDING_ACCESS');
      }
    } else if (userRole === 2) {
      const isManager = await CctvRepository.isClubManager(game.club_id, userId);
      if (!isManager) {
        throw new ApiError(403, 'Forbidden: You do not manage this club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    const recording = await CctvRepository.getRecordingByGame(gameId);
    return recording ? formatRecordingResponse(recording) : { status: 'NO_RECORDING', gameId };
  }

  /**
   * Get Short-Lived Signed Playback URL for Match Video
   */
  static async getMatchVideoPlaybackUrl(gameId: string, userId?: string, userRole = 3, cctvId?: string) {
    const gameRes = await dbPool.query('SELECT * FROM public.games WHERE id = $1;', [gameId]);
    if (gameRes.rows.length === 0) {
      throw new ApiError(404, 'Match not found', 'MATCH_NOT_FOUND');
    }
    const game = gameRes.rows[0];

    if (userRole === 3 && userId) {
      const isParticipant = await dbPool.query(
        'SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;',
        [gameId, userId]
      );
      if (isParticipant.rows.length === 0) {
        throw new ApiError(403, 'Forbidden: Only match participants can access video recordings', 'FORBIDDEN_RECORDING_ACCESS');
      }
    } else if (userRole === 2 && userId) {
      const isManager = await CctvRepository.isClubManager(game.club_id, userId);
      if (!isManager) {
        throw new ApiError(403, 'Forbidden: You do not manage this match club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    let query = `
      SELECT gv.*, cam.name as camera_name
      FROM public.game_videos gv
      LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
      WHERE gv.game_id = $1 AND gv.status = 'AVAILABLE'
    `;
    const params: any[] = [gameId];
    if (cctvId) {
      query += ` AND gv.cctv_id = $2 ORDER BY gv.created_at DESC LIMIT 1;`;
      params.push(cctvId);
    } else {
      query += ` ORDER BY gv.created_at ASC LIMIT 1;`;
    }

    let videoRes = await dbPool.query(query, params);

    if (videoRes.rows.length === 0 && cctvId) {
      videoRes = await dbPool.query(
        `SELECT gv.*, cam.name as camera_name
         FROM public.game_videos gv
         LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
         WHERE gv.game_id = $1 AND gv.status = 'AVAILABLE'
         ORDER BY gv.created_at ASC LIMIT 1;`,
        [gameId]
      );
    }

    if (videoRes.rows.length === 0) {
      throw new ApiError(404, 'No recorded video available for this match', 'VIDEO_NOT_FOUND');
    }

    const video = videoRes.rows[0];
    const signedUrl = await getSignedPlaybackUrl(video.video_url, 3600);

    return {
      gameId,
      videoId: video.id,
      cctvId: video.cctv_id || null,
      cameraName: video.camera_name || 'Camera 1',
      title: video.title,
      status: video.status,
      playbackUrl: signedUrl,
      expiresInSeconds: 3600,
    };
  }

  /**
   * Get failures for monitoring
   */
  static async getRecordingFailures(userId: string, userRole: number, clubId?: string) {
    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden', 'FORBIDDEN_ROLE');
    }

    if (userRole === 2 && clubId) {
      const isManager = await CctvRepository.isClubManager(clubId, userId);
      if (!isManager) {
        throw new ApiError(403, 'Forbidden: You do not manage this club', 'FORBIDDEN_CLUB_SCOPE');
      }
    }

    return await CctvRepository.getRecordingFailures(clubId);
  }

  /**
   * Get Dynamic Live CCTV Camera Options from DB Credentials & Host Configuration
   */
  static async getLiveCameras(userId: string, userRole: number) {
    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden: Live CCTV is only accessible to Managers and Admins', 'FORBIDDEN_LIVE_CCTV_ROLE');
    }

    const host = env.CAMERA_HOST || '192.168.1.2';
    const port = env.CAMERA_RTSP_PORT || 554;

    const testResult = await CctvRecordingService.testCameraConnection({
      id: 'dahua_dvr_host',
      ip_address: host,
      port,
      rtsp_url_encrypted: '',
    });

    const isHostOnline = testResult.status === 'ONLINE';

    // 4 Dynamic Dahua Channels corresponding to XVR Channel 1, 2, 3, 4
    const channelConfigs = [
      { channel: 1, name: 'Camera 1 (Court 1 - Main)', courtName: 'Court 1' },
      { channel: 2, name: 'Camera 2 (Court 1 - Sideline)', courtName: 'Court 1' },
      { channel: 3, name: 'Camera 3 (Court 2 - Main)', courtName: 'Court 2' },
      { channel: 4, name: 'Camera 4 (Court 2 - Goalpost)', courtName: 'Court 2' },
    ];

    return channelConfigs.map((c) => ({
      id: `live_cam_channel_${c.channel}`,
      channel: c.channel,
      name: c.name,
      courtName: c.courtName,
      status: isHostOnline ? 'ONLINE' : 'OFFLINE',
      healthStatus: isHostOnline ? 'ONLINE' : 'OFFLINE',
      ipAddress: host,
      port,
      protocol: 'rtsp',
      supportedSubtypes: ['main', 'sub'],
    }));
  }

  /**
   * Request Authorized Direct RTSP Live Stream Session (Zero FFmpeg Dependency)
   */
  static async createLiveSession(
    userId: string,
    userRole: number,
    channel: number,
    streamType: 'main' | 'sub' = 'main'
  ) {
    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden: Live CCTV is only accessible to Managers and Admins', 'FORBIDDEN_LIVE_CCTV_ROLE');
    }

    if (channel < 1 || channel > 16) {
      throw new ApiError(400, 'Invalid channel. Camera channel must be between 1 and 16', 'INVALID_CAMERA_CHANNEL');
    }

    const subtype = streamType === 'sub' ? 1 : 0;
    const rtspUrl = getDefaultRtspUrl(channel, subtype);

    if (!rtspUrl) {
      throw new ApiError(500, 'CCTV RTSP configuration is missing on server', 'RTSP_CONFIG_MISSING');
    }

    const host = env.CAMERA_HOST || '192.168.1.2';
    const port = env.CAMERA_RTSP_PORT || 554;

    const connTest = await CctvRecordingService.testCameraConnection({
      id: `dahua_ch_${channel}`,
      ip_address: host,
      port,
      rtsp_url_encrypted: '',
    });

    const sessionId = `live_sess_${channel}_${Date.now()}`;
    const expiresAt = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString();

    const cameraNameMap: Record<number, string> = {
      1: 'Camera 1 (Court 1 - Main)',
      2: 'Camera 2 (Court 1 - Sideline)',
      3: 'Camera 3 (Court 2 - Main)',
      4: 'Camera 4 (Court 2 - Goalpost)',
    };

    const cameraName = cameraNameMap[channel] || `Camera ${channel}`;

    await CctvRepository.logAudit({
      adminId: userId,
      adminName: `User:${userId}`,
      action: 'LIVE_CCTV_SESSION_CREATED',
      target: `Channel:${channel}`,
      details: `Created Direct RTSP Live Stream Session '${sessionId}' for Channel ${channel} (${streamType} stream)`,
    });

    return {
      sessionId,
      channel,
      cameraName,
      streamType,
      status: connTest.status,
      latencyMs: connTest.latencyMs || 0,
      rtspUrl,
      playbackUrl: rtspUrl,
      hlsUrl: rtspUrl,
      expiresAt,
    };
  }

  /**
   * Probe Live Camera Channel Status
   */
  static async getLiveChannelStatus(channel: number, userId: string, userRole: number) {
    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden', 'FORBIDDEN_ROLE');
    }

    const host = env.CAMERA_HOST || '192.168.1.2';
    const port = env.CAMERA_RTSP_PORT || 554;

    const testResult = await CctvRecordingService.testCameraConnection({
      id: `dahua_ch_${channel}`,
      ip_address: host,
      port,
      rtsp_url_encrypted: '',
    });

    return {
      channel,
      status: testResult.status,
      message: testResult.message,
      latencyMs: testResult.latencyMs || 0,
    };
  }

  /**
   * Release Live CCTV Stream Session
   */
  static async releaseLiveSession(sessionId: string, userId: string, userRole: number) {
    if (userRole === 3) {
      throw new ApiError(403, 'Forbidden', 'FORBIDDEN_ROLE');
    }

    await CctvRepository.logAudit({
      adminId: userId,
      adminName: `User:${userId}`,
      action: 'LIVE_CCTV_SESSION_RELEASED',
      target: `Session:${sessionId}`,
      details: `Released Live Stream Session '${sessionId}'`,
    });

    return { sessionId, released: true };
  }
}
