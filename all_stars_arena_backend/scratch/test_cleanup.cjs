const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    console.log('Transaction started for dry run...');

    // Disable triggers during the cleanup session
    await client.query("SET session_replication_role = 'replica';");
    console.log('session_replication_role set to replica');

    // 1. List of tables to completely empty
    const tablesToEmpty = [
      'audit_logs',
      'cctv_recording_segments',
      'cctv_recording_events',
      'cctv_recordings',
      'cctv_cameras',
      'challenge_progress',
      'challenges',
      'community_posts',
      'post_comments',
      'post_likes',
      'poll_votes',
      'poll_options',
      'polls',
      'game_activity_logs',
      'live_score_logs',
      'match_disputes',
      'player_match_results',
      'game_videos',
      'game_waitlist',
      'game_slot_requests',
      'game_players',
      'games',
      'court_bookings',
      'tournament_bracket_matches',
      'tournament_teams',
      'tournaments',
      'payment_webhook_events',
      'payment_orders',
      'wallet_transactions',
      'transactions',
      'notifications',
      'otp_verifications',
      'support_tickets',
      'user_device_tokens',
      'user_identity_history',
      'user_sessions',
    ];

    for (const tbl of tablesToEmpty) {
      const res = await client.query(`DELETE FROM public."${tbl}"`);
      console.log(`Cleared ${tbl} (${res.rowCount} rows removed)`);
    }

    // 2. Target user emails from login page icons
    const targetEmails = ['player@gmail.com', 'roshan12@gmail.com', 'aadiverma4206@gmail.com'];
    const usersRes = await client.query(
      `SELECT id, email, role_id FROM public.users WHERE email = ANY($1)`,
      [targetEmails]
    );
    const targetUserIds = usersRes.rows.map(r => r.id);
    console.log('Target user IDs to keep:', targetUserIds);

    // 3. Clean up profile tables to only keep the target users
    const delStats = await client.query(
      `DELETE FROM public.player_stats WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'player@gmail.com')`
    );
    console.log(`Cleared player_stats (${delStats.rowCount} rows removed)`);

    const delPd = await client.query(
      `DELETE FROM public.player_details WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'player@gmail.com')`
    );
    console.log(`Cleared player_details (${delPd.rowCount} rows removed)`);

    const delMd = await client.query(
      `DELETE FROM public.manager_details WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'roshan12@gmail.com')`
    );
    console.log(`Cleared manager_details (${delMd.rowCount} rows removed)`);

    const delAd = await client.query(
      `DELETE FROM public.admin_details WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'aadiverma4206@gmail.com')`
    );
    console.log(`Cleared admin_details (${delAd.rowCount} rows removed)`);

    // 4. Clean up clubs & club_managers (preserve all_stars_arena_club for courts & roshan)
    const delCm = await client.query(
      `DELETE FROM public.club_managers WHERE club_id <> 'all_stars_arena_club' OR user_id NOT IN (SELECT id FROM public.users WHERE email = 'roshan12@gmail.com')`
    );
    console.log(`Cleared club_managers (${delCm.rowCount} rows removed)`);

    const delClubs = await client.query(
      `DELETE FROM public.clubs WHERE id <> 'all_stars_arena_club'`
    );
    console.log(`Cleared clubs (${delClubs.rowCount} rows removed)`);

    // 5. Delete all other users
    const delUsers = await client.query(
      `DELETE FROM public.users WHERE id <> ALL($1)`,
      [targetUserIds]
    );
    console.log(`Deleted other users (${delUsers.rowCount} rows removed)`);

    // Re-enable triggers
    await client.query("SET session_replication_role = 'origin';");
    console.log('session_replication_role restored to origin');

    // 6. Verify table counts
    const allTablesRes = await client.query(
      `SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;`
    );
    console.log('\n--- VERIFICATION OF COUNTS ---');
    for (const t of allTablesRes.rows.map(r => r.table_name)) {
      const cnt = await client.query(`SELECT COUNT(*) FROM public."${t}"`);
      console.log(`  ${t.padEnd(30)}: ${cnt.rows[0].count} rows`);
    }

    console.log('\nDry run succeeded without any errors!');
    await client.query('ROLLBACK');
    console.log('Transaction rolled back (dry run).');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Dry run failed:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
