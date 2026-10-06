import { Response } from 'express';
import { dbPool } from '../../config/db.config.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getNotificationsController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const resDb = await dbPool.query(
    `SELECT * FROM public.notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50;`,
    [userId]
  );

  res.status(200).json(ApiResponse.success('Notifications retrieved', resDb.rows));
});

export const markNotificationReadController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: notificationId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  await dbPool.query(
    `UPDATE public.notifications SET is_read = true WHERE id = $1 AND user_id = $2;`,
    [notificationId, userId]
  );

  res.status(200).json(ApiResponse.success('Notification marked as read'));
});

export const markAllReadController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  await dbPool.query(
    `UPDATE public.notifications SET is_read = true WHERE user_id = $1 AND is_read = false;`,
    [userId]
  );

  res.status(200).json(ApiResponse.success('All notifications marked as read'));
});
