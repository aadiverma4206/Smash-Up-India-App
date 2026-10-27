import { dbPool } from "../../config/db.config.js";

export class GamesRepository {
  static async getGames(filters: {
    city?: string;
    format?: string;
    skill?: string;
    date?: string;
    maxEntryFee?: number;
    status?: string;
    privacy?: string;
    court?: string;
    userId?: string;
    limit?: number;
    offset?: number;
  }) {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (filters.city) {
      conditions.push(`c.city = $${idx++}`);
      values.push(filters.city);
    }
    if (filters.format) {
      conditions.push(`g.format = $${idx++}`);
      values.push(filters.format);
    }
    if (filters.skill) {
      conditions.push(`g.skill_requirement::text = $${idx++}`);
      values.push(filters.skill);
    }
    if (filters.date) {
      conditions.push(`g.match_date = $${idx++}`);
      values.push(filters.date);
    }
    if (filters.maxEntryFee !== undefined) {
      conditions.push(`g.entry_fee <= $${idx++}`);
      values.push(filters.maxEntryFee);
    }
    if (filters.status) {
      conditions.push(`g.status = $${idx++}`);
      values.push(filters.status);
    } else {
      conditions.push(`g.status = 'OPEN_FOR_JOINING'`);
    }
    conditions.push(`g.approval_status IN ('APPROVED', 'PENDING_APPROVAL')`);
    if (filters.privacy) {
      conditions.push(`g.privacy = $${idx++}`);
      values.push(filters.privacy);
    }
    if (filters.userId) {
      conditions.push(
        `(g.creator_id = $${idx++} OR g.id IN (SELECT game_id FROM public.game_players WHERE user_id = $${idx++}))`,
      );
      values.push(filters.userId, filters.userId);
    }
    if (filters.court && filters.court.trim().toUpperCase() !== "ALL") {
      const courtUpper = filters.court.trim().toUpperCase();
      if (
        courtUpper === "COURT_1" ||
        courtUpper === "COURT 1" ||
        courtUpper.endsWith("1")
      ) {
        conditions.push(
          `(crt.name ILIKE '%Court 1%' OR g.court_id ILIKE '%court_1%' OR g.court_id ILIKE '%1')`,
        );
      } else if (
        courtUpper === "COURT_2" ||
        courtUpper === "COURT 2" ||
        courtUpper.endsWith("2")
      ) {
        conditions.push(
          `(crt.name ILIKE '%Court 2%' OR g.court_id ILIKE '%court_2%' OR g.court_id ILIKE '%2')`,
        );
      } else {
        conditions.push(`g.court_id = $${idx++}`);
        values.push(filters.court);
      }
    }

    const whereClause =
      conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
    const limit = filters.limit || 20;
    const offset = filters.offset || 0;

    values.push(limit, offset);
    const query = `
      SELECT g.*, 
             TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
             TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
             TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
             COALESCE(crt.club_id, 'all_stars_arena_club') as club_id,
             COALESCE(c.name, 'All Stars Turf Raipur') as club_name, 
             c.address as club_address, 
             c.city, 
             COALESCE(crt.name, CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END) as court_name,
             CASE 
               WHEN g.format = '5v5' THEN 10 
               WHEN g.format = '7v7' THEN 14 
               ELSE 22 
             END as max_players,
             'PUBLIC' as privacy,
             'INTERMEDIATE' as skill_requirement,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count
      FROM public.games g
      LEFT JOIN public.courts crt ON crt.id = g.court_id
      LEFT JOIN public.clubs c ON c.id = crt.club_id
      ${whereClause}
      ORDER BY g.match_date ASC, g.start_time ASC
      LIMIT $${idx++} OFFSET $${idx++};
    `;

    const res = await dbPool.query(query, values);
    return res.rows;
  }

