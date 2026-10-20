import { dbPool } from "../../config/db.config.js";

export class ManagerRepository {
  static async getManagerClub(userId?: string) {
    if (userId) {
      const res = await dbPool.query(
        `SELECT clb.* FROM public.clubs clb
         JOIN public.club_managers cm ON cm.club_id = clb.id
         WHERE cm.user_id = $1 LIMIT 1;`,
        [userId],
      );
      if (res.rows[0]) return res.rows[0];
    }

    const adminRes = await dbPool.query(
      `SELECT clb.* FROM public.clubs clb WHERE clb.id = 'all_stars_arena_club' LIMIT 1;`,
    );
    if (adminRes.rows[0]) return adminRes.rows[0];

    const fallbackRes = await dbPool.query(
      `SELECT * FROM public.clubs ORDER BY created_at ASC LIMIT 1;`,
    );
    return fallbackRes.rows[0] || null;
  }

  static async getDashboardStats(clubId: string) {
    const gamesRes = await dbPool.query(
      `SELECT COUNT(*) as total_games FROM public.games WHERE club_id = $1;`,
      [clubId],
    );
    const bookingsRes = await dbPool.query(
      `SELECT COUNT(*) as total_bookings, COALESCE(SUM(amount_paid), 0) as total_revenue
       FROM public.court_bookings WHERE club_id = $1 AND status = 'CONFIRMED';`,
      [clubId],
    );
    const courtsRes = await dbPool.query(
      `SELECT COUNT(*) as total_courts FROM public.courts WHERE club_id = $1;`,
      [clubId],
    );
    const cctvRes = await dbPool.query(
      `SELECT COUNT(*) as total_cameras,
              COUNT(*) FILTER (WHERE status = 'ONLINE') as online_cameras,
              COUNT(*) FILTER (WHERE status = 'RECORDING') as recording_cameras
       FROM public.cctv_cameras WHERE club_id = $1;`,
      [clubId],
    );

    return {
      totalGames: Number(gamesRes.rows[0]?.total_games || 0),
      totalBookings: Number(bookingsRes.rows[0]?.total_bookings || 0),
      totalRevenueRupees: Number(bookingsRes.rows[0]?.total_revenue || 0),
      totalCourts: Number(courtsRes.rows[0]?.total_courts || 0),
      cctvStats: {
        totalCameras: Number(cctvRes.rows[0]?.total_cameras || 0),
        onlineCameras: Number(cctvRes.rows[0]?.online_cameras || 0),
        recordingCameras: Number(cctvRes.rows[0]?.recording_cameras || 0),
      },
    };
  }

  static async createCourt(data: {
    clubId: string;
    name: string;
    environment: string;
    surface: string;
    basePrice: number;
    peakMultiplier: number;
    weekendMultiplier: number;
  }) {
    const query = `
      INSERT INTO public.courts
      (club_id, name, environment, surface, base_price, peak_multiplier, weekend_multiplier, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'AVAILABLE')
      RETURNING *;
    `;
    const res = await dbPool.query(query, [
      data.clubId,
      data.name,
      data.environment,
      data.surface,
      data.basePrice,
      data.peakMultiplier,
      data.weekendMultiplier,
    ]);
    return res.rows[0];
  }

  static async updateCourtPricing(
    courtId: string,
    data: {
      basePrice?: number;
      peakMultiplier?: number;
      weekendMultiplier?: number;
      peakWindowStart?: string;
      peakWindowEnd?: string;
    },
  ) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (data.basePrice !== undefined) {
      fields.push(`base_price = $${idx++}`);
      values.push(data.basePrice);
    }
    if (data.peakMultiplier !== undefined) {
      fields.push(`peak_multiplier = $${idx++}`);
      values.push(data.peakMultiplier);
    }
    if (data.weekendMultiplier !== undefined) {
      fields.push(`weekend_multiplier = $${idx++}`);
      values.push(data.weekendMultiplier);
    }
    if (data.peakWindowStart) {
      fields.push(`peak_window_start = $${idx++}`);
      values.push(data.peakWindowStart);
    }
    if (data.peakWindowEnd) {
      fields.push(`peak_window_end = $${idx++}`);
      values.push(data.peakWindowEnd);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(courtId);

    const res = await dbPool.query(
      `UPDATE public.courts SET ${fields.join(", ")} WHERE id = $${idx} RETURNING *;`,
      values,
    );
    return res.rows[0];
  }

