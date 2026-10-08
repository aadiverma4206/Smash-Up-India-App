import { Request, Response } from 'express';
import { GamesRepository } from './games.repository.js';
import { GamesService } from './games.service.js';
import { updateLiveMatchScore } from '../../services/match.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getGamesController = asyncHandler(async (req: Request, res: Response) => {
  let skillFilter: string | undefined = undefined;
  if (req.query.skill) {
    const rawSkill = (req.query.skill as string).trim().toUpperCase();
    if (rawSkill !== 'ANY' && rawSkill !== 'ALL' && rawSkill !== '') {
      const skillMap: Record<string, string> = {
        'AMATEUR': 'Beginner',
        'BEGINNER': 'Beginner',
        'INTERMEDIATE': 'Intermediate',
        'SEMI_PRO': 'Intermediate',
        'ADVANCED': 'Advanced',
        'PRO': 'Professional',
        'PROFESSIONAL': 'Professional',
      };
      skillFilter = skillMap[rawSkill] || (rawSkill.charAt(0).toUpperCase() + rawSkill.slice(1).toLowerCase());
    }
  }

  const authReq = req as AuthenticatedRequest;
  const userIdParam = req.query.userId as string;
  const myGamesParam = req.query.myGames === 'true' || req.query.myGames === '1';
  const resolvedUserId = userIdParam || (myGamesParam ? authReq.user?.id : undefined);

  const filters = {
    city: req.query.city as string,
    format: req.query.format as string,
    skill: skillFilter,
    date: req.query.date as string,
    maxEntryFee: req.query.entryFee ? Number(req.query.entryFee) : undefined,
    status: req.query.status as string,
    privacy: req.query.privacy as string,
    court: (req.query.court as string) || (req.query.courtId as string),
    userId: resolvedUserId,
    limit: Number(req.query.limit) || 20,
    offset: Number(req.query.offset) || 0,
  };

  const games = await GamesRepository.getGames(filters);
  res.status(200).json(ApiResponse.success('Games retrieved successfully', games));
});

export const getGameByIdController = asyncHandler(async (req: Request, res: Response) => {
  const { id: gameId } = req.params;
  const game = await GamesRepository.getGameById(gameId);
  if (!game) throw new ApiError(404, 'Game not found', 'GAME_NOT_FOUND');

  const roster = await GamesRepository.getRoster(gameId);
  const waitlist = await GamesRepository.getWaitlist(gameId);
  res.status(200).json(ApiResponse.success('Game details retrieved', { game, roster, waitlist }));
});

export const createGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  if (!userId) throw new ApiError(401, 'Unauthorized');

  const game = await GamesService.createPlayerGame(userId, req.body);
  res.status(201).json(ApiResponse.success('Game created successfully', game));
});

export const requestSlotController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const userName = req.user?.email || 'Player';
  const { id: gameId } = req.params;
  const { position = 'MID' } = req.body;

  if (!userId) throw new ApiError(401, 'Unauthorized');
  if (req.user?.roleId !== 3) {
    throw new ApiError(403, 'Only player accounts can request or occupy match slots', 'FORBIDDEN_ROLE');
  }

  const game = await GamesRepository.getGameById(gameId);
  if (!game) throw new ApiError(404, 'Match not found');

  if (game.status === 'CANCELLED' || game.status === 'COMPLETED') {
    throw new ApiError(400, 'Cannot request slot for cancelled or completed match');
  }

  const reqStatus = game.status === 'FULL' ? 'WAITLISTED' : 'PENDING';
  const slotReq = await GamesRepository.createSlotRequest({
    gameId,
    userId,
    position,
    entryFee: Number(game.entry_fee || 0),
    status: reqStatus,
  });

  await GamesRepository.addActivityLog({
    gameId,
    actorId: userId,
    actorName: userName,
    actorRoleName: 'PLAYER',
    actionType: 'SLOT_REQUESTED',
    details: `Player requested slot in position ${position}`,
  });

  res.status(200).json(ApiResponse.success(
    reqStatus === 'WAITLISTED' ? 'Match is full. Added to waitlist!' : 'Slot request submitted for manager approval',
    slotReq
  ));
});

