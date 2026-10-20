import { Request, Response } from "express";
import {
  getLiveMatches,
  getMatchDetails,
  updateLiveMatchScore,
} from "../services/match.service.js";
import { CctvRecordingService } from "../services/cctvRecording.service.js";
import { ApiResponse, ApiError } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../types/index.js";

export const getLiveMatchesController = asyncHandler(
  async (_req: Request, res: Response) => {
    const matches = await getLiveMatches();
    res
      .status(200)
      .json(
        ApiResponse.success("Live matches retrieved successfully", matches),
      );
  },
);

export const getMatchDetailsController = asyncHandler(
  async (req: Request, res: Response) => {
    const matchId = req.params.gameId || req.params.matchId;
    if (!matchId) throw new ApiError(400, "Match Game ID is required");

    const details =
      await CctvRecordingService.getMatchRecordingDetails(matchId);
    res
      .status(200)
      .json(
        ApiResponse.success("Match details retrieved successfully", details),
      );
  },
);

export const updateScoreController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const matchId = req.params.gameId || req.params.matchId;
    const { teamAScore, teamBScore, isFinal, eventText } = req.body;
    const updatedByUserId = req.user?.id;

    if (!matchId) throw new ApiError(400, "Match Game ID is required");
    if (teamAScore === undefined || teamBScore === undefined) {
      throw new ApiError(400, "Team A score and Team B score are required");
    }

    const result = await updateLiveMatchScore({
      gameId: matchId,
      teamAScore: Number(teamAScore),
      teamBScore: Number(teamBScore),
      isFinal: Boolean(isFinal),
      eventText,
      updatedByUserId,
    });

    res
      .status(200)
      .json(
        ApiResponse.success(
          "Match score updated and broadcasted via Real-Time Socket",
          result,
        ),
      );
  },
);

export const startMatchRecordingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { matchId, matchTitle, cameraId, channel, durationSeconds, rtspUrl } =
      req.body;
    const userId = req.user?.id;
    const userRole = req.user?.roleId;

    if (!matchId) {
      throw new ApiError(400, "matchId is required", "MISSING_MATCH_ID");
    }

    const recordingResult = await CctvRecordingService.startRecording({
      gameId: matchId,
      matchTitle,
      cameraId,
      channel: channel ? Number(channel) : undefined,
      durationSeconds: durationSeconds ? Number(durationSeconds) : undefined,
      rtspUrl,
      userId,
    });

    res
      .status(200)
      .json(
        ApiResponse.success(
          "Match recording started successfully",
          recordingResult,
        ),
      );
  },
);

export const stopMatchRecordingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { matchId } = req.body;
    const userId = req.user?.id;

    if (!matchId) {
      throw new ApiError(400, "matchId is required", "MISSING_MATCH_ID");
    }

    const result = await CctvRecordingService.stopRecording(matchId, {
      userId,
      reason: "MANUAL_USER_STOP",
      manualStop: true,
    });

    res
      .status(200)
      .json(
        ApiResponse.success(
          "Match recording stopped and finalized successfully",
          result,
        ),
      );
  },
);

export const listRecordedMatchesController = asyncHandler(
  async (req: Request, res: Response) => {
    const limit = Math.min(Number(req.query.limit) || 50, 100);
    const offset = Math.max(Number(req.query.offset) || 0, 0);

    const matches = await CctvRecordingService.listRecordedMatches(
      limit,
      offset,
    );

    res.status(200).json({
      success: true,
      message: "Recorded matches retrieved successfully",
      data: matches,
    });
  },
);

export const getMatchRecordingStatusController = asyncHandler(
  async (req: Request, res: Response) => {
    const matchId = req.params.matchId || req.params.gameId;
    if (!matchId) {
      throw new ApiError(400, "matchId is required", "MISSING_MATCH_ID");
    }

    const status = await CctvRecordingService.getMatchRecordingStatus(matchId);
    res
      .status(200)
      .json(ApiResponse.success("Recording status retrieved", status));
  },
);
