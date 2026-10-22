const pg = require('pg');
const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

(async () => {
  try {
    const res = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    console.log('Tables:', res.rows.map(r => r.table_name));
  } catch (e) {
    console.error(e);
  } finally {
    await pool.end();
  }
})();
