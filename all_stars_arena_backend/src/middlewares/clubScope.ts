import { Response, NextFunction } from "express";
import { dbPool } from "../config/db.config.js";
import { ApiError } from "../utils/apiResponse.js";
import { AuthenticatedRequest } from "../types/index.js";

export const clubScope = async (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
) => {
  try {
    const user = req.user;
    if (!user) {
      return next(new ApiError(401, "Authentication required", "UNAUTHORIZED"));
    }

    if (user.roleId === 1) {
      return next();
    }

    if (user.roleId === 2) {
      const clubId =
        req.params.clubId ||
        req.body.clubId ||
        req.query.clubId ||
        req.params.id;

      if (!clubId) {
        return next(
          new ApiError(
            400,
            "Club ID is required for scoping",
            "MISSING_CLUB_ID",
          ),
        );
      }

      const checkRes = await dbPool.query(
        `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
        [clubId, user.id],
      );

      if (checkRes.rows.length === 0) {
        return next(
          new ApiError(
            403,
            "Forbidden: You are not authorized to manage this club",
            "FORBIDDEN_CLUB_SCOPE",
          ),
        );
      }

      return next();
    }

    return next(
      new ApiError(
        403,
        "Forbidden: Role not authorized for club management",
        "FORBIDDEN",
      ),
    );
  } catch (err) {
    return next(err);
  }
};
