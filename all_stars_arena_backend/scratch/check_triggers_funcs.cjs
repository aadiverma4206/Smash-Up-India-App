const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const res = await pool.query(`
      SELECT p.proname, p.prosrc
      FROM pg_proc p
      WHERE p.proname IN ('enforce_game_player_rules', 'sync_game_status_on_roster_change');
    `);
    for (const r of res.rows) {
      console.log(`\n=== FUNCTION: ${r.proname} ===`);
      console.log(r.prosrc);
    }
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

run();
