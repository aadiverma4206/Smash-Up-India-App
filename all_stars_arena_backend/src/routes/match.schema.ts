import { z } from 'zod';

export const getMatchDetailsSchema = z.object({
  params: z.object({
    gameId: z.string().min(1, 'Match Game ID is required'),
  }),
});

export const updateScoreSchema = z.object({
  params: z.object({
    gameId: z.string().min(1, 'Match Game ID is required'),
  }),
  body: z.object({
    teamAScore: z.coerce.number().int().min(0, 'Team A score must be a non-negative integer'),
    teamBScore: z.coerce.number().int().min(0, 'Team B score must be a non-negative integer'),
    isFinal: z.boolean().default(false),
    eventText: z.string().optional(),
  }),
});
