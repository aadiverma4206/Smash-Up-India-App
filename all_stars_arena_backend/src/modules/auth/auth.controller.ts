import { Request, Response } from "express";
import { AuthService } from "./auth.service.js";
import { AuthRepository } from "./auth.repository.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";

export const registerSendOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await AuthService.sendRegisterOtp(req.body);
    res.status(200).json(ApiResponse.success(result.message, result));
  },
);

export const resendOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await AuthService.resendOtp(req.body);
    res.status(200).json(ApiResponse.success(result.message, result));
  },
);

export const registerVerifyOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await AuthService.verifyRegisterOtp(req.body);
    res.status(200).json(ApiResponse.success(result.message, result));
  },
);

export const registerPlayerController = asyncHandler(
  async (req: Request, res: Response) => {
    const result = await AuthService.registerPlayer(req.body);
    res
      .status(201)
      .json(
        ApiResponse.success("Player account registered successfully", result),
      );
  },
);

export const loginController = asyncHandler(
  async (req: Request, res: Response) => {
    const { identifier, password, device } = req.body;
    const result = await AuthService.loginUser(
      identifier,
      password,
      device?.deviceInfo || req.headers["user-agent"] || "Mobile App",
      req.ip || "127.0.0.1",
    );
    res.status(200).json(ApiResponse.success("Login successful", result));
  },
);

export const refreshController = asyncHandler(
  async (req: Request, res: Response) => {
    const { refreshToken } = req.body;
    const result = await AuthService.refreshTokens(refreshToken);
    res
      .status(200)
      .json(ApiResponse.success("Tokens refreshed successfully", result));
  },
);

export const logoutController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (userId) {
      await AuthRepository.revokeAllUserSessions(userId);
    }
    res.status(200).json(ApiResponse.success("Logged out successfully"));
  },
);

export const logoutAllController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const count = await AuthRepository.revokeAllUserSessions(userId);
    res
      .status(200)
      .json(
        ApiResponse.success(
          `Logged out from all ${count} sessions successfully`,
        ),
      );
  },
);

export const getSessionsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const sessions = await AuthRepository.getUserActiveSessions(userId);
    res
      .status(200)
      .json(ApiResponse.success("Active sessions retrieved", sessions));
  },
);

export const revokeSessionController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { id: sessionId } = req.params;
    if (!sessionId) throw new ApiError(400, "Session ID required");

    await AuthRepository.revokeSession(sessionId);
    res.status(200).json(ApiResponse.success("Session revoked successfully"));
  },
);

export const forgotSendOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const { identifier } = req.body;
    const result = await AuthService.forgotPasswordSendOtp(identifier);
    res.status(200).json(ApiResponse.success(result.message));
  },
);

export const forgotVerifyOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const { identifier, otp } = req.body;
    const result = await AuthService.forgotPasswordVerifyOtp(identifier, otp);
    res.status(200).json(ApiResponse.success(result.message, result));
  },
);

export const resetPasswordController = asyncHandler(
  async (req: Request, res: Response) => {
    const { resetToken, newPassword } = req.body;
    const result = await AuthService.resetPassword(resetToken, newPassword);
    res.status(200).json(ApiResponse.success(result.message));
  },
);

export const getMeController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const profile = await AuthService.getMe(userId);
    res
      .status(200)
      .json(ApiResponse.success("Profile retrieved successfully", profile));
  },
);

export const registerFcmTokenController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { token, platform, deviceInfo } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    try {
      await AuthRepository.upsertDeviceToken(
        userId,
        token,
        platform,
        deviceInfo,
      );
    } catch (err: any) {}
    res
      .status(200)
      .json(ApiResponse.success("FCM Device token registered successfully"));
  },
);

export const deleteFcmTokenController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { token } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    try {
      await AuthRepository.deleteDeviceToken(userId, token);
    } catch (err: any) {}
    res
      .status(200)
      .json(ApiResponse.success("FCM Device token removed successfully"));
  },
);