  static async getGameById(gameId: string) {
    const res = await dbPool.query(
      `SELECT g.id, g.title, g.court_id, g.creator_id, g.creator_role_name, g.created_by_player,
              g.format, g.entry_fee, COALESCE(g.per_player_fee, 0.00) as per_player_fee, g.status, g.approval_status,
              g.team_a_score, g.team_b_score, g.winner_team, g.description,
              g.created_at, g.updated_at,
              TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
              TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
              TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
              COALESCE(crt.club_id, 'all_stars_arena_club') as club_id,
              COALESCE(c.name, 'All Stars Turf Raipur') as club_name, 
              COALESCE(crt.name, CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END) as court_name,
              CASE 
                WHEN g.format = '5v5' THEN 10 
                WHEN g.format = '7v7' THEN 14 
                ELSE 22 
              END as max_players,
              'PUBLIC' as privacy,
              'INTERMEDIATE' as skill_requirement,
              (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count,
              CASE
                WHEN g.status = 'COMPLETED' AND (
                  (g.match_date + g.end_time + INTERVAL '10 minutes') <= CURRENT_TIMESTAMP
                  OR (COALESCE(g.updated_at, g.created_at) + INTERVAL '10 minutes') <= CURRENT_TIMESTAMP
                ) THEN COALESCE(
                  (SELECT gv.video_url FROM public.game_videos gv WHERE gv.game_id = g.id AND gv.status = 'AVAILABLE' ORDER BY gv.created_at ASC LIMIT 1),
                  g.video_playback_url
                )
                ELSE NULL
              END as video_playback_url,
              (
                SELECT COALESCE(json_agg(
                  json_build_object(
                    'userId', gp.user_id,
                    'user_id', gp.user_id,
                    'name', COALESCE(pu.name, 'Player'),
                    'profileImageUrl', pu.profile_image_url,
                    'profile_image_url', pu.profile_image_url,
                    'team', UPPER(COALESCE(NULLIF(gp.team::text, ''), 'TEAM_A')),
                    'position', COALESCE(gp.position, 'MID'),
                    'paymentStatus', COALESCE(gp.payment_status, 'PAID'),
                    'payment_status', COALESCE(gp.payment_status, 'PAID'),
                    'phone', pu.phone
                  )
                  ORDER BY gp.team ASC, gp.joined_at ASC
                ), '[]'::json)
                FROM public.game_players gp
                JOIN public.users pu ON pu.id = gp.user_id
                WHERE gp.game_id = g.id
              ) as roster
       FROM public.games g
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs c ON c.id = crt.club_id
       WHERE g.id = $1;`,
      [gameId],
    );
    return res.rows[0] || null;
  }

  static async checkCourtOverlap(
    courtId: string,
    matchDate: string,
    startTime: string,
    endTime: string,
    excludeGameId?: string,
  ): Promise<boolean> {
    const normalizedCourtId = (courtId || "").toLowerCase().includes("2")
      ? "court_2"
      : "court_1";

    const res = await dbPool.query(
      `SELECT (
        (SELECT COUNT(*) FROM public.games 
         WHERE court_id = $1 AND match_date = $2 
           AND status <> 'CANCELLED' AND approval_status <> 'REJECTED'
           AND ($5::text IS NULL OR id <> $5)
           AND (start_time < $4::time AND end_time > $3::time))
        +
        (SELECT COUNT(*) FROM public.court_bookings 
         WHERE court_id = $1 AND booking_date = $2 
           AND status = 'CONFIRMED'
           AND (start_time < $4::time AND end_time > $3::time))
      ) as total_overlap_count;`,
      [normalizedCourtId, matchDate, startTime, endTime, excludeGameId || null],
    );
    return parseInt(res.rows[0]?.total_overlap_count || "0", 10) > 0;
  }

