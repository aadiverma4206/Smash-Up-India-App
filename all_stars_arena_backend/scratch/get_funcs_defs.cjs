const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const res = await pool.query(`
      SELECT p.proname, pg_get_functiondef(p.oid) as def
      FROM pg_proc p
      WHERE p.proname IN ('enforce_game_player_rules', 'sync_game_status_on_roster_change', 'join_game_with_wallet', 'switch_player_team');
    `);
    for (const r of res.rows) {
      console.log(`\n================================`);
      console.log(r.def);
    }
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

run();
