import path from "path";
import fs from "fs";
import { Request, Response } from "express";
import { ManagerService } from "./manager.service.js";
import { ManagerRepository } from "./manager.repository.js";
import { CourtsService } from "../courts/courts.service.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";
import {
  uploadProfileImageToS3,
  deleteS3Object,
} from "../../services/storage.service.js";
import { CctvService } from "../cctv/cctv.service.js";
import { CctvRepository } from "../cctv/cctv.repository.js";
import { dbPool } from "../../config/db.config.js";
import { getSocketIO } from "../../config/socket.config.js";

export const getDashboardController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const dashboard = await ManagerService.getDashboard(userId);
    res
      .status(200)
      .json(ApiResponse.success("Manager dashboard retrieved", dashboard));
  },
);

export const getManagerClubController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const club = await ManagerRepository.getManagerClub(userId);
    res.status(200).json(ApiResponse.success("Assigned club retrieved", club));
  },
);

export const getClubMetricsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id || (req.user as any)?.userId;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const metrics = await ManagerService.getClubMetrics(userId);
    res.status(200).json(ApiResponse.success("Club metrics retrieved", metrics));
  },
);

export const createCourtController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const {
      clubId,
      name,
      environment,
      surface,
      basePrice,
      peakMultiplier,
      weekendMultiplier,
    } = req.body;

    const court = await ManagerRepository.createCourt({
      clubId,
      name,
      environment,
      surface,
      basePrice: Number(basePrice),
      peakMultiplier: Number(peakMultiplier),
      weekendMultiplier: Number(weekendMultiplier),
    });

    res.status(201).json(ApiResponse.success("Court pitch created", court));
  },
);

export const updateCourtPricingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { id: courtId } = req.params;
    const updated = await ManagerRepository.updateCourtPricing(
      courtId,
      req.body,
    );
    res.status(200).json(ApiResponse.success("Court pricing updated", updated));
  },
);

export const simulatePricingController = asyncHandler(
  async (req: Request, res: Response) => {
    const { courtId, bookingDate, startTime } = req.body;
    const quote = await CourtsService.calculateQuote(
      courtId,
      bookingDate,
      startTime,
    );
    res
      .status(200)
      .json(ApiResponse.success("Price simulation quote calculated", quote));
  },
);

export const createGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    if (!managerId) throw new ApiError(401, "Unauthorized");

    const game = await ManagerRepository.createGame({
      ...req.body,
      creatorId: managerId,
      maxPlayers: Number(req.body.maxPlayers),
      entryFee: Number(req.body.entryFee),
    });

    res
      .status(201)
      .json(ApiResponse.success("Match game scheduled successfully", game));
  },
);

export const updateGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const { id: gameId } = req.params;

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const updatedGame = await ManagerRepository.updateGame(gameId, req.body);
    res
      .status(200)
      .json(ApiResponse.success("Match updated successfully", updatedGame));
  },
);

export const rescheduleGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { id: gameId } = req.params;

    const game = await ManagerService.rescheduleMatch(
      managerId,
      managerName,
      userRole,
      gameId,
      req.body,
    );
    res
      .status(200)
      .json(ApiResponse.success("Match rescheduled successfully", game));
  },
);

export const startGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const { id: gameId } = req.params;

    const game = await ManagerService.startMatch(
      managerId,
      managerName,
      gameId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Match started successfully", game));
  },
);

export const completeGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const { id: gameId } = req.params;
    const { teamAScore, teamBScore } = req.body;

    const scoreData =
      teamAScore !== undefined && teamBScore !== undefined
        ? { teamAScore: Number(teamAScore), teamBScore: Number(teamBScore) }
        : undefined;

    const game = await ManagerService.completeMatch(
      managerId,
      managerName,
      gameId,
      scoreData,
    );
    res
      .status(200)
      .json(ApiResponse.success("Match completed successfully", game));
  },
);

export const cancelGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "SYS";
    const managerName = req.user?.email || "Manager";
    const userRole = req.user?.roleId || 2;
    const { id: gameId } = req.params;
    const { cancellationReason } = req.body;

    const game = await ManagerService.cancelMatchWithRefunds(
      managerId,
      managerName,
      gameId,
      cancellationReason,
      userRole,
    );
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Match cancelled and refunds processed successfully",
          game,
        ),
      );
  },
);

export const getPendingRequestsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const club = await ManagerRepository.getManagerClub(userId);
    if (!club)
      throw new ApiError(404, "No assigned club found for this manager");

    const requests = await ManagerRepository.getPendingRequests(club.id);
    res
      .status(200)
      .json(ApiResponse.success("Pending player requests retrieved", requests));
  },
);

export const approveSlotRequestController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: requestId } = req.params;

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.approveSlotRequest(
      managerId,
      managerName,
      requestId,
    );
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Player slot request approved successfully",
          result,
        ),
      );
  },
);