  static async createGame(
    data: {
      id?: string;
      title: string;
      clubId?: string;
      courtId: string;
      creatorId: string;
      creatorRoleName: string;
      createdByPlayer: boolean;
      format: string;
      maxPlayers?: number;
      entryFee: number;
      skillRequirement?: string;
      privacy?: string;
      matchDate: string;
      startTime: string;
      endTime: string;
      description?: string;
      approvalStatus?: string;
      managerId?: string;
    },
    dbClient: any = dbPool,
  ) {
    const approvalStatus = (data as any).approvalStatus || "APPROVED";
    const managerId = (data as any).managerId || null;

    if (data.id) {
      const query = `
        INSERT INTO public.games
        (id, title, court_id, creator_id, creator_role_name, created_by_player, format, entry_fee, match_date, start_time, end_time, status, approval_status, description, manager_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'OPEN_FOR_JOINING', $12, $13, $14)
        RETURNING *;
      `;
      const res = await dbClient.query(query, [
        data.id,
        data.title,
        data.courtId,
        data.creatorId,
        data.creatorRoleName,
        data.createdByPlayer,
        data.format,
        data.entryFee,
        data.matchDate,
        data.startTime,
        data.endTime,
        approvalStatus,
        data.description || null,
        managerId,
      ]);
      return res.rows[0];
    } else {
      const query = `
        INSERT INTO public.games
        (title, court_id, creator_id, creator_role_name, created_by_player, format, entry_fee, match_date, start_time, end_time, status, approval_status, description, manager_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'OPEN_FOR_JOINING', $11, $12, $13)
        RETURNING *;
      `;
      const res = await dbClient.query(query, [
        data.title,
        data.courtId,
        data.creatorId,
        data.creatorRoleName,
        data.createdByPlayer,
        data.format,
        data.entryFee,
        data.matchDate,
        data.startTime,
        data.endTime,
        approvalStatus,
        data.description || null,
        managerId,
      ]);
      return res.rows[0];
    }
  }

  static async createSlotRequest(data: {
    gameId: string;
    userId: string;
    position: string;
    entryFee: number;
    status: string;
  }) {
    const query = `
      INSERT INTO public.game_slot_requests
      (game_id, user_id, position, entry_fee, status)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (game_id, user_id) DO UPDATE SET
        position = EXCLUDED.position,
        status = EXCLUDED.status,
        updated_at = CURRENT_TIMESTAMP
      RETURNING *;
    `;
    const res = await dbPool.query(query, [
      data.gameId,
      data.userId,
      data.position,
      data.entryFee,
      data.status,
    ]);
    return res.rows[0];
  }

  static async getPlayerRequests(userId: string, statusTab = "ALL") {
    let whereClause = `WHERE req.user_id = $1`;
    const params: any[] = [userId];

    if (statusTab !== "ALL") {
      whereClause += ` AND req.status = $2`;
      params.push(statusTab);
    }

    const query = `
      SELECT req.*, g.title as game_title, g.match_date, g.start_time, g.end_time, g.format,
             g.status as game_status, COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name
      FROM public.game_slot_requests req
      JOIN public.games g ON g.id = req.game_id
      LEFT JOIN public.courts crt ON crt.id = g.court_id
      LEFT JOIN public.clubs c ON c.id = crt.club_id
      ${whereClause}
      ORDER BY req.created_at DESC;
    `;

    const res = await dbPool.query(query, params);
    return res.rows;
  }

  static async addActivityLog(
    data: {
      gameId: string;
      actorId?: string;
      actorName?: string;
      actorRoleName: string;
      actionType: string;
      details: string;
    },
    dbClient: any = dbPool,
  ) {
    const query = `
      INSERT INTO public.game_activity_logs
      (game_id, actor_id, actor_name, actor_role_name, action_type, details)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `;
    const res = await dbClient.query(query, [
      data.gameId,
      data.actorId || null,
      data.actorName || null,
      data.actorRoleName,
      data.actionType,
      data.details,
    ]);
    return res.rows[0];
  }

  static async getActivityLogs(gameId: string) {
    const query = `
      SELECT * FROM public.game_activity_logs
      WHERE game_id = $1
      ORDER BY created_at ASC;
    `;
    const res = await dbPool.query(query, [gameId]);
    return res.rows;
  }

  static async getRoster(gameId: string) {
    const res = await dbPool.query(
      `SELECT gp.*, u.name, u.profile_image_url, gp.position as player_position
       FROM public.game_players gp
       JOIN public.users u ON u.id = gp.user_id
       WHERE gp.game_id = $1
       ORDER BY gp.team ASC, gp.joined_at ASC;`,
      [gameId],
    );
    return res.rows;
  }

