import { z } from 'zod';

export const markNotificationReadSchema = z.object({
  params: z.object({
    id: z.string().min(1, 'Notification ID is required'),
  }),
});
