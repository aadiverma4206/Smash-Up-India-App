const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

const statements = [
  // 1. Users normalized phone lookup
  `CREATE INDEX idx_users_phone_10digits ON public.users (("right"(regexp_replace((phone)::text, '[^0-9]'::text, ''::text, 'g'::text), 10))) WHERE phone IS NOT NULL;`,

  // 2. Games match discovery & FKs
  `CREATE INDEX idx_games_discovery_composite ON public.games (status, approval_status, match_date ASC, start_time ASC);`,
  `CREATE INDEX idx_games_creator_id ON public.games (creator_id);`,
  `CREATE INDEX idx_games_manager_id ON public.games (manager_id) WHERE manager_id IS NOT NULL;`,

  // 3. Game Waitlist & Slot Requests FKs
  `CREATE INDEX idx_game_waitlist_user_id ON public.game_waitlist (user_id);`,
  `CREATE INDEX idx_game_slot_requests_user_status ON public.game_slot_requests (user_id, status);`,

  // 4. Wallet Transactions (Core Financial Ledger)
  `CREATE INDEX idx_wallet_transactions_user_created ON public.wallet_transactions (user_id, created_at DESC);`,
  `CREATE INDEX idx_wallet_transactions_reference_id ON public.wallet_transactions (reference_id) WHERE reference_id IS NOT NULL;`,

  // 5. CCTV Surveillance System
  `CREATE INDEX idx_cctv_recordings_game_id ON public.cctv_recordings (game_id);`,
  `CREATE INDEX idx_cctv_recordings_status_deadline ON public.cctv_recordings (status, stop_deadline) WHERE status = 'RECORDING';`,
  `CREATE INDEX idx_cctv_recordings_rec_status ON public.cctv_recordings (recording_status) WHERE recording_status IN ('RECORDING', 'POST_MATCH');`,
  `CREATE INDEX idx_cctv_recordings_camera_id ON public.cctv_recordings (camera_id) WHERE camera_id IS NOT NULL;`,
  `CREATE INDEX idx_cctv_segments_recording_order ON public.cctv_recording_segments (recording_id, segment_order ASC);`,
  `CREATE INDEX idx_cctv_segments_game_id ON public.cctv_recording_segments (game_id);`,
  `CREATE INDEX idx_cctv_events_recording ON public.cctv_recording_events (recording_id, event_time DESC);`,

  // 6. Tournaments & Teams
  `CREATE INDEX idx_tournaments_city_start ON public.tournaments (city, start_date ASC);`,
  `CREATE INDEX idx_tournaments_start ON public.tournaments (start_date ASC);`,
  `CREATE INDEX idx_tournament_teams_captain ON public.tournament_teams (captain_id);`,

  // 7. Notifications & Feed
  `CREATE INDEX idx_notifications_user_created ON public.notifications (user_id, created_at DESC);`,
  `CREATE INDEX idx_notifications_game_id ON public.notifications (game_id) WHERE game_id IS NOT NULL;`,
  `CREATE INDEX idx_community_posts_author ON public.community_posts (author_id);`
];

async function validateAllStatements() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN;');
    for (const sql of statements) {
      console.log('Testing SQL:', sql);
      await client.query(sql);
    }
    console.log('ALL', statements.length, 'INDEX STATEMENTS VALIDATED WITH 100% SUCCESS!');
    await client.query('ROLLBACK;');
    console.log('Rolled back test successfully. Schema unchanged.');
  } catch (err) {
    await client.query('ROLLBACK;');
    console.error('Validation error:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

validateAllStatements();
