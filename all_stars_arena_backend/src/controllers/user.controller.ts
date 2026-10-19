import { Response } from "express";
import { ApiResponse } from "../utils/apiResponse.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../types/index.js";

export const getUserProfile = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const user = req.user;

    res.status(200).json(
      ApiResponse.success("User profile retrieved successfully", {
        profile: user,
      }),
    );
  },
);
