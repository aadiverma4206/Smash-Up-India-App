const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const fks = await pool.query(`
      SELECT
          tc.constraint_name,
          tc.table_name, 
          kcu.column_name, 
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name,
          rc.delete_rule
      FROM 
          information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
          JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_name = tc.constraint_name
      WHERE tc.table_name IN ('courts', 'clubs', 'club_managers', 'player_details', 'manager_details', 'admin_details')
      ORDER BY tc.table_name;
    `);
    console.log('FKS for key tables:');
    console.log(JSON.stringify(fks.rows, null, 2));

    const courts = await pool.query(`SELECT * FROM public.courts`);
    console.log('\nCourts:');
    console.log(courts.rows);

    const club = await pool.query(`SELECT * FROM public.clubs WHERE id = 'all_stars_arena_club'`);
    console.log('\nClub for courts:');
    console.log(club.rows);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
