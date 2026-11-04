import { z } from "zod";

export const getMatchDetailsSchema = z.object({
  params: z.object({
    gameId: z.string().min(1, "Match Game ID is required"),
  }),
});

export const updateScoreSchema = z.object({
  params: z.object({
    gameId: z.string().min(1, "Match Game ID is required"),
  }),
  body: z.object({
    teamAScore: z.coerce
      .number()
      .int()
      .min(0, "Team A score must be a non-negative integer"),
    teamBScore: z.coerce
      .number()
      .int()
      .min(0, "Team B score must be a non-negative integer"),
    isFinal: z.boolean().default(false),
    eventText: z.string().optional(),
  }),
});

export const startMatchRecordingSchema = z.object({
  body: z.object({
    matchId: z.string().min(1, "Match ID is required"),
    matchTitle: z.string().optional(),
    cameraId: z.string().optional(),
    channel: z.coerce.number().int().min(1).max(32).optional(),
    durationSeconds: z.coerce.number().int().min(10).max(18000).optional(),
    rtspUrl: z.string().optional(),
  }),
});

export const stopMatchRecordingSchema = z.object({
  body: z.object({
    matchId: z.string().min(1, "Match ID is required"),
  }),
});

export const getMatchStatusSchema = z.object({
  params: z.object({
    matchId: z.string().min(1, "Match ID is required"),
  }),
});
