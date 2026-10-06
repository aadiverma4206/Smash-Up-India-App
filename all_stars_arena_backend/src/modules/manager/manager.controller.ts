import { Request, Response } from 'express';
import { ManagerService } from './manager.service.js';
import { ManagerRepository } from './manager.repository.js';
import { CourtsService } from '../courts/courts.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getDashboardController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const dashboard = await ManagerService.getDashboard(userId);
  res.status(200).json(ApiResponse.success('Manager dashboard retrieved', dashboard));
});

export const getManagerClubController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const club = await ManagerRepository.getManagerClub(userId);
  res.status(200).json(ApiResponse.success('Assigned club retrieved', club));
});

export const createCourtController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { clubId, name, environment, surface, basePrice, peakMultiplier, weekendMultiplier } = req.body;

  const court = await ManagerRepository.createCourt({
    clubId,
    name,
    environment,
    surface,
    basePrice: Number(basePrice),
    peakMultiplier: Number(peakMultiplier),
    weekendMultiplier: Number(weekendMultiplier),
  });

  res.status(201).json(ApiResponse.success('Court pitch created', court));
});

export const updateCourtPricingController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: courtId } = req.params;
  const updated = await ManagerRepository.updateCourtPricing(courtId, req.body);
  res.status(200).json(ApiResponse.success('Court pricing updated', updated));
});

export const simulatePricingController = asyncHandler(async (req: Request, res: Response) => {
  const { courtId, bookingDate, startTime } = req.body;
  const quote = await CourtsService.calculateQuote(courtId, bookingDate, startTime);
  res.status(200).json(ApiResponse.success('Price simulation quote calculated', quote));
});

export const createGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const game = await ManagerRepository.createGame({
    ...req.body,
    creatorId: managerId,
    maxPlayers: Number(req.body.maxPlayers),
    entryFee: Number(req.body.entryFee),
  });

  res.status(201).json(ApiResponse.success('Match game scheduled successfully', game));
});

export const updateGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const { id: gameId } = req.params;

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const updatedGame = await ManagerRepository.updateGame(gameId, req.body);
  res.status(200).json(ApiResponse.success('Match updated successfully', updatedGame));
});

export const startGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id || 'SYS';
  const managerName = req.user?.email || 'Manager';
  const { id: gameId } = req.params;

  const game = await ManagerService.startMatch(managerId, managerName, gameId);
  res.status(200).json(ApiResponse.success('Match started successfully', game));
});

export const completeGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id || 'SYS';
  const managerName = req.user?.email || 'Manager';
  const { id: gameId } = req.params;
  const { teamAScore, teamBScore } = req.body;

  const scoreData = teamAScore !== undefined && teamBScore !== undefined
    ? { teamAScore: Number(teamAScore), teamBScore: Number(teamBScore) }
    : undefined;

  const game = await ManagerService.completeMatch(managerId, managerName, gameId, scoreData);
  res.status(200).json(ApiResponse.success('Match completed successfully', game));
});

export const cancelGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id || 'SYS';
  const managerName = req.user?.email || 'Manager';
  const userRole = req.user?.roleId || 2;
  const { id: gameId } = req.params;
  const { cancellationReason } = req.body;

  const game = await ManagerService.cancelMatchWithRefunds(managerId, managerName, gameId, cancellationReason, userRole);
  res.status(200).json(ApiResponse.success('Match cancelled and refunds processed successfully', game));
});

export const getPendingRequestsController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const club = await ManagerRepository.getManagerClub(userId);
  if (!club) throw new ApiError(404, 'No assigned club found for this manager');

  const requests = await ManagerRepository.getPendingRequests(club.id);
  res.status(200).json(ApiResponse.success('Pending player requests retrieved', requests));
});

export const approveSlotRequestController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: requestId } = req.params;

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.approveSlotRequest(managerId, managerName, requestId);
  res.status(200).json(ApiResponse.success('Player slot request approved successfully', result));
});

