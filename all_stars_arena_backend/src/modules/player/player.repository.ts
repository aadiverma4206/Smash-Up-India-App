import { dbPool } from "../../config/db.config.js";

export class PlayerRepository {
  static async getProfile(userId: string) {
    const res = await dbPool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.city, u.bio, u.status as account_status,
              u.date_of_birth::text as date_of_birth,
              COALESCE(u.profile_image_url, '') as avatar_url,
              pd.wallet_balance
       FROM public.users u
       LEFT JOIN public.player_wallets pd ON pd.user_id = u.id
       WHERE u.id = $1;`,
      [userId],
    );
    const row = res.rows[0];
    if (!row) return null;

    let dobStr: string | null = null;
    if (row.date_of_birth) {
      if (typeof row.date_of_birth === "string") {
        dobStr = row.date_of_birth.split("T")[0].trim();
      } else if (row.date_of_birth instanceof Date) {
        const y = row.date_of_birth.getFullYear();
        const m = String(row.date_of_birth.getMonth() + 1).padStart(2, "0");
        const d = String(row.date_of_birth.getDate()).padStart(2, "0");
        dobStr = `${y}-${m}-${d}`;
      }
    }

    return {
      userId: row.id,
      id: row.id,
      name: row.name,
      email: row.email,
      phone: row.phone,
      city: row.city || "Raipur",
      bio: row.bio || null,
      avatarUrl: row.avatar_url || null,
      avatar_url: row.avatar_url || null,
      dateOfBirth: dobStr,
      date_of_birth: dobStr,
      walletBalance: parseFloat(row.wallet_balance || "0.00"),
      wallet_balance: parseFloat(row.wallet_balance || "0.00"),
      accountStatus: row.account_status || "ACTIVE",
    };
  }

  static async updateProfile(userId: string, data: any) {
    const name = data.name;
    const bio = data.bio;
    const city = data.city;
    const avatarUrl =
      data.avatarUrl || data.avatar_url || data.profile_image_url;
    const dateOfBirth = data.dateOfBirth || data.date_of_birth;

    const userFields: string[] = [];
    const userVals: any[] = [];
    let idx = 1;

    if (name !== undefined && name !== null && String(name).trim() !== "") {
      userFields.push(`name = $${idx++}`);
      userVals.push(String(name).trim());
    }
    if (bio !== undefined && bio !== null) {
      userFields.push(`bio = $${idx++}`);
      userVals.push(String(bio).trim());
    }
    if (city !== undefined && city !== null && String(city).trim() !== "") {
      userFields.push(`city = $${idx++}`);
      userVals.push(String(city).trim());
    }
    if (
      avatarUrl !== undefined &&
      avatarUrl !== null &&
      String(avatarUrl).trim() !== ""
    ) {
      userFields.push(`profile_image_url = $${idx++}`);
      userVals.push(String(avatarUrl).trim());
    }
    if (
      dateOfBirth !== undefined &&
      dateOfBirth !== null &&
      String(dateOfBirth).trim() !== ""
    ) {
      userFields.push(`date_of_birth = $${idx++}`);
      userVals.push(String(dateOfBirth).trim());
    }

    if (userFields.length > 0) {
      userFields.push(`updated_at = CURRENT_TIMESTAMP`);
      userVals.push(userId);
      await dbPool.query(
        `UPDATE public.users SET ${userFields.join(", ")} WHERE id = $${idx};`,
        userVals,
      );
    }

    return await this.getProfile(userId);
  }

  static async updateAvatar(userId: string, avatarUrl: string) {
    await dbPool.query(
      `UPDATE public.users SET profile_image_url = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2;`,
      [avatarUrl, userId],
    );
    return await this.getProfile(userId);
  }

  static async getStats(userId: string) {
    try {
      await dbPool.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE status NOT IN ('COMPLETED', 'CANCELLED')
           AND (match_date + end_time) <= CURRENT_TIMESTAMP;`,
      );
    } catch (_) {}

    const res = await dbPool.query(
      `SELECT * FROM public.player_stats WHERE user_id = $1;`,
      [userId],
    );

    const statsRes = await dbPool
      .query(
        `SELECT
          COUNT(DISTINCT CASE
            WHEN UPPER(COALESCE(g.status::text, 'OPEN')) <> 'CANCELLED'
             AND UPPER(COALESCE(gp.payment_status::text, 'PAID')) NOT IN ('CANCELLED', 'REFUNDED', 'FAILED')
            THEN g.id
          END)::int AS joined_count,

          COUNT(DISTINCT CASE
            WHEN UPPER(COALESCE(g.status::text, 'OPEN')) <> 'CANCELLED'
             AND UPPER(COALESCE(gp.payment_status::text, 'PAID')) NOT IN ('CANCELLED', 'REFUNDED', 'FAILED')
             AND (UPPER(g.status::text) = 'COMPLETED' OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP)
            THEN g.id
          END)::int AS played_count,

          /* Won count: ONLY counted if score/winner is officially announced AND player's team won */
          COUNT(DISTINCT CASE
            WHEN UPPER(COALESCE(g.status::text, 'OPEN')) <> 'CANCELLED'
             AND UPPER(COALESCE(gp.payment_status::text, 'PAID')) NOT IN ('CANCELLED', 'REFUNDED', 'FAILED')
             AND (UPPER(g.status::text) = 'COMPLETED' OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP)
             AND (
               (g.winner_team IS NOT NULL AND g.winner_team <> '') OR
               (g.team_a_score IS NOT NULL AND g.team_b_score IS NOT NULL)
             )
             AND (
               (UPPER(COALESCE(g.winner_team::text, '')) = 'TEAM_A' AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_A') OR
               (UPPER(COALESCE(g.winner_team::text, '')) = 'TEAM_B' AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_B') OR
               (g.winner_team IS NULL AND g.team_a_score > g.team_b_score AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_A') OR
               (g.winner_team IS NULL AND g.team_b_score > g.team_a_score AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_B')
             )
            THEN g.id
          END)::int AS won_count,

          /* Drawn count: ONLY counted if score/winner is officially announced AND teams tied */
          COUNT(DISTINCT CASE
            WHEN UPPER(COALESCE(g.status::text, 'OPEN')) <> 'CANCELLED'
             AND UPPER(COALESCE(gp.payment_status::text, 'PAID')) NOT IN ('CANCELLED', 'REFUNDED', 'FAILED')
             AND (UPPER(g.status::text) = 'COMPLETED' OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP)
             AND (
               (g.winner_team IS NOT NULL AND g.winner_team <> '') OR
               (g.team_a_score IS NOT NULL AND g.team_b_score IS NOT NULL)
             )
             AND (
               UPPER(COALESCE(g.winner_team::text, '')) = 'DRAW' OR
               (g.team_a_score IS NOT NULL AND g.team_b_score IS NOT NULL AND g.team_a_score = g.team_b_score)
             )
            THEN g.id
          END)::int AS drawn_count,

          /* Lost count: ONLY counted if score/winner is officially announced AND player's team lost */
          COUNT(DISTINCT CASE
            WHEN UPPER(COALESCE(g.status::text, 'OPEN')) <> 'CANCELLED'
             AND UPPER(COALESCE(gp.payment_status::text, 'PAID')) NOT IN ('CANCELLED', 'REFUNDED', 'FAILED')
             AND (UPPER(g.status::text) = 'COMPLETED' OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP)
             AND (
               (g.winner_team IS NOT NULL AND g.winner_team <> '') OR
               (g.team_a_score IS NOT NULL AND g.team_b_score IS NOT NULL)
             )
             AND (
               (UPPER(COALESCE(g.winner_team::text, '')) = 'TEAM_A' AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_B') OR
               (UPPER(COALESCE(g.winner_team::text, '')) = 'TEAM_B' AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_A') OR
               (g.winner_team IS NULL AND g.team_a_score > g.team_b_score AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_B') OR
               (g.winner_team IS NULL AND g.team_b_score > g.team_a_score AND UPPER(COALESCE(gp.team::text, 'TEAM_A')) = 'TEAM_A')
             )
            THEN g.id
          END)::int AS lost_count
         FROM public.games g
         LEFT JOIN public.game_players gp ON gp.game_id = g.id AND gp.user_id = $1
         WHERE gp.user_id = $1 OR g.creator_id = $1;`,
        [userId],
      )
      .catch(() => ({
        rows: [
          {
            joined_count: 0,
            played_count: 0,
            won_count: 0,
            drawn_count: 0,
            lost_count: 0,
          },
        ],
      }));

    const dynamicStats = statsRes.rows[0] || {
      joined_count: 0,
      played_count: 0,
      won_count: 0,
      drawn_count: 0,
      lost_count: 0,
    };

    const row = res.rows[0] || {};

    /* Always use the live dynamic calculations from games and game_players */
    const matchesJoined = dynamicStats.joined_count || 0;
    const matchesPlayed = dynamicStats.played_count || 0;
    const matchesWon = dynamicStats.won_count || 0;
    const matchesDrawn = dynamicStats.drawn_count || 0;
    const matchesLost = dynamicStats.lost_count || 0;

    const goalsScored = Number(row.goals_scored ?? row.goals ?? 0);
    const assists = Number(row.assists ?? 0);
    const motmCount = Number(row.motm_count ?? row.motm ?? 0);

    const winRatePercentage =
      matchesPlayed > 0
        ? Number(((matchesWon / matchesPlayed) * 100).toFixed(1))
        : 0.0;

    try {
      await dbPool.query(
        `INSERT INTO public.player_stats (user_id, matches_played, wins, draws, losses, win_rate, goals_scored, assists, motm_count, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
         ON CONFLICT (user_id) DO UPDATE SET
           matches_played = EXCLUDED.matches_played,
           wins = EXCLUDED.wins,
           draws = EXCLUDED.draws,
           losses = EXCLUDED.losses,
           win_rate = EXCLUDED.win_rate,
           goals_scored = EXCLUDED.goals_scored,
           assists = EXCLUDED.assists,
           motm_count = EXCLUDED.motm_count,
           updated_at = CURRENT_TIMESTAMP;`,
        [
          userId,
          matchesPlayed,
          matchesWon,
          matchesDrawn,
          matchesLost,
          winRatePercentage,
          goalsScored,
          assists,
          motmCount,
        ],
      );
    } catch (_) {}

    return {
      matchesJoined,
      matches_joined: matchesJoined,
      matchesPlayed,
      matches_played: matchesPlayed,
      matchesWon,
      matches_won: matchesWon,
      matchesLost,
      matches_lost: matchesLost,
      matchesDrawn,
      matches_drawn: matchesDrawn,
      goalsScored,
      goals_scored: goalsScored,
      assists,
      motmCount,
      motm_count: motmCount,
      winRatePercentage,
      win_rate_percentage: winRatePercentage,
    };
  }

  static async getHistory(
    userId: string,
    limit = 20,
    offset = 0,
    statusFilter?: string,
  ) {
    const conditions: string[] = [
      "(gp.user_id = $1 OR g.creator_id = $1)",
      "(UPPER(g.status::text) IN ('COMPLETED', 'CANCELLED') OR g.match_date::date <= CURRENT_DATE)",
    ];
    const values: any[] = [userId];
    let idx = 2;

    if (statusFilter && statusFilter.toUpperCase() !== "ALL") {
      const upperStatus = statusFilter.toUpperCase();
      if (upperStatus === "COMPLETED") {
        conditions.push(`UPPER(g.status::text) = 'COMPLETED'`);
      } else {
        conditions.push(`UPPER(g.status::text) = $${idx++}`);
        values.push(upperStatus);
      }
    }

    values.push(limit, offset);

    const query = `
       SELECT g.id, COALESCE(crt.club_id, 'all_stars_arena_club') as club_id, g.court_id, g.creator_id, g.creator_role_name, g.created_by_player, g.title, g.description,
              to_char(g.match_date::date, 'YYYY-MM-DD') as match_date, g.start_time, g.end_time,
              g.status, g.format, 'PUBLIC' as privacy, g.entry_fee, g.entry_fee as per_player_fee, g.entry_fee as my_entry_fee,
              g.team_a_score, g.team_b_score, g.winner_team,
              COALESCE(g.cancellation_reason, g.rejection_reason) as cancellation_reason,
              g.rejection_reason,
              CASE
                WHEN COALESCE(g.cancellation_reason, '') ILIKE '%host%' OR COALESCE(g.cancellation_reason, '') ILIKE '%player%' THEN 'HOST'
                WHEN COALESCE(g.cancellation_reason, '') ILIKE '%manager%' OR COALESCE(g.rejection_reason, '') ILIKE '%manager%' OR g.approval_status = 'REJECTED' OR g.manager_id IS NOT NULL THEN 'MANAGER'
                WHEN COALESCE(g.cancellation_reason, '') ILIKE '%admin%' THEN 'ADMIN'
                WHEN COALESCE(g.cancellation_reason, '') ILIKE '%auto%' THEN 'SYSTEM'
                WHEN g.status = 'CANCELLED' AND g.created_by_player = true AND g.manager_id IS NULL THEN 'HOST'
                WHEN g.status = 'CANCELLED' THEN 'MANAGER'
                ELSE NULL
              END as cancelled_by,
              COALESCE(
                (SELECT gv.video_url FROM public.game_videos gv WHERE gv.game_id = g.id AND gv.status = 'AVAILABLE' ORDER BY gv.created_at ASC LIMIT 1),
                g.video_playback_url
              ) as video_playback_url,
              CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END as court_name,
              c.name as club_name,
              COALESCE(gp.team, 'TEAM_A') as my_team, COALESCE(gp.position, 'MID') as my_position,
              CASE
                WHEN UPPER(g.status::text) = 'CANCELLED' THEN 'CANCELLED'
                WHEN UPPER(g.status::text) <> 'COMPLETED' THEN 'PENDING'
                WHEN g.winner_team = 'DRAW' THEN 'DRAW'
                WHEN (COALESCE(gp.team, 'TEAM_A') = 'TEAM_A' AND g.winner_team = 'TEAM_A') OR (COALESCE(gp.team, 'TEAM_A') = 'TEAM_B' AND g.winner_team = 'TEAM_B') THEN 'WIN'
                ELSE 'LOSS'
              END as result,
              (SELECT COUNT(*) FROM public.game_players gp_cnt WHERE gp_cnt.game_id = g.id) as current_players_count,
              (
                SELECT COALESCE(json_agg(
                  json_build_object(
                    'userId', gp_r.user_id,
                    'user_id', gp_r.user_id,
                    'name', COALESCE(pu.name, 'Player'),
                    'profileImageUrl', pu.profile_image_url,
                    'profile_image_url', pu.profile_image_url,
                    'team', UPPER(COALESCE(NULLIF(gp_r.team::text, ''), 'TEAM_A')),
                    'position', COALESCE(gp_r.position, 'MID'),
                    'paymentStatus', COALESCE(gp_r.payment_status, 'PAID'),
                    'payment_status', COALESCE(gp_r.payment_status, 'PAID'),
                    'phone', pu.phone
                  )
                  ORDER BY gp_r.team ASC, gp_r.joined_at ASC
                ), '[]'::json)
                FROM public.game_players gp_r
                JOIN public.users pu ON pu.id = gp_r.user_id
                WHERE gp_r.game_id = g.id
              ) as roster
       FROM public.games g
       LEFT JOIN public.game_players gp ON gp.game_id = g.id AND gp.user_id = $1
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs c ON c.id = crt.club_id
       WHERE ${conditions.join(" AND ")}
       ORDER BY g.match_date DESC, g.start_time DESC, g.created_at DESC
       LIMIT $${idx++} OFFSET $${idx++};`;

    const res = await dbPool.query(query, values);
    return res.rows;
  }

  static async getDashboardSummary(userId: string) {
    try {
      await dbPool.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE status NOT IN ('COMPLETED', 'CANCELLED')
           AND (match_date + end_time) <= CURRENT_TIMESTAMP;`,
      );
    } catch (_) {}

    const profile = await this.getProfile(userId);
    const stats = await this.getStats(userId);

    const activeRes = await dbPool.query(
      `SELECT g.*,
              TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
              TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
              TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
              COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name, gp.team as user_team, gp.position as user_position
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs c ON c.id = crt.club_id
       WHERE gp.user_id = $1
         AND (
           g.status = 'ONGOING'
           OR (g.status NOT IN ('COMPLETED', 'CANCELLED') AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP AND (g.match_date + g.end_time) > CURRENT_TIMESTAMP)
         )
       ORDER BY g.match_date DESC, g.start_time DESC LIMIT 1;`,
      [userId],
    );

    const upcomingRes = await dbPool.query(
      `SELECT g.*,
              TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
              TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
              TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
              COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name, gp.team as user_team, gp.position as user_position
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs c ON c.id = crt.club_id
       WHERE gp.user_id = $1
         AND g.status NOT IN ('COMPLETED', 'CANCELLED')
         AND (g.match_date + g.start_time) > CURRENT_TIMESTAMP
       ORDER BY g.match_date ASC, g.start_time ASC LIMIT 1;`,
      [userId],
    );

    const recentRes = await dbPool.query(
      `SELECT g.*,
              TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
              TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
              TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
              COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name, gp.team as user_team, gp.position as user_position,
              CASE
                WHEN g.winner_team = 'DRAW' THEN 'DRAW'
                WHEN (gp.team = 'TEAM_A' AND g.winner_team = 'TEAM_A') OR (gp.team = 'TEAM_B' AND g.winner_team = 'TEAM_B') THEN 'WIN'
                ELSE 'LOSS'
              END as result
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       LEFT JOIN public.clubs c ON c.id = crt.club_id
       WHERE gp.user_id = $1
         AND (g.status::text IN ('COMPLETED', 'CANCELLED') OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP)
       ORDER BY g.match_date DESC, g.start_time DESC LIMIT 1;`,
      [userId],
    );

    return {
      profile,
      stats,
      activeMatch: activeRes.rows[0] || null,
      upcomingMatch: upcomingRes.rows[0] || null,
      recentMatch: recentRes.rows[0] || null,
      walletBalance: profile?.walletBalance || 0,
    };
  }

  static async getMyMatches(userId: string, tab: string) {
    try {
      await dbPool.query(
        `UPDATE public.games
         SET status = 'COMPLETED', updated_at = CURRENT_TIMESTAMP
         WHERE status NOT IN ('COMPLETED', 'CANCELLED')
           AND (match_date + end_time) <= CURRENT_TIMESTAMP;`,
      );
    } catch (_) {}

    let query = "";
    let params: any[] = [userId];

    if (tab === "WAITLISTED") {
      query = `
        SELECT g.*,
               TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
               TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
               TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
               COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name, gw.position as waitlist_position, gw.status as waitlist_status, gw.joined_at as waitlist_joined_at
        FROM public.game_waitlist gw
        JOIN public.games g ON g.id = gw.game_id
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        LEFT JOIN public.clubs c ON c.id = crt.club_id
        WHERE gw.user_id = $1
        ORDER BY g.match_date ASC, g.start_time ASC;
      `;
    } else if (tab === "PAST" || tab === "COMPLETED" || tab === "HISTORY") {
      query = `
        SELECT COALESCE(gp.team, 'TEAM_A') as user_team, COALESCE(gp.position, 'MID') as user_position, COALESCE(gp.payment_status, 'PAID') as payment_status,
               g.*,
               TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
               TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
               TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
               COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name,
               COALESCE(g.cancellation_reason, g.rejection_reason) as cancellation_reason,
               CASE
                 WHEN COALESCE(g.cancellation_reason, '') ILIKE '%host%' OR COALESCE(g.cancellation_reason, '') ILIKE '%player%' THEN 'HOST'
                 WHEN COALESCE(g.cancellation_reason, '') ILIKE '%manager%' OR COALESCE(g.rejection_reason, '') ILIKE '%manager%' OR g.approval_status = 'REJECTED' OR g.manager_id IS NOT NULL THEN 'MANAGER'
                 WHEN COALESCE(g.cancellation_reason, '') ILIKE '%admin%' THEN 'ADMIN'
                 WHEN COALESCE(g.cancellation_reason, '') ILIKE '%auto%' THEN 'SYSTEM'
                 WHEN g.status = 'CANCELLED' AND g.created_by_player = true AND g.manager_id IS NULL THEN 'HOST'
                 WHEN g.status = 'CANCELLED' THEN 'MANAGER'
                 ELSE NULL
               END as cancelled_by,
               (SELECT COUNT(*) FROM public.game_players gp2 WHERE gp2.game_id = g.id) as current_players_count
        FROM public.games g
        LEFT JOIN public.game_players gp ON gp.game_id = g.id AND gp.user_id = $1
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        LEFT JOIN public.clubs c ON c.id = crt.club_id
        WHERE (gp.user_id = $1 OR g.creator_id = $1)
          AND (g.status::text IN ('COMPLETED', 'CANCELLED') OR (g.match_date + g.end_time) <= CURRENT_TIMESTAMP)
        ORDER BY g.match_date DESC, g.start_time DESC;
      `;
    } else if (tab === "ONGOING") {
      query = `
        SELECT COALESCE(gp.team, 'TEAM_A') as user_team, COALESCE(gp.position, 'MID') as user_position, COALESCE(gp.payment_status, 'PAID') as payment_status,
               g.*,
               TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
               TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
               TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
               COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name,
               (SELECT COUNT(*) FROM public.game_players gp2 WHERE gp2.game_id = g.id) as current_players_count
        FROM public.games g
        LEFT JOIN public.game_players gp ON gp.game_id = g.id AND gp.user_id = $1
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        LEFT JOIN public.clubs c ON c.id = crt.club_id
        WHERE (gp.user_id = $1 OR g.creator_id = $1)
          AND UPPER(g.status::text) NOT IN ('COMPLETED', 'CANCELLED', 'FINISHED')
          AND COALESCE(g.approval_status, 'APPROVED') <> 'REJECTED'
          AND (
            g.status = 'ONGOING'
            OR ((g.match_date + g.start_time) <= CURRENT_TIMESTAMP AND (g.match_date + g.end_time) > CURRENT_TIMESTAMP)
          )
        ORDER BY g.match_date DESC, g.start_time DESC;
      `;
    } else {
      // UPCOMING / Active matches
      query = `
        SELECT COALESCE(gp.team, 'TEAM_A') as user_team, COALESCE(gp.position, 'MID') as user_position, COALESCE(gp.payment_status, 'PAID') as payment_status,
               g.*,
               TO_CHAR(g.match_date, 'YYYY-MM-DD') as match_date,
               TO_CHAR(g.start_time, 'HH24:MI:SS') as start_time,
               TO_CHAR(g.end_time, 'HH24:MI:SS') as end_time,
               COALESCE(c.name, 'All Stars Turf Raipur') as club_name, COALESCE(crt.name, 'Court 1') as court_name,
               (SELECT COUNT(*) FROM public.game_players gp2 WHERE gp2.game_id = g.id) as current_players_count
        FROM public.games g
        LEFT JOIN public.game_players gp ON gp.game_id = g.id AND gp.user_id = $1
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        LEFT JOIN public.clubs c ON c.id = crt.club_id
        WHERE (gp.user_id = $1 OR g.creator_id = $1)
          AND UPPER(g.status::text) NOT IN ('COMPLETED', 'CANCELLED', 'FINISHED')
          AND COALESCE(g.approval_status, 'APPROVED') <> 'REJECTED'
          AND (g.match_date + g.start_time) > CURRENT_TIMESTAMP
        ORDER BY g.match_date ASC, g.start_time ASC;
      `;
    }

    const res = await dbPool.query(query, params);
    return res.rows;
  }
}
