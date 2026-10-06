import { dbPool } from '../../config/db.config.js';
import { sendUserNotification } from '../../services/realtime.service.js';
import { ApiError } from '../../utils/apiResponse.js';

export class TournamentsService {
  static async getTournaments(city?: string) {
    const query = city
      ? `SELECT * FROM public.tournaments WHERE city = $1 ORDER BY start_date ASC;`
      : `SELECT * FROM public.tournaments ORDER BY start_date ASC;`;
    const res = await dbPool.query(query, city ? [city] : []);
    return res.rows;
  }

  static async getTournamentById(tournamentId: string) {
    const tournRes = await dbPool.query(
      `SELECT t.*, c.name as club_name FROM public.tournaments t LEFT JOIN public.clubs c ON c.id = t.club_id WHERE t.id = $1;`,
      [tournamentId]
    );

    if (tournRes.rows.length === 0) {
      throw new ApiError(404, 'Tournament not found', 'TOURNAMENT_NOT_FOUND');
    }

    const teamsRes = await dbPool.query(
      `SELECT tm.*, u.name as captain_name
       FROM public.tournament_teams tm
       JOIN public.users u ON u.id = tm.captain_id
       WHERE tm.tournament_id = $1;`,
      [tournamentId]
    );

    const bracketRes = await dbPool.query(
      `SELECT bm.*, ta.name as team_a_name, tb.name as team_b_name
       FROM public.tournament_bracket_matches bm
       LEFT JOIN public.tournament_teams ta ON ta.id = bm.team_a_id
       LEFT JOIN public.tournament_teams tb ON tb.id = bm.team_b_id
       WHERE bm.tournament_id = $1
       ORDER BY bm.match_order ASC;`,
      [tournamentId]
    );

    return {
      tournament: tournRes.rows[0],
      teams: teamsRes.rows,
      bracket: bracketRes.rows,
    };
  }

  static async registerTeam(userId: string, tournamentId: string, teamName: string, logo = '⚡') {
    const tourn = await dbPool.query('SELECT * FROM public.tournaments WHERE id = $1;', [
      tournamentId,
    ]);
    if (tourn.rows.length === 0) {
      throw new ApiError(404, 'Tournament not found', 'TOURNAMENT_NOT_FOUND');
    }

    // Insert team (DB trigger trg_sync_tournament_team_count updates team count & enforces max_teams!)
    const res = await dbPool.query(
      `INSERT INTO public.tournament_teams (tournament_id, name, captain_id, logo, status)
       VALUES ($1, $2, $3, $4, 'CONFIRMED') RETURNING *;`,
      [tournamentId, teamName, userId, logo]
    );

    sendUserNotification(userId, {
      title: '🏆 Tournament Registration Successful',
      message: `Your team '${teamName}' is registered for ${tourn.rows[0].title}!`,
      type: 'SUCCESS',
    });

    return res.rows[0];
  }
}
