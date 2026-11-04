import { z } from "zod";

export const getGamesSchema = z.object({
  query: z.object({
    city: z.string().optional(),
    format: z.string().optional(),
    skill: z.string().optional(),
    date: z.string().optional(),
    entryFee: z.coerce.number().min(0).optional(),
    status: z.string().optional(),
    privacy: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});

export const getGameByIdSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});

export const getActivityLogsSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});

export const createPlayerGameSchema = z.object({
  body: z.object({
    title: z
      .string()
      .min(3, "Game title is required")
      .default("Pickle Match"),
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
    maxPlayers: z.number().int().min(2).max(22).optional(),
    reservePlayersCount: z.number().int().min(0).max(10).default(2),
    entryFee: z.number().min(0, "Entry fee cannot be negative").default(200),
    skillRequirement: z
      .enum([
        "AMATEUR",
        "BEGINNER",
        "INTERMEDIATE",
        "SEMI_PRO",
        "ADVANCED",
        "PRO",
        "PROFESSIONAL",
        "ANY",
      ])
      .default("INTERMEDIATE"),
    privacy: z.enum(["PUBLIC", "PRIVATE"]).default("PUBLIC"),
    matchDate: z.string().min(1, "Match date is required"),
    startTime: z.string().min(1, "Start time is required"),
    endTime: z.string().min(1, "End time is required"),
    description: z.string().optional(),
    paymentMethod: z.string().optional(),
    paymentReference: z.string().optional(),
    walletPin: z.string().optional(),
    paymentOrderId: z.string().optional(),
    razorpayPaymentId: z.string().optional(),
    razorpayOrderId: z.string().optional(),
    razorpaySignature: z.string().optional(),
  }),
});

export const requestSlotSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z
    .object({
      position: z.string().default("MID"),
    })
    .optional(),
});

export const joinGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z
    .object({
      position: z.string().default("MID"),
    })
    .optional(),
});

export const switchTeamSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});

export const leaveGameSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});

export const joinWaitlistSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
  body: z
    .object({
      position: z.string().default("MID"),
    })
    .optional(),
});

export const leaveWaitlistSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});

export const updateGameScoreSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
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

export const getGameVideosSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Game ID is required"),
  }),
});
