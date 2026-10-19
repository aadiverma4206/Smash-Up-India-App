import { Request, Response } from "express";
import { CctvService } from "./cctv.service.js";
import { CctvRecordingService } from "../../services/cctvRecording.service.js";
import { MediaMtxService } from "../../services/mediaMtx.service.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";
import { env } from "../../config/env.config.js";
import { logger } from "../../utils/logger.js";

export const addCamera = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const {
      clubId,
      courtId,
      name,
      rtspUrl,
      ipAddress,
      port,
      serialNumber,
      protocol,
    } = req.body;

    const camera = await CctvService.addCamera(
      managerId,
      managerName,
      userRole,
      {
        clubId,
        courtId,
        name,
        rtspUrl,
        ipAddress,
        port,
        serialNumber,
        protocol,
      },
    );

    res
      .status(201)
      .json(ApiResponse.success("CCTV Camera added successfully", camera));
  },
);

export const editCamera = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { cameraId } = req.params;
    const {
      name,
      courtId,
      rtspUrl,
      ipAddress,
      port,
      isEnabled,
      serialNumber,
      protocol,
    } = req.body;

    const updated = await CctvService.editCamera(
      managerId,
      managerName,
      userRole,
      cameraId,
      {
        name,
        courtId,
        rtspUrl,
        ipAddress,
        port,
        serialNumber,
        protocol,
        isEnabled,
      },
    );

    res
      .status(200)
      .json(ApiResponse.success("CCTV Camera updated successfully", updated));
  },
);

export const toggleCamera = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { cameraId } = req.params;
    const { isEnabled } = req.body;

    const updated = await CctvService.toggleCamera(
      managerId,
      managerName,
      userRole,
      cameraId,
      Boolean(isEnabled),
    );

    res.status(200).json(ApiResponse.success("Camera state updated", updated));
  },
);

export const testCameraConnection = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { cameraId } = req.params;
    const result = await CctvService.testCameraConnection(
      cameraId,
      req.user?.id,
      req.user?.roleId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Camera connection test complete", result));
  },
);

export const getClubCameras = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const clubId = (req.params.clubId || req.query.clubId) as string;
    if (!clubId)
      throw new ApiError(400, "Club ID is required", "MISSING_CLUB_ID");

    const cameras = await CctvService.getClubCameras(
      clubId,
      req.user?.id,
      req.user?.roleId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Club cameras retrieved", cameras));
  },
);

export const startRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { gameId, cameraId } = req.body;

    const result = await CctvService.startMatchRecording(
      managerId,
      managerName,
      userRole,
      gameId,
      cameraId,
    );

    res.status(200).json(ApiResponse.success("CCTV Recording started", result));
  },
);

export const stopRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { recordingId } = req.params;
    const { reason } = req.body || {};

    const result = await CctvService.stopMatchRecording(
      managerId,
      managerName,
      userRole,
      recordingId,
      reason,
    );

    res.status(200).json(ApiResponse.success("CCTV Recording stopped", result));
  },
);

export const extendRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { recordingId } = req.params;
    const { additionalMinutes } = req.body;

    const result = await CctvService.extendRecording(
      managerId,
      managerName,
      userRole,
      recordingId,
      Number(additionalMinutes),
    );

    res
      .status(200)
      .json(ApiResponse.success("CCTV Recording deadline extended", result));
  },
);

export const getGameRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { gameId } = req.params;
    if (!gameId) throw new ApiError(400, "Game ID is required");

    const result = await CctvService.getGameRecording(
      gameId,
      req.user?.id || "",
      req.user?.roleId || 3,
    );

    res
      .status(200)
      .json(ApiResponse.success("Match recording details retrieved", result));
  },
);

export const getPlaybackUrl = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { gameId } = req.params;
    const cctvId = (req.query.cctvId || req.query.cameraId) as
      string | undefined;
    if (!gameId) throw new ApiError(400, "Game ID is required");

    const result = await CctvService.getMatchVideoPlaybackUrl(
      gameId,
      req.user?.id,
      req.user?.roleId || 3,
      cctvId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Signed playback URL generated", result));
  },
);

export const getRecordingFailures = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const clubId = (req.query.clubId as string) || undefined;
    const failures = await CctvService.getRecordingFailures(
      req.user?.id || "",
      req.user?.roleId || 2,
      clubId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Recording failures retrieved", failures));
  },
);

export const getFfmpegHealth = asyncHandler(
  async (_req: AuthenticatedRequest, res: Response) => {
    const isMediaMtxActive = await MediaMtxService.isPortListening(8888);
    res.status(200).json(
      ApiResponse.success("Media server status", {
        available: isMediaMtxActive,
        engine: "MediaMTX (HLS/WebRTC) Native Engine",
        hlsPort: 8888,
        rtspPort: 8555,
      }),
    );
  },
);

export const getLiveCameras = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const forceRefresh = req.query.refresh === "true";
    const cameras = await CctvService.getLiveCameras(
      req.user?.id || "",
      req.user?.roleId || 2,
      forceRefresh,
    );
    res
      .status(200)
      .json(
        ApiResponse.success("Live CCTV camera channels retrieved", cameras),
      );
  },
);

export const createLiveSession = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { channel, streamType } = req.body;

    const protocol = req.headers["x-forwarded-proto"] || req.protocol || "http";
    const host =
      req.headers["x-forwarded-host"] ||
      req.headers["host"] ||
      `localhost:${env.PORT || 5000}`;
    const backendBaseUrl = process.env.BACKEND_URL || `${protocol}://${host}`;

    const session = await CctvService.createLiveSession(
      req.user?.id || "",
      req.user?.roleId || 2,
      Number(channel),
      streamType || "sub",
      backendBaseUrl,
    );
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Authorized live stream session generated",
          session,
        ),
      );
  },
);

export const getLiveChannelStatus = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const channel = Number(req.params.channel);
    const status = await CctvService.getLiveChannelStatus(
      channel,
      req.user?.id || "",
      req.user?.roleId || 2,
    );
    res
      .status(200)
      .json(ApiResponse.success("Camera channel status retrieved", status));
  },
);

export const releaseLiveSession = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { sessionId } = req.params;
    const result = await CctvService.releaseLiveSession(
      sessionId,
      req.user?.id || "",
      req.user?.roleId || 2,
    );
    res
      .status(200)
      .json(ApiResponse.success("Live stream session released", result));
  },
);
