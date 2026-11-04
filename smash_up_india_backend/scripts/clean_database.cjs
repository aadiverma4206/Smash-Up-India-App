/**
 * Clean Database Script for Smash Up India
 * 
 * Preserves ONLY:
 * 1. roles table (all roles: ADMIN, MANAGER, PLAYER)
 * 2. courts table (court_1, court_2)
 * 3. users table: Only 3 users from Login Page Autofill:
 *    - Player: player@gmail.com (Password: Player@123)
 *    - Manager: roshan12@gmail.com (Password: Roshan@123)
 *    - Admin: aadiverma4206@gmail.com (Password: Admin@123)
 * 4. Respective profile records for the 3 users (player_details, player_stats, manager_details, admin_details)
 *    and club 'smash_up_india_club' with club_managers so foreign keys and manager permissions stay intact.
 * 
 * All other tables are completely cleared of data while keeping the schema intact.
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/smash_up_india',
});

async function cleanDatabase() {
  const client = await pool.connect();
  try {
    console.log('🚀 Starting database cleanup transaction...');
    await client.query('BEGIN');

    // Bypass mutation blocking triggers during cleanup
    await client.query("SET session_replication_role = 'replica';");

    // 1. Completely empty tables (0 rows)
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
      console.log(`- Cleared ${tbl.padEnd(28)}: ${res.rowCount} rows deleted`);
    }

    // 2. Identify target user IDs from login page icons
    const targetEmails = ['player@gmail.com', 'roshan12@gmail.com', 'aadiverma4206@gmail.com'];
    const usersRes = await client.query(
      `SELECT id, name, email, role_id FROM public.users WHERE email = ANY($1)`,
      [targetEmails]
    );
    const targetUserIds = usersRes.rows.map(r => r.id);
    console.log('\n✅ Preserved Users:');
    usersRes.rows.forEach(u => console.log(`   - [Role ${u.role_id}] ${u.name} <${u.email}> (ID: ${u.id})`));

    // 3. Keep profiles only for target users
    const delStats = await client.query(
      `DELETE FROM public.player_stats WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'player@gmail.com')`
    );
    console.log(`- Cleared player_stats         : ${delStats.rowCount} rows deleted`);

    const delPd = await client.query(
      `DELETE FROM public.player_details WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'player@gmail.com')`
    );
    console.log(`- Cleared player_details       : ${delPd.rowCount} rows deleted`);

    const delMd = await client.query(
      `DELETE FROM public.manager_details WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'roshan12@gmail.com')`
    );
    console.log(`- Cleared manager_details      : ${delMd.rowCount} rows deleted`);

    const delAd = await client.query(
      `DELETE FROM public.admin_details WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'aadiverma4206@gmail.com')`
    );
    console.log(`- Cleared admin_details        : ${delAd.rowCount} rows deleted`);

    // 4. Preserve smash_up_india_club (referenced by courts & roshan) and clean other clubs
    const delCm = await client.query(
      `DELETE FROM public.club_managers WHERE club_id <> 'smash_up_india_club' OR user_id NOT IN (SELECT id FROM public.users WHERE email = 'roshan12@gmail.com')`
    );
    console.log(`- Cleared club_managers        : ${delCm.rowCount} rows deleted`);

    const delClubs = await client.query(
      `DELETE FROM public.clubs WHERE id <> 'smash_up_india_club'`
    );
    console.log(`- Cleared clubs                : ${delClubs.rowCount} rows deleted`);

    // 5. Delete all other users
    const delUsers = await client.query(
      `DELETE FROM public.users WHERE id <> ALL($1)`,
      [targetUserIds]
    );
    console.log(`- Cleared users                : ${delUsers.rowCount} other users deleted`);

    // Restore replication role
    await client.query("SET session_replication_role = 'origin';");

    // Commit changes
    await client.query('COMMIT');
    console.log('\n✨ Database cleanup COMMITTED successfully!\n');

    // Verification of all tables
    const allTablesRes = await client.query(
      `SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;`
    );
    console.log('📊 Final database table row counts:');
    for (const t of allTablesRes.rows.map(r => r.table_name)) {
      const cnt = await client.query(`SELECT COUNT(*) FROM public."${t}"`);
      console.log(`   ${t.padEnd(30)}: ${cnt.rows[0].count} rows`);
    }

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Database cleanup failed, rolled back:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

cleanDatabase();
