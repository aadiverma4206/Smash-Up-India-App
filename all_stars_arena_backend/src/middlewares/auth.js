import jwt from "jsonwebtoken";
import { env } from "../config/env.js";
import { dbPool } from "../config/db.js";
import { ApiError } from "../utils/apiResponse.js";

export const requireAuth = async (req, _res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return next(
      new ApiError(401, "Authentication token required", "UNAUTHORIZED"),
    );
  }

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET);

    // Verify user in PostgreSQL
    const userRes = await dbPool.query(
      `SELECT u.id, u.email, u.phone, u.role_id, u.status,
              ad.admin_type, ad.is_owner
       FROM public.users u
       LEFT JOIN public.admin_details ad ON ad.user_id = u.id
       WHERE u.id = $1;`,
      [decoded.id],
    );

    if (userRes.rows.length === 0) {
      return next(
        new ApiError(401, "User account not found", "USER_NOT_FOUND"),
      );
    }

    const user = userRes.rows[0];

    if (user.status === "SUSPENDED") {
      return next(
        new ApiError(
          403,
          "Account is suspended. Access denied.",
          "ACCOUNT_SUSPENDED",
        ),
      );
    }

    req.user = {
      id: user.id,
      email: user.email,
      phone: user.phone,
      roleId: user.role_id, // 1=ADMIN, 2=MANAGER, 3=PLAYER
      adminType: user.admin_type || null, // SUPER_ADMIN, OPS_ADMIN, FINANCE_ADMIN
      isOwner: Boolean(user.is_owner),
    };

    next();
  } catch (err) {
    return next(new ApiError(401, "Invalid or expired token", "INVALID_TOKEN"));
  }
};
