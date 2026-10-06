import { Response } from 'express';
import { dbPool } from '../../config/db.config.js';
import bcrypt from 'bcryptjs';
import { ApiResponse, ApiError } from '../../utils/apiResponse.js';
import { asyncHandler } from '../../utils/asyncHandler.js';
import { AuthenticatedRequest } from '../../types/index.js';

export const getAdminDashboardController = asyncHandler(async (_req: AuthenticatedRequest, res: Response) => {
  const usersRes = await dbPool.query('SELECT COUNT(*) as total_users FROM public.users;');
  const clubsRes = await dbPool.query('SELECT COUNT(*) as total_clubs FROM public.clubs;');
  const gamesRes = await dbPool.query('SELECT COUNT(*) as total_games FROM public.games;');
  const revenueRes = await dbPool.query("SELECT COALESCE(SUM(amount_paid), 0) as total_revenue FROM public.court_bookings WHERE status = 'CONFIRMED';");

  res.status(200).json(
    ApiResponse.success('Admin platform overview retrieved', {
      totalUsers: Number(usersRes.rows[0]?.total_users || 0),
      totalClubs: Number(clubsRes.rows[0]?.total_clubs || 0),
      totalGames: Number(gamesRes.rows[0]?.total_games || 0),
      totalRevenueRupees: Number(revenueRes.rows[0]?.total_revenue || 0),
    })
  );
});

export const getUsersController = asyncHandler(async (_req: AuthenticatedRequest, res: Response) => {
  const users = await dbPool.query(
    `SELECT u.id, u.name, u.email, u.phone, u.role_id, u.status, u.city, u.created_at,
            ad.admin_type, ad.is_owner
     FROM public.users u
     LEFT JOIN public.admin_details ad ON ad.user_id = u.id
     ORDER BY u.created_at DESC LIMIT 100;`
  );
  res.status(200).json(ApiResponse.success('User list retrieved', users.rows));
});

export const suspendUserController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: targetUserId } = req.params;
  const { suspend } = req.body; // true = suspend, false = active

  const newStatus = suspend ? 'SUSPENDED' : 'ACTIVE';

  try {
    const resDb = await dbPool.query(
      `UPDATE public.users SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, status;`,
      [newStatus, targetUserId]
    );
    if (resDb.rows.length === 0) throw new ApiError(404, 'User not found');
    res.status(200).json(ApiResponse.success(`User account ${newStatus}`, resDb.rows[0]));
  } catch (err: any) {
    if (err.message?.includes('OWNER PROTECTION') || err.code === '42501') {
      throw new ApiError(403, 'OWNER PROTECTION: Founder/Owner account cannot be suspended', 'OWNER_PROTECTION');
    }
    throw err;
  }
});

export const createManagerController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const adminId = req.user?.id;
  const { name, email, phone, password, city, employeeCode } = req.body;

  if (!adminId) throw new ApiError(401, 'Unauthorized');

  const pwdHash = await bcrypt.hash(password, 12);
  const dbRes = await dbPool.query(
    `SELECT public.create_manager_account($1, $2, $3, $4, $5, $6, $7) as user_id;`,
    [adminId, name, email, phone, pwdHash, city || 'Raipur', employeeCode || null]
  );

  res.status(201).json(ApiResponse.success('Manager account created successfully', { userId: dbRes.rows[0]?.user_id }));
});

export const createAdminController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const ownerId = req.user?.id;
  const { name, email, phone, password, adminType = 'OPS_ADMIN', city } = req.body;

  if (!ownerId) throw new ApiError(401, 'Unauthorized');

  const pwdHash = await bcrypt.hash(password, 12);
  const dbRes = await dbPool.query(
    `SELECT public.create_admin_account($1, $2, $3, $4, $5, $6, $7) as user_id;`,
    [ownerId, name, email, phone, pwdHash, adminType, city || 'Raipur']
  );

  res.status(201).json(ApiResponse.success('Admin account created successfully', { userId: dbRes.rows[0]?.user_id }));
});

export const approveClubController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: clubId } = req.params;
  const resDb = await dbPool.query(
    `UPDATE public.clubs SET status = 'ACTIVE' WHERE id = $1 RETURNING *;`,
    [clubId]
  );
  res.status(200).json(ApiResponse.success('Club venue approved and set ACTIVE', resDb.rows[0]));
});

export const assignManagerController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const { id: clubId } = req.params;
  const { managerUserId } = req.body;

  await dbPool.query(
    `INSERT INTO public.club_managers (club_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;`,
    [clubId, managerUserId]
  );

  res.status(200).json(ApiResponse.success('Manager assigned to club successfully'));
});

export const resolveDisputeController = asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
  const adminId = req.user?.id;
  const { id: disputeId } = req.params;
  const { winnerOverride, scoreOverride, adjudicatorNotes } = req.body;

  if (!adminId) throw new ApiError(401, 'Unauthorized');

  await dbPool.query(
    `SELECT public.resolve_match_dispute($1, $2, $3, $4, $5);`,
    [disputeId, adminId, winnerOverride, scoreOverride, adjudicatorNotes]
  );

  res.status(200).json(ApiResponse.success('Match dispute resolved successfully'));
});

export const getAuditLogsController = asyncHandler(async (_req: AuthenticatedRequest, res: Response) => {
  const logs = await dbPool.query('SELECT * FROM public.audit_logs ORDER BY created_at DESC LIMIT 100;');
  res.status(200).json(ApiResponse.success('Audit logs retrieved', logs.rows));
});
