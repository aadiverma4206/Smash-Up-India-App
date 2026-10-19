import { Response, NextFunction } from "express";
import { ApiError } from "../utils/apiResponse.js";
import { AuthenticatedRequest } from "../types/index.js";

/**
 * Require specific Role IDs (1=ADMIN, 2=MANAGER, 3=PLAYER)
 */
export const requireRole = (allowedRoleIds: number[]) => {
  return (req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
    if (!req.user || !allowedRoleIds.includes(req.user.roleId)) {
      return next(
        new ApiError(
          403,
          "Forbidden: You do not have permission to perform this action",
          "FORBIDDEN_ROLE",
        ),
      );
    }
    next();
  };
};

/**
 * Require specific Admin Types (SUPER_ADMIN, OPS_ADMIN, FINANCE_ADMIN)
 */
export const requireAdminType = (allowedTypes: string[]) => {
  return (req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
    if (
      !req.user ||
      req.user.roleId !== 1 ||
      !req.user.adminType ||
      !allowedTypes.includes(req.user.adminType)
    ) {
      return next(
        new ApiError(
          403,
          "Forbidden: Specific admin privilege required",
          "FORBIDDEN_ADMIN_TYPE",
        ),
      );
    }
    next();
  };
};

/**
 * Require Platform Owner
 */
export const requireOwner = (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
) => {
  if (!req.user || !req.user.isOwner) {
    return next(
      new ApiError(
        403,
        "Forbidden: Only the Platform Owner can perform this action",
        "FORBIDDEN_OWNER_ONLY",
      ),
    );
  }
  next();
};
