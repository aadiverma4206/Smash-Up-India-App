const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const trigs = await pool.query(`
      SELECT event_object_table, trigger_name, action_statement, action_timing, event_manipulation
      FROM information_schema.triggers
      WHERE trigger_schema = 'public'
    `);
    console.log('TRIGGERS:');
    console.log(trigs.rows);

    // Also check TRUNCATE permissions on audit_logs
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