export const rejectSlotRequestController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: requestId } = req.params;
    const { rejectionReason } = req.body;

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.rejectSlotRequest(
      managerId,
      managerName,
      requestId,
      rejectionReason,
    );
    res
      .status(200)
      .json(ApiResponse.success("Player slot request rejected", result));
  },
);

export const getClubMatchesController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const tab =
      (req.query.tab as string) ||
      (req.path.endsWith("/games") ? "ALL" : "TODAY");
    const courtFilter =
      (req.query.court as string) || (req.query.courtId as string);

    if (!userId) throw new ApiError(401, "Unauthorized");

    const club = await ManagerRepository.getManagerClub(userId);
    if (!club) throw new ApiError(404, "No assigned club found");

    const matches = await ManagerRepository.getClubMatchesByStatus(
      club.id,
      tab.toUpperCase(),
      courtFilter,
    );
    res
      .status(200)
      .json(ApiResponse.success("Club matches retrieved", matches));
  },
);

export const getManagerBookingsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const club = await ManagerRepository.getManagerClub(userId);
    if (!club) throw new ApiError(404, "No assigned club found");

    const bookings = await ManagerRepository.getClubBookings(club.id);
    res
      .status(200)
      .json(ApiResponse.success("Club bookings retrieved", bookings));
  },
);

export const getManagerCourtsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const courts = await ManagerService.getClubCourts(userId);
    res.status(200).json(ApiResponse.success("Club courts retrieved", courts));
  },
);

export const getCourtSlotsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { courtId } = req.params;
    const date = (req.query.date as string) || undefined;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.getCourtSlots(userId, courtId, date);
    res
      .status(200)
      .json(ApiResponse.success("Court slot list retrieved", result));
  },
);

export const getPendingGamesController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const pendingGames = await ManagerService.getPendingPlayerGames(userId);
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Pending player-created matches retrieved",
          pendingGames,
        ),
      );
  },
);

export const approvePlayerGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: gameId } = req.params;

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.approvePlayerGame(
      managerId,
      managerName,
      gameId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Match game approved and scheduled", result));
  },
);

export const rejectPlayerGameController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: gameId } = req.params;
    const { rejectionReason } = req.body || {};

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.rejectPlayerGame(
      managerId,
      managerName,
      gameId,
      rejectionReason,
    );
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Match game rejected and refunds processed",
          result,
        ),
      );
  },
);

export const getAllPlayersController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const search = (req.query.search as string) || undefined;
    const status = (req.query.status as string) || undefined;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    const result = await ManagerService.getAllPlayers(
      userId,
      search,
      status,
      limit,
      offset,
    );
    res.status(200).json(ApiResponse.success("Players list retrieved", result));
  },
);

export const getPlayerDetailHistoryController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const { id: playerId } = req.params;
    if (!playerId) throw new ApiError(400, "Player ID is required");

    const result = await ManagerService.getPlayerDetailHistory(
      userId,
      playerId,
    );
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Player detail and match history retrieved",
          result,
        ),
      );
  },
);

export const blockPlayerController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: playerId } = req.params;
    const { reason } = req.body || {};

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.blockPlayer(
      managerId,
      managerName,
      playerId,
      reason,
    );
    res
      .status(200)
      .json(ApiResponse.success("Player blocked successfully", result));
  },
);

export const unblockPlayerController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: playerId } = req.params;

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.unblockPlayer(
      managerId,
      managerName,
      playerId,
    );
    res
      .status(200)
      .json(ApiResponse.success("Player unblocked successfully", result));
  },
);

export const submitMatchScoreController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const userName = req.user?.email || "User";
    const userRole = req.user?.roleId || 2;
    const { id: gameId } = req.params;
    const { teamAScore, teamBScore, isFinal } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.submitMatchScore(
      userId,
      userName,
      userRole,
      gameId,
      {
        teamAScore: Number(teamAScore),
        teamBScore: Number(teamBScore),
        isFinal: isFinal !== undefined ? Boolean(isFinal) : true,
      },
    );

    res
      .status(200)
      .json(ApiResponse.success("Match score submitted successfully", result));
  },
);

export const getMatchRecordingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: gameId } = req.params;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.getMatchRecording(userId, gameId);
    res
      .status(200)
      .json(ApiResponse.success("Match recording details retrieved", result));
  },
);

export const stopMatchRecordingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id;
    const managerName = req.user?.email || "Manager";
    const { id: gameId } = req.params;

    if (!managerId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.stopMatchRecording(
      managerId,
      managerName,
      gameId,
    );
    res
      .status(200)
      .json(
        ApiResponse.success("Match recording stopped successfully", result),
      );
  },
);

