const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    const res = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT
          wt.id::VARCHAR(64) as id,
          wt.user_id::VARCHAR(64) as user_id,
          wt.amount::NUMERIC(10,2) as amount,
          wt.created_at as created_at
      FROM public.wallet_transactions wt
      WHERE wt.user_id = 'usr_51c1ff5e61a381ce'
        AND NOT EXISTS (
            SELECT 1 FROM public.transactions t2 WHERE t2.id = wt.id OR (wt.reference_id IS NOT NULL AND t2.reference_id = wt.reference_id)
        );
    `);
    console.log(res.rows.map(r => r['QUERY PLAN']).join('\n'));
  } finally {
    client.release();
    await pool.end();
  }
}

run();
