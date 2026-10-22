const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  try {
    const res = await pool.query(`SELECT id, email, password_hash FROM public.users WHERE email IN ('player@gmail.com', 'roshan12@gmail.com', 'aadiverma4206@gmail.com')`);
    
    for (const u of res.rows) {
      let pass = '';
      if (u.email === 'player@gmail.com') pass = 'Player@123';
      if (u.email === 'roshan12@gmail.com') pass = 'Roshan@123';
      if (u.email === 'aadiverma4206@gmail.com') pass = 'Admin@123';
      
      const match = await bcrypt.compare(pass, u.password_hash);
      console.log(`User ${u.email}: password match = ${match}`);
    }
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await pool.end();
  }
}

run();
