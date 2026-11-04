import { z } from "zod";

const passwordRegex =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$/;

export const suspendUserSchema = z.object({
  params: z.object({
    id: z.string().min(1, "User ID is required"),
  }),
  body: z.object({
    suspend: z.boolean(),
  }),
});

export const createManagerSchema = z.object({
  body: z.object({
    name: z.string().min(2, "Name must be at least 2 characters"),
    email: z.string().email("Invalid email address"),
    phone: z
      .string()
      .regex(
        /^\+?[0-9]{10,15}$/,
        "Invalid phone number (E.164 format expected)",
      ),
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .regex(
        passwordRegex,
        "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
      ),
    city: z.string().optional().default("Raipur"),
    employeeCode: z.string().optional(),
  }),
});

export const createAdminSchema = z.object({
  body: z.object({
    name: z.string().min(2, "Name must be at least 2 characters"),
    email: z.string().email("Invalid email address"),
    phone: z
      .string()
      .regex(
        /^\+?[0-9]{10,15}$/,
        "Invalid phone number (E.164 format expected)",
      ),
    password: z
      .string()
      .min(8, "Password must be at least 8 characters")
      .regex(
        passwordRegex,
        "Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character",
      ),
    adminType: z
      .enum(["OPS_ADMIN", "FINANCE_ADMIN", "SUPPORT_ADMIN", "SUPER_ADMIN"])
      .default("OPS_ADMIN"),
    city: z.string().optional().default("Raipur"),
  }),
});

export const approveClubSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Club ID is required"),
  }),
});

export const assignManagerSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Club ID is required"),
  }),
  body: z.object({
    managerUserId: z.string().min(1, "Manager User ID is required"),
  }),
});

export const resolveDisputeSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Dispute ID is required"),
  }),
  body: z
    .object({
      winnerOverride: z.string().optional(),
      scoreOverride: z.string().optional(),
      adjudicatorNotes: z.string().optional(),
    })
    .optional(),
});

export const getUsersSchema = z.object({
  query: z.object({
    limit: z.coerce.number().int().min(1).max(200).default(100),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});

export const getAuditLogsSchema = z.object({
  query: z.object({
    limit: z.coerce.number().int().min(1).max(200).default(100),
    offset: z.coerce.number().int().min(0).default(0),
  }),
});
