const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const fks = await pool.query(`
      SELECT
          tc.table_name, 
          kcu.column_name, 
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name 
      FROM 
          information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema='public'
      ORDER BY tc.table_name;
    `);
    console.log('--- FOREIGN KEYS ---');
    console.log(JSON.stringify(fks.rows, null, 2));

    const tables = await pool.query(`SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;`);
    console.log('\n--- ALL TABLES ---');
    console.log(tables.rows.map(r => r.table_name));

    // Check count of rows in all tables
    console.log('\n--- ROW COUNTS ---');
    for (const t of tables.rows.map(r => r.table_name)) {
      const cnt = await pool.query(`SELECT COUNT(*) FROM public."${t}"`);
      console.log(`${t}: ${cnt.rows[0].count}`);
    }

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
