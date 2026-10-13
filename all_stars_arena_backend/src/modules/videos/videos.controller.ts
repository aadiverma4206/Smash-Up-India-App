import { Response } from 'express';
import { dbPool } from '../../config/db.config.js';
import { getSignedPlaybackUrl } from '../../services/storage.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getVideoMetadata = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: videoId } = req.params;
  const userId = req.user?.id;
  const userRole = req.user?.roleId || 3;

  const videoRes = await dbPool.query(
    `SELECT gv.*, cam.name as camera_name, cam.camera_type
     FROM public.game_videos gv
     LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
     WHERE gv.id = $1;`,
    [videoId]
  );

  if (videoRes.rows.length === 0) {
    throw new ApiError(404, 'Video recording not found', 'VIDEO_NOT_FOUND');
  }

  const video = videoRes.rows[0];

  // Authorization check
  if (userRole === 3 && userId) {
    const isParticipant = await dbPool.query(
      'SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;',
      [video.game_id, userId]
    );
    if (isParticipant.rows.length === 0) {
      throw new ApiError(
        403,
        'Forbidden: Only match participants can access video recordings',
        'FORBIDDEN_RECORDING_ACCESS'
      );
    }
  } else if (userRole === 2 && userId) {
    const isClubMgr = await dbPool.query(
      'SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;',
      [video.club_id, userId]
    );
    if (isClubMgr.rows.length === 0) {
      throw new ApiError(
        403,
        'Forbidden: You do not manage the club hosting this video',
        'FORBIDDEN_CLUB_SCOPE'
      );
    }
  }

  res.status(200).json(ApiResponse.success('Video metadata retrieved', video));
});

export const getVideoPlaybackUrl = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: videoId } = req.params;
  const userId = req.user?.id;
  const userRole = req.user?.roleId || 3;

  const videoRes = await dbPool.query(
    `SELECT gv.*, cam.name as camera_name, cam.camera_type
     FROM public.game_videos gv
     LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
     WHERE gv.id = $1;`,
    [videoId]
  );

  if (videoRes.rows.length === 0) {
    throw new ApiError(404, 'Video recording not found', 'VIDEO_NOT_FOUND');
  }

  const video = videoRes.rows[0];

  // Authorization check
  if (userRole === 3 && userId) {
    const isParticipant = await dbPool.query(
      'SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;',
      [video.game_id, userId]
    );
    if (isParticipant.rows.length === 0) {
      throw new ApiError(
        403,
        'Forbidden: Only match participants can access video recordings',
        'FORBIDDEN_RECORDING_ACCESS'
      );
    }
  } else if (userRole === 2 && userId) {
    const isClubMgr = await dbPool.query(
      'SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;',
      [video.club_id, userId]
    );
    if (isClubMgr.rows.length === 0) {
      throw new ApiError(
        403,
        'Forbidden: You do not manage the club hosting this video',
        'FORBIDDEN_CLUB_SCOPE'
      );
    }
  }

  if (video.status !== 'AVAILABLE') {
    throw new ApiError(
      400,
      'Recording is currently being processed or unavailable',
      'RECORDING_PROCESSING'
    );
  }

  const playbackUrl = await getSignedPlaybackUrl(video.video_url, 3600); // 1-hour pre-signed URL

  res.status(200).json(
    ApiResponse.success('Signed playback URL generated', {
      videoId: video.id,
      gameId: video.game_id,
      title: video.title,
      playbackUrl,
      expiresInSeconds: 3600,
    })
  );
});
