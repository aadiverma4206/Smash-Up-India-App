import { dbPool } from "../../config/db.config.js";

export class PlayerRepository {
  static async getProfile(userId: string) {
    const res = await dbPool.query(
      `SELECT u.id, u.name, u.email, u.phone, u.city, u.bio, u.status as account_status, u.date_of_birth,
              COALESCE(u.profile_image_url, '') as avatar_url,
              pd.position, pd.secondary_position, pd.preferred_foot, pd.skill_level,
              pd.ovr_rating, pd.elo_rating, pd.badges, pd.wallet_balance
       FROM public.users u
       LEFT JOIN public.player_details pd ON pd.user_id = u.id
       WHERE u.id = $1;`,
      [userId],
    );
    const row = res.rows[0];
    if (!row) return null;
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
      dateOfBirth: row.date_of_birth
        ? row.date_of_birth.toISOString().split("T")[0]
        : null,
      position: row.position || "ST",
      secondaryPosition: row.secondary_position || null,
      preferredFoot: row.preferred_foot || "Right",
      preferred_foot: row.preferred_foot || "Right",
      skillLevel: row.skill_level || "AMATEUR",
      skill_level: row.skill_level || "AMATEUR",
      ovr: row.ovr_rating || 75,
      ovr_rating: row.ovr_rating || 75,
      elo: row.elo_rating || 1200,
      elo_rating: row.elo_rating || 1200,
      walletBalance: parseFloat(row.wallet_balance || "0.00"),
      wallet_balance: parseFloat(row.wallet_balance || "0.00"),
      accountStatus: row.account_status || "ACTIVE",
    };
  }

  static async updateProfile(
    userId: string,
    data: {
      name?: string;
      bio?: string;
      city?: string;
      avatarUrl?: string;
      dateOfBirth?: string;
      position?: string;
      secondaryPosition?: string;
      preferredFoot?: string;
      skillLevel?: string;
    },
  ) {
    if (
      data.name ||
      data.bio ||
      data.city ||
      data.avatarUrl ||
      data.dateOfBirth
    ) {
      const userFields: string[] = [];
      const userVals: any[] = [];
      let idx = 1;

      if (data.name) {
        userFields.push(`name = $${idx++}`);
        userVals.push(data.name);
      }
      if (data.bio !== undefined) {
        userFields.push(`bio = $${idx++}`);
        userVals.push(data.bio);
      }
      if (data.city) {
        userFields.push(`city = $${idx++}`);
        userVals.push(data.city);
      }
      if (data.avatarUrl) {
        userFields.push(`profile_image_url = $${idx++}`);
        userVals.push(data.avatarUrl);
      }
      if (data.dateOfBirth) {
        userFields.push(`date_of_birth = $${idx++}`);
        userVals.push(data.dateOfBirth);
      }
      userFields.push(`updated_at = CURRENT_TIMESTAMP`);

      userVals.push(userId);
      await dbPool.query(
        `UPDATE public.users SET ${userFields.join(", ")} WHERE id = $${idx};`,
        userVals,
      );
    }

    if (
      data.position ||
      data.secondaryPosition ||
      data.preferredFoot ||
      data.skillLevel
    ) {
      const pdFields: string[] = [];
      const pdVals: any[] = [];
      let idx = 1;

      if (data.position) {
        pdFields.push(`position = $${idx++}`);
        pdVals.push(data.position);
      }
      if (data.secondaryPosition !== undefined) {
        pdFields.push(`secondary_position = $${idx++}`);
        pdVals.push(data.secondaryPosition);
      }
      if (data.preferredFoot) {
        pdFields.push(`preferred_foot = $${idx++}`);
        pdVals.push(data.preferredFoot);
      }
      if (data.skillLevel) {
        pdFields.push(`skill_level = $${idx++}`);
        pdVals.push(data.skillLevel);
      }
      pdFields.push(`updated_at = CURRENT_TIMESTAMP`);

      pdVals.push(userId);
      await dbPool.query(
        `UPDATE public.player_details SET ${pdFields.join(", ")} WHERE user_id = $${idx};`,
        pdVals,
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
    const res = await dbPool.query(
      `SELECT * FROM public.player_stats WHERE user_id = $1;`,
      [userId],
    );
    const joinedRes = await dbPool
      .query(
        `SELECT COUNT(*)::int as joined_count FROM public.game_players WHERE user_id = $1;`,
        [userId],
      )
      .catch(() => ({ rows: [{ joined_count: 0 }] }));

    const matchesJoined = joinedRes.rows[0]?.joined_count || 0;
    const row = res.rows[0];

    if (!row) {
      return {
        matchesJoined: matchesJoined,
        matches_joined: matchesJoined,
        matchesPlayed: 0,
        matches_played: 0,
        matchesWon: 0,
        matches_won: 0,
        matchesLost: 0,
        matches_lost: 0,
        matchesDrawn: 0,
        matches_drawn: 0,
        goalsScored: 0,
        goals_scored: 0,
        assists: 0,
        motmCount: 0,
        motm_count: 0,
        winRatePercentage: 0.0,
        win_rate_percentage: 0.0,
      };
    }

    const played = row.matches_played || 0;
    return {
      matchesJoined: matchesJoined > 0 ? matchesJoined : played,
      matches_joined: matchesJoined > 0 ? matchesJoined : played,
      matchesPlayed: played,
      matches_played: played,
      matchesWon: row.matches_won || 0,
      matches_won: row.matches_won || 0,
      matchesLost: row.matches_lost || 0,
      matches_lost: row.matches_lost || 0,
      matchesDrawn: row.matches_drawn || 0,
      matches_drawn: row.matches_drawn || 0,
      goalsScored: row.goals_scored || 0,
      goals_scored: row.goals_scored || 0,
      assists: row.assists || 0,
      motmCount: row.motm_count || 0,
      motm_count: row.motm_count || 0,
      winRatePercentage: parseFloat(row.win_rate_percentage) || 0.0,
      win_rate_percentage: parseFloat(row.win_rate_percentage) || 0.0,
    };
  }

  static async getHistory(
    userId: string,
    limit = 20,
    offset = 0,
    statusFilter?: string,
  ) {
    const conditions: string[] = [
      "gp.user_id = $1",
      "UPPER(g.status::text) IN ('COMPLETED', 'CANCELLED', 'FINISHED')",
      "(UPPER(g.status::text) = 'CANCELLED' OR g.match_date::date <= CURRENT_DATE)",
    ];
    const values: any[] = [userId];
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

    values.push(limit, offset);

    const query = `
       SELECT g.id, g.club_id, g.court_id, g.creator_id, g.title, g.description,
              to_char(g.match_date::date, 'YYYY-MM-DD') as match_date, g.start_time, g.end_time,
              g.status, g.format, g.privacy, g.entry_fee, g.entry_fee as per_player_fee, g.entry_fee as my_entry_fee,
              g.team_a_score, g.team_b_score, g.winner_team,
              COALESCE(
                (SELECT gv.video_url FROM public.game_videos gv WHERE gv.game_id = g.id AND gv.status = 'AVAILABLE' ORDER BY gv.created_at ASC LIMIT 1),
                g.video_playback_url
              ) as video_playback_url,
              CASE WHEN g.court_id = 'court_2' THEN 'Court 2' ELSE 'Court 1' END as court_name,
              c.name as club_name,
              gp.team as my_team, gp.position as my_position,
              CASE
                WHEN UPPER(g.status::text) NOT IN ('COMPLETED', 'FINISHED') THEN 'PENDING'
                WHEN g.winner_team = 'DRAW' THEN 'DRAW'
                WHEN (gp.team = 'TEAM_A' AND g.winner_team = 'TEAM_A') OR (gp.team = 'TEAM_B' AND g.winner_team = 'TEAM_B') THEN 'WIN'
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
                    'ovr', COALESCE(pd.ovr_rating, 80),
                    'paymentStatus', COALESCE(gp_r.payment_status, 'PAID'),
                    'payment_status', COALESCE(gp_r.payment_status, 'PAID'),
                    'phone', pu.phone
                  )
                  ORDER BY gp_r.team ASC, gp_r.joined_at ASC
                ), '[]'::json)
                FROM public.game_players gp_r
                JOIN public.users pu ON pu.id = gp_r.user_id
                LEFT JOIN public.player_details pd ON pd.user_id = gp_r.user_id
                WHERE gp_r.game_id = g.id
              ) as roster
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.clubs c ON c.id = g.club_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       WHERE ${conditions.join(" AND ")}
       ORDER BY g.match_date DESC, g.start_time DESC, g.created_at DESC
       LIMIT $${idx++} OFFSET $${idx++};`;

    const res = await dbPool.query(query, values);
    return res.rows;
  }

  static async getDashboardSummary(userId: string) {
    const profile = await this.getProfile(userId);
    const stats = await this.getStats(userId);

    const activeRes = await dbPool.query(
      `SELECT g.*, c.name as club_name, crt.name as court_name, gp.team as user_team, gp.position as user_position
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.clubs c ON c.id = g.club_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       WHERE gp.user_id = $1 AND g.status = 'ONGOING'
       ORDER BY g.match_date DESC, g.start_time DESC LIMIT 1;`,
      [userId],
    );

    const upcomingRes = await dbPool.query(
      `SELECT g.*, c.name as club_name, crt.name as court_name, gp.team as user_team, gp.position as user_position
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.clubs c ON c.id = g.club_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       WHERE gp.user_id = $1 AND g.status IN ('OPEN_FOR_JOINING', 'FULL') AND (g.match_date > CURRENT_DATE OR (g.match_date = CURRENT_DATE AND g.start_time >= CURRENT_TIME))
       ORDER BY g.match_date ASC, g.start_time ASC LIMIT 1;`,
      [userId],
    );

    const recentRes = await dbPool.query(
      `SELECT g.*, c.name as club_name, crt.name as court_name, gp.team as user_team, gp.position as user_position,
              CASE
                WHEN g.winner_team = 'DRAW' THEN 'DRAW'
                WHEN (gp.team = 'TEAM_A' AND g.winner_team = 'TEAM_A') OR (gp.team = 'TEAM_B' AND g.winner_team = 'TEAM_B') THEN 'WIN'
                ELSE 'LOSS'
              END as result
       FROM public.game_players gp
       JOIN public.games g ON g.id = gp.game_id
       LEFT JOIN public.clubs c ON c.id = g.club_id
       LEFT JOIN public.courts crt ON crt.id = g.court_id
       WHERE gp.user_id = $1 AND g.status = 'COMPLETED'
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
    let query = "";
    let params: any[] = [userId];

    if (tab === "WAITLISTED") {
      query = `
        SELECT g.*, c.name as club_name, crt.name as court_name, gw.position as waitlist_position, gw.status as waitlist_status, gw.joined_at as waitlist_joined_at
        FROM public.game_waitlist gw
        JOIN public.games g ON g.id = gw.game_id
        LEFT JOIN public.clubs c ON c.id = g.club_id
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        WHERE gw.user_id = $1
        ORDER BY g.match_date ASC, g.start_time ASC;
      `;
    } else {
      let statusCondition = "";
      if (tab === "ONGOING") {
        statusCondition = "AND g.status = 'ONGOING'";
      } else {
        // UPCOMING / Active matches (completed & cancelled strictly excluded)
        statusCondition =
          "AND g.status IN ('OPEN_FOR_JOINING', 'FULL', 'CONFIRMED') AND g.status NOT IN ('COMPLETED', 'CANCELLED') AND (g.match_date > CURRENT_DATE OR (g.match_date = CURRENT_DATE AND g.start_time >= CURRENT_TIME))";
      }

      query = `
        SELECT gp.team as user_team, gp.position as user_position, gp.payment_status,
               g.*, c.name as club_name, crt.name as court_name,
               (SELECT COUNT(*) FROM public.game_players gp2 WHERE gp2.game_id = g.id) as current_players_count
        FROM public.game_players gp
        JOIN public.games g ON g.id = gp.game_id
        LEFT JOIN public.clubs c ON c.id = g.club_id
        LEFT JOIN public.courts crt ON crt.id = g.court_id
        WHERE gp.user_id = $1 ${statusCondition}
        ORDER BY g.match_date DESC, g.start_time DESC;
      `;
    }

    const res = await dbPool.query(query, params);
    return res.rows;
  }
}
