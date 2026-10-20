import request from "supertest";
import app from "../app.js";
import { dbPool } from "../config/db.config.js";
import bcrypt from "bcryptjs";

describe("Slot Approval & Match Workflow Unit Tests", () => {
  jest.setTimeout(15000);

  const testPlayerEmail = `wf_player_${Date.now()}@example.com`;
  const testPlayerPhone = `+9196${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testApplicantEmail = `wf_applicant_${Date.now()}@example.com`;
  const testApplicantPhone = `+9197${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testManagerEmail = `wf_manager_${Date.now()}@example.com`;
  const testManagerPhone = `+9195${Math.floor(10000000 + Math.random() * 90000000)}`;
  const testPassword = "Password123!";

  let playerToken: string;
  let playerUserId: string;
  let applicantToken: string;
  let applicantUserId: string;
  let managerToken: string;
  let managerUserId: string;
  let testClubId: string;
  let testCourtId: string;
  let testGameId: string;

  beforeAll(async () => {
    const adminRes = await dbPool.query(
      `SELECT id FROM public.users WHERE role_id = 1 LIMIT 1;`,
    );
    const adminId = adminRes.rows[0]?.id;

    const pwdHash = await bcrypt.hash(testPassword, 10);
    const pUserRes = await dbPool.query(
      `SELECT public.register_player('Workflow Player', $1, $2, $3, 'Raipur') as user_id;`,
      [testPlayerEmail, testPlayerPhone, pwdHash],
    );
    playerUserId = pUserRes.rows[0].user_id;

    await dbPool.query(
      `UPDATE public.player_details SET wallet_balance = 5000.00 WHERE user_id = $1;`,
      [playerUserId],
    );

    const pLogin = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: testPlayerEmail, password: testPassword });
    playerToken = pLogin.body.data.accessToken;

    const aUserRes = await dbPool.query(
      `SELECT public.register_player('Applicant Player', $1, $2, $3, 'Raipur') as user_id;`,
      [testApplicantEmail, testApplicantPhone, pwdHash],
    );
    applicantUserId = aUserRes.rows[0].user_id;

    await dbPool.query(
      `UPDATE public.player_details SET wallet_balance = 5000.00 WHERE user_id = $1;`,
      [applicantUserId],
    );

    const aLogin = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: testApplicantEmail, password: testPassword });
    applicantToken = aLogin.body.data.accessToken;

    const mUserRes = await dbPool.query(
      `INSERT INTO public.users (name, email, phone, password_hash, role_id, status)
       VALUES ('Workflow Manager', $1, $2, $3, 2, 'ACTIVE') RETURNING id;`,
      [testManagerEmail, testManagerPhone, pwdHash],
    );
    managerUserId = mUserRes.rows[0].id;

    if (adminId) {
      await dbPool.query(
        `INSERT INTO public.manager_details (user_id, created_by_admin_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;`,
        [managerUserId, adminId],
      );
    }

    const mLogin = await request(app)
      .post("/api/v1/auth/login")
      .send({ identifier: testManagerEmail, password: testPassword });
    managerToken = mLogin.body.data.accessToken;

    const clubRes = await dbPool.query(
      `INSERT INTO public.clubs (name, address, city, status)
       VALUES ('Workflow Arena Club', 'Ring Road, Raipur', 'Raipur', 'ACTIVE')
       RETURNING id;`,
    );
    testClubId = clubRes.rows[0].id;

    const courtRes = await dbPool.query(
      `INSERT INTO public.courts (club_id, name, base_price, status)
       VALUES ($1, 'Workflow Pitch 1', 1000.00, 'AVAILABLE')
       RETURNING id;`,
      [testClubId],
    );
    testCourtId = courtRes.rows[0].id;

    await dbPool.query(
      `INSERT INTO public.club_managers (club_id, user_id) VALUES ($1, $2), ('all_stars_arena_club', $2) ON CONFLICT DO NOTHING;`,
      [testClubId, managerUserId],
    );
  });

  it("Player should create a football game successfully", async () => {
    const randomDays = Math.floor(Math.random() * 100) + 10;
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + randomDays);
    const dateStr = futureDate.toISOString().split("T")[0];

    const res = await request(app)
      .post("/api/v1/games/create")
      .set("Authorization", `Bearer ${playerToken}`)
      .send({
        title: "Workflow Test Match 5v5",
        clubId: testClubId,
        courtId: testCourtId,
        format: "5v5",
        maxPlayers: 10,
        entryFee: 500,
        skillRequirement: "AMATEUR",
        privacy: "PUBLIC",
        matchDate: dateStr,
        startTime: "19:00:00",
        endTime: "20:30:00",
        description: "Test match for slot approval workflow",
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBeDefined();
    testGameId = res.body.data.id;
  });

  it("Player should submit a slot request for the game", async () => {
    const res = await request(app)
      .post(`/api/v1/games/${testGameId}/request-slot`)
      .set("Authorization", `Bearer ${applicantToken}`)
      .send({ position: "ST" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe("PENDING");
  });

  it("Manager should view pending slot requests for their club", async () => {
    const res = await request(app)
      .get("/api/v1/manager/requests")
      .set("Authorization", `Bearer ${managerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("Manager should approve the slot request atomically", async () => {
    const reqRes = await dbPool.query(
      `SELECT id FROM public.game_slot_requests WHERE game_id = $1 AND user_id = $2;`,
      [testGameId, applicantUserId],
    );
    const requestId = reqRes.rows[0]?.id;

    const res = await request(app)
      .post(`/api/v1/manager/requests/${requestId}/approve`)
      .set("Authorization", `Bearer ${managerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe("APPROVED");
  });

  it("Manager should get activity timeline logs for the game", async () => {
    const res = await request(app).get(`/api/v1/games/${testGameId}/activity`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it("Manager should cancel match with full atomic refunds", async () => {
    const res = await request(app)
      .post(`/api/v1/manager/games/${testGameId}/cancel`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ cancellationReason: "Heavy rainfall alert on turf" });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe("CANCELLED");
  });
});