  static async leaveGame(gameId: string, userId: string) {
    const res = await dbPool.query(
      `DELETE FROM public.game_players WHERE game_id = $1 AND user_id = $2 RETURNING id;`,
      [gameId, userId],
    );
    return Boolean(res.rowCount && res.rowCount > 0);
  }

  static async getWaitlist(gameId: string) {
    const res = await dbPool.query(
      `SELECT gw.*, u.name, u.profile_image_url
       FROM public.game_waitlist gw
       JOIN public.users u ON u.id = gw.user_id
       WHERE gw.game_id = $1
       ORDER BY gw.joined_at ASC;`,
      [gameId],
    );
    return res.rows;
  }

  static async addToWaitlist(gameId: string, userId: string, position: string) {
    const countRes = await dbPool.query(
      `SELECT COUNT(*) as waitlist_count FROM public.game_waitlist WHERE game_id = $1;`,
      [gameId],
    );
    const queuePosition =
      parseInt(countRes.rows[0]?.waitlist_count || "0", 10) + 1;

    const res = await dbPool.query(
      `INSERT INTO public.game_waitlist (game_id, user_id, position)
       VALUES ($1, $2, $3)
       ON CONFLICT (game_id, user_id) DO UPDATE SET position = EXCLUDED.position
       RETURNING *;`,
      [gameId, userId, position],
    );
    return { ...res.rows[0], queuePosition };
  }

  static async removeFromWaitlist(gameId: string, userId: string) {
    const res = await dbPool.query(
      `DELETE FROM public.game_waitlist WHERE game_id = $1 AND user_id = $2;`,
      [gameId, userId],
    );
    return Boolean(res.rowCount && res.rowCount > 0);
  }

  static async popNextWaitlistPlayer(gameId: string) {
    const res = await dbPool.query(
      `DELETE FROM public.game_waitlist
       WHERE id = (
         SELECT id FROM public.game_waitlist
         WHERE game_id = $1
         ORDER BY joined_at ASC LIMIT 1
       )
       RETURNING *;`,
      [gameId],
    );
    return res.rows[0] || null;
  }

  static async getGameVideos(gameId: string) {
    const res = await dbPool.query(
      `SELECT gv.*,
              gv.cctv_id,
              COALESCE(cam.name, 'Camera ' || ROW_NUMBER() OVER(PARTITION BY gv.game_id ORDER BY gv.created_at ASC)) as camera_name,
              COALESCE(cam.camera_type, 'RTSP_DOME') as camera_type,
              COALESCE(cam.status, 'ONLINE') as camera_status,
              COALESCE(crt.name, 'Court 1') as court_name,
              COALESCE(clb.name, 'All Stars Turf') as club_name,
              COALESCE(rec.started_at, rec.created_at, gv.created_at) as started_at,
              COALESCE(rec.actual_stopped_at, rec.actual_stop_time, gv.created_at) as actual_stopped_at,
              COALESCE(rec.duration_seconds, 5400) as duration_seconds
       FROM public.game_videos gv
       JOIN public.games g ON g.id = gv.game_id
       LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
       LEFT JOIN public.courts crt ON crt.id = COALESCE(gv.court_id, cam.court_id)
       LEFT JOIN public.clubs clb ON clb.id = gv.club_id
       LEFT JOIN public.cctv_recordings rec ON (rec.game_id = gv.game_id AND (rec.camera_id = gv.cctv_id OR gv.cctv_id IS NULL))
       WHERE gv.game_id = $1
         AND UPPER(COALESCE(gv.status, 'AVAILABLE')) = 'AVAILABLE'
         AND (
           UPPER(g.status::text) IN ('COMPLETED', 'CANCELLED')
           OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP
         )
       ORDER BY gv.created_at ASC;`,
      [gameId],
    );
    return res.rows;
  }

  static async isClubManager(clubId: string, userId: string): Promise<boolean> {
    const res = await dbPool.query(
      `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
      [clubId, userId],
    );
    return (res.rowCount || 0) > 0;
  }
}
