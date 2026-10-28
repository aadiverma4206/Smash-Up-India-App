import path from "path";
import fs from "fs";
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

    const uploadedFile =
      req.file || (req.files && (req.files as Express.Multer.File[])[0]);

    if (!uploadedFile) {
      throw new ApiError(400, "No image file uploaded");
    }

    const profileImagesStoreDir = path.join(
      process.cwd(),
      "Profile_images_store",
    );
    if (!fs.existsSync(profileImagesStoreDir)) {
      fs.mkdirSync(profileImagesStoreDir, { recursive: true });
    }

    const userProfile = await PlayerRepository.getProfile(userId);
    const email = userProfile?.email || req.user?.email || "user";
    const phone = userProfile?.phone || req.user?.phone || "0000";

    // 1. Email prefix before @
    const emailPrefix = email.split("@")[0].replace(/[^a-zA-Z0-9_-]/g, "");

    // 2. Last 4 digits of phone
    const cleanPhone = phone.replace(/[^0-9]/g, "");
    const lastDigits =
      cleanPhone.length >= 4 ? cleanPhone.slice(-4) : cleanPhone || "0000";

    // 3. File extension
    let ext = path.extname(uploadedFile.originalname).toLowerCase();
    if (!ext || ext.length < 2) {
      if (uploadedFile.mimetype?.includes("png")) ext = ".png";
      else if (uploadedFile.mimetype?.includes("webp")) ext = ".webp";
      else ext = ".jpg";
    }

    // 4. Formatted filename: e.g. aadiverma4206_3585.jpg
    const filename = `${emailPrefix}_${lastDigits}${ext}`;
    const filePath = path.join(profileImagesStoreDir, filename);

    // Delete old profile image if it had a different filename/extension
    const oldAvatarUrl = userProfile?.avatarUrl || userProfile?.avatar_url;
    if (oldAvatarUrl && oldAvatarUrl.includes("/Profile_images_store/")) {
      try {
        const oldFileName = path.basename(oldAvatarUrl);
        const oldFilePath = path.join(profileImagesStoreDir, oldFileName);
        if (oldFilePath !== filePath && fs.existsSync(oldFilePath)) {
          fs.unlinkSync(oldFilePath);
        }
      } catch (_) {}
    }

    const fileBuffer =
      uploadedFile.buffer ||
      (uploadedFile.path && fs.existsSync(uploadedFile.path)
        ? fs.readFileSync(uploadedFile.path)
        : null);

    if (!fileBuffer) {
      throw new ApiError(400, "Corrupted image file buffer.");
    }

    // Save/Overwrite file in Profile_images_store
    fs.writeFileSync(filePath, fileBuffer);

    // Clean temp file if Multer created one
    if (
      uploadedFile.path &&
      uploadedFile.path !== filePath &&
      fs.existsSync(uploadedFile.path)
    ) {
      try {
        fs.unlinkSync(uploadedFile.path);
      } catch (_) {}
    }

    const avatarUrl = `/Profile_images_store/${filename}?v=${Date.now()}`;

    const updatedProfile = await PlayerRepository.updateAvatar(
      userId,
      avatarUrl,
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
    const oldAvatarUrl =
      currentProfile?.avatarUrl || currentProfile?.avatar_url;
    if (oldAvatarUrl && oldAvatarUrl.includes("/Profile_images_store/")) {
      try {
        const oldFileName = path.basename(oldAvatarUrl);
        const oldFilePath = path.join(
          process.cwd(),
          "Profile_images_store",
          oldFileName,
        );
        if (fs.existsSync(oldFilePath)) {
          fs.unlinkSync(oldFilePath);
        }
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
    const status = req.query.status as string;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const history = await PlayerRepository.getHistory(
      userId,
      limit,
      offset,
      status,
    );
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
