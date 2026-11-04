import { z } from "zod";

export const updatePlayerProfileSchema = z.object({
  body: z.object({
    name: z.string().min(2, "Name must be at least 2 characters").optional(),
    bio: z.string().max(500, "Bio maximum 500 characters").optional(),
    city: z.string().optional(),
    avatarUrl: z.string().optional(),
    dateOfBirth: z.string().optional(),
    position: z
      .enum([
        "GK",
        "CB",
        "LB",
        "RB",
        "LWB",
        "RWB",
        "DEF",
        "CDM",
        "CM",
        "CAM",
        "LM",
        "RM",
        "MID",
        "ST",
        "CF",
        "LW",
        "RW",
        "FWD",
        "WING",
      ])
      .optional(),
    secondaryPosition: z
      .enum([
        "GK",
        "CB",
        "LB",
        "RB",
        "LWB",
        "RWB",
        "DEF",
        "CDM",
        "CM",
        "CAM",
        "LM",
        "RM",
        "MID",
        "ST",
        "CF",
        "LW",
        "RW",
        "FWD",
        "WING",
        "NONE",
      ])
      .nullable()
      .optional(),
    preferredFoot: z
      .preprocess(
        (val) => {
          if (typeof val !== "string") return val;
          const upper = val.trim().toUpperCase();
          if (upper === "RIGHT" || upper === "RIGHT_FOOTED" || val === "Right")
            return "Right";
          if (upper === "LEFT" || upper === "LEFT_FOOTED" || val === "Left")
            return "Left";
          if (upper === "BOTH" || upper === "AMBIDEXTROUS" || val === "Both")
            return "Both";
          return val;
        },
        z.enum(["Right", "Left", "Both"]),
      )
      .optional(),
    skillLevel: z
      .preprocess(
        (val) => {
          if (typeof val !== "string") return val;
          const upper = val.trim().toUpperCase();
          if (upper === "AMATEUR" || upper === "BEGINNER" || val === "Beginner")
            return "AMATEUR";
          if (
            upper === "SEMI_PRO" ||
            upper === "INTERMEDIATE" ||
            upper === "SEMI-PRO" ||
            upper === "SEMI PRO" ||
            val === "Intermediate"
          )
            return "SEMI_PRO";
          if (
            upper === "PRO" ||
            upper === "ADVANCED" ||
            upper === "PROFESSIONAL" ||
            val === "Advanced" ||
            val === "Professional"
          )
            return "PRO";
          return val;
        },
        z.enum([
          "AMATEUR",
          "SEMI_PRO",
          "PRO",
          "Beginner",
          "Intermediate",
          "Advanced",
          "Professional",
        ]),
      )
      .optional(),
  }),
});

export const getPlayerHistorySchema = z.object({
  query: z.object({
    limit: z.coerce.number().int().min(1).max(100).default(20),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});

export const getMyMatchesSchema = z.object({
  query: z.object({
    tab: z.string().default("UPCOMING"),
  }),
});

export const getPlayerRequestsSchema = z.object({
  query: z.object({
    status: z.string().default("ALL"),
  }),
});
