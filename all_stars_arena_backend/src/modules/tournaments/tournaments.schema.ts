import { z } from "zod";

export const getTournamentsSchema = z.object({
  query: z.object({
    city: z.string().optional(),
  }),
});

export const getTournamentByIdSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Tournament ID is required"),
  }),
});

export const registerTeamSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Tournament ID is required"),
  }),
  body: z.object({
    teamName: z.string().min(2, "Team name is required"),
    logo: z.string().optional(),
  }),
});
