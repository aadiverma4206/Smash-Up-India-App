import pg from "pg";
import { env } from "./env.js";
import { logger } from "./logger.js";

const { Pool } = pg;

export const dbPool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
});

dbPool.on("connect", (client) => {
  // Set session timezone to Asia/Kolkata
  client.query("SET timezone = 'Asia/Kolkata';");
  logger.info(
    "Connected to PostgreSQL Database (all_stars_arena) - Timezone: Asia/Kolkata",
  );
});

dbPool.on("error", (err) => {
  logger.error({ err }, "Unexpected error on idle PostgreSQL client");
});

/**
 * Transaction Helper
 * Executes callback within a PostgreSQL transaction with BEGIN/COMMIT/ROLLBACK
 */
export const executeTransaction = async (callback) => {
  const client = await dbPool.connect();
  try {
    await client.query("BEGIN;");
    const result = await callback(client);
    await client.query("COMMIT;");
    return result;
  } catch (error) {
    await client.query("ROLLBACK;");
    logger.error({ error }, "Transaction rolled back due to error");
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Connection Health Check
 */
export const checkDbHealth = async () => {
  try {
    const res = await dbPool.query(
      "SELECT current_database(), current_user, version(), NOW() AT TIME ZONE 'Asia/Kolkata' as local_time;",
    );
    return {
      status: "HEALTHY",
      details: res.rows[0],
    };
  } catch (error) {
    logger.error({ error }, "Database health check failed");
    return {
      status: "UNHEALTHY",
      error: error.message,
    };
  }
};

/**
 * Graceful Shutdown Handler
 */
export const closeDbPool = async () => {
  logger.info("Closing PostgreSQL database connection pool...");
  await dbPool.end();
  logger.info("PostgreSQL pool closed cleanly.");
};
