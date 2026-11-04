import { Request, Response } from "express";
import { ApiResponse, ApiError } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import {
  broadcastNotification,
  sendUserNotification,
  broadcastLiveMatchScore,
} from "../services/realtime.service.js";

export const sendRealtimeNotification = asyncHandler(
  async (req: Request, res: Response) => {
    const { userId, title, message, type } = req.body;

    if (!title || !message) {
      throw new ApiError(400, "Title and message are required");
    }

    if (userId) {
      sendUserNotification(userId, { title, message, type });
      return res
        .status(200)
        .json(
          ApiResponse.success(`Real-time notification sent to user:${userId}`),
        );
    } else {
      broadcastNotification({ title, message, type });
      return res
        .status(200)
        .json(
          ApiResponse.success(
            "Global real-time notification broadcasted to all users",
          ),
        );
    }
  },
);

export const triggerLiveMatchEvent = asyncHandler(
  async (req: Request, res: Response) => {
    const { gameId, teamAScore, teamBScore, eventText } = req.body;

    if (!gameId) {
      throw new ApiError(400, "Game ID is required");
    }

    broadcastLiveMatchScore(gameId, {
      teamAScore,
      teamBScore,
      eventText: eventText || "⚽ Live Event Update",
    });

    res
      .status(200)
      .json(
        ApiResponse.success(
          `Live match score event broadcasted for game:${gameId} via Socket.IO`,
        ),
      );
  },
);
