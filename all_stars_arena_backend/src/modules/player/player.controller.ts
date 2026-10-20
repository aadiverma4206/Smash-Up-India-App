import { Response } from "express";
import { PlayerRepository } from "./player.repository.js";
import { GamesRepository } from "../games/games.repository.js";
import {
  uploadProfileImageToS3,
  deleteS3Object,
} from "../../services/storage.service.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";

export const getPlayerProfile = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const profile = await PlayerRepository.getProfile(userId);
    res
      .status(200)
      .json(ApiResponse.success("Player profile retrieved", profile));
  },
);

export const updatePlayerProfile = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const updated = await PlayerRepository.updateProfile(userId, req.body);
    res
      .status(200)
      .json(ApiResponse.success("Player profile updated", updated));
  },
);

export const uploadPlayerAvatar = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    if (!req.file) {
      throw new ApiError(400, "No image file uploaded");
    }

    const currentProfile = await PlayerRepository.getProfile(userId);
    if (
      currentProfile?.avatarUrl &&
      currentProfile.avatarUrl.includes("players/")
    ) {
      try {
        const oldKey = currentProfile.avatarUrl.substring(
          currentProfile.avatarUrl.indexOf("players/"),
        );
        await deleteS3Object(oldKey);
      } catch (_) {}
    }

    const extension = req.file.mimetype.split("/")[1] || "jpg";
    const { publicUrl } = await uploadProfileImageToS3(
      userId,
      req.file.buffer,
      req.file.mimetype,
      extension,
    );

    const updatedProfile = await PlayerRepository.updateAvatar(
      userId,
      publicUrl,
    );
    res
      .status(200)
      .json(
        ApiResponse.success("Avatar uploaded successfully", updatedProfile),
      );
  },
);

export const deletePlayerAvatar = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const currentProfile = await PlayerRepository.getProfile(userId);
    if (
      currentProfile?.avatarUrl &&
      currentProfile.avatarUrl.includes("players/")
    ) {
      try {
        const oldKey = currentProfile.avatarUrl.substring(
          currentProfile.avatarUrl.indexOf("players/"),
        );
        await deleteS3Object(oldKey);
      } catch (_) {}
    }

    const updatedProfile = await PlayerRepository.updateAvatar(userId, "");
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Profile image deleted successfully",
          updatedProfile,
        ),
      );
  },
);

export const getPlayerStats = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const stats = await PlayerRepository.getStats(userId);
    res.status(200).json(ApiResponse.success("Player stats retrieved", stats));
  },
);

export const getPlayerHistory = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const limit = Number(req.query.limit) || 20;
    const offset = Number(req.query.offset) || 0;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const history = await PlayerRepository.getHistory(userId, limit, offset);
    res
      .status(200)
      .json(ApiResponse.success("Player match history retrieved", history));
  },
);

export const getDashboardSummary = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const summary = await PlayerRepository.getDashboardSummary(userId);
    res
      .status(200)
      .json(ApiResponse.success("Dashboard summary retrieved", summary));
  },
);

export const getMyMatches = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const tab = (req.query.tab as string) || "UPCOMING";

    if (!userId) throw new ApiError(401, "Unauthorized");

    const matches = await PlayerRepository.getMyMatches(
      userId,
      tab.toUpperCase(),
    );
    res
      .status(200)
      .json(ApiResponse.success("Player matches retrieved", matches));
  },
);

export const getPlayerRequestsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const statusTab = ((req.query.status as string) || "ALL").toUpperCase();

    if (!userId) throw new ApiError(401, "Unauthorized");

    const requests = await GamesRepository.getPlayerRequests(userId, statusTab);
    res
      .status(200)
      .json(ApiResponse.success("Player slot requests retrieved", requests));
  },
);