export const extendMatchRecordingController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const managerId = req.user?.id || "";
    const managerName = req.user?.email || "Manager";
    const { id: gameId } = req.params;
    const { additionalMinutes } = req.body || {};
    const mins = Number(additionalMinutes || 15);

    // 1. Extend match end_time in games table so LifecycleWorker does not auto-complete the match prematurely
    await dbPool.query(
      `UPDATE public.games
       SET end_time = (end_time::time + ($1 || ' minutes')::interval)::time,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2;`,
      [mins, gameId],
    );

    // 2. Extend CCTV recording deadline
    const rec = await CctvRepository.getRecordingByGame(gameId);
    let recResult = null;
    if (rec) {
      recResult = await CctvService.extendRecording(
        managerId,
        managerName,
        req.user?.roleId || 2,
        rec.id,
        mins,
      );
    }

    // 3. Emit live socket event
    try {
      const io = getSocketIO();
      io.to(`game:${gameId}`).emit("match:extended", {
        gameId,
        additionalMinutes: mins,
        message: `Match time extended by ${mins} minutes by manager`,
      });
      io.emit("match:live_feed", {
        gameId,
        status: "ONGOING",
        eventText: `⏱️ EXTRA TIME: Match extended by ${mins} minutes`,
      });
    } catch (_) {}

    res.status(200).json(
      ApiResponse.success(`Match time extended by ${mins} minutes successfully`, {
        gameId,
        additionalMinutes: mins,
        recording: recResult,
      }),
    );
  },
);

export const getManagerCamerasController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    let clubId = req.query.clubId as string;
    if (!clubId) {
      const club = await ManagerRepository.getManagerClub(userId);
      clubId = club?.id;
    }

    if (!clubId) {
      return res.status(200).json(ApiResponse.success("Cameras retrieved", []));
    }

    const cameras = await CctvService.getClubCameras(
      clubId,
      userId,
      req.user?.roleId || 2,
    );
    res.status(200).json(ApiResponse.success("Cameras retrieved", cameras));
  },
);

export const getGameDetailsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: gameId } = req.params;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.getGameDetails(userId, gameId);
    res
      .status(200)
      .json(ApiResponse.success("Match details retrieved", result));
  },
);

export const getGamePlayersController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: gameId } = req.params;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const result = await ManagerService.getGamePlayers(userId, gameId);
    res
      .status(200)
      .json(ApiResponse.success("Match players retrieved", result));
  },
);

export const getClubHistoryController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;
    const status = req.query.status as string;
    const court = req.query.court as string;

    if (!userId) throw new ApiError(401, "Unauthorized");

    const club = await ManagerRepository.getManagerClub(userId);
    if (!club)
      throw new ApiError(404, "No assigned club found for this manager");

    const history = await ManagerRepository.getClubHistoryMatches(
      club.id,
      limit,
      offset,
      status,
      court,
    );
    res
      .status(200)
      .json(ApiResponse.success("Club history matches retrieved", history));
  },
);

export const getManagerProfileController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const profile = await ManagerRepository.getManagerProfile(userId);
    res
      .status(200)
      .json(ApiResponse.success("Manager profile retrieved", profile));
  },
);

export const uploadManagerAvatarController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) throw new ApiError(401, "Unauthorized");

    const uploadedFile =
      req.file ||
      (req.files && (req.files as Express.Multer.File[])[0]);

    if (!uploadedFile) {
      throw new ApiError(400, "No image file uploaded");
    }

    const profileImagesStoreDir = path.join(process.cwd(), "Profile_images_store");
    if (!fs.existsSync(profileImagesStoreDir)) {
      fs.mkdirSync(profileImagesStoreDir, { recursive: true });
    }

    const currentProfile = await ManagerRepository.getManagerProfile(userId);
    const email = currentProfile?.email || req.user?.email || "manager";
    const phone = currentProfile?.phone || req.user?.phone || "0000";

    // 1. Email prefix before @
    const emailPrefix = email.split("@")[0].replace(/[^a-zA-Z0-9_-]/g, "");

    // 2. Last 4 digits of phone
    const cleanPhone = phone.replace(/[^0-9]/g, "");
    const lastDigits =
      cleanPhone.length >= 4
        ? cleanPhone.slice(-4)
        : cleanPhone || "0000";

    // 3. File extension
    let ext = path.extname(uploadedFile.originalname).toLowerCase();
    if (!ext || ext.length < 2) {
      if (uploadedFile.mimetype?.includes("png")) ext = ".png";
      else if (uploadedFile.mimetype?.includes("webp")) ext = ".webp";
      else ext = ".jpg";
    }

    // 4. Formatted filename: e.g. manager1_3585.jpg
    const filename = `${emailPrefix}_${lastDigits}${ext}`;
    const filePath = path.join(profileImagesStoreDir, filename);

    // Delete old manager profile image if it had a different filename/extension
    const oldAvatarUrl = currentProfile?.profile_image_url || currentProfile?.avatarUrl;
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
    if (uploadedFile.path && uploadedFile.path !== filePath && fs.existsSync(uploadedFile.path)) {
      try {
        fs.unlinkSync(uploadedFile.path);
      } catch (_) {}
    }

    const avatarUrl = `/Profile_images_store/${filename}?v=${Date.now()}`;

    const updatedProfile = await ManagerRepository.updateAvatar(
      userId,
      avatarUrl,
    );
    res
      .status(200)
      .json(
        ApiResponse.success(
          "Manager avatar uploaded successfully",
          updatedProfile,
        ),
      );
  },
);
