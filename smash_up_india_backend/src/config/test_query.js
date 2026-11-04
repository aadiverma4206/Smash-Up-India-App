import pg from "pg";

const pool = new pg.Pool({
  connectionString:
    "postgresql://postgres:system@localhost:5432/smash_up_india",
});

async function findUser(id) {
  const norm = id.trim().toLowerCase();
  const raw = id.trim();
  const digits = raw.replace(/\D/g, "");

  const res = await pool.query(
    `SELECT u.id, u.name, u.email, u.phone, u.role_id, u.status
     FROM public.users u
     WHERE LOWER(TRIM(u.email)) = $1
        OR TRIM(u.phone) = $2
        OR TRIM(u.phone) = $3
        OR ($4 <> '' AND LENGTH($4) >= 10 AND RIGHT(REGEXP_REPLACE(u.phone, '[^0-9]', '', 'g'), 10) = RIGHT($4, 10))
     LIMIT 1;`,
    [norm, raw, raw.startsWith("+91") ? raw.substring(3) : "+91" + raw, digits],
  );
  return res.rows[0] || null;
}

async function run() {
  try {
    console.log("Login by +919999999999:", await findUser("+919999999999"));
    console.log("Login by 9999999999:", await findUser("9999999999"));
    console.log(
      "Login by smashupindia@gmail.com:",
      await findUser("smashupindia@gmail.com"),
    );
  } catch (err) {
    console.error("Query error:", err);
  } finally {
    await pool.end();
  }
}

run();
