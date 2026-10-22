const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const targetEmails = ['player@gmail.com', 'roshan12@gmail.com', 'aadiverma4206@gmail.com'];
    const res = await pool.query(
      `SELECT id, name, email, phone, role_id, status FROM public.users WHERE email = ANY($1)`,
      [targetEmails]
    );
    console.log('=== TARGET USERS ===');
    console.log(JSON.stringify(res.rows, null, 2));

    for (const u of res.rows) {
      console.log(`\n--- Details for user ${u.name} (${u.email}) [role ${u.role_id}] ---`);
      if (u.role_id === 3) {
        const pd = await pool.query(`SELECT * FROM public.player_details WHERE user_id = $1`, [u.id]);
        console.log('player_details:', pd.rows);
      } else if (u.role_id === 2) {
        const md = await pool.query(`SELECT * FROM public.manager_details WHERE user_id = $1`, [u.id]);
        console.log('manager_details:', md.rows);
        const cm = await pool.query(`SELECT * FROM public.club_managers WHERE manager_id = $1`, [u.id]);
        console.log('club_managers:', cm.rows);
      } else if (u.role_id === 1) {
        const ad = await pool.query(`SELECT * FROM public.admin_details WHERE user_id = $1`, [u.id]);
        console.log('admin_details:', ad.rows);
      }
    }
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
