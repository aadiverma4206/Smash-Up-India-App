import { z } from "zod";

export const getCourtsSchema = z.object({
  query: z.object({
    clubId: z.string().optional(),
  }),
});

export const getCourtByIdSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Court ID is required"),
  }),
});

export const getAvailabilitySchema = z.object({
  params: z.object({
    id: z.string().min(1, "Court ID is required"),
  }),
  query: z.object({
    date: z.string().optional(),
  }),
});

export const getPriceQuoteSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Court ID is required"),
  }),
  query: z.object({
    date: z.string().optional(),
    startTime: z.string().optional(),
  }),
});
