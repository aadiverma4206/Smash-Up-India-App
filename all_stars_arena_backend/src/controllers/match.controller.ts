import { Request, Response } from 'express';
import {
  getLiveMatches,
  getMatchDetails,
  updateLiveMatchScore,
} from '../services/match.service.js';
import { ApiResponse, ApiError } from '../utils/apiResponse.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../types/index.js';

export const getLiveMatchesController = asyncHandler(async (_req: Request, res: Response) => {
  const matches = await getLiveMatches();
  res.status(200).json(ApiResponse.success('Live matches retrieved successfully', matches));
});

export const getMatchDetailsController = asyncHandler(async (req: Request, res: Response) => {
  const { gameId } = req.params;
  if (!gameId) throw new ApiError(400, 'Match Game ID is required');

  const details = await getMatchDetails(gameId);
  res.status(200).json(ApiResponse.success('Match details retrieved successfully', details));
});

export const updateScoreController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { gameId } = req.params;
  const { teamAScore, teamBScore, isFinal, eventText } = req.body;
  const updatedByUserId = req.user?.id;

  if (!gameId) throw new ApiError(400, 'Match Game ID is required');
  if (teamAScore === undefined || teamBScore === undefined) {
    throw new ApiError(400, 'Team A score and Team B score are required');
  }

  const result = await updateLiveMatchScore({
    gameId,
    teamAScore: Number(teamAScore),
    teamBScore: Number(teamBScore),
    isFinal: Boolean(isFinal),
    eventText,
    updatedByUserId,
  });

  res
    .status(200)
    .json(ApiResponse.success('Match score updated and broadcasted via Real-Time Socket', result));
});
