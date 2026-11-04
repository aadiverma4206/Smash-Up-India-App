import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import pg from "pg";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const pool = new pg.Pool({
  connectionString:
    "postgresql://postgres:system@localhost:5432/smash_up_india",
});

async function run() {
  try {
    const sqlPath = path.join(
      __dirname,
      "../migrations/002_fix_auth_and_phone_matching.sql",
    );
    const sql = fs.readFileSync(sqlPath, "utf8");
    await pool.query(sql);
    console.log(
      "✅ Successfully applied migration 002_fix_auth_and_phone_matching.sql",
    );
  } catch (err) {
    console.error("❌ Migration error:", err);
  } finally {
    await pool.end();
  }
}

run();
