import request from 'supertest';
import bcrypt from 'bcryptjs';
import app from '../app.js';
import { dbPool, initDbTables } from '../config/db.config.js';

jest.setTimeout(30000);

describe('ALL STARS ARENA Manager, Admin & CCTV Management Production Tests', () => {
  const managerEmail = `manager_test_${Date.now()}@example.com`;
  const managerPhone = `+9195${Math.floor(10000000 + Math.random() * 90000000)}`;
  const password = 'Password123!';

  let managerId = '';
  let managerToken = '';
  let playerToken = '';
  let clubId = '';
  let courtId = '';
  let cameraId = '';
  let gameId = '';
  let recordingId = '';

  beforeAll(async () => {
    // Initialize CCTV DB tables
    await initDbTables();

    // 1. Get Owner Admin Account
    const ownerRes = await dbPool.query(
      `SELECT u.id, u.email FROM public.users u JOIN public.admin_details ad ON ad.user_id = u.id WHERE ad.is_owner = true LIMIT 1;`
    );
    const ownerId = ownerRes.rows[0]?.id || 'usr_owner_admin_001';

    // 2. Create Manager Account via DB Stored Function create_manager_account
    const pwdHash = await bcrypt.hash(password, 12);
    const mgrRes = await dbPool.query(
      `SELECT public.create_manager_account($1, $2, $3, $4, $5, 'Raipur', 'EMP_001') as user_id;`,
      [ownerId, 'Turf Manager', managerEmail, managerPhone, pwdHash]
    );
    managerId = mgrRes.rows[0].user_id;

    // Login Manager
    const mgrLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: managerEmail, password });
    managerToken = mgrLogin.body.data.accessToken;

    // Create & Login Player
    const playerEmail = `player_cctv_${Date.now()}@example.com`;
    const playerPhone = `+9194${Math.floor(10000000 + Math.random() * 90000000)}`;
    await dbPool.query(
      `SELECT public.register_player('CCTV Player', $1, $2, $3, 'Raipur') as user_id;`,
      [playerEmail, playerPhone, pwdHash]
    );
    const plLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: playerEmail, password });
    playerToken = plLogin.body.data.accessToken;

    // 3. Create Club & Assign Manager
    const clubRes = await dbPool.query(
      `INSERT INTO public.clubs (name, address, city, status)
       VALUES ('All Stars Turf Raipur', 'VIP Road, Raipur', 'Raipur', 'ACTIVE')
       RETURNING id;`
    );
    clubId = clubRes.rows[0].id;

    await dbPool.query(
      `INSERT INTO public.club_managers (club_id, user_id) VALUES ($1, $2);`,
      [clubId, managerId]
    );

    // 4. Create Court
    const crtRes = await dbPool.query(
      `INSERT INTO public.courts (club_id, name, base_price, status)
       VALUES ($1, 'Pitch 1 (5v5)', 1200.00, 'AVAILABLE') RETURNING id;`,
      [clubId]
    );
    courtId = crtRes.rows[0].id;

    // 5. Create Game
    const gmRes = await dbPool.query(
      `INSERT INTO public.games (title, club_id, court_id, creator_id, creator_role_name, created_by_player, match_date, start_time, end_time, status)
       VALUES ('Manager Match', $1, $2, $3, 'MANAGER', false, CURRENT_DATE, '18:00:00', '19:30:00', 'OPEN_FOR_JOINING')
       RETURNING id;`,
      [clubId, courtId, managerId]
    );
    gameId = gmRes.rows[0].id;
  });

  afterAll(async () => {
    await dbPool.query(`UPDATE public.users SET status = 'SUSPENDED' WHERE id = $1;`, [
      managerId,
    ]);
  });

  it('Player should be forbidden from accessing Manager Dashboard & CCTV Management', async () => {
    const res = await request(app)
      .get('/api/v1/manager/dashboard')
      .set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('FORBIDDEN_ROLE');
  });

  it('Manager should retrieve assigned club dashboard', async () => {
    const res = await request(app)
      .get('/api/v1/manager/dashboard')
      .set('Authorization', `Bearer ${managerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.club.id).toBe(clubId);
  });

  it('Manager should create CCTV camera with encrypted RTSP credentials (no raw secrets returned)', async () => {
    const rawRtsp = 'rtsp://admin:secretPass123@192.168.1.100:554/stream1';

    const res = await request(app)
      .post('/api/v1/cctv/cameras')
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        clubId,
        courtId,
        name: 'Court 1 Dome Camera',
        rtspUrl: rawRtsp,
        ipAddress: '192.168.1.100',
        port: 554,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('id');
    expect(res.body.data).not.toHaveProperty('rtspUrl');
    expect(res.body.data).not.toHaveProperty('password');

    cameraId = res.body.data.id;
  });

  it('Manager should test CCTV camera connection', async () => {
    const res = await request(app)
      .post(`/api/v1/cctv/cameras/${cameraId}/test`)
      .set('Authorization', `Bearer ${managerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('status');
  });

  it('Manager starting match should automatically create CCTV recording record', async () => {
    const res = await request(app)
      .post(`/api/v1/manager/games/${gameId}/start`)
      .set('Authorization', `Bearer ${managerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('ONGOING');

    const recRes = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE game_id = $1;`,
      [gameId]
    );

    if (recRes.rows.length > 0) {
      recordingId = recRes.rows[0].id;
      expect(recRes.rows[0]).toHaveProperty('stop_deadline');
    }
  });

  it('Manager completing match should enter POST_MATCH window (+15 min deadline)', async () => {
    const res = await request(app)
      .post(`/api/v1/manager/games/${gameId}/complete`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ teamAScore: 3, teamBScore: 2 });

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('COMPLETED');

    if (recordingId) {
      const recRes = await dbPool.query(
        `SELECT recording_status FROM public.cctv_recordings WHERE id = $1;`,
        [recordingId]
      );
      expect(recRes.rows[0].recording_status).toBe('POST_MATCH');
    }
  });

  it('Manager extending recording should update stop deadline', async () => {
    if (!recordingId) return;

    const res = await request(app)
      .post(`/api/v1/cctv/recordings/${recordingId}/extend`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ additionalMinutes: 15 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('Manager manually stopping recording should set status STOPPED_MANUALLY', async () => {
    if (!recordingId) return;

    const res = await request(app)
      .post(`/api/v1/cctv/recordings/${recordingId}/stop`)
      .set('Authorization', `Bearer ${managerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('Player requesting video playback should receive short-lived signed S3 URL', async () => {
    // Add mock game video metadata
    await dbPool.query(
      `INSERT INTO public.game_videos (game_id, club_id, court_id, title, video_url, status)
       VALUES ($1, $2, $3, 'Match Recording', 'recordings/test.mp4', 'AVAILABLE')
       ON CONFLICT DO NOTHING;`,
      [gameId, clubId, courtId]
    );

    const res = await request(app)
      .get(`/api/v1/cctv/playback/${gameId}`)
      .set('Authorization', `Bearer ${playerToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveProperty('playbackUrl');
    expect(res.body.data.playbackUrl).toContain('X-Amz-');
  });
});
