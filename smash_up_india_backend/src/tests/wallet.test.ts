import request from "supertest";
import crypto from "crypto";
import bcrypt from "bcryptjs";
import app from "../app.js";
import { dbPool } from "../config/db.config.js";
import { env } from "../config/env.config.js";

describe("SMASH UP INDIA Wallet & Razorpay Production Tests", () => {
  const testEmail = `wallet_player_${Date.now()}@example.com`;
  const testPhone = `+9196${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testPassword = "Password123!";
  const testPin = "849204";

  let userId = "";
  let accessToken = "";

  beforeAll(async () => {
    const pwdHash = await bcrypt.hash(testPassword, 10);
    const userRes = await dbPool.query(
      `SELECT public.register_player($1, $2, $3, $4, 'Raipur') as user_id;`,
      ["Wallet Player", testEmail, testPhone, pwdHash],
    );
    userId = userRes.rows[0].user_id;

    await dbPool.query(`SELECT public.set_wallet_pin($1, $2);`, [
      userId,
      testPin,
    ]);

    const loginRes = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: testEmail, password: testPassword });

    accessToken = loginRes.body.data.accessToken;
  });

  afterAll(async () => {
    await dbPool.query(
      `UPDATE public.users SET status = 'SUSPENDED' WHERE email = $1;`,
      [testEmail],
    );
  });

  it("GET /api/v1/wallet should return wallet details & PIN status", async () => {
    const res = await request(app)
      .get("/api/v1/wallet")
      .set("Authorization", `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("walletBalance");
    expect(res.body.data).toHaveProperty("isPinSet", true);
  });

  it("POST /api/v1/wallet/pin/verify with wrong PIN should fail", async () => {
    const res = await request(app)
      .post("/api/v1/wallet/pin/verify")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({ pin: "999999" });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("POST /api/v1/wallet/pin/verify with valid PIN should succeed", async () => {
    const res = await request(app)
      .post("/api/v1/wallet/pin/verify")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({ pin: testPin });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("POST /api/v1/wallet/topup/order exceeding single top-up max (₹50,000) should fail", async () => {
    const res = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        amountRupees: 60000,
        idempotencyKey: `idemp_${Date.now()}_invalid`,
        walletPin: testPin,
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("POST /api/v1/wallet/topup/order with valid inputs should create order", async () => {
    const idempotencyKey = `idemp_${Date.now()}_valid_12345`;

    const res = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        amountRupees: 500,
        idempotencyKey,
        walletPin: testPin,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty("paymentOrderId");
    expect(res.body.data).toHaveProperty("amountPaise", 50000);

    const duplicateRes = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        amountRupees: 500,
        idempotencyKey,
        walletPin: testPin,
      });

    expect(duplicateRes.status).toBe(200);
    expect(duplicateRes.body.data.paymentOrderId).toBe(
      res.body.data.paymentOrderId,
    );
  });

  it("POST /api/v1/wallet/topup/verify with tampered signature should fail", async () => {
    const orderRes = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        amountRupees: 100,
        idempotencyKey: `idemp_${Date.now()}_tamper_12345`,
        walletPin: testPin,
      });

    const paymentOrderId = orderRes.body.data.paymentOrderId;
    const razorpayOrderId = orderRes.body.data.razorpayOrderId;

    const verifyRes = await request(app)
      .post("/api/v1/wallet/topup/verify")
      .set("Authorization", `Bearer ${accessToken}`)
      .send({
        paymentOrderId,
        razorpayPaymentId: "pay_tampered_123",
        razorpayOrderId,
        razorpaySignature: "invalid_tampered_signature_123456",
      });

    expect(verifyRes.status).toBe(400);
    expect(verifyRes.body.success).toBe(false);
  });

  it("POST /api/v1/webhooks/razorpay with duplicate event should deduplicate", async () => {
    const eventId = `evt_test_dedup_${Date.now()}`;
    const payload = {
      event: "payment.captured",
      event_id: eventId,
      payload: {
        payment: {
          entity: {
            id: "pay_test_987",
            amount: 50000,
            status: "captured",
            notes: { userId, paymentOrderId: "pay_dummy_123" },
          },
        },
      },
    };

    const rawBody = JSON.stringify(payload);
    const signature = crypto
      .createHmac(
        "sha256",
        env.RAZORPAY_WEBHOOK_SECRET || "rzp_webhook_secret_key",
      )
      .update(rawBody)
      .digest("hex");

    const res1 = await request(app)
      .post("/api/v1/webhooks/razorpay")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res1.status).toBe(200);

    const res2 = await request(app)
      .post("/api/v1/webhooks/razorpay")
      .set("x-razorpay-signature", signature)
      .send(payload);

    expect(res2.status).toBe(200);
    expect(res2.body.data.status).toBe("IGNORED_DUPLICATE");
  });

  it("GET /api/v1/wallet/transactions should return player transaction history", async () => {
    const res = await request(app)
      .get("/api/v1/wallet/transactions")
      .set("Authorization", `Bearer ${accessToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data.transactions)).toBe(true);
  });
});