export const getActivityLogsController = asyncHandler(async (req: Request, res: Response) => {
  const { id: gameId } = req.params;
  const logs = await GamesRepository.getActivityLogs(gameId);
  res.status(200).json(ApiResponse.success('Activity logs retrieved', logs));
});

export const joinGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;
  const {
    position = 'MID',
    paymentMethod,
    walletPin,
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
  } = req.body || {};

  if (!userId) throw new ApiError(401, 'Unauthorized');
  if (req.user?.roleId !== 3) {
    throw new ApiError(403, 'Only player accounts can request or join match slots', 'FORBIDDEN_ROLE');
  }

  const result = await GamesService.joinGame(userId, gameId, position, {
    paymentMethod,
    walletPin,
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
  });
  res.status(200).json(ApiResponse.success('Joined match successfully', result));
});

export const switchTeamController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await GamesService.switchTeam(userId, gameId);
  res.status(200).json(ApiResponse.success('Switched team successfully', result));
});

export const leaveGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await GamesService.leaveGame(userId, gameId);
  res.status(200).json(ApiResponse.success('Left game successfully', result));
});

export const joinWaitlistController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;
  const { position = 'MID' } = req.body;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await GamesRepository.addToWaitlist(gameId, userId, position);
  res.status(200).json(ApiResponse.success('Added to game waitlist', result));
});

export const leaveWaitlistController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  await GamesRepository.removeFromWaitlist(gameId, userId);
  res.status(200).json(ApiResponse.success('Removed from game waitlist'));
});

export const updateGameScoreController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const roleId = req.user?.roleId || 3;
  const { id: gameId } = req.params;
  const { teamAScore, teamBScore, isFinal, eventText } = req.body;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  // Verify authorization: Only Admin, Club Manager, or Game Host can enter/update score
  const game = await GamesRepository.getGameById(gameId);
  if (!game) throw new ApiError(404, 'Match not found', 'MATCH_NOT_FOUND');

  if (game.status === 'CANCELLED') {
    throw new ApiError(400, 'Cannot enter or update score for a cancelled match', 'INVALID_MATCH_STATUS');
  }

  if (roleId === 1) {
    // Admin authorized
  } else if (roleId === 2) {
    // Check if manager manages this club
    const isManager = await GamesRepository.isClubManager(game.club_id, userId);
    if (!isManager) {
      throw new ApiError(403, 'You do not manage the club hosting this match', 'FORBIDDEN_CLUB_SCOPE');
    }
  } else if (roleId === 3) {
    // Player: only the match creator/host can enter score
    if (game.creator_id !== userId) {
      throw new ApiError(403, 'Only the host player or turf manager can submit match scores', 'FORBIDDEN_SCORE_AUTHORITY');
    }
  } else {
    throw new ApiError(403, 'Unauthorized to update match scores', 'FORBIDDEN');
  }

  const result = await updateLiveMatchScore({
    gameId,
    teamAScore: Number(teamAScore),
    teamBScore: Number(teamBScore),
    isFinal: Boolean(isFinal),
    eventText,
    updatedByUserId: userId,
  });

  res.status(200).json(ApiResponse.success('Score updated and broadcasted', result));
});

export const getGameVideosController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const videos = await GamesService.getAuthorizedVideos(userId, gameId, req.user?.roleId || 3);
  res.status(200).json(ApiResponse.success('Authorized match videos retrieved', videos));
});

export const cancelPlayerGameController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: gameId } = req.params;
  const { cancellationReason } = req.body || {};

  if (!userId) throw new ApiError(401, 'Unauthorized');

  const result = await GamesService.cancelPlayerGame(userId, gameId, cancellationReason);
  res.status(200).json(ApiResponse.success('Match cancelled by host player and refunds processed', result));
});
