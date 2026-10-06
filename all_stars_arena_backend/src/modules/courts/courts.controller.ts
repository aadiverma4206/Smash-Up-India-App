import { Request, Response } from 'express';
import { CourtsService } from './courts.service.js';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';

export const getClubsController = asyncHandler(async (req: Request, res: Response) => {
  const city = req.query.city as string;
  const clubs = await CourtsService.getClubs(city);
  res.status(200).json(ApiResponse.success('Clubs retrieved successfully', clubs));
});

export const getCourtsController = asyncHandler(async (req: Request, res: Response) => {
  const clubId = req.query.clubId as string;
  const courts = await CourtsService.getCourts(clubId);
  res.status(200).json(ApiResponse.success('Courts retrieved successfully', courts));
});

export const getCourtByIdController = asyncHandler(async (req: Request, res: Response) => {
  const { id: courtId } = req.params;
  const court = await CourtsService.getCourtById(courtId);
  res.status(200).json(ApiResponse.success('Court details retrieved', court));
});

export const getAvailabilityController = asyncHandler(async (req: Request, res: Response) => {
  const { id: courtId } = req.params;
  const date = (req.query.date as string) || new Date().toISOString().split('T')[0];

  const availability = await CourtsService.checkAvailability(courtId, date);
  res.status(200).json(ApiResponse.success('Court slot availability retrieved', availability));
});

export const getPriceQuoteController = asyncHandler(async (req: Request, res: Response) => {
  const { id: courtId } = req.params;
  const date = (req.query.date as string) || new Date().toISOString().split('T')[0];
  const startTime = (req.query.startTime as string) || '18:00:00';

  const quote = await CourtsService.calculateQuote(courtId, date, startTime);
  res.status(200).json(ApiResponse.success('Court price quote calculated', quote));
});
