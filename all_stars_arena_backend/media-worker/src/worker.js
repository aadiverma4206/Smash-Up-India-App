import pg from 'pg';
import dotenv from 'dotenv';
import pino from 'pino';

dotenv.config({ path: '../.env' });
const logger = pino({ level: 'info' });

const dbPool = new pg.Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@localhost:5432/all_stars_arena',
});

logger.info('🎥 ALL STARS ARENA Isolated Media Worker Started');

const processPendingRecordings = async () => {
  try {
    const res = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE status = 'STARTING' LIMIT 5;`
    );

    for (const rec of res.rows) {
      logger.info(`Starting CCTV Media Recording Process for Game ${rec.game_id}`);

      await dbPool.query(
        `UPDATE public.cctv_recordings SET status = 'RECORDING' WHERE id = $1;`,
        [rec.id]
      );

      await dbPool.query(
        `INSERT INTO public.cctv_recording_events (recording_id, event_type, metadata)
         VALUES ($1, 'RECORDING_STARTED', $2);`,
        [rec.id, JSON.stringify({ workerPid: process.pid })]
      );
    }
  } catch (err) {
    logger.error({ err }, 'Media Worker loop error');
  }
};

setInterval(processPendingRecordings, 5000);
