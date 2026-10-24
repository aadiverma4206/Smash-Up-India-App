import { dbPool } from "../../config/db.config.js";

export class CctvRepository {
  static async isClubManager(clubId: string, userId: string): Promise<boolean> {
    const res = await dbPool.query(
      `SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;`,
      [clubId, userId],
    );
    return (res.rowCount || 0) > 0;
  }

  static async isCourtInClub(
    courtId: string,
    clubId: string,
  ): Promise<boolean> {
    const res = await dbPool.query(
      `SELECT 1 FROM public.courts WHERE id = $1 AND club_id = $2;`,
      [courtId, clubId],
    );
    return (res.rowCount || 0) > 0;
  }

  static async createCamera(data: {
    clubId: string;
    courtId?: string;
    name: string;
    rtspUrlEncrypted: string;
    ipAddress?: string;
    port?: number;
    serialNumber?: string;
    protocol?: string;
    createdBy?: string;
  }) {
    const query = `
      INSERT INTO public.cctv_cameras
      (club_id, court_id, name, rtsp_url_encrypted, encrypted_connection_reference, ip_address, port, serial_number, protocol, is_enabled, status, health_status, created_by)
      VALUES ($1, $2, $3, $4, $4, $5, $6, $7, $8, true, 'ONLINE', 'ONLINE', $9)
      RETURNING *;
    `;
    const values = [
      data.clubId,
      data.courtId || null,
      data.name,
      data.rtspUrlEncrypted,
      data.ipAddress || null,
      data.port || 554,
      data.serialNumber || null,
      data.protocol || "rtsp",
      data.createdBy || null,
    ];
    const res = await dbPool.query(query, values);
    return res.rows[0];
  }

