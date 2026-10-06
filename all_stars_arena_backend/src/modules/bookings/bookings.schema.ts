import { z } from 'zod';

export const createBookingSchema = z.object({
  body: z.object({
    courtId: z.string().min(1, 'Court ID is required'),
    bookingDate: z.string().min(1, 'Booking date is required'),
    startTime: z.string().min(1, 'Start time is required'),
    endTime: z.string().min(1, 'End time is required'),
  }),
});

export const cancelBookingSchema = z.object({
  params: z.object({
    id: z.string().min(1, 'Booking ID is required'),
  }),
  body: z
    .object({
      reason: z.string().optional(),
    })
    .optional(),
});
