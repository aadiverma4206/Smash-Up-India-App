import { Request, Response } from 'express';
import { TournamentsService } from './tournaments.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getTournamentsController = asyncHandler(async (req: Request, res: Response) => {
  const city = req.query.city as string;
  const tournaments = await TournamentsService.getTournaments(city);
  res.status(200).json(ApiResponse.success('Tournaments retrieved', tournaments));
});

export const getTournamentByIdController = asyncHandler(async (req: Request, res: Response) => {
  const { id: tournamentId } = req.params;
  const details = await TournamentsService.getTournamentById(tournamentId);
  res.status(200).json(ApiResponse.success('Tournament details retrieved', details));
});

export const registerTeamController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.user?.id;
  const { id: tournamentId } = req.params;
  const { teamName, logo } = req.body;

  if (!userId) throw new ApiError(401, 'Unauthorized');
  if (!teamName) throw new ApiError(400, 'Team name is required');

  const team = await TournamentsService.registerTeam(userId, tournamentId, teamName, logo);
  res.status(201).json(ApiResponse.success('Team registered successfully', team));
});
