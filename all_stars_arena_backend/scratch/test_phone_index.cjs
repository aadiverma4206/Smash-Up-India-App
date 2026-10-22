const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN;');

    // Try creating the index in transaction
    await client.query(`
      CREATE INDEX test_idx_users_phone_10digits
      ON public.users USING btree (
        ("right"(regexp_replace((phone)::text, '[^0-9]'::text, ''::text, 'g'::text), 10))
      ) WHERE phone IS NOT NULL;
    `);

    const res = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT u.id, u.name, u.email, u.phone
      FROM public.users u
      WHERE LOWER(TRIM(u.email)) = 'mgr_1792567420459_53838@example.com'
         OR TRIM(u.phone) = '+919814770462'
         OR TRIM(u.phone) = '9814770462'
         OR ('9814770462' <> '' AND LENGTH('9814770462') >= 10 AND RIGHT(REGEXP_REPLACE(u.phone, '[^0-9]', '', 'g'), 10) = RIGHT('9814770462', 10))
      LIMIT 1;
    `);

    console.log('Plan with test index:');
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
