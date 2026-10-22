const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN;');

    await client.query(`
      CREATE INDEX test_idx_wallet_transactions_user_created
      ON public.wallet_transactions (user_id, created_at DESC);
      
      CREATE INDEX test_idx_wallet_transactions_reference
      ON public.wallet_transactions (reference_id)
      WHERE reference_id IS NOT NULL;
    `);

    await client.query('SET enable_seqscan = off;');

    const res = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT * FROM public.get_wallet_transaction_history('usr_51c1ff5e61a381ce', 50, 0);
    `);

    console.log('Wallet function plan with indexes:');
    console.log(res.rows.map(r => r['QUERY PLAN']).join('\n'));

    // Also run an EXPLAIN (ANALYZE, BUFFERS) on the subquery inside the function
    const subRes = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT wt.id, wt.user_id, wt.amount, wt.created_at
      FROM public.wallet_transactions wt
      WHERE wt.user_id = 'usr_51c1ff5e61a381ce'
        AND NOT EXISTS (
            SELECT 1 FROM public.transactions t2 WHERE t2.id = wt.id OR (wt.reference_id IS NOT NULL AND t2.reference_id = wt.reference_id)
        );
    `);
    console.log('\nSubquery plan with indexes:');
    console.log(subRes.rows.map(r => r['QUERY PLAN']).join('\n'));

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
