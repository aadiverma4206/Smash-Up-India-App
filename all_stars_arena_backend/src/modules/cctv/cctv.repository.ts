import { dbPool } from '../../config/db.config.js';

export class CctvRepository {
  static async createCamera(data: {
    clubId: string;
    courtId?: string;
    name: string;
    rtspUrlEncrypted: string;
    ipAddress?: string;
    port?: number;
    createdBy?: string;
  }) {
    const query = `
      INSERT INTO public.cctv_cameras
      (club_id, court_id, name, rtsp_url_encrypted, encrypted_connection_reference, ip_address, port, is_enabled, status, health_status, created_by)
      VALUES ($1, $2, $3, $4, $4, $5, $6, true, 'ONLINE', 'ONLINE', $7)
      RETURNING *;
    `;
    const values = [
      data.clubId,
      data.courtId || null,
      data.name,
      data.rtspUrlEncrypted,
      data.ipAddress || null,
      data.port || 554,
      data.createdBy || null,
    ];
    const res = await dbPool.query(query, values);
    return res.rows[0];
  }

  static async updateCamera(
    cameraId: string,
    data: {
      name?: string;
      courtId?: string;
      rtspUrlEncrypted?: string;
      ipAddress?: string;
      port?: number;
      isEnabled?: boolean;
      status?: string;
    }
  ) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (data.name !== undefined) {
      fields.push(`name = $${idx++}`);
      values.push(data.name);
    }
    if (data.courtId !== undefined) {
      fields.push(`court_id = $${idx++}`);
      values.push(data.courtId);
    }
    if (data.rtspUrlEncrypted !== undefined) {
      fields.push(`rtsp_url_encrypted = $${idx++}`);
      fields.push(`encrypted_connection_reference = $${idx - 1}`);
      values.push(data.rtspUrlEncrypted);
    }
    if (data.ipAddress !== undefined) {
      fields.push(`ip_address = $${idx++}`);
      values.push(data.ipAddress);
    }
    if (data.port !== undefined) {
      fields.push(`port = $${idx++}`);
      values.push(data.port);
    }
    if (data.isEnabled !== undefined) {
      fields.push(`is_enabled = $${idx++}`);
      values.push(data.isEnabled);
    }
    if (data.status !== undefined) {
      fields.push(`status = $${idx++}`);
      fields.push(`health_status = $${idx - 1}`);
      values.push(data.status);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    values.push(cameraId);
    const query = `
      UPDATE public.cctv_cameras
      SET ${fields.join(', ')}
      WHERE id = $${idx}
      RETURNING *;
    `;

    const res = await dbPool.query(query, values);
    return res.rows[0];
  }

  static async getCameraById(cameraId: string) {
    const res = await dbPool.query(
      'SELECT * FROM public.cctv_cameras WHERE id = $1;',
      [cameraId]
    );
    return res.rows[0] || null;
  }

  static async getCamerasByClub(clubId: string) {
    const res = await dbPool.query(
      `SELECT cam.*, crt.name as court_name
       FROM public.cctv_cameras cam
       LEFT JOIN public.courts crt ON crt.id = cam.court_id
       WHERE cam.club_id = $1
       ORDER BY cam.created_at DESC;`,
      [clubId]
    );
    return res.rows;
  }

  static async createRecording(data: {
    gameId: string;
    clubId: string;
    courtId?: string;
    cameraId: string;
    scheduledMatchEnd: Date;
    stopDeadline: Date;
    s3ObjectKey: string;
  }) {
    const query = `
      INSERT INTO public.cctv_recordings
      (game_id, club_id, court_id, camera_id, start_time, started_at, scheduled_match_end, scheduled_match_end_at, stop_deadline, post_match_stop_at, s3_object_key, storage_object_key, status, recording_status)
      VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $5, $5, $6, $6, $7, $7, 'RECORDING', 'RECORDING')
      RETURNING *;
    `;
    const values = [
      data.gameId,
      data.clubId,
      data.courtId || null,
      data.cameraId,
      data.scheduledMatchEnd,
      data.stopDeadline,
      data.s3ObjectKey,
    ];
    const res = await dbPool.query(query, values);
    return res.rows[0];
  }

  static async updateRecordingStatus(
    recordingId: string,
    status: string,
    actualStopTime?: Date
  ) {
    const res = await dbPool.query(
      `UPDATE public.cctv_recordings
       SET status = $1, recording_status = $1, actual_stop_time = COALESCE($2, CURRENT_TIMESTAMP), actual_stopped_at = COALESCE($2, CURRENT_TIMESTAMP)
       WHERE id = $3 RETURNING *;`,
      [status, actualStopTime || new Date(), recordingId]
    );
    return res.rows[0];
  }

  static async extendRecordingDeadline(recordingId: string, newStopDeadline: Date) {
    const res = await dbPool.query(
      `UPDATE public.cctv_recordings
       SET stop_deadline = $1, post_match_stop_at = $1
       WHERE id = $2 RETURNING *;`,
      [newStopDeadline, recordingId]
    );
    return res.rows[0];
  }

  static async getRecordingByGame(gameId: string) {
    const res = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE game_id = $1 ORDER BY created_at DESC LIMIT 1;`,
      [gameId]
    );
    return res.rows[0] || null;
  }

  static async getRecordingById(recordingId: string) {
    const res = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE id = $1;`,
      [recordingId]
    );
    return res.rows[0] || null;
  }

  static async saveGameVideoMetadata(data: {
    gameId: string;
    clubId: string;
    courtId?: string;
    title: string;
    s3ObjectKey: string;
    uploadedById?: string;
  }) {
    const query = `
      INSERT INTO public.game_videos
      (game_id, club_id, court_id, title, video_url, uploaded_by_id, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'AVAILABLE')
      RETURNING *;
    `;
    const res = await dbPool.query(query, [
      data.gameId,
      data.clubId,
      data.courtId || null,
      data.title,
      data.s3ObjectKey,
      data.uploadedById || null,
    ]);
    return res.rows[0];
  }

  static async logAudit(data: {
    adminId?: string;
    adminName: string;
    action: string;
    target: string;
    details: string;
  }) {
    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
       VALUES ($1, $2, $3, $4, $5);`,
      [data.adminId || null, data.adminName, data.action, data.target, data.details]
    );
  }
}
