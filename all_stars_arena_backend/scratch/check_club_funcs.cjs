const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const res = await pool.query(`
      SELECT p.proname
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.prosrc ILIKE '%games%club_id%';
    `);
    console.log('Functions referencing games club_id:', res.rows.map(r => r.proname));
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

run();