  static async createGame(data: {
    title: string;
    clubId?: string;
    courtId: string;
    creatorId: string;
    format: string;
    maxPlayers: number;
    entryFee: number;
    matchDate: string;
    startTime: string;
    endTime: string;
    privacy: string;
    description?: string;
  }) {
    const normalizedCourtId = (data.courtId || "").toLowerCase().includes("2")
      ? "court_2"
      : "court_1";
    const query = `
      INSERT INTO public.games
      (title, club_id, court_id, creator_id, creator_role_name, created_by_player, format, max_players, entry_fee, match_date, start_time, end_time, privacy, status, approval_status, manager_id, description)
      VALUES ($1, 'all_stars_arena_club', $2, $3, 'MANAGER', false, $4, $5, $6, $7, $8, $9, $10, 'OPEN_FOR_JOINING', 'APPROVED', $3, $11)
      RETURNING *;
    `;
    const res = await dbPool.query(query, [
      data.title,
      normalizedCourtId,
      data.creatorId,
      data.format,
      data.maxPlayers,
      data.entryFee,
      data.matchDate,
      data.startTime,
      data.endTime,
      data.privacy,
      data.description || null,
    ]);
    return res.rows[0];
  }

  static async updateGame(
    gameId: string,
    data: Partial<{
      title: string;
      courtId: string;
      format: string;
      maxPlayers: number;
      entryFee: number;
      matchDate: string;
      startTime: string;
      endTime: string;
      description: string;
      privacy: string;
    }>,
  ) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (data.title !== undefined) {
      fields.push(`title = $${idx++}`);
      values.push(data.title);
    }
    if (data.courtId !== undefined) {
      fields.push(`court_id = $${idx++}`);
      values.push(data.courtId);
    }
    if (data.format !== undefined) {
      fields.push(`format = $${idx++}`);
      values.push(data.format);
    }
    if (data.maxPlayers !== undefined) {
      fields.push(`max_players = $${idx++}`);
      values.push(data.maxPlayers);
    }
    if (data.entryFee !== undefined) {
      fields.push(`entry_fee = $${idx++}`);
      values.push(data.entryFee);
    }
    if (data.matchDate !== undefined) {
      fields.push(`match_date = $${idx++}`);
      values.push(data.matchDate);
    }
    if (data.startTime !== undefined) {
      fields.push(`start_time = $${idx++}`);
      values.push(data.startTime);
    }
    if (data.endTime !== undefined) {
      fields.push(`end_time = $${idx++}`);
      values.push(data.endTime);
    }
    if (data.description !== undefined) {
      fields.push(`description = $${idx++}`);
      values.push(data.description);
    }
    if (data.privacy !== undefined) {
      fields.push(`privacy = $${idx++}`);
      values.push(data.privacy);
    }

    if (fields.length === 0) return null;

    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(gameId);

