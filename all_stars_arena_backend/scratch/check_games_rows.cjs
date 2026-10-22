const pg = require('pg');
const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

(async () => {
  try {
    const res = await pool.query(`SELECT count(*) FROM public.games;`);
    console.log('Games count:', res.rows[0].count);
    const sample = await pool.query(`SELECT * FROM public.games LIMIT 1;`);
    console.log('Sample game keys:', Object.keys(sample.rows[0] || {}));
  } catch (e) {
    console.error(e);
  } finally {
    await pool.end();
  }
})();
