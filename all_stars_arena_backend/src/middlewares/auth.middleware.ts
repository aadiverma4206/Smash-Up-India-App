import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.config.js';
import { dbPool } from '../config/db.config.js';
import { ApiError } from '../utils/apiResponse.js';
import { AuthenticatedRequest, UserPayload } from '../types/index.js';

export const authenticateToken = async (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers['authorization'];
  const token = (authHeader && authHeader.split(' ')[1]) || (req.query?.token as string);

  if (!token) {
    return next(new ApiError(401, 'Authentication token required', 'UNAUTHORIZED'));
  }

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as UserPayload;

    // Check user status in DB
    const userRes = await dbPool.query(
      `SELECT u.id, u.email, u.phone, u.role_id, u.status,
              ad.admin_type, ad.is_owner
       FROM public.users u
       LEFT JOIN public.admin_details ad ON ad.user_id = u.id
       WHERE u.id = $1;`,
      [decoded.id]
    );

    if (userRes.rows.length === 0) {
      return next(new ApiError(401, 'User account not found', 'USER_NOT_FOUND'));
    }

    const user = userRes.rows[0];

    if (user.status === 'SUSPENDED') {
      return next(
        new ApiError(403, 'Account is suspended. Access denied.', 'ACCOUNT_SUSPENDED')
      );
    }

    req.user = {
      id: user.id,
      email: user.email,
      phone: user.phone,
      roleId: user.role_id,
      adminType: user.admin_type || null,
      isOwner: Boolean(user.is_owner),
    };

    next();
  } catch (err: any) {
    if (err instanceof ApiError) {
      return next(err);
    }
    if (err.name === 'TokenExpiredError') {
      return next(
        new ApiError(401, 'Authentication token has expired. Please log in again.', 'TOKEN_EXPIRED')
      );
    }
    if (err.name === 'JsonWebTokenError' || err.name === 'NotBeforeError') {
      return next(new ApiError(401, 'Invalid authentication token provided', 'INVALID_TOKEN'));
    }
    return next(err);
  }
};

/**
 * RBAC Guard: Restrict access by Role ID (1=ADMIN, 2=MANAGER, 3=PLAYER)
 */
export const requireRole = (allowedRoleIds: number[]) => {
  return (req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
    if (!req.user || !allowedRoleIds.includes(req.user.roleId)) {
      return next(
        new ApiError(
          403,
          'Forbidden: You do not have permission to perform this action',
          'FORBIDDEN_ROLE'
        )
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
          'Forbidden: Specific admin privilege required',
          'FORBIDDEN_ADMIN_TYPE'
        )
      );
    }
    next();
  };
};

/**
 * Require Platform Owner
 */
export const requireOwner = (req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
  if (!req.user || !req.user.isOwner) {
    return next(
      new ApiError(
        403,
        'Forbidden: Only the Platform Owner can perform this action',
        'FORBIDDEN_OWNER_ONLY'
      )
    );
  }
};

/**
 * Optional Authentication: Attaches req.user if token is valid, but allows guest/unauthenticated requests through
 */
export const optionalAuthenticateToken = async (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers['authorization'];
  const token = (authHeader && authHeader.split(' ')[1]) || (req.query?.token as string);

  if (!token) {
    return next();
  }

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as UserPayload;
    const userRes = await dbPool.query(
      `SELECT u.id, u.email, u.phone, u.role_id, u.status,
              ad.admin_type, ad.is_owner
       FROM public.users u
       LEFT JOIN public.admin_details ad ON ad.user_id = u.id
       WHERE u.id = $1;`,
      [decoded.id]
    );

    if (userRes.rows.length > 0 && userRes.rows[0].status !== 'SUSPENDED') {
      const user = userRes.rows[0];
      req.user = {
        id: user.id,
        email: user.email,
        phone: user.phone,
        roleId: user.role_id,
        adminType: user.admin_type || null,
        isOwner: Boolean(user.is_owner),
      };
    }
  } catch (_) {
    // Non-fatal for optional auth
  }
  next();
};

