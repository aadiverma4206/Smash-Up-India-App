import { Response } from "express";
import { dbPool } from "../../config/db.config.js";
import bcrypt from "bcryptjs";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";

export const getAdminDashboardController = asyncHandler(
  async (_req: AuthenticatedRequest, res: Response) => {
    let totalUsers = 0;
    let totalManagers = 0;
    let totalPlayers = 0;
    let totalClubs = 0;
    let totalGames = 0;
    let totalRevenue = 0;
    let totalRefunds = 0;

    try {
      const usersRes = await dbPool.query(
        "SELECT COUNT(*) as total_users FROM public.users;",
      );
      totalUsers = Number(usersRes.rows[0]?.total_users || 0);
    } catch (_) {}

    try {
      const managersRes = await dbPool.query(
        "SELECT COUNT(*) as total_managers FROM public.users WHERE role_id = 2;",
      );
      totalManagers = Number(managersRes.rows[0]?.total_managers || 0);
    } catch (_) {}

    try {
      const playersRes = await dbPool.query(
        "SELECT COUNT(*) as total_players FROM public.users WHERE role_id = 3;",
      );
      totalPlayers = Number(playersRes.rows[0]?.total_players || 0);
    } catch (_) {}

    try {
      const clubsRes = await dbPool.query(
        "SELECT COUNT(*) as total_clubs FROM public.clubs;",
      );
      totalClubs = Number(clubsRes.rows[0]?.total_clubs || 0);
    } catch (_) {}

    try {
      const gamesRes = await dbPool.query(
        "SELECT COUNT(*) as total_games FROM public.games;",
      );
      totalGames = Number(gamesRes.rows[0]?.total_games || 0);
    } catch (_) {}

    try {
      const revenueRes = await dbPool.query(`
      SELECT COALESCE(SUM(amount_paid), 0) as total_revenue
      FROM public.court_bookings
      WHERE status IN ('CONFIRMED', 'COMPLETED', 'PAID');
    `);
      totalRevenue = Number(revenueRes.rows[0]?.total_revenue || 0);
    } catch (_) {}

    try {
      const refundsRes = await dbPool.query(`
      SELECT COALESCE(SUM(amount), 0) as total_refunds
      FROM public.transactions
      WHERE type ILIKE '%REFUND%';
    `);
      totalRefunds = Number(refundsRes.rows[0]?.total_refunds || 0);
    } catch (_) {
      try {
        const refundsResFallback = await dbPool.query(`
        SELECT COALESCE(SUM(amount), 0) as total_refunds
        FROM public.wallet_transactions
        WHERE description ILIKE '%REFUND%';
      `);
        totalRefunds = Number(refundsResFallback.rows[0]?.total_refunds || 0);
      } catch (_) {}
    }

    res.status(200).json(
      ApiResponse.success("Admin platform overview retrieved", {
        totalUsers,
        totalManagers,
        totalPlayers,
        totalClubs,
        totalGames,
        totalRevenue,
        totalRefunds,
        activeRecordings: totalGames,
      }),
    );
  },
);

export const getUsersController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { search, role, role_id, page = 1, limit = 50 } = req.query;

    const pageNum = Math.max(Number(page) || 1, 1);
    const limitNum = Math.min(Math.max(Number(limit) || 50, 1), 50); // Enforce max 50 per batch
    const offset = (pageNum - 1) * limitNum;

    let query = `
    SELECT u.id, u.name, u.email, u.phone, u.role_id, u.status, u.city, u.profile_image_url, u.created_at,
           ad.admin_type, ad.is_owner
    FROM public.users u
    LEFT JOIN public.admin_details ad ON ad.user_id = u.id
    WHERE 1=1
  `;
    const params: any[] = [];

    if (role_id) {
      params.push(Number(role_id));
      query += ` AND u.role_id = $${params.length}`;
    } else if (role) {
      const roleStr = String(role).toUpperCase();
      let targetRoleId = 3;
      if (roleStr === "MANAGER") targetRoleId = 2;
      if (roleStr === "ADMIN") targetRoleId = 1;
      if (roleStr === "PLAYER") targetRoleId = 3;
      params.push(targetRoleId);
      query += ` AND u.role_id = $${params.length}`;
    }

    if (search && String(search).trim() !== "") {
      const searchTerm = String(search).trim();
      params.push(`%${searchTerm}%`);
      query += ` AND (u.name ILIKE $${params.length} OR u.email ILIKE $${params.length} OR u.phone ILIKE $${params.length})`;
    }

    // Uses indexed columns (role_id, name) for fast sorting
    query += ` ORDER BY u.name ASC, u.id ASC`;

    params.push(limitNum);
    query += ` LIMIT $${params.length}`;

    params.push(offset);
    query += ` OFFSET $${params.length};`;

    const users = await dbPool.query(query, params);

    const mapped = users.rows.map((row) => ({
      ...row,
      profileImageUrl: row.profile_image_url,
      roleId: row.role_id,
      roleName:
        row.role_id === 1 ? "ADMIN" : row.role_id === 2 ? "MANAGER" : "PLAYER",
      createdAt: row.created_at,
    }));

    res.status(200).json(
      ApiResponse.success("User list retrieved", mapped, {
        page: pageNum,
        limit: limitNum,
        count: mapped.length,
        hasMore: mapped.length === limitNum,
      }),
    );
  },
);

