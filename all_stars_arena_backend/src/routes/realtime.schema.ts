import { z } from 'zod';

export const sendRealtimeNotificationSchema = z.object({
  body: z.object({
    userId: z.string().optional(),
    title: z.string().min(1, 'Title is required'),
    message: z.string().min(1, 'Message is required'),
    type: z.string().optional(),
  }),
});

export const triggerLiveMatchEventSchema = z.object({
  body: z.object({
    gameId: z.string().min(1, 'Game ID is required'),
    teamAScore: z.coerce.number().int().min(0).optional(),
    teamBScore: z.coerce.number().int().min(0).optional(),
    eventText: z.string().optional(),
  }),
});
