import { Request, Response } from "express";
import { dbPool } from "../../config/db.config.js";
import { ApiResponse } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";

export const getLeaderboardController = asyncHandler(
  async (req: Request, res: Response) => {
    const city = req.query.city as string;
    const limit = Math.min(100, Number(req.query.limit) || 50);

    const query = city
      ? `SELECT u.id, u.name, u.city, u.profile_image_url as avatar_url,
              ps.matches_played, ps.wins, ps.points, ps.goals_scored, ps.win_rate
       FROM public.users u
       JOIN public.player_stats ps ON ps.user_id = u.id
       WHERE u.city = $1 AND u.status = 'ACTIVE'
       ORDER BY ps.points DESC, ps.wins DESC, ps.goals_scored DESC
       LIMIT $2;`
      : `SELECT u.id, u.name, u.city, u.profile_image_url as avatar_url,
              ps.matches_played, ps.wins, ps.points, ps.goals_scored, ps.win_rate
       FROM public.users u
       JOIN public.player_stats ps ON ps.user_id = u.id
       WHERE u.status = 'ACTIVE'
       ORDER BY ps.points DESC, ps.wins DESC, ps.goals_scored DESC
       LIMIT $1;`;

    const values = city ? [city, limit] : [limit];
    const resDb = await dbPool.query(query, values);

    res
      .status(200)
      .json(ApiResponse.success("Leaderboard rankings retrieved", resDb.rows));
  },
);
