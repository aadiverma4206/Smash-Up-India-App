const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function testWorkerQuery() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const unapprovedGames = await client.query(
      `SELECT g.id, g.creator_id, g.title, g.entry_fee, g.match_date, g.start_time, g.end_time, g.approval_status
       FROM public.games g
       WHERE g.approval_status = 'PENDING_APPROVAL' AND g.status <> 'CANCELLED'
         AND (g.match_date + g.start_time) <= CURRENT_TIMESTAMP
       FOR UPDATE OF g SKIP LOCKED;`,
    );

    console.log("Found unapproved overdue games:", unapprovedGames.rows.length);

    for (const game of unapprovedGames.rows) {
      console.log("Would cancel game:", game.id, game.title);
    }

    await client.query("ROLLBACK");
    console.log("Worker query test passed 100%!");
  } catch (err) {
    await client.query("ROLLBACK").catch(() => {});
    console.error("Worker query test error:", err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

testWorkerQuery();