    const res = await dbPool.query(
      `UPDATE public.games SET ${fields.join(", ")} WHERE id = $${idx} RETURNING *;`,
      values,
    );
    return res.rows[0];
  }

  static async updateGameStatus(gameId: string, status: string) {
    const res = await dbPool.query(
      `UPDATE public.games SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *;`,
      [status, gameId],
    );
    return res.rows[0];
  }

  static async startMatchGame(gameId: string) {
    const res = await dbPool.query(
      `UPDATE public.games
       SET status = 'ONGOING',
           match_date = CURRENT_DATE,
           start_time = CURRENT_TIME,
           end_time = CURRENT_TIME + INTERVAL '90 minutes',
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *;`,
      [gameId],
    );
    return res.rows[0];
  }

  static async completeMatchGame(gameId: string) {
    const res = await dbPool.query(
      `UPDATE public.games
       SET status = 'COMPLETED',
           end_time = CURRENT_TIME,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1
       RETURNING *;`,
      [gameId],
    );
    return res.rows[0];
  }

  static async getClubBookings(clubId: string) {
    const res = await dbPool.query(
      `SELECT b.*, crt.name as court_name, u.name as player_name, u.phone as player_phone
       FROM public.court_bookings b
       JOIN public.courts crt ON crt.id = b.court_id
       JOIN public.users u ON u.id = b.user_id
       WHERE b.club_id = $1
       ORDER BY b.booking_date DESC, b.start_time DESC;`,
      [clubId],
    );
    return res.rows;
  }

  static async getPendingRequests(clubId: string) {
    const query = `
      SELECT req.*, u.name as player_name, u.profile_image_url as player_image,
             pd.position as player_position, pd.skill_level, pd.ovr_rating, pd.elo_rating, pd.preferred_foot,
             g.title as game_title, g.match_date, g.start_time, g.end_time, g.format, g.max_players,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_roster_count
      FROM public.game_slot_requests req
      JOIN public.games g ON g.id = req.game_id
      JOIN public.users u ON u.id = req.user_id
      LEFT JOIN public.player_details pd ON pd.user_id = req.user_id
      WHERE g.club_id = $1 AND req.status IN ('PENDING', 'APPROVED')
      ORDER BY req.updated_at DESC, req.created_at ASC;
    `;
    const res = await dbPool.query(query, [clubId]);
    return res.rows;
  }

  static async getClubMatchesByStatus(
    _clubId: string,
    statusTab?: string,
    courtFilter?: string,
  ) {
    const conditions: string[] = ["g.club_id = 'all_stars_arena_club'"];
    const values: any[] = [];

    const tabUpper = (statusTab || "").toUpperCase();
    if (tabUpper === "TODAY") {
      conditions.push(
        "g.match_date = CURRENT_DATE AND g.status <> 'CANCELLED'",
      );
    } else if (tabUpper === "UPCOMING") {
      conditions.push(
        "g.match_date > CURRENT_DATE AND g.status <> 'CANCELLED'",
      );
    } else if (tabUpper === "ONGOING") {
      conditions.push("g.status = 'ONGOING'");
    } else if (tabUpper === "COMPLETED") {
      conditions.push("g.status = 'COMPLETED'");
    } else if (tabUpper === "CANCELLED") {
      conditions.push("g.status = 'CANCELLED'");
    }

    if (courtFilter && courtFilter.trim().toUpperCase() !== "ALL") {
      const courtUpper = courtFilter.trim().toUpperCase();
      if (courtUpper.includes("2")) {
        conditions.push("g.court_id = 'court_2'");
      } else if (courtUpper.includes("1")) {
        conditions.push("g.court_id = 'court_1'");
      }
    }

    const query = `
      SELECT g.*,
             CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END as court_name,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count,
             (SELECT COUNT(*) FROM public.game_slot_requests req WHERE req.game_id = g.id AND req.status = 'PENDING') as pending_requests_count,
             (
               SELECT COALESCE(json_agg(
                 json_build_object(
                   'userId', gp.user_id,
                   'user_id', gp.user_id,
                   'name', COALESCE(pu.name, 'Player'),
                   'profileImageUrl', pu.profile_image_url,
                   'profile_image_url', pu.profile_image_url,
                   'team', COALESCE(gp.team, 'TEAM_A'),
                   'position', COALESCE(gp.position, 'MID'),
                   'ovr', COALESCE(pd.ovr_rating, 80),
                   'paymentStatus', COALESCE(gp.payment_status, 'PAID'),
                   'payment_status', COALESCE(gp.payment_status, 'PAID'),
                   'phone', pu.phone
                 )
               ), '[]'::json)
               FROM public.game_players gp
               JOIN public.users pu ON pu.id = gp.user_id
               LEFT JOIN public.player_details pd ON pd.user_id = gp.user_id
               WHERE gp.game_id = g.id
             ) as roster
      FROM public.games g
      WHERE ${conditions.join(" AND ")}
      ORDER BY g.match_date ASC, g.start_time ASC;
    `;
    const res = await dbPool.query(query, values);
    return res.rows;
  }

  static async getClubHistoryMatches(
    clubId: string,
    limit = 20,
    offset = 0,
    statusFilter?: string,
    courtFilter?: string,
  ) {
    const conditions: string[] = [
      "(g.club_id = $1 OR g.club_id = 'all_stars_arena_club')",
      "UPPER(g.status::text) IN ('COMPLETED', 'CANCELLED', 'FINISHED')",
      "(UPPER(g.status::text) = 'CANCELLED' OR g.match_date::date <= CURRENT_DATE)",
    ];
    const values: any[] = [clubId || "all_stars_arena_club"];
    let idx = 2;

    if (statusFilter && statusFilter.toUpperCase() !== "ALL") {
      const upperStatus = statusFilter.toUpperCase();
      if (upperStatus === "COMPLETED") {
        conditions.push(`UPPER(g.status::text) IN ('COMPLETED', 'FINISHED')`);
      } else {
        conditions.push(`UPPER(g.status::text) = $${idx++}`);
        values.push(upperStatus);
      }
    }

    if (courtFilter && courtFilter.trim().toUpperCase() !== "ALL") {
      const courtUpper = courtFilter.trim().toUpperCase();
      conditions.push(`g.court_id = $${idx++}`);
      values.push(courtUpper.includes("2") ? "court_2" : "court_1");
    }

    values.push(limit, offset);

    const query = `
      SELECT g.*,
             to_char(g.match_date::date, 'YYYY-MM-DD') as match_date,
             COALESCE(
               (SELECT gv.video_url FROM public.game_videos gv WHERE gv.game_id = g.id AND gv.status = 'AVAILABLE' ORDER BY gv.created_at ASC LIMIT 1),
               g.video_playback_url
             ) as video_playback_url,
             CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END as court_name,
             u.id as host_user_id, u.name as host_name, u.phone as host_phone, u.profile_image_url as host_image,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id AND gp.payment_status = 'PAID') * g.entry_fee as total_amount_collected,
             (
               SELECT COALESCE(json_agg(
                 json_build_object(
                   'userId', gp.user_id,
                   'name', COALESCE(pu.name, 'Player'),
                   'profileImageUrl', pu.profile_image_url,
                   'team', COALESCE(gp.team, 'TEAM_A'),
                   'position', COALESCE(gp.position, 'MID'),
                   'ovr', COALESCE(pd.ovr_rating, 80)
                 )
               ), '[]'::json)
               FROM public.game_players gp
               JOIN public.users pu ON pu.id = gp.user_id
               LEFT JOIN public.player_details pd ON pd.user_id = gp.user_id
               WHERE gp.game_id = g.id
             ) as roster
      FROM public.games g
      LEFT JOIN public.users u ON u.id = g.creator_id
      WHERE ${conditions.join(" AND ")}
      ORDER BY g.match_date DESC, g.start_time DESC, g.created_at DESC
      LIMIT $${idx++} OFFSET $${idx++};
    `;
    const res = await dbPool.query(query, values);
    return res.rows;
  }

  static async getCourtsByClub(clubId: string) {
    const targetClubId = clubId || "all_stars_arena_club";
    const clubCheck = await dbPool.query(
      `SELECT id FROM public.clubs WHERE id = $1;`,
      [targetClubId],
    );
    if (clubCheck.rows.length === 0) {
      return [];
    }

    const query = `
      SELECT crt.id, crt.club_id, crt.name, crt.environment, crt.surface, crt.base_price,
             crt.peak_multiplier, crt.weekend_multiplier, crt.peak_window_start, crt.peak_window_end,
             crt.status, crt.image_url, crt.created_at, crt.updated_at,
             (SELECT COUNT(*) FROM public.cctv_cameras cam WHERE cam.court_id = crt.id AND cam.is_enabled = true) as camera_count,
             (SELECT cam.status FROM public.cctv_cameras cam WHERE cam.court_id = crt.id AND cam.is_enabled = true LIMIT 1) as camera_status
      FROM public.courts crt
      WHERE crt.club_id = $1
      ORDER BY
          CASE
              WHEN crt.id = 'court_1' THEN 1
              WHEN crt.id = 'court_2' THEN 2
              ELSE 999
          END,
          crt.name;
    `;
    const res = await dbPool.query(query, [targetClubId]);
    return res.rows;
  }

  static async getCourtById(courtId: string) {
    const normalizedId = courtId.includes("2") ? "court_2" : "court_1";
    const res = await dbPool.query(
      `SELECT crt.*, 'All Stars Turf Raipur' as club_name, 'VIP Road, Raipur' as club_address
       FROM public.courts crt
       WHERE crt.id = $1;`,
      [normalizedId],
    );
    return res.rows[0] || null;
  }

  static async getCourtSlots(courtId: string, date?: string | null) {
    try {
      const expired = await dbPool.query(
        `SELECT g.id, g.title FROM public.games g
         WHERE g.approval_status = 'PENDING_APPROVAL' AND g.status <> 'CANCELLED'
           AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP;`,
      );
      for (const game of expired.rows) {
        await dbPool.query(
          `UPDATE public.games
           SET status = 'CANCELLED', approval_status = 'REJECTED',
               rejection_reason = 'Auto-cancelled: Not approved by start time',
               cancellation_reason = 'Auto-cancelled: Not approved by start time',
               updated_at = CURRENT_TIMESTAMP
           WHERE id = $1;`,
          [game.id],
        );
        const paidPlayers = await dbPool.query(
          `SELECT gp.user_id, COALESCE(g.entry_fee, 0) as refund_amount
           FROM public.game_players gp
           JOIN public.games g ON g.id = gp.game_id
           WHERE gp.game_id = $1 AND gp.payment_status = 'PAID';`,
          [game.id],
        );
        for (const player of paidPlayers.rows) {
          const amt = Number(player.refund_amount);
          if (amt > 0) {
            await dbPool.query(
              `INSERT INTO public.wallets (user_id, balance) VALUES ($1, $2)
               ON CONFLICT (user_id) DO UPDATE SET balance = public.wallets.balance + $2, updated_at = CURRENT_TIMESTAMP;`,
              [player.user_id, amt],
            );
            await dbPool.query(
              `INSERT INTO public.wallet_transactions (wallet_id, user_id, type, amount, status, description)
               VALUES ((SELECT id FROM public.wallets WHERE user_id = $1), $1, 'REFUND', $2, 'SUCCESS', $3);`,
              [
                player.user_id,
                amt,
                `Auto refund: Match "${game.title}" unapproved by start time`,
              ],
            );
            await dbPool.query(
              `UPDATE public.game_players SET payment_status = 'REFUNDED', updated_at = CURRENT_TIMESTAMP WHERE game_id = $1 AND user_id = $2;`,
              [game.id, player.user_id],
            );
          }
        }
      }

      const autoStartGames = await dbPool.query(
        `SELECT g.id, g.club_id, g.title, crt.name as court_name
         FROM public.games g
         LEFT JOIN public.courts crt ON crt.id = g.court_id
         WHERE g.approval_status = 'APPROVED'
           AND g.status IN ('OPEN_FOR_JOINING', 'FULL', 'SCHEDULED')
           AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP
           AND (g.match_date + g.end_time) > CURRENT_TIMESTAMP;`,
      );

      for (const game of autoStartGames.rows) {
        await dbPool.query(
          `UPDATE public.games SET status = 'ONGOING', updated_at = CURRENT_TIMESTAMP WHERE id = $1;`,
          [game.id],
        );

        const managers = await dbPool.query(
          `SELECT user_id FROM public.club_managers WHERE club_id = $1;`,
          [game.club_id],
        );
        for (const mgr of managers.rows) {
          await dbPool.query(
            `INSERT INTO public.notifications (user_id, title, body, message, type, data)
             VALUES ($1, $2, $3, $3, 'MATCH_AUTO_STARTED', $4);`,
            [
              mgr.user_id,
              "⚽ Match Auto-Started",
              `Match "${game.title}" on ${game.court_name || "Court"} auto-started at scheduled start time!`,
              JSON.stringify({
                gameId: game.id,
                route: "/manager/games/details",
              }),
            ],
          );
        }

        const players = await dbPool.query(
          `SELECT user_id FROM public.game_players WHERE game_id = $1;`,
          [game.id],
        );
        for (const ply of players.rows) {
          await dbPool.query(
            `INSERT INTO public.notifications (user_id, title, body, message, type, data)
             VALUES ($1, $2, $3, $3, 'MATCH_AUTO_STARTED', $4);`,
            [
              ply.user_id,
              "⚽ Kick-off! Match Started",
              `Your match "${game.title}" on ${game.court_name || "Court"} has officially started! Good luck!`,
              JSON.stringify({ gameId: game.id, route: "/games/details" }),
            ],
          );
        }
      }
    } catch (_) {}

    const normalizedCourtId =
      courtId && courtId.includes("2") ? "court_2" : "court_1";
    const conditions: string[] = [
      "g.court_id = $1",
      "g.status NOT IN ('CANCELLED', 'COMPLETED')",
    ];
    const values: any[] = [normalizedCourtId];
    let idx = 2;

    if (date && date.toUpperCase() !== "ALL") {
      let targetDate = date;
      const today = new Date().toISOString().split("T")[0];
      const tomorrow = new Date(Date.now() + 86400000)
        .toISOString()
        .split("T")[0];

      if (date.toUpperCase() === "TODAY") {
        targetDate = today;
      } else if (date.toUpperCase() === "TOMORROW") {
        targetDate = tomorrow;
      }

      if (/^\d{4}-\d{2}-\d{2}$/.test(targetDate)) {
        conditions.push(`g.match_date = $${idx++}`);
        values.push(targetDate);
      }
    }

    const query = `
      SELECT g.id, g.title, g.format, g.max_players, g.entry_fee, g.privacy,
             g.match_date, g.start_time, g.end_time, g.status, g.approval_status,
             g.created_by_player, g.creator_role_name, g.rejection_reason,
             g.team_a_score, g.team_b_score, g.winner_team,
             u.id as host_user_id, u.name as host_name, u.phone as host_phone, u.profile_image_url as host_image,
             CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END as court_name,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id AND gp.payment_status = 'PAID') as paid_players_count,
             cam.id as camera_id, cam.status as camera_status,
             rec.id as recording_id, rec.recording_status
      FROM public.games g
      LEFT JOIN public.users u ON u.id = g.creator_id
      LEFT JOIN public.cctv_cameras cam ON cam.court_id = g.court_id AND cam.is_enabled = true
      LEFT JOIN public.cctv_recordings rec ON rec.game_id = g.id AND rec.recording_status IN ('RECORDING', 'POST_MATCH', 'STARTING')
      WHERE ${conditions.join(" AND ")}
      ORDER BY g.match_date ASC, g.start_time ASC
      LIMIT 20;
    `;
    const res = await dbPool.query(query, values);
    return res.rows;
  }

  static async getPendingPlayerGames(_clubId?: string) {
    const query = `
      SELECT g.*,
             CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END as court_name,
             u.id as host_user_id, u.name as host_name, u.email as host_email, u.phone as host_phone,
             u.profile_image_url as host_image, pd.elo_rating as host_elo, pd.position as host_position,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count
      FROM public.games g
      JOIN public.users u ON u.id = g.creator_id
      LEFT JOIN public.player_details pd ON pd.user_id = g.creator_id
      WHERE g.club_id = 'all_stars_arena_club' AND g.approval_status = 'PENDING_APPROVAL' AND g.status <> 'CANCELLED'
      ORDER BY g.match_date ASC, g.start_time ASC;
    `;
    const res = await dbPool.query(query);
    return res.rows;
  }

  static async getAllPlayers(
    search?: string,
    status?: string,
    limit = 50,
    offset = 0,
  ) {
    const conditions: string[] = ["u.role_id = 3"];
    const values: any[] = [];
    let idx = 1;

    if (search && search.trim().length > 0) {
      conditions.push(
        `(u.name ILIKE $${idx} OR u.email ILIKE $${idx} OR u.phone ILIKE $${idx} OR pd.position ILIKE $${idx})`,
      );
      values.push(`%${search.trim()}%`);
      idx++;
    }

    if (
      status &&
      status.toUpperCase() !== "ALL" &&
      status.toUpperCase() !== "ALL PLAYERS"
    ) {
      const statusUpper = status.toUpperCase();
      if (statusUpper === "BLOCKED" || statusUpper === "SUSPENDED") {
        conditions.push(`u.status = 'SUSPENDED'`);
      } else if (statusUpper === "ACTIVE") {
        conditions.push(`u.status = 'ACTIVE'`);
      } else {
        conditions.push(`u.status = $${idx}`);
        values.push(statusUpper);
        idx++;
      }
    }

    values.push(limit, offset);

    const query = `
      SELECT u.id, u.name, u.email, u.phone, u.profile_image_url, u.status, u.created_at,
             u.city, u.bio,
             pd.position, pd.skill_level, pd.ovr_rating, pd.elo_rating, pd.preferred_foot,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.user_id = u.id) as matches_played
      FROM public.users u
      LEFT JOIN public.player_details pd ON pd.user_id = u.id
      WHERE ${conditions.join(" AND ")}
      ORDER BY LOWER(u.name) ASC
      LIMIT $${idx++} OFFSET $${idx++};
    `;
    const res = await dbPool.query(query, values);

    const countQuery = `
      SELECT COUNT(*) as total_count
      FROM public.users u
      WHERE ${conditions.join(" AND ")};
    `;
    const countRes = await dbPool.query(countQuery, values.slice(0, idx - 3));

    return {
      players: res.rows,
      totalCount: parseInt(countRes.rows[0]?.total_count || "0", 10),
    };
  }

  static async getPlayerDetailHistory(playerId: string) {
    const userRes = await dbPool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.profile_image_url, u.status, u.created_at,
              u.city, u.bio,
              pd.position, pd.skill_level, pd.ovr_rating, pd.elo_rating, pd.preferred_foot
       FROM public.users u
       LEFT JOIN public.player_details pd ON pd.user_id = u.id
       WHERE u.id = $1 AND u.role_id = 3;`,
      [playerId],
    );

    if (userRes.rows.length === 0) {
      return null;
    }

    const player = userRes.rows[0];

    const historyRes = await dbPool.query(
      `SELECT gp.game_id, gp.payment_status, gp.team, gp.position as game_position, gp.created_at as joined_at,
              g.title as game_title, g.match_date, g.start_time, g.end_time, g.format,
              g.entry_fee, g.status as match_status,
              crt.name as court_name, clb.name as club_name,
              gv.video_url
       FROM public.game_players gp
       INNER JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs clb ON clb.id = g.club_id
       LEFT JOIN public.game_videos gv ON gv.game_id = g.id AND gv.status = 'AVAILABLE'
       WHERE gp.user_id = $1
       ORDER BY g.match_date DESC, g.start_time DESC;`,
      [playerId],
    );

    const history = historyRes.rows;

    let totalMatches = history.length;
    let completedMatches = 0;
    let cancelledMatches = 0;
    let totalPaid = 0;
    let totalRefunded = 0;

    for (const match of history) {
      if (match.match_status === "COMPLETED") {
        completedMatches++;
      } else if (match.match_status === "CANCELLED") {
        cancelledMatches++;
      }

      const fee = Number(match.entry_fee || 0);
      if (match.payment_status === "PAID") {
        totalPaid += fee;
      } else if (match.payment_status === "REFUNDED") {
        totalRefunded += fee;
      }
    }

    return {
      player,
      stats: {
        totalMatches,
        completedMatches,
        cancelledMatches,
        totalPaid,
        totalRefunded,
      },
      matchHistory: history,
    };
  }

  static async updatePlayerStatus(playerId: string, status: string) {
    const res = await dbPool.query(
      `UPDATE public.users SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND role_id = 3 RETURNING id, name, email, status;`,
      [status, playerId],
    );
    return res.rows[0] || null;
  }

  static async getGameForManager(gameId: string) {
    const gameRes = await dbPool.query(
      `SELECT g.*, crt.name as court_name, clb.name as club_name,
              u.id as host_user_id, u.name as host_name, u.email as host_email, u.phone as host_phone,
              u.profile_image_url as host_image, pd.elo_rating as host_elo
       FROM public.games g
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs clb ON clb.id = g.club_id
       LEFT JOIN public.users u ON u.id = g.creator_id
       LEFT JOIN public.player_details pd ON pd.user_id = g.creator_id
       WHERE g.id = $1;`,
      [gameId],
    );

    if (gameRes.rows.length === 0) return null;
    const game = gameRes.rows[0];

    const playersRes = await dbPool.query(
      `SELECT gp.id as roster_id, gp.user_id, gp.team, gp.position, gp.payment_status, gp.created_at as joined_at,
              u.name, u.email, u.phone, u.profile_image_url,
              pd.elo_rating, pd.ovr_rating
       FROM public.game_players gp
       JOIN public.users u ON u.id = gp.user_id
       LEFT JOIN public.player_details pd ON pd.user_id = gp.user_id
       WHERE gp.game_id = $1
       ORDER BY gp.created_at ASC;`,
      [gameId],
    );

    const recordingRes = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE game_id = $1 ORDER BY created_at DESC LIMIT 1;`,
      [gameId],
    );

    const mappedPlayers = playersRes.rows.map((r: any) => ({
      rosterId: r.roster_id,
      roster_id: r.roster_id,
      userId: r.user_id,
      user_id: r.user_id,
      team: (r.team || "TEAM_A").toUpperCase(),
      position: r.position || "MID",
      paymentStatus: (r.payment_status || "PAID").toUpperCase(),
      payment_status: (r.payment_status || "PAID").toUpperCase(),
      joinedAt: r.joined_at,
      name: r.name || "Player",
      email: r.email,
      phone: r.phone,
      profileImageUrl: r.profile_image_url,
      profile_image_url: r.profile_image_url,
      eloRating: Number(r.elo_rating || 1200),
      ovr: Number(r.ovr_rating || 75),
      ovr_rating: Number(r.ovr_rating || 75),
    }));

    return {
      ...game,
      roster: mappedPlayers,
      recording: recordingRes.rows[0] || null,
    };
  }

  static async getGamePlayers(gameId: string) {
    const playersRes = await dbPool.query(
      `SELECT gp.id as roster_id, gp.user_id, gp.team, gp.position, gp.payment_status, gp.created_at as joined_at,
              u.name, u.email, u.phone, u.profile_image_url,
              pd.elo_rating, pd.ovr_rating
       FROM public.game_players gp
       JOIN public.users u ON u.id = gp.user_id
       LEFT JOIN public.player_details pd ON pd.user_id = gp.user_id
       WHERE gp.game_id = $1
       ORDER BY gp.team ASC, gp.created_at ASC;`,
      [gameId],
    );

    const players = playersRes.rows.map((r: any) => ({
      rosterId: r.roster_id,
      roster_id: r.roster_id,
      userId: r.user_id,
      user_id: r.user_id,
      team: (r.team || "TEAM_A").toUpperCase(),
      position: r.position || "MID",
      paymentStatus: (r.payment_status || "PAID").toUpperCase(),
      payment_status: (r.payment_status || "PAID").toUpperCase(),
      joinedAt: r.joined_at,
      name: r.name || "Player",
      email: r.email,
      phone: r.phone,
      profileImageUrl: r.profile_image_url,
      profile_image_url: r.profile_image_url,
      eloRating: Number(r.elo_rating || 1200),
      ovr: Number(r.ovr_rating || 75),
      ovr_rating: Number(r.ovr_rating || 75),
    }));

    const teamA = players.filter((p: any) =>
      p.team.toUpperCase().includes("A"),
    );
    const teamB = players.filter((p: any) =>
      p.team.toUpperCase().includes("B"),
    );

    return {
      totalPlayers: players.length,
      teamACount: teamA.length,
      teamBCount: teamB.length,
      teamA,
      teamB,
      roster: players,
    };
  }

  static async getManagerProfile(userId: string) {
    const query = `
      SELECT u.id, u.name, u.email, u.phone, u.role_id, u.profile_image_url,
             'All Stars Arena Turf' as club_name, 'VIP Road, Raipur' as club_address, 'Raipur' as club_city
      FROM public.users u
      WHERE u.id = $1;
    `;
    const res = await dbPool.query(query, [userId]);
    return res.rows[0] || null;
  }

  static async updateAvatar(userId: string, avatarUrl: string) {
    const query = `
      UPDATE public.users
      SET profile_image_url = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, name, email, phone, role_id, profile_image_url;
    `;
    const res = await dbPool.query(query, [avatarUrl, userId]);
    return res.rows[0];
  }
}
