const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN;');

    await client.query(`
      CREATE INDEX test_idx_cctv_recordings_status ON public.cctv_recordings (status, stop_deadline);
      CREATE INDEX test_idx_cctv_recordings_game ON public.cctv_recordings (game_id);
      CREATE INDEX test_idx_cctv_segments_recording ON public.cctv_recording_segments (recording_id, segment_order ASC);
      CREATE INDEX test_idx_game_waitlist_user ON public.game_waitlist (user_id);
    `);

    await client.query('SET enable_seqscan = off;');

    const q1 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT id, game_id, club_id, court_id, s3_object_key
      FROM public.cctv_recordings
      WHERE status = 'RECORDING' AND stop_deadline <= CURRENT_TIMESTAMP;
    `);
    console.log('CCTV status query plan:');
    console.log(q1.rows.map(r => r['QUERY PLAN']).join('\n'));

    const q2 = await client.query(`
      EXPLAIN (ANALYZE, BUFFERS)
      SELECT rec.*, seg.file_size_bytes
      FROM public.cctv_recordings rec
      LEFT JOIN public.cctv_recording_segments seg ON seg.recording_id = rec.id
      WHERE rec.game_id = 'gam_ab4730b5cfd89124';
    `);
    console.log('\nCCTV join segments plan:');
    console.log(q2.rows.map(r => r['QUERY PLAN']).join('\n'));

    await client.query('ROLLBACK;');
    console.log('Rolled back test successfully.');
  } catch (err) {
    await client.query('ROLLBACK;');
    console.error('Error during test:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
