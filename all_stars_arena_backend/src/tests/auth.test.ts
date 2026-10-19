import request from "supertest";
import app from "../app.js";
import { dbPool } from "../config/db.config.js";
import bcrypt from "bcryptjs";

describe("ALL STARS ARENA Authentication Module Tests", () => {
  jest.setTimeout(15000);
  const testEmail = `test_player_${Date.now()}@example.com`;
  const testPhone = `+9198${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testPassword = "Password123!";

  let verificationToken = "";
  let accessToken = "";
  let refreshToken = "";

  afterAll(async () => {
    // DB trigger trg_prevent_user_delete prohibits DELETE FROM users. Set status to SUSPENDED.
    await dbPool.query(
      `UPDATE public.users SET status = 'SUSPENDED' WHERE email = $1 OR phone = $2;`,
      [testEmail, testPhone],
    );
  });

  it("Step 1: POST /api/v1/auth/register/send-otp should send OTP", async () => {
    const res = await request(app).post("/api/v1/auth/register/send-otp").send({
      name: "Test Striker",
      email: testEmail,
      phone: testPhone,
      city: "Raipur",
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("email", testEmail);
  });

  it("Step 2: POST /api/v1/auth/register/verify with wrong OTP should return 400", async () => {
    const res = await request(app).post("/api/v1/auth/register/verify").send({
      email: testEmail,
      phone: testPhone,
      emailOtp: "000000",
    });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("Step 2: POST /api/v1/auth/register/verify with valid OTP should return verification token", async () => {
    const otpRes = await dbPool.query(
      `SELECT * FROM public.otp_verifications WHERE identifier = $1 ORDER BY created_at DESC LIMIT 1;`,
      [testEmail],
    );
    expect(otpRes.rows.length).toBe(1);

    const testOtp = "123456";
    const otpHash = await bcrypt.hash(testOtp, 10);
    await dbPool.query(
      `UPDATE public.otp_verifications SET otp_hash = $1 WHERE id = $2;`,
      [otpHash, otpRes.rows[0].id],
    );

    const res = await request(app).post("/api/v1/auth/register/verify").send({
      email: testEmail,
      phone: testPhone,
      emailOtp: testOtp,
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("verificationToken");
    verificationToken = res.body.data.verificationToken;
  });

  it("Step 3: POST /api/v1/auth/register should create PLAYER account only", async () => {
    const res = await request(app).post("/api/v1/auth/register").send({
      name: "Test Striker",
      email: testEmail,
      phone: testPhone,
      password: testPassword,
      city: "Raipur",
      verificationToken,
    });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("accessToken");
    expect(res.body.data).toHaveProperty("refreshToken");

    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;

    const userRes = await dbPool.query(
      `SELECT role_id FROM public.users WHERE email = $1;`,
      [testEmail],
    );
    expect(userRes.rows[0].role_id).toBe(3);
  });

  it("POST /api/v1/auth/register/send-otp duplicate email should return 400", async () => {
    const res = await request(app).post("/api/v1/auth/register/send-otp").send({
      name: "Test Striker",
      email: testEmail,
      phone: "+919900112233",
    });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("POST /api/v1/auth/login with valid email and password should succeed", async () => {
    const res = await request(app).post("/api/v1/auth/login").send({
      identifier: testEmail,
      password: testPassword,
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user).toHaveProperty("roleId", 3);
    expect(res.body.data.user).toHaveProperty("roleName", "PLAYER");

    accessToken = res.body.data.accessToken;
    refreshToken = res.body.data.refreshToken;
  });

  it("POST /api/v1/auth/login with valid phone number should succeed", async () => {
    const res = await request(app).post("/api/v1/auth/login").send({
      identifier: testPhone,
      password: testPassword,
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("POST /api/v1/auth/login with wrong password should fail and record failed login", async () => {
    const res = await request(app).post("/api/v1/auth/login").send({
      identifier: testEmail,
      password: "WrongPassword1!",
    });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("POST /api/v1/auth/refresh should rotate refresh token", async () => {
    const res = await request(app).post("/api/v1/auth/refresh").send({
      refreshToken,
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("accessToken");
    expect(res.body.data).toHaveProperty("refreshToken");

    const newRefreshToken = res.body.data.refreshToken;

    const reuseRes = await request(app).post("/api/v1/auth/refresh").send({
      refreshToken,
    });

    expect(reuseRes.status).toBe(401);
    expect(reuseRes.body.error.code).toBe("TOKEN_REUSE_DETECTED");

    refreshToken = newRefreshToken;
  });

  it("GET /api/v1/auth/me should return user profile", async () => {
    const res = await request(app)
      .get("/api/v1/auth/me")
      .set("Authorization", `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("email", testEmail);
    expect(res.body.data).toHaveProperty("roleId", 3);
  });

  it("POST /api/v1/auth/forgot/send-otp and reset password should invalidate all active sessions", async () => {
    const sendRes = await request(app)
      .post("/api/v1/auth/forgot/send-otp")
      .send({
        identifier: testEmail,
      });
    expect(sendRes.status).toBe(200);

    const resetOtp = "654321";
    const resetOtphash = await bcrypt.hash(resetOtp, 10);
    await dbPool.query(
      `UPDATE public.otp_verifications
       SET otp_hash = $1
       WHERE identifier = $2 AND purpose = 'PASSWORD_RESET';`,
      [resetOtphash, testEmail],
    );

    const verifyRes = await request(app)
      .post("/api/v1/auth/forgot/verify")
      .send({
        identifier: testEmail,
        otp: resetOtp,
      });
    expect(verifyRes.status).toBe(200);
    const resetToken = verifyRes.body.data.resetToken;

    const newPassword = "NewSecurePassword123!";
    const resetRes = await request(app)
      .post("/api/v1/auth/reset-password")
      .send({
        resetToken,
        newPassword,
      });
    expect(resetRes.status).toBe(200);

    const refreshRes = await request(app).post("/api/v1/auth/refresh").send({
      refreshToken,
    });
    expect(refreshRes.status).toBe(401);

    const loginRes = await request(app).post("/api/v1/auth/login").send({
      identifier: testEmail,
      password: newPassword,
    });
    expect(loginRes.status).toBe(200);
  });
});
