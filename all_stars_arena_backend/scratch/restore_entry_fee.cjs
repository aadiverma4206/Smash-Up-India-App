const pg = require('pg');
const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

(async () => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if column already exists
    const checkCol = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'entry_fee';
    `);

    if (checkCol.rows.length === 0) {
      console.log('Restoring entry_fee column on public.games...');
      await client.query(`
        ALTER TABLE public.games 
        ADD COLUMN entry_fee NUMERIC(10,2) DEFAULT 200.00 NOT NULL;
      `);

      await client.query(`
        ALTER TABLE public.games
        ADD CONSTRAINT games_entry_fee_check CHECK (entry_fee >= 0);
      `);
      console.log('Successfully restored entry_fee column and check constraint.');
    } else {
      console.log('entry_fee column already exists on public.games.');
    }

    // Add index on entry_fee if useful for queries like g.entry_fee <= $1
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_games_entry_fee ON public.games(entry_fee);
    `);

    await client.query('COMMIT');
    console.log('Migration committed successfully.');
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Error restoring entry_fee:', e);
  } finally {
    client.release();
    await pool.end();
  }
})();
