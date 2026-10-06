import { Response } from 'express';
import { dbPool } from '../../config/db.config.js';
import { getSignedPlaybackUrl } from '../../services/storage.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getVideoMetadata = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: videoId } = req.params;
  const videoRes = await dbPool.query('SELECT * FROM public.game_videos WHERE id = $1;', [videoId]);

  if (videoRes.rows.length === 0) {
    throw new ApiError(404, 'Video recording not found', 'VIDEO_NOT_FOUND');
  }

  res.status(200).json(ApiResponse.success('Video metadata retrieved', videoRes.rows[0]));
});

export const getVideoPlaybackUrl = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: videoId } = req.params;
  const videoRes = await dbPool.query('SELECT * FROM public.game_videos WHERE id = $1;', [videoId]);

  if (videoRes.rows.length === 0) {
    throw new ApiError(404, 'Video recording not found', 'VIDEO_NOT_FOUND');
  }

  const video = videoRes.rows[0];
  const playbackUrl = await getSignedPlaybackUrl(video.video_url, 3600); // 1-hour pre-signed URL

  res.status(200).json(
    ApiResponse.success('Signed playback URL generated', {
      videoId: video.id,
      title: video.title,
      playbackUrl,
      expiresInSeconds: 3600,
    })
  );
});
