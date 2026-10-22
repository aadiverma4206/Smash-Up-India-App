const pg = require('pg');
const fs = require('fs');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function runBenchmark() {
  const client = await pool.connect();
  const results = {};

  try {
    // 1. Match Discovery Default
    const q1 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT g.*, c.name as club_name, c.address as club_address, c.city, crt.name as court_name,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count
      FROM public.games g
      LEFT JOIN public.clubs c ON c.id = g.club_id
      LEFT JOIN public.courts crt ON crt.id = g.court_id
      WHERE g.status = 'OPEN_FOR_JOINING'
        AND g.approval_status IN ('APPROVED', 'PENDING_APPROVAL')
      ORDER BY g.match_date ASC, g.start_time ASC
      LIMIT 20 OFFSET 0;
    `);
    results.matchDiscoveryDefault = q1.rows[0]['QUERY PLAN'][0];

    // 2. Match Discovery Filtered by Date & Court
    const q2 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT g.*, c.name as club_name, c.address as club_address, c.city, crt.name as court_name,
             (SELECT COUNT(*) FROM public.game_players gp WHERE gp.game_id = g.id) as current_players_count
      FROM public.games g
      LEFT JOIN public.clubs c ON c.id = g.club_id
      LEFT JOIN public.courts crt ON crt.id = g.court_id
      WHERE g.match_date = '2026-11-15'
        AND g.court_id = 'court_2'
        AND g.status = 'OPEN_FOR_JOINING'
        AND g.approval_status IN ('APPROVED', 'PENDING_APPROVAL')
      ORDER BY g.match_date ASC, g.start_time ASC
      LIMIT 20 OFFSET 0;
    `);
    results.matchDiscoveryFiltered = q2.rows[0]['QUERY PLAN'][0];

    // 3. Login Query (findUserByIdentifier)
    const q3 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT u.*,
             ad.admin_type, ad.is_owner,
             md.employee_code
      FROM public.users u
      LEFT JOIN public.admin_details ad ON ad.user_id = u.id
      LEFT JOIN public.manager_details md ON md.user_id = u.id
      WHERE LOWER(TRIM(u.email)) = 'mgr_1792567420459_53838@example.com'
         OR TRIM(u.phone) = '+919814770462'
         OR TRIM(u.phone) = '9814770462'
         OR ('9814770462' <> '' AND LENGTH('9814770462') >= 10 AND RIGHT(REGEXP_REPLACE(u.phone, '[^0-9]', '', 'g'), 10) = RIGHT('9814770462', 10))
      LIMIT 1;
    `);
    results.loginQuery = q3.rows[0]['QUERY PLAN'][0];

    // 4. Player Search by Name ILIKE or GIN pg_trgm
    const q4 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT u.id, u.name, u.email, u.phone, u.city, u.profile_image_url
      FROM public.users u
      WHERE u.role_id = 3
        AND (u.name ILIKE '%Player%' OR u.phone ILIKE '%991%' OR u.email ILIKE '%test%')
      ORDER BY u.name ASC
      LIMIT 20;
    `);
    results.playerSearch = q4.rows[0]['QUERY PLAN'][0];

    // 5. Player Match History
    const q5 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT g.id, g.club_id, g.court_id, g.creator_id, g.title,
             to_char(g.match_date::date, 'YYYY-MM-DD') as match_date, g.start_time, g.end_time,
             g.status, g.format, g.privacy, g.entry_fee,
             gp.team as my_team, gp.position as my_position
      FROM public.game_players gp
      JOIN public.games g ON g.id = gp.game_id
      LEFT JOIN public.clubs c ON c.id = g.club_id
      LEFT JOIN public.courts crt ON crt.id = g.court_id
      WHERE gp.user_id = 'usr_51c1ff5e61a381ce'
        AND UPPER(g.status::text) IN ('COMPLETED', 'CANCELLED', 'FINISHED')
        AND (UPPER(g.status::text) = 'CANCELLED' OR g.match_date::date <= CURRENT_DATE)
      ORDER BY g.match_date DESC, g.start_time DESC, g.created_at DESC
      LIMIT 20 OFFSET 0;
    `);
    results.playerHistory = q5.rows[0]['QUERY PLAN'][0];

    // 6. Player Upcoming Matches
    const q6 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT gp.team as user_team, gp.position as user_position, gp.payment_status,
             g.*, c.name as club_name, crt.name as court_name
      FROM public.game_players gp
      JOIN public.games g ON g.id = gp.game_id
      LEFT JOIN public.clubs c ON c.id = g.club_id
      LEFT JOIN public.courts crt ON crt.id = g.court_id
      WHERE gp.user_id = 'usr_51c1ff5e61a381ce'
        AND g.status IN ('OPEN_FOR_JOINING', 'FULL')
        AND (g.match_date > CURRENT_DATE OR (g.match_date = CURRENT_DATE AND g.start_time >= CURRENT_TIME))
      ORDER BY g.match_date ASC, g.start_time ASC
      LIMIT 20 OFFSET 0;
    `);
    results.playerUpcomingMatches = q6.rows[0]['QUERY PLAN'][0];

    // 7. Wallet Transaction History (Stored Function)
    const q7 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT * FROM public.get_wallet_transaction_history('usr_51c1ff5e61a381ce', 50, 0);
    `);
    results.walletHistoryFunction = q7.rows[0]['QUERY PLAN'][0];

    // Also benchmark the underlying wallet query directly:
    const q7b = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT t.id, t.user_id, t.type, t.amount, t.balance_after, t.created_at
      FROM public.transactions t
      WHERE t.user_id = 'usr_51c1ff5e61a381ce'
      ORDER BY t.created_at DESC
      LIMIT 50;
    `);
    results.transactionsUserCreated = q7b.rows[0]['QUERY PLAN'][0];

    const q7c = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT wt.id, wt.user_id, wt.transaction_type, wt.amount, wt.created_at
      FROM public.wallet_transactions wt
      WHERE wt.user_id = 'usr_51c1ff5e61a381ce'
      ORDER BY wt.created_at DESC
      LIMIT 50;
    `);
    results.walletTransactionsUser = q7c.rows[0]['QUERY PLAN'][0];

    // 8. Notifications list and unread count
    const q8a = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT id, user_id, title, COALESCE(body, message, '') as body,
             type, data, link_url, game_id, club_id,
             is_read, created_at
      FROM public.notifications
      WHERE user_id = 'usr_51c1ff5e61a381ce'
      ORDER BY created_at DESC
      LIMIT 20 OFFSET 0;
    `);
    results.notificationsList = q8a.rows[0]['QUERY PLAN'][0];

    const q8b = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT COUNT(*) as unread_count
      FROM public.notifications
      WHERE user_id = 'usr_51c1ff5e61a381ce' AND is_read = false;
    `);
    results.notificationsUnreadCount = q8b.rows[0]['QUERY PLAN'][0];

    // 9. CCTV Active Recordings Check
    const q9 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
      SELECT id, game_id, club_id, court_id, s3_object_key
      FROM public.cctv_recordings
      WHERE status = 'RECORDING' AND stop_deadline <= CURRENT_TIMESTAMP;
    `);
    results.cctvActiveRecordings = q9.rows[0]['QUERY PLAN'][0];

    fs.writeFileSync('scratch/benchmark_current.json', JSON.stringify(results, null, 2));
    console.log('Saved benchmark results to scratch/benchmark_current.json successfully');

  } catch (err) {
    console.error('Benchmark error:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

runBenchmark();
