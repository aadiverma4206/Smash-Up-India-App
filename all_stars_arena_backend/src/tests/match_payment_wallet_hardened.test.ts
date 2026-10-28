import { jest } from "@jest/globals";
import request from "supertest";
import crypto from "crypto";
import bcrypt from "bcryptjs";
import app from "../app.js";
import { dbPool } from "../config/db.config.js";
import { env } from "../config/env.config.js";

describe("Mandatory 16 Payment, Wallet & Refund Requirements Test Suite", () => {
  jest.setTimeout(30000);

  const testPassword = "Password123!";
  const testPin = "715392";

  let managerUserId = "";
  let managerToken = "";

  const createTestPlayer = async (name: string, balance = 0) => {
    const email = `test_${Date.now()}_${Math.floor(Math.random() * 100000)}@example.com`;
    const phone = `+9199${Math.floor(10000000 + Math.random() * 90000000)}`;
    const pwdHash = await bcrypt.hash(testPassword, 10);
    const res = await dbPool.query(
      `SELECT public.register_player($1, $2, $3, $4, 'Raipur') as user_id;`,
      [name, email, phone, pwdHash],
    );
    const userId = res.rows[0].user_id;
    await dbPool.query(`SELECT public.set_wallet_pin($1, $2);`, [
      userId,
      testPin,
    ]);
    if (balance > 0) {
      await dbPool.query(
        `UPDATE public.player_details SET wallet_balance = $1 WHERE user_id = $2;`,
        [balance, userId],
      );
    }
    const login = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: email, password: testPassword });
    return { userId, token: login.body.data.accessToken, email, phone };
  };

  const createTestManager = async () => {
    const email = `mgr_${Date.now()}_${Math.floor(Math.random() * 100000)}@example.com`;
    const phone = `+9198${Math.floor(10000000 + Math.random() * 90000000)}`;
    const pwdHash = await bcrypt.hash(testPassword, 10);
    const userRes = await dbPool.query(
      `INSERT INTO public.users (name, email, phone, password_hash, role_id, status)
       VALUES ('Test Manager', $1, $2, $3, 2, 'ACTIVE') RETURNING id;`,
      [email, phone, pwdHash],
    );
    const userId = userRes.rows[0].id;
    await dbPool.query(
      `INSERT INTO public.club_managers (user_id, club_id)
       VALUES ($1, 'all_stars_arena_club')
       ON CONFLICT DO NOTHING;`,
      [userId],
    );
    const login = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: email, password: testPassword });
    return { userId, token: login.body.data.accessToken };
  };

  let testSlotCounter = Math.floor(Math.random() * 500) + 100;
  const createTestGame = async (entryFee = 300, _maxPlayers = 10) => {
    testSlotCounter++;
    const gameId = `gm_${Date.now().toString(36)}_${testSlotCounter}`;
    await dbPool.query(
      `INSERT INTO public.games (id, title, club_id, court_id, creator_id, creator_role_name, created_by_player, format, entry_fee, per_player_fee, match_date, start_time, end_time, status, approval_status)
       VALUES ($1, 'Payment Test Game', 'all_stars_arena_club', 'court_1', $2, 'MANAGER', false, '5v5', $3, $3, (CURRENT_DATE + ($4 || ' days')::interval)::date, '18:00:00', '19:00:00', 'OPEN_FOR_JOINING', 'APPROVED');`,
      [gameId, managerUserId, entryFee, `${testSlotCounter + 50}`],
    );
    return gameId;
  };

  beforeAll(async () => {
    await dbPool
      .query("DELETE FROM public.games WHERE title = 'Payment Test Game';")
      .catch(() => {});
    const mgr = await createTestManager();
    managerUserId = mgr.userId;
    managerToken = mgr.token;
  });

  afterAll(async () => {
    await dbPool
      .query("DELETE FROM public.games WHERE title = 'Payment Test Game';")
      .catch(() => {});
  });

  // 1. Successful Razorpay match payment does not change wallet balance
  it("Rule 1: Successful Razorpay match payment does not change wallet balance", async () => {
    const player = await createTestPlayer("Razorpay Join Player", 500);
    const balanceBefore = 500;
    const gameId = await createTestGame(250);

    const orderRes = await request(app)
      .post("/api/v1/games/order")
      .set("Authorization", `Bearer ${player.token}`)
      .send({ gameId, amountRupees: 250 });
    expect(orderRes.status).toBe(200);

    const rzpOrderId = orderRes.body.data.razorpayOrderId;
    const rzpPaymentId = `pay_rzp_mock_${Date.now()}`;
    const secret = env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";
    const sig = crypto
      .createHmac("sha256", secret)
      .update(`${rzpOrderId}|${rzpPaymentId}`)
      .digest("hex");

    const joinRes = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "ST",
        paymentDetails: {
          paymentMethod: "RAZORPAY",
          razorpayOrderId: rzpOrderId,
          razorpayPaymentId: rzpPaymentId,
          razorpaySignature: sig,
        },
      });
    expect(joinRes.status).toBe(200);

    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    const balanceAfter = parseFloat(afterBalRes.rows[0].wallet_balance);

    // Balance MUST remain unchanged!
    expect(balanceAfter).toBe(balanceBefore);

    const gpRes = await dbPool.query(
      `SELECT payment_status, payment_method, payment_reference FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
      [gameId, player.userId],
    );
    expect(gpRes.rows[0].payment_status).toBe("PAID");
    expect(gpRes.rows[0].payment_method).toBe("RAZORPAY");
    expect(gpRes.rows[0].payment_reference).toBe(rzpPaymentId);
  });

  // 2. Successful wallet match payment deducts the exact fee
  it("Rule 2: Successful wallet match payment deducts the exact fee", async () => {
    const player = await createTestPlayer("Wallet Join Player", 500);
    const balanceBefore = 500;
    const fee = 150;
    const gameId = await createTestGame(fee);

    const joinRes = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "MID",
        paymentDetails: {
          paymentMethod: "WALLET",
          walletPin: testPin,
        },
      });
    expect(joinRes.status).toBe(200);

    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    const balanceAfter = parseFloat(afterBalRes.rows[0].wallet_balance);
    expect(balanceAfter).toBe(balanceBefore - fee);

    const gpRes = await dbPool.query(
      `SELECT payment_status, payment_method FROM public.game_players WHERE game_id = $1 AND user_id = $2;`,
      [gameId, player.userId],
    );
    expect(gpRes.rows[0].payment_status).toBe("PAID");
    expect(gpRes.rows[0].payment_method).toBe("WALLET");
  });

  // 3. Insufficient wallet balance rejects the join request without changing the balance
  it("Rule 3: Insufficient wallet balance rejects join request without changing balance", async () => {
    const player = await createTestPlayer("Low Balance Player", 100);
    const balanceBefore = 100;
    const fee = 600;
    const gameId = await createTestGame(fee);

    const joinRes = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "DEF",
        paymentDetails: {
          paymentMethod: "WALLET",
          walletPin: testPin,
        },
      });
    expect(joinRes.status).toBe(400);
    expect(joinRes.body.error?.code || joinRes.body.code).toBe(
      "INSUFFICIENT_WALLET_BALANCE",
    );

    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(afterBalRes.rows[0].wallet_balance)).toBe(balanceBefore);
  });

  // 4. Successful wallet top-up credits the balance exactly once
  it("Rule 4: Successful wallet top-up credits the balance exactly once", async () => {
    const player = await createTestPlayer("Topup Player", 0);
    const topupAmount = 200;

    const orderRes = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        amountRupees: topupAmount,
        idempotencyKey: `topup_${Date.now()}`,
        walletPin: testPin,
      });
    expect(orderRes.status).toBe(200);

    const paymentOrderId = orderRes.body.data.paymentOrderId;
    const rzpOrderId = orderRes.body.data.razorpayOrderId;
    const rzpPaymentId = `pay_mock_topup_${Date.now()}`;
    const secret = env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";
    const sig = crypto
      .createHmac("sha256", secret)
      .update(`${rzpOrderId}|${rzpPaymentId}`)
      .digest("hex");

    const verifyRes = await request(app)
      .post("/api/v1/wallet/topup/verify")
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        paymentOrderId,
        razorpayPaymentId: rzpPaymentId,
        razorpayOrderId: rzpOrderId,
        razorpaySignature: sig,
      });
    expect(verifyRes.status).toBe(200);

    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(afterBalRes.rows[0].wallet_balance)).toBe(topupAmount);
  });

  // 5. Failed or canceled top-up does not credit the wallet
  it("Rule 5: Failed or canceled top-up does not credit the wallet", async () => {
    const player = await createTestPlayer("Cancelled Topup Player", 0);

    const orderRes = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        amountRupees: 500,
        idempotencyKey: `topup_cancel_${Date.now()}`,
        walletPin: testPin,
      });
    expect(orderRes.status).toBe(200);

    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(afterBalRes.rows[0].wallet_balance)).toBe(0);
  });

  // 6. Invalid Razorpay signature is rejected
  it("Rule 6: Invalid Razorpay signature is rejected", async () => {
    const player = await createTestPlayer("Tampered Sig Player", 0);
    const gameId = await createTestGame(300);

    const orderRes = await request(app)
      .post("/api/v1/games/order")
      .set("Authorization", `Bearer ${player.token}`)
      .send({ gameId, amountRupees: 300 });

    const rzpOrderId = orderRes.body.data.razorpayOrderId;
    const rzpPaymentId = `pay_fake_${Date.now()}`;

    const joinRes = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "GK",
        paymentDetails: {
          paymentMethod: "RAZORPAY",
          razorpayOrderId: rzpOrderId,
          razorpayPaymentId: rzpPaymentId,
          razorpaySignature: "invalid_tampered_signature_xyz",
        },
      });

    expect(joinRes.status).toBe(400);
    expect(joinRes.body.error?.code || joinRes.body.code).toBe(
      "INVALID_SIGNATURE",
    );
  });

  // 7. Duplicate Razorpay callback/webhook does not create a duplicate credit
  it("Rule 7: Duplicate Razorpay callback/webhook does not create duplicate credit", async () => {
    const player = await createTestPlayer("Webhook Player", 0);
    const eventId = `evt_dedup_test_${Date.now()}`;
    const payload = {
      event_id: eventId,
      event: "payment.captured",
      payload: {
        payment: {
          entity: {
            id: `pay_webhook_${Date.now()}`,
            amount: 10000,
            currency: "INR",
            notes: { userId: player.userId },
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

  // 8. Match cancellation refunds an eligible wallet payment exactly once
  it("Rule 8: Match cancellation refunds an eligible wallet payment exactly once", async () => {
    const player = await createTestPlayer("Refund Wallet Player", 500);
    const balanceBefore = 500;
    const fee = 100;
    const gameId = await createTestGame(fee);

    // Join with wallet
    await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "ST",
        paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
      });

    const midBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(midBalRes.rows[0].wallet_balance)).toBe(
      balanceBefore - fee,
    );

    // Manager cancels match
    const cancelRes = await request(app)
      .post(`/api/v1/manager/games/${gameId}/cancel`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ cancellationReason: "Turf maintenance" });
    expect(cancelRes.status).toBe(200);

    // Wallet refunded back to balanceBefore
    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(afterBalRes.rows[0].wallet_balance)).toBe(balanceBefore);

    // Subsequent cancellation call should not refund again
    await request(app)
      .post(`/api/v1/manager/games/${gameId}/cancel`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ cancellationReason: "Repeat cancel" });

    const finalBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(finalBalRes.rows[0].wallet_balance)).toBe(balanceBefore);
  });

  // 9. Match cancellation follows configured policy for Razorpay-originated payments (credits wallet as refund)
  it("Rule 9: Match cancellation refunds Razorpay-paid player to wallet without double refunding", async () => {
    const player = await createTestPlayer("Razorpay Refund Player", 500);
    const balanceBefore = 500;
    const fee = 200;
    const gameId = await createTestGame(fee);

    const orderRes = await request(app)
      .post("/api/v1/games/order")
      .set("Authorization", `Bearer ${player.token}`)
      .send({ gameId, amountRupees: fee });

    const rzpOrderId = orderRes.body.data.razorpayOrderId;
    const rzpPaymentId = `pay_rzp_cancel_test_${Date.now()}`;
    const secret = env.RAZORPAY_KEY_SECRET || "0TkqPajfyDM5ng6e3CQxIzYy";
    const sig = crypto
      .createHmac("sha256", secret)
      .update(`${rzpOrderId}|${rzpPaymentId}`)
      .digest("hex");

    await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "CB",
        paymentDetails: {
          paymentMethod: "RAZORPAY",
          razorpayOrderId: rzpOrderId,
          razorpayPaymentId: rzpPaymentId,
          razorpaySignature: sig,
        },
      });

    // Cancel match
    const cancelRes = await request(app)
      .post(`/api/v1/manager/games/${gameId}/cancel`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ cancellationReason: "Weather condition" });
    expect(cancelRes.status).toBe(200);

    const afterBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    // Refund fee credited to wallet
    expect(parseFloat(afterBalRes.rows[0].wallet_balance)).toBe(
      balanceBefore + fee,
    );
  });

  // 10. Rejected player-created match refunds eligible payments correctly
  it("Rule 10: Rejected player-created match refunds host payment correctly", async () => {
    const hostPlayer = await createTestPlayer("Host Player", 600);
    const balanceBefore = 600;
    const entryFee = 200;

    const createRes = await request(app)
      .post("/api/v1/games")
      .set("Authorization", `Bearer ${hostPlayer.token}`)
      .send({
        title: "Player Sunday Game",
        courtId: "court_1",
        format: "5v5",
        entryFee,
        matchDate: "2026-10-30",
        startTime: "16:00:00",
        endTime: "17:00:00",
        paymentMethod: "WALLET",
        walletPin: testPin,
      });
    expect(createRes.status).toBe(201);
    const createdGameId = createRes.body.data.id;

    // Manager rejects the match
    const rejectRes = await request(app)
      .post(`/api/v1/manager/games/${createdGameId}/reject`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ rejectionReason: "Slot unavailable for tournament" });
    expect(rejectRes.status).toBe(200);

    const hostBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [hostPlayer.userId],
    );
    expect(parseFloat(hostBalRes.rows[0].wallet_balance)).toBe(balanceBefore);
  });

  // 11. Failed or unpaid registrations are not refunded
  it("Rule 11: Failed or unpaid registrations are not refunded", async () => {
    const unpaidPlayer = await createTestPlayer("Unpaid Player", 0);
    const gameId = await createTestGame(300);

    // Insert an unpaid registration manually
    await dbPool.query(
      `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
       VALUES ($1, $2, 'TEAM_A', 'LW', 'PENDING');`,
      [gameId, unpaidPlayer.userId],
    );

    // Cancel match
    await request(app)
      .post(`/api/v1/manager/games/${gameId}/cancel`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ cancellationReason: "Cancelled" });

    const balRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [unpaidPlayer.userId],
    );
    expect(parseFloat(balRes.rows[0].wallet_balance)).toBe(0);
  });

  // 12. Concurrent wallet payments cannot cause a negative balance
  it("Rule 12: Concurrent wallet payments cannot cause a negative balance", async () => {
    const poorPlayer = await createTestPlayer("Poor Player", 100);
    const gameId1 = await createTestGame(100);
    const gameId2 = await createTestGame(100);

    // Fire 2 simultaneous join requests
    const [res1, res2] = await Promise.all([
      request(app)
        .post(`/api/v1/games/${gameId1}/join`)
        .set("Authorization", `Bearer ${poorPlayer.token}`)
        .send({
          position: "ST",
          paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
        }),
      request(app)
        .post(`/api/v1/games/${gameId2}/join`)
        .set("Authorization", `Bearer ${poorPlayer.token}`)
        .send({
          position: "ST",
          paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
        }),
    ]);

    // One must succeed (200) and one must fail (400)
    const statuses = [res1.status, res2.status].sort();
    expect(statuses).toEqual([200, 400]);

    const finalBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [poorPlayer.userId],
    );
    expect(parseFloat(finalBalRes.rows[0].wallet_balance)).toBe(0);
  });

  // 13. Concurrent cancellation requests cannot create duplicate refunds
  it("Rule 13: Concurrent cancellation requests cannot create duplicate refunds", async () => {
    const player = await createTestPlayer("Concurrent Refund Player", 500);
    const gameId = await createTestGame(200);

    await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "MID",
        paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
      });

    // Simultaneous cancellation requests
    await Promise.all([
      request(app)
        .post(`/api/v1/manager/games/${gameId}/cancel`)
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ cancellationReason: "Cancellation 1" }),
      request(app)
        .post(`/api/v1/manager/games/${gameId}/cancel`)
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ cancellationReason: "Cancellation 2" }),
    ]);

    const finalBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(finalBalRes.rows[0].wallet_balance)).toBe(500);
  });

  // 14. A database error rolls back the entire wallet transaction
  it("Rule 14: Database error rolls back the entire wallet transaction", async () => {
    const player = await createTestPlayer("Rollback Player", 300);
    const balanceBefore = 300;

    const joinRes = await request(app)
      .post(`/api/v1/games/non_existent_game_99999/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "ST",
        paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
      });

    expect(joinRes.status).toBe(404);

    const balRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(balRes.rows[0].wallet_balance)).toBe(balanceBefore);
  });

  // 15. Another player cannot access or modify someone else's wallet
  it("Rule 15: Another player cannot access or modify someone else's wallet", async () => {
    const victim = await createTestPlayer("Victim Player", 0);
    const attacker = await createTestPlayer("Attacker Player", 0);

    const orderRes = await request(app)
      .post("/api/v1/wallet/topup/order")
      .set("Authorization", `Bearer ${victim.token}`)
      .send({
        amountRupees: 100,
        idempotencyKey: `victim_topup_${Date.now()}`,
        walletPin: testPin,
      });

    const victimOrderId = orderRes.body.data.paymentOrderId;

    const hackRes = await request(app)
      .post("/api/v1/wallet/topup/verify")
      .set("Authorization", `Bearer ${attacker.token}`)
      .send({
        paymentOrderId: victimOrderId,
        razorpayPaymentId: "pay_hack_123",
        razorpayOrderId: "order_hack_123",
      });

    expect(hackRes.status).toBe(403);
    expect(hackRes.body.error?.code || hackRes.body.code).toBe("FORBIDDEN");
  });

  // 16. Match joining cannot charge the same registration twice
  it("Rule 16: Match joining cannot charge the same registration twice", async () => {
    const player = await createTestPlayer("Double Join Player", 500);
    const fee = 150;
    const gameId = await createTestGame(fee);

    const join1 = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "ST",
        paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
      });
    expect(join1.status).toBe(200);

    const join2 = await request(app)
      .post(`/api/v1/games/${gameId}/join`)
      .set("Authorization", `Bearer ${player.token}`)
      .send({
        position: "MID",
        paymentDetails: { paymentMethod: "WALLET", walletPin: testPin },
      });
    expect(join2.status).toBe(400);
    expect(join2.body.error?.code || join2.body.code).toBe("ALREADY_JOINED");

    const balRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player.userId],
    );
    expect(parseFloat(balRes.rows[0].wallet_balance)).toBe(350);
  });

  // 17. When host player cancels match, ONLY the host who paid is refunded; other players get NO refund
  it("Rule 17: When host player cancels match, ONLY the player who paid gets refunded to wallet, other players do NOT get refunded", async () => {
    const hostPlayer = await createTestPlayer("Host Payer", 1000);
    const nonPayingPlayer = await createTestPlayer("Non Payer", 50);

    const createRes = await request(app)
      .post("/api/v1/games")
      .set("Authorization", `Bearer ${hostPlayer.token}`)
      .send({
        title: "Cancel Test Match",
        courtId: "court_1",
        format: "5v5",
        entryFee: 400,
        matchDate: "2026-11-05",
        startTime: "18:00:00",
        endTime: "19:00:00",
        paymentMethod: "WALLET",
        walletPin: testPin,
      });
    expect(createRes.status).toBe(201);
    const gameId = createRes.body.data.id;

    // Verify host was debited 400 (balance now 600)
    const hostMidBal = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [hostPlayer.userId],
    );
    expect(parseFloat(hostMidBal.rows[0].wallet_balance)).toBe(600);

    // Host adds non-paying player to roster (HOST_ADDED)
    await dbPool.query(
      `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status, payment_method)
       VALUES ($1, $2, 'TEAM_B', 'ST', 'PAID', 'HOST_ADDED');`,
      [gameId, nonPayingPlayer.userId],
    );

    // Host cancels match
    const cancelRes = await request(app)
      .post(`/api/v1/games/${gameId}/cancel`)
      .set("Authorization", `Bearer ${hostPlayer.token}`)
      .send({ reason: "Injury" });
    expect(cancelRes.status).toBe(200);

    // Host wallet balance MUST be refunded back to 1000
    const hostFinalBal = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [hostPlayer.userId],
    );
    expect(parseFloat(hostFinalBal.rows[0].wallet_balance)).toBe(1000);

    // Non-paying player wallet balance MUST REMAIN 50 (NO REFUND!)
    const nonPayingFinalBal = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [nonPayingPlayer.userId],
    );
    expect(parseFloat(nonPayingFinalBal.rows[0].wallet_balance)).toBe(50);
  });

  // 18. When manager cancels match, ONLY the player who paid is refunded; non-paying players do NOT get refunded
  it("Rule 18: When manager cancels match, ONLY the player who paid gets refunded, other players do NOT get refunded", async () => {
    const hostPlayer = await createTestPlayer("Mgr Cancel Host", 800);
    const nonPayingPlayer = await createTestPlayer(
      "Mgr Cancel Free Player",
      20,
    );

    const createRes = await request(app)
      .post("/api/v1/games")
      .set("Authorization", `Bearer ${hostPlayer.token}`)
      .send({
        title: "Manager Cancel Test Match",
        courtId: "court_1",
        format: "5v5",
        entryFee: 300,
        matchDate: "2026-11-06",
        startTime: "19:00:00",
        endTime: "20:00:00",
        paymentMethod: "WALLET",
        walletPin: testPin,
      });
    expect(createRes.status).toBe(201);
    const gameId = createRes.body.data.id;

    // Approve the match by manager
    await dbPool.query(
      `UPDATE public.games SET approval_status = 'APPROVED' WHERE id = $1;`,
      [gameId],
    );

    // Add non-paying player to roster
    await dbPool.query(
      `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status, payment_method)
       VALUES ($1, $2, 'TEAM_B', 'MID', 'PAID', 'FREE');`,
      [gameId, nonPayingPlayer.userId],
    );

    // Manager cancels match
    const cancelRes = await request(app)
      .post(`/api/v1/manager/games/${gameId}/cancel`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ cancellationReason: "Turf waterlogged" });
    expect(cancelRes.status).toBe(200);

    // Host wallet balance MUST be refunded back to 800
    const hostFinalBal = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [hostPlayer.userId],
    );
    expect(parseFloat(hostFinalBal.rows[0].wallet_balance)).toBe(800);

    // Non-paying player wallet balance MUST REMAIN 20 (NO REFUND!)
    const nonPayingFinalBal = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [nonPayingPlayer.userId],
    );
    expect(parseFloat(nonPayingFinalBal.rows[0].wallet_balance)).toBe(20);
  });
});