export const getUserDetailsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const userRes = await dbPool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.role_id, u.status, u.city, u.profile_image_url, u.created_at, u.updated_at,
            ad.admin_type, ad.is_owner
     FROM public.users u
     LEFT JOIN public.admin_details ad ON ad.user_id = u.id
     WHERE u.id = $1 LIMIT 1;`,
      [id],
    );

    if (userRes.rows.length === 0) {
      throw new ApiError(404, "User not found");
    }

    const row = userRes.rows[0];
    const mapped = {
      ...row,
      profileImageUrl: row.profile_image_url,
      roleId: row.role_id,
      roleName:
        row.role_id === 1 ? "ADMIN" : row.role_id === 2 ? "MANAGER" : "PLAYER",
      createdAt: row.created_at,
    };

    res.status(200).json(ApiResponse.success("User details retrieved", mapped));
  },
);

export const suspendUserController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const adminId = req.user?.id;
    const adminName = req.user?.name || "Admin";
    const { id: targetUserId } = req.params;
    const { suspend, reason } = req.body; // true = suspend, false = active

    const newStatus = suspend ? "SUSPENDED" : "ACTIVE";

    try {
      const resDb = await dbPool.query(
        `UPDATE public.users SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, name, email, phone, role_id, status;`,
        [newStatus, targetUserId],
      );
      if (resDb.rows.length === 0) throw new ApiError(404, "User not found");
      const targetUser = resDb.rows[0];

      const actionType = suspend ? "USER_SUSPENDED" : "USER_REACTIVATED";
      const actionDetails = suspend
        ? `User ${targetUser.name} (${targetUser.email || targetUser.phone}) was SUSPENDED/BLOCKED by ${adminName}. Reason: ${reason || "Administrative Suspension"}`
        : `User ${targetUser.name} (${targetUser.email || targetUser.phone}) was REACTIVATED/UNLOCKED by ${adminName}.`;

      await dbPool.query(
        `INSERT INTO public.audit_logs (admin_id, admin_name, user_id, action, target, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6, $7);`,
        [
          adminId || null,
          adminName,
          targetUserId,
          actionType,
          targetUser.name,
          actionDetails,
          req.ip || "127.0.0.1",
        ],
      );

      res
        .status(200)
        .json(ApiResponse.success(`User account ${newStatus}`, targetUser));
    } catch (err: any) {
      if (err.message?.includes("OWNER PROTECTION") || err.code === "42501") {
        throw new ApiError(
          403,
          "OWNER PROTECTION: Founder/Owner account cannot be suspended",
          "OWNER_PROTECTION",
        );
      }
      throw err;
    }
  },
);

export const createManagerController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const adminId = req.user?.id;
    const adminName = req.user?.name || "Admin";
    const { name, email, phone, password, city, employeeCode } = req.body;

    if (!adminId) throw new ApiError(401, "Unauthorized");

    const pwdHash = await bcrypt.hash(password, 12);
    const dbRes = await dbPool.query(
      `SELECT public.create_manager_account($1, $2, $3, $4, $5, $6, $7) as user_id;`,
      [
        adminId,
        name,
        email,
        phone,
        pwdHash,
        city || "Raipur",
        employeeCode || null,
      ],
    );
    const newUserId = dbRes.rows[0]?.user_id;

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, user_id, action, target, details, ip_address)
     VALUES ($1, $2, $3, 'MANAGER_ACCOUNT_CREATED', $4, $5, $6);`,
      [
        adminId,
        adminName,
        newUserId,
        name,
        `Turf Manager account created for ${name} (${email}, ${phone}, city: ${city || "Raipur"}) by ${adminName}.`,
        req.ip || "127.0.0.1",
      ],
    );

    res.status(201).json(
      ApiResponse.success("Manager account created successfully", {
        userId: newUserId,
      }),
    );
  },
);

