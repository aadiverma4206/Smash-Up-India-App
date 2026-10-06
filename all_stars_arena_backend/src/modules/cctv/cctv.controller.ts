import { Response } from 'express';
import { CctvService } from './cctv.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const addCamera = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || 'SYS';
    const managerName = req.user?.email || 'Manager';
    const { clubId, courtId, name, rtspUrl, ipAddress, port } = req.body;

    const camera = await CctvService.addCamera(managerId, managerName, {
      clubId,
      courtId,
      name,
      rtspUrl,
      ipAddress,
      port,
    });

    res.status(201).json(ApiResponse.success('CCTV Camera added successfully', camera));
  }
);

export const editCamera = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || 'SYS';
    const managerName = req.user?.email || 'Manager';
    const { cameraId } = req.params;
    const { name, courtId, rtspUrl, ipAddress, port, isEnabled } = req.body;

    const updated = await CctvService.editCamera(managerId, managerName, cameraId, {
      name,
      courtId,
      rtspUrl,
      ipAddress,
      port,
      isEnabled,
    });

    res.status(200).json(ApiResponse.success('CCTV Camera updated successfully', updated));
  }
);

export const testCameraConnection = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { cameraId } = req.params;
    const result = await CctvService.testCameraConnection(cameraId);
    res.status(200).json(ApiResponse.success('Camera connection test complete', result));
  }
);

export const getClubCameras = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { clubId } = req.params;
    if (!clubId) throw new ApiError(400, 'Club ID is required');

    const cameras = await CctvService.getClubCameras(clubId);
    res.status(200).json(ApiResponse.success('Club cameras retrieved', cameras));
  }
);

export const startRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || 'SYS';
    const managerName = req.user?.email || 'Manager';
    const { gameId, cameraId } = req.body;

    const result = await CctvService.startMatchRecording(
      managerId,
      managerName,
      gameId,
      cameraId
    );

    res.status(200).json(ApiResponse.success('CCTV Recording started', result));
  }
);

export const stopRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || 'SYS';
    const managerName = req.user?.email || 'Manager';
    const { recordingId } = req.params;

    const result = await CctvService.stopMatchRecording(
      managerId,
      managerName,
      recordingId
    );

    res.status(200).json(ApiResponse.success('CCTV Recording stopped', result));
  }
);

export const extendRecording = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || 'SYS';
    const managerName = req.user?.email || 'Manager';
    const { recordingId } = req.params;
    const { additionalMinutes } = req.body;

    const result = await CctvService.extendRecording(
      managerId,
      managerName,
      recordingId,
      Number(additionalMinutes)
    );

    res.status(200).json(ApiResponse.success('CCTV Recording deadline extended', result));
  }
);

export const getPlaybackUrl = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { gameId } = req.params;
    if (!gameId) throw new ApiError(400, 'Game ID is required');

    const result = await CctvService.getMatchVideoPlaybackUrl(gameId);
    res.status(200).json(ApiResponse.success('Signed playback URL generated', result));
  }
);
