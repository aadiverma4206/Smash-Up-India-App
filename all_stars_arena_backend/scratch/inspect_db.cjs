require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena' });

async function inspect() {
  try {
    const tables = await pool.query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name");
    console.log('--- ALL TABLES ---');
    console.log(tables.rows.map(r => r.table_name).join(', '));

    for (const t of ['court_bookings', 'bookings', 'games', 'courts', 'pitches', 'court_pricing', 'court_availability']) {
      const cols = await pool.query("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = $1 ORDER BY ordinal_position", [t]);
      if (cols.rows.length > 0) {
        console.log(`\n--- TABLE: ${t} ---`);
        cols.rows.forEach(c => console.log(`  ${c.column_name}: ${c.data_type} (null: ${c.is_nullable}, def: ${c.column_default})`));
      }
    }
  } catch (e) {
    console.error(e);
  } finally {
    await pool.end();
  }
}

inspect();
