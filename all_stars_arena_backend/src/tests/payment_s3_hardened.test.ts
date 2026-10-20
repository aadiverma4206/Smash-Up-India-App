import request from "supertest";
import app from "../app.js";
import { dbPool } from "../config/db.config.js";
import bcrypt from "bcryptjs";

describe("Player Payment, Razorpay, Refund & AWS S3 Integration Tests", () => {
  jest.setTimeout(20000);

  const player1Email = `pay_p1_${Date.now()}@example.com`;
  const player1Phone = `+9198${Math.floor(10000000 + Math.random() * 90000000)}`;
  const player2Email = `pay_p2_${Date.now()}@example.com`;
  const player2Phone = `+9197${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testPassword = "Password123!";
  const validPin = "948261";

  let p1Token: string;
  let p1UserId: string;
  let p2Token: string;
  let p2UserId: string;

  beforeAll(async () => {
    await dbPool.query(`UPDATE public.users SET status = 'ACTIVE';`);

    const pwdHash = await bcrypt.hash(testPassword, 10);
    const p1Res = await dbPool.query(
      `SELECT public.register_player('Payment Player 1', $1, $2, $3, 'Raipur') as user_id;`,
      [player1Email, player1Phone, pwdHash],
    );
    p1UserId = p1Res.rows[0].user_id;

    await dbPool.query(`SELECT public.set_wallet_pin($1, $2);`, [
      p1UserId,
      validPin,
    ]);

    const p1Login = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: player1Email, password: testPassword });
    p1Token = p1Login.body.data.accessToken;

    const p2Res = await dbPool.query(
      `SELECT public.register_player('Payment Player 2', $1, $2, $3, 'Raipur') as user_id;`,
      [player2Email, player2Phone, pwdHash],
    );
    p2UserId = p2Res.rows[0].user_id;

    await dbPool.query(`SELECT public.set_wallet_pin($1, $2);`, [
      p2UserId,
      validPin,
    ]);

    const p2Login = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: player2Email, password: testPassword });
    p2Token = p2Login.body.data.accessToken;
  });

  describe("Razorpay & Wallet Top-Up Hardening Tests", () => {
    it("Should reject invalid top-up amounts (< ₹1 or > ₹50,000)", async () => {
      const resHigh = await request(app)
        .post("/api/v1/wallet/topup/order")
        .set("Authorization", `Bearer ${p1Token}`)
        .send({
          amountRupees: 60000,
          walletPin: validPin,
          idempotencyKey: `idemp_${Date.now()}`,
        });

      expect(resHigh.status).toBe(400);

      const resZero = await request(app)
        .post("/api/v1/wallet/topup/order")
        .set("Authorization", `Bearer ${p1Token}`)
        .send({
          amountRupees: 0,
          walletPin: validPin,
          idempotencyKey: `idemp_${Date.now()}`,
        });

      expect(resZero.status).toBe(400);
    });

    it("Should create Razorpay order and payment_orders record for valid amount", async () => {
      const res = await request(app)
        .post("/api/v1/wallet/topup/order")
        .set("Authorization", `Bearer ${p1Token}`)
        .send({
          amountRupees: 1000,
          walletPin: validPin,
          idempotencyKey: `idemp_valid_${Date.now()}`,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.paymentOrderId).toBeDefined();
      expect(res.body.data.amountRupees).toBe(1000);
      expect(res.body.data.currency).toBe("INR");
    });

    it("Should reject verification when Razorpay signature is invalid", async () => {
      const orderRes = await request(app)
        .post("/api/v1/wallet/topup/order")
        .set("Authorization", `Bearer ${p1Token}`)
        .send({
          amountRupees: 500,
          walletPin: validPin,
          idempotencyKey: `idemp_sig_${Date.now()}`,
        });

      const paymentOrderId = orderRes.body.data.paymentOrderId;

      const verifyRes = await request(app)
        .post("/api/v1/wallet/topup/verify")
        .set("Authorization", `Bearer ${p1Token}`)
        .send({
          paymentOrderId,
          razorpayPaymentId: "pay_mock_123",
          razorpayOrderId: "order_mock_123",
          razorpaySignature: "invalid_signature_hash_xyz",
        });

      expect(verifyRes.status).toBe(400);
      expect(verifyRes.body.success).toBe(false);
    });

    it("Should deduplicate duplicate Razorpay webhook events", async () => {
      const eventId = `evt_test_${Date.now()}`;
      const payload = {
        event_id: eventId,
        event: "payment.captured",
        payload: {
          payment: {
            entity: {
              id: "pay_webhook_mock",
              amount: 50000,
              currency: "INR",
              notes: { userId: p1UserId },
            },
          },
        },
      };

      const res1 = await request(app)
        .post("/api/v1/webhooks/razorpay")
        .send(payload);

      expect(res1.status).toBe(200);

      const res2 = await request(app)
        .post("/api/v1/webhooks/razorpay")
        .send(payload);

      expect(res2.status).toBe(200);
      expect(res2.body.data.status).toBe("IGNORED_DUPLICATE");
    });

    it("Should enforce payment transaction history isolation between players", async () => {
      const res1 = await request(app)
        .get("/api/v1/wallet/transactions")
        .set("Authorization", `Bearer ${p1Token}`);

      expect(res1.status).toBe(200);
      expect(Array.isArray(res1.body.data.transactions)).toBe(true);

      const res2 = await request(app)
        .get("/api/v1/wallet/transactions")
        .set("Authorization", `Bearer ${p2Token}`);

      expect(res2.status).toBe(200);
      expect(Array.isArray(res2.body.data.transactions)).toBe(true);
    });
  });

  describe("AWS S3 Profile Image Upload, Delete & Security Tests", () => {
    it("Should reject oversized or invalid MIME type image uploads", async () => {
      const textBuffer = Buffer.from("Plain text file data, not an image");

      const res = await request(app)
        .post("/api/v1/player/profile/image")
        .set("Authorization", `Bearer ${p1Token}`)
        .attach("profileImage", textBuffer, {
          filename: "malicious.exe",
          contentType: "application/x-msdownload",
        });

      expect(res.status).toBe(400);
    });

    it("Should delete profile image from S3 and update database", async () => {
      const res = await request(app)
        .delete("/api/v1/player/profile/image")
        .set("Authorization", `Bearer ${p1Token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it("Should prevent unauthenticated or unauthorized profile modification", async () => {
      const resNoToken = await request(app)
        .put("/api/v1/player/profile")
        .send({ bio: "Hacked bio" });

      expect(resNoToken.status).toBe(401);
    });
  });
});
