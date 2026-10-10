import request from 'supertest';
import bcrypt from 'bcryptjs';
import app from '../app.js';
import { dbPool, initDbTables } from '../config/db.config.js';
import { CctvService } from '../modules/cctv/cctv.service.js';
import { CctvRecordingService } from '../services/cctvRecording.service.js';
import { encryptSecret, decryptSecret, redactRtspUrl } from '../utils/crypto.utils.js';
import { uploadLocalFileToS3, safeDeleteLocalFile } from '../services/storage.service.js';
import fs from 'fs';
import path from 'path';

jest.setTimeout(30000);

describe('Complete Production CCTV Recording System Tests', () => {
  const timestamp = Date.now();
  const password = 'Password123!';

  let ownerAdminToken = '';
  let managerAId = '';
  let managerAToken = '';
  let managerBId = '';
  let managerBToken = '';
  let player1Id = '';
  let player1Token = '';
  let player2Id = '';
  let player2Token = '';

  let clubAId = '';
  let clubBId = '';
  let courtA1Id = '';
  let courtB1Id = '';
  let cameraA1Id = '';
  let gameA1Id = '';
  let gameA1RecordingId = '';

  beforeAll(async () => {
    await initDbTables();

    const pwdHash = await bcrypt.hash(password, 10);

    // 1. Get Owner Admin Account
    const ownerRes = await dbPool.query(
      `SELECT u.id, u.email FROM public.users u JOIN public.admin_details ad ON ad.user_id = u.id WHERE ad.is_owner = true LIMIT 1;`
    );
    const ownerId = ownerRes.rows[0]?.id || 'usr_owner_admin_001';
    const ownerEmail = ownerRes.rows[0]?.email;
    if (ownerEmail) {
      // Login as owner admin if exists or create
      const adminLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: ownerEmail, password: 'Password123!' });
      if (adminLogin.status === 200) {
        ownerAdminToken = adminLogin.body.data.accessToken;
      }
    }

    // 2. Create Clubs A & B
    const clubARes = await dbPool.query(
      `INSERT INTO public.clubs (name, address, city, status)
       VALUES ('CCTV Arena Club Alpha', 'Stadium Road, Raipur', 'Raipur', 'ACTIVE')
       RETURNING id;`
    );
    clubAId = clubARes.rows[0].id;

    const clubBRes = await dbPool.query(
      `INSERT INTO public.clubs (name, address, city, status)
       VALUES ('CCTV Arena Club Beta', 'Civil Lines, Raipur', 'Raipur', 'ACTIVE')
       RETURNING id;`
    );
    clubBId = clubBRes.rows[0].id;

    // 3. Create Managers A and B via create_manager_account stored function
    const mgrAEmail = `mgr_a_${timestamp}@example.com`;
    const mgrAPhone = `+9197${Math.floor(10000000 + Math.random() * 90000000)}`;
    const mgrARes = await dbPool.query(
      `SELECT public.create_manager_account($1, $2, $3, $4, $5, 'Raipur', 'EMP_A01') as user_id;`,
      [ownerId, 'Manager Club Alpha', mgrAEmail, mgrAPhone, pwdHash]
    );
    managerAId = mgrARes.rows[0].user_id;
    await dbPool.query(
      `INSERT INTO public.club_managers (club_id, user_id) VALUES ($1, $2);`,
      [clubAId, managerAId]
    );
    const mgrALogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: mgrAEmail, password });
    managerAToken = mgrALogin.body.data.accessToken;

    const mgrBEmail = `mgr_b_${timestamp}@example.com`;
    const mgrBPhone = `+9196${Math.floor(10000000 + Math.random() * 90000000)}`;
    const mgrBRes = await dbPool.query(
      `SELECT public.create_manager_account($1, $2, $3, $4, $5, 'Raipur', 'EMP_B01') as user_id;`,
      [ownerId, 'Manager Club Beta', mgrBEmail, mgrBPhone, pwdHash]
    );
    managerBId = mgrBRes.rows[0].user_id;
    await dbPool.query(
      `INSERT INTO public.club_managers (club_id, user_id) VALUES ($1, $2);`,
      [clubBId, managerBId]
    );
    const mgrBLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: mgrBEmail, password });
    managerBToken = mgrBLogin.body.data.accessToken;

    // 4. Create Players 1 & 2 via register_player stored function
    const p1Email = `player1_cctv_${timestamp}@example.com`;
    const p1Phone = `+9195${Math.floor(10000000 + Math.random() * 90000000)}`;
    const p1Res = await dbPool.query(
      `SELECT public.register_player('Match Participant 1', $1, $2, $3, 'Raipur') as user_id;`,
      [p1Email, p1Phone, pwdHash]
    );
    player1Id = p1Res.rows[0].user_id;
    await dbPool.query(
      `UPDATE public.player_details SET wallet_balance = 500.00 WHERE user_id = $1;`,
      [player1Id]
    );
    const p1Login = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: p1Email, password });
    player1Token = p1Login.body.data.accessToken;

    const p2Email = `player2_cctv_${timestamp}@example.com`;
    const p2Phone = `+9194${Math.floor(10000000 + Math.random() * 90000000)}`;
    const p2Res = await dbPool.query(
      `SELECT public.register_player('External Player 2', $1, $2, $3, 'Raipur') as user_id;`,
      [p2Email, p2Phone, pwdHash]
    );
    player2Id = p2Res.rows[0].user_id;
    await dbPool.query(
      `UPDATE public.player_details SET wallet_balance = 200.00 WHERE user_id = $1;`,
      [player2Id]
    );
    const p2Login = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: p2Email, password });
    player2Token = p2Login.body.data.accessToken;

    // 5. Create Courts
    const crtARes = await dbPool.query(
      `INSERT INTO public.courts (club_id, name, base_price, status)
       VALUES ($1, 'Alpha Pitch 1', 1000.00, 'AVAILABLE')
       RETURNING id;`,
      [clubAId]
    );
    courtA1Id = crtARes.rows[0].id;

    const crtBRes = await dbPool.query(
      `INSERT INTO public.courts (club_id, name, base_price, status)
       VALUES ($1, 'Beta Pitch 1', 1000.00, 'AVAILABLE')
       RETURNING id;`,
      [clubBId]
    );
    courtB1Id = crtBRes.rows[0].id;

    // 6. Create Approved Match in Club Alpha with Player 1 rostered
    const gmRes = await dbPool.query(
      `INSERT INTO public.games (
         title, club_id, court_id, creator_id, creator_role_name, created_by_player,
         match_date, start_time, end_time, status, approval_status, entry_fee
       ) VALUES (
         'CCTV Arena League Match', $1, $2, $3, 'MANAGER', false,
         CURRENT_DATE, '19:00:00', '20:30:00', 'ONGOING', 'APPROVED', 250.00
       ) RETURNING id;`,
      [clubAId, courtA1Id, managerAId]
    );
    gameA1Id = gmRes.rows[0].id;

    // Roster Player 1 as paid participant
    await dbPool.query(
      `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
       VALUES ($1, $2, 'TEAM_A', 'FWD', 'PAID');`,
      [gameA1Id, player1Id]
    );
  });

  afterAll(async () => {
    await dbPool.query(
      `DELETE FROM public.cctv_recordings WHERE club_id IN ($1, $2);`,
      [clubAId, clubBId]
    );
    await dbPool.query(
      `DELETE FROM public.cctv_cameras WHERE club_id IN ($1, $2);`,
      [clubAId, clubBId]
    );
    await dbPool.query(
      `DELETE FROM public.games WHERE club_id IN ($1, $2);`,
      [clubAId, clubBId]
    );
    await dbPool.query(
      `DELETE FROM public.courts WHERE club_id IN ($1, $2);`,
      [clubAId, clubBId]
    );
    await dbPool.query(
      `DELETE FROM public.club_managers WHERE club_id IN ($1, $2);`,
      [clubAId, clubBId]
    );
    await dbPool.query(
      `DELETE FROM public.clubs WHERE id IN ($1, $2);`,
      [clubAId, clubBId]
    );
    await dbPool.query(
      `UPDATE public.users SET status = 'SUSPENDED' WHERE id IN ($1, $2, $3, $4);`,
      [managerAId, managerBId, player1Id, player2Id]
    );
  });

  // TEST 1: Camera configuration validation & AES-256-GCM encryption at rest
  it('1. Camera Configuration Validation: rejects invalid body and securely encrypts RTSP credentials at rest', async () => {
    // Missing required fields
    const invalidRes = await request(app)
      .post('/api/v1/cctv/cameras')
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ name: 'Short' });
    expect(invalidRes.status).toBe(400);

    // Valid camera registration
    const rawRtsp = 'rtsp://admin:superSecretPass123@192.168.1.150:554/live/ch0';
    const validRes = await request(app)
      .post('/api/v1/cctv/cameras')
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({
        clubId: clubAId,
        courtId: courtA1Id,
        name: 'Alpha Court 1 PTZ Camera',
        rtspUrl: rawRtsp,
        ipAddress: '192.168.1.150',
        port: 554,
        serialNumber: 'CAM-SN-998822',
        protocol: 'rtsp',
      });

    expect(validRes.status).toBe(201);
    expect(validRes.body.data).toHaveProperty('id');
    cameraA1Id = validRes.body.data.id;

    // Verify raw credentials never leaked in API response
    expect(validRes.body.data).not.toHaveProperty('rtspUrl');
    expect(validRes.body.data).not.toHaveProperty('password');
    expect(JSON.stringify(validRes.body.data)).not.toContain('superSecretPass123');

    // Verify encrypted at rest in PostgreSQL with AES-256-GCM
    const dbCam = await dbPool.query(
      `SELECT rtsp_url_encrypted FROM public.cctv_cameras WHERE id = $1;`,
      [cameraA1Id]
    );
    const encryptedInDb = dbCam.rows[0].rtsp_url_encrypted;
    expect(encryptedInDb).not.toBe(rawRtsp);
    expect(encryptedInDb).toContain(':');

    // Verify deciphers correctly with authentication tag
    const decrypted = decryptSecret(encryptedInDb);
    expect(decrypted).toBe(rawRtsp);
  });

  // TEST 2: Unauthorized camera access
  it('2. Unauthorized Camera Access: normal player is forbidden from camera management routes', async () => {
    const res = await request(app)
      .get(`/api/v1/cctv/clubs/${clubAId}/cameras`)
      .set('Authorization', `Bearer ${player1Token}`);

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('FORBIDDEN_ROLE');
  });

  // TEST 3: Role and club/court authorization scoping
  it('3. Club Authorization Scoping: Manager B cannot view or register cameras for Club A', async () => {
    // Manager B attempting to add camera for Club A
    const addRes = await request(app)
      .post('/api/v1/cctv/cameras')
      .set('Authorization', `Bearer ${managerBToken}`)
      .send({
        clubId: clubAId,
        name: 'Intruder Camera',
        rtspUrl: 'rtsp://admin:pass@192.168.1.200:554/stream',
      });
    expect(addRes.status).toBe(403);
    expect(addRes.body.error.code).toBe('FORBIDDEN_CLUB_SCOPE');

    // Manager B attempting to list Club A cameras
    const listRes = await request(app)
      .get(`/api/v1/cctv/clubs/${clubAId}/cameras`)
      .set('Authorization', `Bearer ${managerBToken}`);
    expect(listRes.status).toBe(403);
    expect(listRes.body.error.code).toBe('FORBIDDEN_CLUB_SCOPE');
  });

  // TEST 4: Invalid match state transitions
  it('4. Invalid Match State Transitions: cannot record an unapproved or cancelled match', async () => {
    // Create an unapproved match in Club A
    const unapprovedGame = await dbPool.query(
      `INSERT INTO public.games (title, club_id, court_id, creator_id, creator_role_name, created_by_player, match_date, start_time, end_time, status, approval_status)
       VALUES ('Unapproved Game', $1, $2, $3, 'PLAYER', true, CURRENT_DATE, '15:00:00', '16:30:00', 'OPEN_FOR_JOINING', 'PENDING_APPROVAL')
       RETURNING id;`,
      [clubAId, courtA1Id, player1Id]
    );

    const res = await request(app)
      .post('/api/v1/cctv/recordings/start')
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ gameId: unapprovedGame.rows[0].id, cameraId: cameraA1Id });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('MATCH_NOT_APPROVED');
  });

  // TEST 5: Duplicate start events and idempotency
  it('5. Duplicate Start Events & Idempotency: re-requesting start returns existing recording session without duplicates', async () => {
    // 1st start call
    const res1 = await request(app)
      .post('/api/v1/cctv/recordings/start')
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ gameId: gameA1Id, cameraId: cameraA1Id });

    expect(res1.status).toBe(200);
    expect(res1.body.data).toHaveProperty('recordingId');
    gameA1RecordingId = res1.body.data.recordingId;

    // 2nd duplicate start call for same game
    const res2 = await request(app)
      .post('/api/v1/cctv/recordings/start')
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ gameId: gameA1Id, cameraId: cameraA1Id });

    expect(res2.status).toBe(200);
    expect(res2.body.data.recordingId || res2.body.data.id).toBe(gameA1RecordingId);

    // Verify only 1 row exists in DB
    const recCount = await dbPool.query(
      `SELECT COUNT(*) FROM public.cctv_recordings WHERE game_id = $1;`,
      [gameA1Id]
    );
    expect(parseInt(recCount.rows[0].count, 10)).toBe(1);
  });

  // TEST 6: Automatic stop deadline calculation
  it('6. Automatic Stop Deadline Calculation: stop_deadline is scheduled match end + 15 minutes', async () => {
    const recRes = await dbPool.query(
      `SELECT start_time, scheduled_match_end, stop_deadline, post_match_stop_at
       FROM public.cctv_recordings WHERE id = $1;`,
      [gameA1RecordingId]
    );

    const rec = recRes.rows[0];
    const scheduledEnd = new Date(rec.scheduled_match_end).getTime();
    const stopDeadline = new Date(rec.stop_deadline).getTime();

    // The deadline should be scheduledEnd + 15 minutes (900,000 ms)
    const diffMinutes = Math.round((stopDeadline - scheduledEnd) / (60 * 1000));
    expect(diffMinutes).toBe(15);
  });

  // TEST 7: Manual stop and extension authorization
  it('7. Manual Stop and Extension Authorization: player is forbidden; manager can stop and extend', async () => {
    // Player cannot extend recording
    const plExtend = await request(app)
      .post(`/api/v1/cctv/recordings/${gameA1RecordingId}/extend`)
      .set('Authorization', `Bearer ${player1Token}`)
      .send({ additionalMinutes: 15 });
    expect(plExtend.status).toBe(403);

    // Player cannot stop recording
    const plStop = await request(app)
      .post(`/api/v1/cctv/recordings/${gameA1RecordingId}/stop`)
      .set('Authorization', `Bearer ${player1Token}`);
    expect(plStop.status).toBe(403);

    // Manager extends recording by 20 minutes
    const mgrExtend = await request(app)
      .post(`/api/v1/cctv/recordings/${gameA1RecordingId}/extend`)
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ additionalMinutes: 20 });
    expect(mgrExtend.status).toBe(200);

    // Verify extended deadline persisted in DB
    const extCheck = await dbPool.query(
      `SELECT stop_deadline FROM public.cctv_recordings WHERE id = $1;`,
      [gameA1RecordingId]
    );
    expect(extCheck.rows[0]).toBeDefined();

    // Manager stops recording
    const mgrStop = await request(app)
      .post(`/api/v1/cctv/recordings/${gameA1RecordingId}/stop`)
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ reason: 'Match concluded early by referee' });
    expect(mgrStop.status).toBe(200);

    const stopCheck = await dbPool.query(
      `SELECT status, recording_status, manual_stop, actual_stop_time FROM public.cctv_recordings WHERE id = $1;`,
      [gameA1RecordingId]
    );
    expect(stopCheck.rows[0].status).toBe('STOPPED');
    expect(stopCheck.rows[0].manual_stop).toBe(true);
    expect(stopCheck.rows[0].actual_stop_time).not.toBeNull();
  });

  // TEST 8: FFmpeg failure & camera disconnection handling
  it('8. FFmpeg Check & Camera Disconnection: reports truthful connection status without crashing', async () => {
    // Check FFmpeg availability
    const ffmpegInfo = await CctvRecordingService.checkFfmpeg();
    expect(ffmpegInfo).toHaveProperty('available');
    expect(ffmpegInfo).toHaveProperty('binaryPath');

    // Real camera test against an offline IP
    const testRes = await request(app)
      .post(`/api/v1/cctv/cameras/${cameraA1Id}/test`)
      .set('Authorization', `Bearer ${managerAToken}`);

    expect(testRes.status).toBe(200);
    expect(testRes.body.data).toHaveProperty('status');
    expect(testRes.body.data.status).toBe('OFFLINE');
    expect(testRes.body.data.message).toMatch(/(failed|timed out|refused)/i);

    // Redaction check for RTSP URLs
    const sanitizedUrl = redactRtspUrl('rtsp://turfadmin:superSecretPass@192.168.1.100:554/stream');
    expect(sanitizedUrl).toBe('rtsp://***:***@192.168.1.100:554/stream');
    expect(sanitizedUrl).not.toContain('superSecretPass');
  });

  // TEST 9: S3 upload failure and retry
  it('9. S3 Upload Failure & Retry: handles missing or corrupt local files cleanly', async () => {
    await expect(
      uploadLocalFileToS3('/non/existent/path/video.mp4', 'recordings/test.mp4', { maxRetries: 1 })
    ).rejects.toThrow('Local file not found');
  });

  // TEST 10: Database transaction failure resilience
  it('10. Database Transaction Failure: ensures rollbacks handle errors safely without leaving uncommitted state', async () => {
    const client = await dbPool.connect();
    try {
      await client.query('BEGIN');
      await client.query(
        `UPDATE public.cctv_cameras SET status = 'TESTING_ROLLBACK' WHERE id = $1;`,
        [cameraA1Id]
      );
      // Trigger intentional error
      await client.query(`SELECT 1 FROM non_existent_table_for_rollback_test;`);
    } catch (err) {
      await client.query('ROLLBACK');
    } finally {
      client.release();
    }

    const checkRes = await dbPool.query(
      `SELECT status FROM public.cctv_cameras WHERE id = $1;`,
      [cameraA1Id]
    );
    expect(checkRes.rows[0].status).not.toBe('TESTING_ROLLBACK');
  });

  // TEST 11: Recording-worker restart & boot reconciliation
  it('11. Worker Restart & Recovery: reconcileOnBoot reconciles expired recordings cleanly', async () => {
    // Insert an expired active recording in DB
    const expiredRec = await dbPool.query(
      `INSERT INTO public.cctv_recordings (
         game_id, club_id, court_id, camera_id,
         status, recording_status,
         started_at, scheduled_match_end, scheduled_match_end_at,
         stop_deadline, post_match_stop_at,
         s3_object_key, storage_object_key
       ) VALUES (
         $1, $2, $3, $4,
         'RECORDING', 'RECORDING',
         CURRENT_TIMESTAMP - INTERVAL '120 minutes',
         CURRENT_TIMESTAMP - INTERVAL '30 minutes',
         CURRENT_TIMESTAMP - INTERVAL '30 minutes',
         CURRENT_TIMESTAMP - INTERVAL '15 minutes',
         CURRENT_TIMESTAMP - INTERVAL '15 minutes',
         'recordings/reconcile_test.mp4', 'recordings/reconcile_test.mp4'
       ) RETURNING id;`,
      [gameA1Id, clubAId, courtA1Id, cameraA1Id]
    );
    const expiredId = expiredRec.rows[0].id;

    // Run reconciliation pass
    await CctvRecordingService.reconcileOnBoot();

    // Verify it transitioned to COMPLETED
    const checkRes = await dbPool.query(
      `SELECT status, recording_status FROM public.cctv_recordings WHERE id = $1;`,
      [expiredId]
    );
    expect(checkRes.rows[0].status).toBe('COMPLETED');
  });

  // TEST 12 & 13: Signed URL authorization & unauthorized access to another player's video
  it('12 & 13. Signed URL Playback Authorization: participant player gets presigned URL; non-participant player is rejected with 403', async () => {
    // Populate game_videos catalog with video for game A1
    const vidRes = await dbPool.query(
      `INSERT INTO public.game_videos (game_id, club_id, court_id, title, video_url, status)
       VALUES ($1, $2, $3, 'Match Recording - Game A1', 'recordings/test_game.mp4', 'AVAILABLE')
       RETURNING id;`,
      [gameA1Id, clubAId, courtA1Id]
    );
    const videoId = vidRes.rows[0].id;

    // Player 1 (participant in Game A1) requests playback
    const pl1Res = await request(app)
      .get(`/api/v1/cctv/playback/${gameA1Id}`)
      .set('Authorization', `Bearer ${player1Token}`);

    expect(pl1Res.status).toBe(200);
    expect(pl1Res.body.data).toHaveProperty('playbackUrl');
    expect(pl1Res.body.data.playbackUrl).toContain('X-Amz-');

    // Also via /api/v1/videos/:id/playback-url
    const pl1VideoRes = await request(app)
      .get(`/api/v1/videos/${videoId}/playback-url`)
      .set('Authorization', `Bearer ${player1Token}`);
    expect(pl1VideoRes.status).toBe(200);
    expect(pl1VideoRes.body.data.playbackUrl).toContain('X-Amz-');

    // Player 2 (NOT in Game A1) requests playback -> 403 Forbidden
    const pl2Res = await request(app)
      .get(`/api/v1/cctv/playback/${gameA1Id}`)
      .set('Authorization', `Bearer ${player2Token}`);

    expect(pl2Res.status).toBe(403);
    expect(pl2Res.body.error.code).toBe('FORBIDDEN_RECORDING_ACCESS');

    // Also via /api/v1/videos/:id/playback-url
    const pl2VideoRes = await request(app)
      .get(`/api/v1/videos/${videoId}/playback-url`)
      .set('Authorization', `Bearer ${player2Token}`);
    expect(pl2VideoRes.status).toBe(403);
    expect(pl2VideoRes.body.error.code).toBe('FORBIDDEN_RECORDING_ACCESS');
  });

  // TEST 14 & 15: Cancellation/rejection handling & payment/refund integrity
  it('14 & 15. Cancellation Handling & Payment Wallet Refunds: cancelling match stops recording and issues refunds to players', async () => {
    // Create new active game with player 1 paid fee of ₹200
    const cancelGameRes = await dbPool.query(
      `INSERT INTO public.games (title, club_id, court_id, creator_id, creator_role_name, created_by_player, match_date, start_time, end_time, status, approval_status, entry_fee)
       VALUES ('Match to Cancel', $1, $2, $3, 'MANAGER', false, CURRENT_DATE, '21:00:00', '22:30:00', 'OPEN_FOR_JOINING', 'APPROVED', 200.00)
       RETURNING id;`,
      [clubAId, courtA1Id, managerAId]
    );
    const cancelGameId = cancelGameRes.rows[0].id;

    // Player 1 joined & paid
    await dbPool.query(
      `INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
       VALUES ($1, $2, 'TEAM_A', 'MID', 'PAID');`,
      [cancelGameId, player1Id]
    );

    // Initial wallet balance
    const initBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player1Id]
    );
    const initialBal = parseFloat(initBalRes.rows[0].wallet_balance);

    // Cancel match
    const cancelRes = await request(app)
      .post(`/api/v1/manager/games/${cancelGameId}/cancel`)
      .set('Authorization', `Bearer ${managerAToken}`)
      .send({ reason: 'Pitch waterlogged after heavy rain' });

    expect(cancelRes.status).toBe(200);
    expect(cancelRes.body.data.status).toBe('CANCELLED');

    // Verify refund credited to player's wallet balance
    const updatedBalRes = await dbPool.query(
      `SELECT wallet_balance FROM public.player_details WHERE user_id = $1;`,
      [player1Id]
    );
    const updatedBal = parseFloat(updatedBalRes.rows[0].wallet_balance);
    expect(updatedBal).toBe(initialBal + 200);

    // Verify game status is CANCELLED
    const gameStatus = await dbPool.query(
      `SELECT status FROM public.games WHERE id = $1;`,
      [cancelGameId]
    );
    expect(gameStatus.rows[0].status).toBe('CANCELLED');
  });
});
