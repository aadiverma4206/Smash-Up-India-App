const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN;');

    await client.query(`
      CREATE INDEX test_idx_games_open_discovery
      ON public.games (match_date ASC, start_time ASC)
      WHERE status = 'OPEN_FOR_JOINING' AND approval_status IN ('APPROVED', 'PENDING_APPROVAL');
    `);

    await client.query('SET enable_seqscan = off;');

    const res = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT g.id, g.title, g.match_date, g.start_time
      FROM public.games g
      WHERE g.status = 'OPEN_FOR_JOINING'
        AND g.approval_status IN ('APPROVED', 'PENDING_APPROVAL')
      ORDER BY g.match_date ASC, g.start_time ASC
      LIMIT 20 OFFSET 0;
    `);

    console.log('Match discovery plan with partial index:');
    console.log(res.rows.map(r => r['QUERY PLAN']).join('\n'));

    await client.query('ROLLBACK;');
    console.log('Rolled back test successfully.');
  } catch (err) {
    await client.query('ROLLBACK;');
    console.error('Error during test:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
