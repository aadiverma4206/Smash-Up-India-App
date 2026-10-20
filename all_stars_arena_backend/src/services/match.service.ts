import { dbPool } from "../config/db.config.js";
import { getSocketIO } from "../config/socket.config.js";
import { ApiError } from "../utils/apiResponse.js";
import { logger } from "../utils/logger.js";

export interface ScoreUpdatePayload {
  gameId: string;
  teamAScore: number;
  teamBScore: number;
  isFinal?: boolean;
  eventText?: string;
  updatedByUserId?: string;
}

export const updateLiveMatchScore = async (payload: ScoreUpdatePayload) => {
  const {
    gameId,
    teamAScore,
    teamBScore,
    isFinal = false,
    eventText,
    updatedByUserId,
  } = payload;

  const gameRes = await dbPool.query(
    "SELECT * FROM public.games WHERE id = $1;",
    [gameId],
  );
  if (gameRes.rows.length === 0) {
    throw new ApiError(404, "Match not found");
  }

  const game = gameRes.rows[0];
  if (game.status === "CANCELLED") {
    throw new ApiError(
      400,
      "Cannot submit or update scores for a cancelled match",
      "CANCELLED_MATCH_SCORE_FORBIDDEN",
    );
  }

  const logRes = await dbPool.query(
    `INSERT INTO public.live_score_logs
     (game_id, team_a_score, team_b_score, updated_by_user_id, is_final)
     VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at;`,
    [gameId, teamAScore, teamBScore, updatedByUserId || null, isFinal],
  );

  if (!isFinal) {
    await dbPool.query(
      `UPDATE public.games
       SET team_a_score = $1, team_b_score = $2, status = 'ONGOING'
       WHERE id = $3;`,
      [teamAScore, teamBScore, gameId],
    );
  }

  const updatedGame = (
    await dbPool.query("SELECT * FROM public.games WHERE id = $1;", [gameId])
  ).rows[0];

  const socketPayload = {
    gameId,
    teamAScore,
    teamBScore,
    isFinal,
    matchStatus: updatedGame.status,
    eventText: eventText || (isFinal ? "🏁 MATCH COMPLETED" : "⚽ GOAL!"),
    timestamp: new Date().toISOString(),
  };

  try {
    const io = getSocketIO();

    io.to(`game:${gameId}`).emit("match:score_update", socketPayload);

    io.emit("match:live_feed", socketPayload);

    logger.info(
      `⚽ [Real-Time Score] Game ${gameId}: Team A ${teamAScore} - ${teamBScore} Team B`,
    );
  } catch (err: any) {
    logger.error(
      "Failed to emit live score update via Socket.IO:",
      err.message,
    );
  }

  return socketPayload;
};

export const getLiveMatches = async () => {
  const res = await dbPool.query(
    `SELECT g.*, c.name as club_name, c.address as club_address
     FROM public.games g
     LEFT JOIN public.clubs c ON c.id = g.club_id
     ORDER BY g.match_date ASC, g.start_time ASC;`,
  );
  return res.rows;
};

export const getMatchDetails = async (gameId: string) => {
  const gameRes = await dbPool.query(
    `SELECT g.*, c.name as club_name, crt.name as court_name
     FROM public.games g
     LEFT JOIN public.clubs c ON c.id = g.club_id
     LEFT JOIN public.courts crt ON crt.id = g.court_id
     WHERE g.id = $1;`,
    [gameId],
  );

  if (gameRes.rows.length === 0) {
    throw new ApiError(404, "Match not found");
  }

  const playersRes = await dbPool.query(
    `SELECT gp.*, u.name, u.profile_image_url, pd.elo_rating, pd.ovr_rating
     FROM public.game_players gp
     JOIN public.users u ON u.id = gp.user_id
     LEFT JOIN public.player_details pd ON pd.user_id = gp.user_id
     WHERE gp.game_id = $1;`,
    [gameId],
  );

  const scoreLogsRes = await dbPool.query(
    `SELECT * FROM public.live_score_logs
     WHERE game_id = $1 ORDER BY created_at DESC;`,
    [gameId],
  );

  return {
    match: gameRes.rows[0],
    players: playersRes.rows,
    scoreLogs: scoreLogsRes.rows,
  };
};