export const rejectSlotRequestController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: requestId } = req.params;
  const { rejectionReason } = req.body;

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.rejectSlotRequest(managerId, managerName, requestId, rejectionReason);
  res.status(200).json(ApiResponse.success('Player slot request rejected', result));
});

export const getClubMatchesController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const tab = (req.query.tab as string) || (req.path.endsWith('/games') ? 'ALL' : 'TODAY');

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const club = await ManagerRepository.getManagerClub(userId);
  if (!club) throw new ApiError(404, 'No assigned club found');

  const matches = await ManagerRepository.getClubMatchesByStatus(club.id, tab.toUpperCase());
  res.status(200).json(ApiResponse.success('Club matches retrieved', matches));
});

export const getManagerBookingsController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const club = await ManagerRepository.getManagerClub(userId);
  if (!club) throw new ApiError(404, 'No assigned club found');

  const bookings = await ManagerRepository.getClubBookings(club.id);
  res.status(200).json(ApiResponse.success('Club bookings retrieved', bookings));
});

export const getManagerCourtsController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const courts = await ManagerService.getClubCourts(userId);
  res.status(200).json(ApiResponse.success('Club courts retrieved', courts));
});

export const getCourtSlotsController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { courtId } = req.params;
  const date = (req.query.date as string) || undefined;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.getCourtSlots(userId, courtId, date);
  res.status(200).json(ApiResponse.success('Court slot list retrieved', result));
});

export const getPendingGamesController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const pendingGames = await ManagerService.getPendingPlayerGames(userId);
  res.status(200).json(ApiResponse.success('Pending player-created matches retrieved', pendingGames));
});

export const approvePlayerGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: gameId } = req.params;

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.approvePlayerGame(managerId, managerName, gameId);
  res.status(200).json(ApiResponse.success('Match game approved and scheduled', result));
});

export const rejectPlayerGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: gameId } = req.params;
  const { rejectionReason } = req.body || {};

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.rejectPlayerGame(managerId, managerName, gameId, rejectionReason);
  res.status(200).json(ApiResponse.success('Match game rejected and refunds processed', result));
});

export const getAllPlayersController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const search = (req.query.search as string) || undefined;
  const status = (req.query.status as string) || undefined;
  const limit = parseInt(req.query.limit as string) || 50;
  const offset = parseInt(req.query.offset as string) || 0;

  const result = await ManagerService.getAllPlayers(userId, search, status, limit, offset);
  res.status(200).json(ApiResponse.success('Players list retrieved', result));
});

export const blockPlayerController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: playerId } = req.params;
  const { reason } = req.body || {};

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.blockPlayer(managerId, managerName, playerId, reason);
  res.status(200).json(ApiResponse.success('Player blocked successfully', result));
});

export const unblockPlayerController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: playerId } = req.params;

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.unblockPlayer(managerId, managerName, playerId);
  res.status(200).json(ApiResponse.success('Player unblocked successfully', result));
});

export const submitMatchScoreController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const userName = req.user?.email || 'User';
  const userRole = req.user?.roleId || 2;
  const { id: gameId } = req.params;
  const { teamAScore, teamBScore, isFinal } = req.body;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.submitMatchScore(userId, userName, userRole, gameId, {
    teamAScore: Number(teamAScore),
    teamBScore: Number(teamBScore),
    isFinal: isFinal !== undefined ? Boolean(isFinal) : true,
  });

  res.status(200).json(ApiResponse.success('Match score submitted successfully', result));
});

export const getMatchRecordingController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.getMatchRecording(userId, gameId);
  res.status(200).json(ApiResponse.success('Match recording details retrieved', result));
});

export const stopMatchRecordingController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const managerId = req.user?.id;
  const managerName = req.user?.email || 'Manager';
  const { id: gameId } = req.params;

  if (!managerId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.stopMatchRecording(managerId, managerName, gameId);
  res.status(200).json(ApiResponse.success('Match recording stopped successfully', result));
});

export const getGameDetailsController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await ManagerService.getGameDetails(userId, gameId);
  res.status(200).json(ApiResponse.success('Match details retrieved', result));
});