  static async updateCamera(
    cameraId: string,
    data: {
      name?: string;
      courtId?: string | null;
      rtspUrlEncrypted?: string;
      ipAddress?: string;
      port?: number;
      serialNumber?: string;
      protocol?: string;
      isEnabled?: boolean;
      status?: string;
      lastError?: string | null;
      lastConnectionAt?: Date;
      lastSuccessfulConnection?: Date;
    },
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
    if (data.serialNumber !== undefined) {
      fields.push(`serial_number = $${idx++}`);
      values.push(data.serialNumber);
    }
    if (data.protocol !== undefined) {
      fields.push(`protocol = $${idx++}`);
      values.push(data.protocol);
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
    if (data.lastError !== undefined) {
      fields.push(`last_error = $${idx++}`);
      values.push(data.lastError);
    }
    if (data.lastConnectionAt !== undefined) {
      fields.push(`last_connection_at = $${idx++}`);
      values.push(data.lastConnectionAt);
    }
    if (data.lastSuccessfulConnection !== undefined) {
      fields.push(`last_successful_connection = $${idx++}`);
      values.push(data.lastSuccessfulConnection);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    values.push(cameraId);
    const query = `
      UPDATE public.cctv_cameras
      SET ${fields.join(", ")}
      WHERE id = $${idx}
      RETURNING *;
    `;

    const res = await dbPool.query(query, values);
    return res.rows[0];
  }

  static async getCameraById(cameraId: string) {
    const res = await dbPool.query(
      "SELECT * FROM public.cctv_cameras WHERE id = $1;",
      [cameraId],
    );
    return res.rows[0] || null;
  }

  static async getCamerasByClub(clubId?: string) {
    const res = await dbPool.query(
      `SELECT cam.id, cam.club_id, cam.court_id, cam.name, cam.camera_type,
              cam.connection_type, cam.ip_address, cam.port, cam.serial_number,
              cam.protocol, cam.is_enabled, cam.status, cam.health_status,
              cam.last_seen_at, cam.last_connection_at, cam.last_successful_connection,
              cam.last_error, cam.created_at, cam.updated_at,
              crt.name as court_name
       FROM public.cctv_cameras cam
       LEFT JOIN public.courts crt ON crt.id = cam.court_id
       WHERE ($1::text IS NULL OR $1::text = '' OR cam.club_id = $1)
       ORDER BY cam.created_at DESC;`,
      [clubId || null],
    );
    return res.rows;
  }

  static async getActiveCameraForCourt(courtId?: string, clubId?: string) {
    const res = await dbPool.query(
      `SELECT * FROM public.cctv_cameras
       WHERE (court_id = $1 OR (club_id = $2 AND court_id IS NULL))
         AND is_enabled = true
       ORDER BY court_id NULLS LAST
       LIMIT 1;`,
      [courtId || null, clubId || null],
    );
    return res.rows[0] || null;
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
    actualStopTime?: Date,
  ) {
    const res = await dbPool.query(
      `UPDATE public.cctv_recordings
       SET status = $1, recording_status = $1, actual_stop_time = COALESCE($2, CURRENT_TIMESTAMP), actual_stopped_at = COALESCE($2, CURRENT_TIMESTAMP)
       WHERE id = $3 RETURNING *;`,
      [status, actualStopTime || new Date(), recordingId],
    );
    return res.rows[0];
  }

  static async extendRecordingDeadline(
    recordingId: string,
    newStopDeadline: Date,
  ) {
    const res = await dbPool.query(
      `UPDATE public.cctv_recordings
       SET stop_deadline = $1, post_match_stop_at = $1
       WHERE id = $2 RETURNING *;`,
      [newStopDeadline, recordingId],
    );
    return res.rows[0];
  }

  static async getRecordingByGame(gameId: string) {
    const res = await dbPool.query(
      `SELECT rec.*, cam.name as camera_name, cam.status as camera_status
       FROM public.cctv_recordings rec
       LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
       WHERE rec.game_id = $1
       ORDER BY rec.created_at DESC LIMIT 1;`,
      [gameId],
    );
    return res.rows[0] || null;
  }

  static async getRecordingById(recordingId: string) {
    const res = await dbPool.query(
      `SELECT * FROM public.cctv_recordings WHERE id = $1;`,
      [recordingId],
    );
    return res.rows[0] || null;
  }

  static async getRecordingFailures(clubId?: string) {
    let query = `
      SELECT rec.id, rec.game_id, rec.club_id, rec.court_id, rec.camera_id,
             rec.status, rec.recording_status, rec.error_code, rec.error_message,
             rec.retry_count, rec.started_at, rec.created_at,
             cam.name as camera_name, g.title as game_title
      FROM public.cctv_recordings rec
      LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
      LEFT JOIN public.games g ON g.id = rec.game_id
      WHERE rec.status = 'FAILED' OR rec.recording_status = 'FAILED'
    `;
    const params: any[] = [];
    if (clubId) {
      query += ` AND rec.club_id = $1`;
      params.push(clubId);
    }
    query += ` ORDER BY rec.created_at DESC LIMIT 50;`;

    const res = await dbPool.query(query, params);
    return res.rows;
  }

  static async saveGameVideoMetadata(data: {
    gameId: string;
    clubId: string;
    courtId?: string;
    cctvId?: string;
    title: string;
    s3ObjectKey: string;
    uploadedById?: string;
  }) {
    const query = `
      INSERT INTO public.game_videos
      (game_id, club_id, court_id, cctv_id, title, video_url, uploaded_by_id, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'AVAILABLE')
      ON CONFLICT DO NOTHING
      RETURNING *;
    `;
    const res = await dbPool.query(query, [
      data.gameId,
      data.clubId,
      data.courtId || null,
      data.cctvId || null,
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
    // Foreign key public.audit_logs(admin_id) references public.users(id).
    // System actors (like SYSTEM_WORKER) must store NULL in admin_id to satisfy the foreign key constraint.
    const adminId =
      data.adminId && data.adminId.startsWith("usr_") ? data.adminId : null;
    await dbPool.query(
      `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
       VALUES ($1, $2, $3, $4, $5);`,
      [
        adminId,
        data.adminName,
        data.action,
        data.target,
        data.details,
      ],
    );
  }
}
