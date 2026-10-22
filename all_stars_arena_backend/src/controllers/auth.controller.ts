import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt, { SignOptions } from "jsonwebtoken";
import { dbPool } from "../config/db.config.js";
import { env } from "../config/env.config.js";
import { createAndSendOTP, verifyOTP } from "../services/otp.service.js";
import { ApiResponse, ApiError } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../types/index.js";

export const sendOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const { email, purpose = "LOGIN" } = req.body;

    if (!email) {
      throw new ApiError(400, "Email is required to send OTP");
    }

    const result = await createAndSendOTP(email, purpose);
    res.status(200).json(ApiResponse.success(result.message));
  },
);

export const verifyOtpController = asyncHandler(
  async (req: Request, res: Response) => {
    const { email, otp, purpose = "LOGIN" } = req.body;

    if (!email || !otp) {
      throw new ApiError(400, "Email and OTP are required");
    }

    await verifyOTP(email, otp, purpose);
    res.status(200).json(ApiResponse.success("OTP verified successfully"));
  },
);

export const registerPlayerController = asyncHandler(
  async (req: Request, res: Response) => {
    const { name, email, phone, password, city = "Raipur" } = req.body;

    if (!email || !phone || !password) {
      throw new ApiError(400, "Email, phone, and password are required");
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const dbRes = await dbPool.query(
      "SELECT public.register_player($1, $2, $3, $4, $5) as user_id;",
      [name || null, email, phone, passwordHash, city],
    );

    const userId = dbRes.rows[0]?.user_id;

    const signOptions: SignOptions = { expiresIn: "7d" };
    const token = jwt.sign(
      { id: userId, email, roleId: 3 },
      env.JWT_SECRET,
      signOptions,
    );

    res.status(201).json(
      ApiResponse.success("Player registered successfully", {
        userId,
        name,
        email,
        phone,
        token,
      }),
    );
  },
);

export const loginPlayerController = asyncHandler(
  async (req: Request, res: Response) => {
    const { identifier, password } = req.body;

    if (!identifier || !password) {
      throw new ApiError(
        400,
        "Identifier (Email/Phone) and password are required",
      );
    }

    const userRes = await dbPool.query(
      "SELECT * FROM public.get_login_user($1);",
      [identifier.trim()],
    );

    if (userRes.rows.length === 0) {
      throw new ApiError(401, "Invalid credentials");
    }

    const user = userRes.rows[0];

    if (user.status === "SUSPENDED") {
      throw new ApiError(403, "Account is suspended. Please contact admin.");
    }

    if (user.locked_until && new Date(user.locked_until) > new Date()) {
      throw new ApiError(
        429,
        `Account is locked until ${user.locked_until}. Try again later.`,
      );
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      await dbPool.query("SELECT public.record_failed_login($1);", [user.id]);
      throw new ApiError(401, "Invalid credentials");
    }

    await dbPool.query("SELECT public.record_successful_login($1);", [user.id]);

    const signOptions: SignOptions = { expiresIn: "7d" };
    const token = jwt.sign(
      { id: user.id, email: user.email, roleId: user.role_id },
      env.JWT_SECRET,
      signOptions,
    );

    const playerRes = await dbPool.query(
      "SELECT * FROM public.player_details WHERE user_id = $1;",
      [user.id],
    );

    res.status(200).json(
      ApiResponse.success("Login successful", {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          roleId: user.role_id,
          playerDetails: playerRes.rows[0] || null,
        },
        token,
      }),
    );
  },
);

export const logoutController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    if (userId) {
      await dbPool.query("SELECT public.logout_all_sessions($1);", [userId]);
    }
    res.status(200).json(ApiResponse.success("Logged out successfully"));
  },
);
