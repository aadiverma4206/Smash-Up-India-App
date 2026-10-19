import request from "supertest";
import app from "../app.js";
import { dbPool } from "../config/db.config.js";
import bcrypt from "bcryptjs";

describe("ALL STARS ARENA Player-Facing Modules Integration Tests", () => {
  const testEmail = `player_test_${Date.now()}@example.com`;
  const testPhone = `+9197${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testPassword = "Password123!";

  let accessToken = "";
  let gameId = "";
  let courtId = "";
  let bookingId = "";
  let tournamentId = "";

  beforeAll(async () => {
    // 1. Create a Test Player Account directly in DB
    const pwdHash = await bcrypt.hash(testPassword, 10);
    const userRes = await dbPool.query(
      `SELECT public.register_player($1, $2, $3, $4, 'Raipur') as user_id;`,
      ["Test Player", testEmail, testPhone, pwdHash],
    );
    const userId = userRes.rows[0].user_id;

    // Top up player wallet balance directly for tests
    await dbPool.query(
      `UPDATE public.player_details SET wallet_balance = 5000.00 WHERE user_id = $1;`,
      [userId],
    );

    // Login to get access token
    const loginRes = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: testEmail, password: testPassword });

    accessToken = loginRes.body.data.accessToken;

    // 2. Fetch existing game, court, and tournament for testing
    const gameRes = await dbPool.query(`SELECT id FROM public.games LIMIT 1;`);
    if (gameRes.rows.length > 0) gameId = gameRes.rows[0].id;

    const courtRes = await dbPool.query(
      `SELECT id FROM public.courts LIMIT 1;`,
    );
    if (courtRes.rows.length > 0) courtId = courtRes.rows[0].id;

    const tournRes = await dbPool.query(
      `SELECT id FROM public.tournaments LIMIT 1;`,
    );
    if (tournRes.rows.length > 0) tournamentId = tournRes.rows[0].id;
  });

  afterAll(async () => {
    await dbPool.query(
      `UPDATE public.users SET status = 'SUSPENDED' WHERE email = $1;`,
      [testEmail],
    );
  });

  it("GET /api/v1/player/profile should return player profile", async () => {
    const res = await request(app)
      .get("/api/v1/player/profile")
      .set("Authorization", `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("email", testEmail);
    expect(res.body.data).toHaveProperty("wallet_balance");
  });

  it("PUT /api/v1/player/profile should update player details", async () => {
    const res = await request(app)
      .put("/api/v1/player/profile")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        bio: "Speedy Winger from Raipur",
        position: "LW",
        preferredFoot: "Right",
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.position).toBe("LW");
  });

  it("GET /api/v1/player/stats should return player statistics", async () => {
    const res = await request(app)
      .get("/api/v1/player/stats")
      .set("Authorization", `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("matches_played");
  });

  it("GET /api/v1/games should list public games", async () => {
    const res = await request(app).get("/api/v1/games");
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("POST /api/v1/games/:id/join should allow joining a game if available", async () => {
    if (!gameId) return;

    const res = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${accessToken}`)
      .send({ position: "LW" });

    if (res.status === 200) {
      expect(res.body.success).toBe(true);

      // Test Switch Team
      const switchRes = await request(app)
        .post(`/api/v1/games/${gameId}/switch-team`)
        .set("Authorization", `Bearer ${accessToken}`);
      expect(switchRes.status).toBe(200);

      // Test Leave Game
      const leaveRes = await request(app)
        .post(`/api/v1/games/${gameId}/leave`)
        .set("Authorization", `Bearer ${accessToken}`);
      expect(leaveRes.status).toBe(200);
    }
  });

  it("POST /api/v1/games/:id/waitlist & DELETE waitlist", async () => {
    if (!gameId) return;

    const res = await request(app)
      .post(`/api/v1/games/${gameId}/waitlist`)
      .set("Authorization", `Bearer ${accessToken}`)
      .send({ position: "CM" });

    expect(res.status).toBe(200);

    const deleteRes = await request(app)
      .delete(`/api/v1/games/${gameId}/waitlist`)
      .set("Authorization", `Bearer ${accessToken}`);

    expect(deleteRes.status).toBe(200);
  });

  it("GET /api/v1/courts should list available courts and quote price", async () => {
    const res = await request(app).get("/api/v1/courts");
    expect(res.status).toBe(200);

    if (courtId) {
      const quoteRes = await request(app).get(
        `/api/v1/courts/${courtId}/price-quote`,
      );
      expect(quoteRes.status).toBe(200);
      expect(quoteRes.body.data).toHaveProperty("totalAmount");
    }
  });

  it("POST /api/v1/bookings & cancellation refund tier test", async () => {
    if (!courtId) return;

    const bookingDate = "2026-10-15";
    const startTime = "18:00:00";
    const endTime = "19:00:00";

    const res = await request(app)
      .post("/api/v1/bookings")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        courtId,
        bookingDate,
        startTime,
        endTime,
      });

    if (res.status === 201) {
      bookingId = res.body.data.id;
      expect(res.body.data.status).toBe("CONFIRMED");

      // Test Booking Cancellation (Triggers trg_apply_refund_tier)
      const cancelRes = await request(app)
        .post(`/api/v1/bookings/${bookingId}/cancel`)
        .set("Authorization", `Bearer ${accessToken}`)
        .send({ reason: "Schedule conflict" });

      expect(cancelRes.status).toBe(200);
      expect(cancelRes.body.data).toHaveProperty("refund_tier");
    }
  });

  it("GET /api/v1/leaderboard should return player rankings", async () => {
    const res = await request(app).get("/api/v1/leaderboard");
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
