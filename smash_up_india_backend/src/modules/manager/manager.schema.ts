import { z } from "zod";

export const updateClubSchema = z.object({
  body: z.object({
    name: z.string().min(2).optional(),
    address: z.string().optional(),
    city: z.string().optional(),
    openTime: z.string().optional(),
    closeTime: z.string().optional(),
    description: z.string().optional(),
  }),
});

export const createCourtSchema = z.object({
  body: z.object({
    clubId: z.string().min(1, "Club ID is required"),
    name: z.string().min(2, "Court name is required"),
    environment: z.enum(["Indoor", "Outdoor"]).default("Outdoor"),
    surface: z
      .enum(["3G Turf", "Synthetic Grass", "Natural Grass", "Rubber Futsal"])
      .default("3G Turf"),
    basePrice: z.number().min(100, "Base price minimum ₹100"),
    peakMultiplier: z.number().min(1.0).default(1.5),
    weekendMultiplier: z.number().min(1.0).default(1.75),
  }),
});

export const updateCourtPricingSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Court ID is required"),
  }),
  body: z.object({
    basePrice: z.number().min(0).optional(),
    status: z.enum(["AVAILABLE", "BLOCKED", "MAINTENANCE"]).optional(),
    peakMultiplier: z.number().min(1.0).optional(),
    weekendMultiplier: z.number().min(1.0).optional(),
    peakWindowStart: z.string().optional(),
    peakWindowEnd: z.string().optional(),
  }),
});

export const simulatePricingSchema = z.object({
  body: z.object({
    courtId: z.string().min(1, "Court ID is required"),
    bookingDate: z.string().min(1, "Booking date is required"),
    startTime: z.string().min(1, "Start time is required"),
  }),
});

export const createGameSchema = z.object({
  body: z.object({
    title: z.string().min(3, "Game title is required"),
    clubId: z.string().min(1, "Club ID is required"),
    courtId: z.string().min(1, "Court ID is required"),
    format: z
      .enum([
        "1v1",
        "2v2",
        "3v3",
        "4v4",
        "5v5",
        "6v6",
        "7v7",
        "8v8",
        "9v9",
        "11v11",
      ])
      .default("11v11"),
    maxPlayers: z.number().int().min(2).max(22),
    entryFee: z.number().min(0).max(200000),
    matchDate: z.string().min(1, "Match date is required"),
    startTime: z.string().min(1, "Start time is required"),
    endTime: z.string().min(1, "End time is required"),
    privacy: z.enum(["PUBLIC", "PRIVATE"]).default("PUBLIC"),
    description: z.string().optional(),
  }),
});

export const updateGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z.object({
    title: z.string().min(3).optional(),
    format: z
      .enum([
        "1v1",
        "2v2",
        "3v3",
        "4v4",
        "5v5",
        "6v6",
        "7v7",
        "8v8",
        "9v9",
        "11v11",
      ])
      .optional(),
    maxPlayers: z.number().int().min(2).max(22).optional(),
    entryFee: z.number().min(0).max(200000).optional(),
    matchDate: z.string().optional(),
    startTime: z.string().optional(),
    endTime: z.string().optional(),
    privacy: z.enum(["PUBLIC", "PRIVATE"]).optional(),
    status: z.string().optional(),
    description: z.string().optional(),
  }),
});

export const rescheduleGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z.object({
    matchDate: z.string().min(1, "matchDate is required"),
    startTime: z.string().min(1, "startTime is required"),
    endTime: z.string().min(1, "endTime is required"),
    courtId: z.string().optional(),
    reason: z.string().optional(),
  }),
});

export const startGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});

export const completeGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z
    .object({
      teamAScore: z.coerce.number().int().min(0).optional(),
      teamBScore: z.coerce.number().int().min(0).optional(),
    })
    .optional(),
});

export const cancelGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z
    .object({
      cancellationReason: z.string().optional(),
    })
    .optional(),
});

export const approveSlotRequestSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Request ID is required"),
  }),
});

export const rejectSlotRequestSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Request ID is required"),
  }),
  body: z
    .object({
      rejectionReason: z.string().optional(),
    })
    .optional(),
});

export const getClubMatchesSchema = z.object({
  query: z.object({
    tab: z.string().default("TODAY"),
  }),
});
