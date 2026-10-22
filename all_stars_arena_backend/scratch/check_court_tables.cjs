const pg = require('pg');
const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

(async () => {
  try {
    const courtsCols = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'courts'
      ORDER BY ordinal_position;
    `);
    console.log('--- COURTS ---', courtsCols.rows);

    const cbCols = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'court_bookings'
      ORDER BY ordinal_position;
    `);
    console.log('--- COURT_BOOKINGS ---', cbCols.rows);

    const slotReqCols = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'game_slot_requests'
      ORDER BY ordinal_position;
    `);
    console.log('--- GAME_SLOT_REQUESTS ---', slotReqCols.rows);
  } catch (e) {
    console.error(e);
  } finally {
    await pool.end();
  }
})();
