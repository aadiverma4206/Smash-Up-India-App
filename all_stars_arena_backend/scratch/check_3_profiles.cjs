const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const cm = await pool.query(`SELECT * FROM public.club_managers WHERE user_id = 'usr_2868a49c6aa551f5'`);
    console.log('club_managers for roshan:', cm.rows);

    const pd = await pool.query(`SELECT * FROM public.player_details WHERE user_id = 'usr_771ffc659cac6f5f'`);
    console.log('player_details for player:', pd.rows);

    const ps = await pool.query(`SELECT * FROM public.player_stats WHERE user_id = 'usr_771ffc659cac6f5f'`);
    console.log('player_stats for player:', ps.rows);

    const md = await pool.query(`SELECT * FROM public.manager_details WHERE user_id = 'usr_2868a49c6aa551f5'`);
    console.log('manager_details for roshan:', md.rows);

    const ad = await pool.query(`SELECT * FROM public.admin_details WHERE user_id = 'usr_e55abb463db8392d'`);
    console.log('admin_details for admin:', ad.rows);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