export const createAdminController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const ownerId = req.user?.id;
    const ownerName = req.user?.name || "Owner";
    const {
      name,
      email,
      phone,
      password,
      adminType = "OPS_ADMIN",
      city,
    } = req.body;

    if (!ownerId) throw new ApiError(401, "Unauthorized");

    const pwdHash = await bcrypt.hash(password, 12);
    const dbRes = await dbPool.query(
      `SELECT public.create_admin_account($1, $2, $3, $4, $5, $6, $7) as user_id;`,
      [ownerId, name, email, phone, pwdHash, adminType, city || "Raipur"],
    );
    const newUserId = dbRes.rows[0]?.user_id;

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, user_id, action, target, details, ip_address)
     VALUES ($1, $2, $3, 'ADMIN_ACCOUNT_CREATED', $4, $5, $6);`,
      [
        ownerId,
        ownerName,
        newUserId,
        name,
        `Admin account (${adminType}) created for ${name} (${email}) by Owner ${ownerName}.`,
        req.ip || "127.0.0.1",
      ],
    );

    res.status(201).json(
      ApiResponse.success("Admin account created successfully", {
        userId: newUserId,
      }),
    );
  },
);

export const approveClubController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const adminId = req.user?.id;
    const adminName = req.user?.name || "Admin";
    const { id: clubId } = req.params;

    const resDb = await dbPool.query(
      `UPDATE public.clubs SET status = 'ACTIVE' WHERE id = $1 RETURNING *;`,
      [clubId],
    );
    if (resDb.rows.length === 0) throw new ApiError(404, "Club not found");
    const club = resDb.rows[0];

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details, ip_address)
     VALUES ($1, $2, 'CLUB_VENUE_APPROVED', $3, $4, $5);`,
      [
        adminId || null,
        adminName,
        club.name || clubId,
        `Turf club venue "${club.name || clubId}" approved and set ACTIVE by ${adminName}.`,
        req.ip || "127.0.0.1",
      ],
    );

    res
      .status(200)
      .json(ApiResponse.success("Club venue approved and set ACTIVE", club));
  },
);

export const assignManagerController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { id: clubId } = req.params;
    const { managerUserId } = req.body;

    await dbPool.query(
      `INSERT INTO public.club_managers (club_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;`,
      [clubId, managerUserId],
    );

    res
      .status(200)
      .json(ApiResponse.success("Manager assigned to club successfully"));
  },
);

export const resolveDisputeController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const adminId = req.user?.id;
    const adminName = req.user?.name || "Admin";
    const { id: disputeId } = req.params;
    const { winnerOverride, scoreOverride, adjudicatorNotes } = req.body;

    if (!adminId) throw new ApiError(401, "Unauthorized");

    await dbPool.query(
      `SELECT public.resolve_match_dispute($1, $2, $3, $4, $5);`,
      [disputeId, adminId, winnerOverride, scoreOverride, adjudicatorNotes],
    );

    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details, ip_address)
     VALUES ($1, $2, 'MATCH_DISPUTE_RESOLVED', $3, $4, $5);`,
      [
        adminId,
        adminName,
        disputeId,
        `Match dispute ${disputeId} resolved by ${adminName}. Winner: ${winnerOverride || "N/A"}, Score: ${scoreOverride || "N/A"}. Notes: ${adjudicatorNotes || "None"}`,
        req.ip || "127.0.0.1",
      ],
    );

    res
      .status(200)
      .json(ApiResponse.success("Match dispute resolved successfully"));
  },
);

export const getAuditLogsController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { page = 1, limit = 40 } = req.query;

    const pageNum = Math.max(Number(page) || 1, 1);
    const limitNum = Math.min(Math.max(Number(limit) || 40, 1), 100);
    const offset = (pageNum - 1) * limitNum;

    const logs = await dbPool.query(
      "SELECT * FROM public.audit_logs ORDER BY created_at DESC LIMIT $1 OFFSET $2;",
      [limitNum, offset],
    );

    res.status(200).json(
      ApiResponse.success("Audit logs retrieved", logs.rows, {
        page: pageNum,
        limit: limitNum,
        count: logs.rows.length,
        hasMore: logs.rows.length === limitNum,
      }),
    );
  },
);
