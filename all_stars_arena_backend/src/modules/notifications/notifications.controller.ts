import { Response } from "express";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";
import { NotificationService } from "./notifications.service.js";

export const getNotificationsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const page = parseInt((req.query.page as string) || "1", 10);
    const limit = parseInt((req.query.limit as string) || "50", 10);
    const type = req.query.type as string | undefined;
    const isRead =
      req.query.isRead !== undefined ? req.query.isRead === "true" : undefined;

    const result = await NotificationService.getUserNotifications(
      userId,
      page,
      limit,
      type,
      isRead,
    );

    res
      .status(200)
      .json(
        ApiResponse.success("Notifications retrieved", result.notifications),
      );
  },
);

export const markNotificationReadController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: notificationId } = req.params;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const success = await NotificationService.markNotificationRead(
      notificationId,
      userId,
    );
    if (!success) {
      throw new ApiError(404, "Notification not found or unauthorized");
    }

    res.status(200).json(ApiResponse.success("Notification marked as read"));
  },
);

export const markAllReadController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const count = await NotificationService.markAllRead(userId);

    res
      .status(200)
      .json(ApiResponse.success(`Marked ${count} notifications as read`));
  },
);
