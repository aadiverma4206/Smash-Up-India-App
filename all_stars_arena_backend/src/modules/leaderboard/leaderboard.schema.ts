import { z } from 'zod';

export const getLeaderboardSchema = z.object({
  query: z.object({
    city: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(50),
  }),
});
