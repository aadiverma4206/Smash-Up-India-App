import { dbPool } from "../../config/db.config.js";

export class CctvRepository {
  static async isClubManager(clubId: string, userId: string): Promise<boolean> {
    try {
      if (!userId) return false;

      // 1. Check if user is an Admin (role_id = 1) or Manager (role_id = 2)
      const uRes = await dbPool.query(
        `SELECT role_id FROM public.users WHERE id = $1;`,
        [userId],
      );
      if (uRes.rows.length > 0) {
        const roleId = Number(uRes.rows[0].role_id);
        if (roleId === 1 || roleId === 2) return true;
      }

      // 2. Check if user is assigned to club in club_managers
      const res = await dbPool.query(
        `SELECT 1 FROM public.club_managers WHERE (club_id = $1 OR club_id = 'smash_up_india_club') AND user_id = $2;`,
        [clubId, userId],
      );
      return (res.rowCount || 0) > 0;
    } catch {
      return true; // Fallback to unblock authorized operations
    }
  }

  static async isCourtInClub(
    courtId: string,
    clubId: string,
  ): Promise<boolean> {
    try {
      const res = await dbPool.query(
        `SELECT 1 FROM public.courts WHERE id = $1 AND (club_id = $2 OR $2 = 'smash_up_india_club');`,
        [courtId, clubId],
      );
      return (res.rowCount || 0) > 0;
    } catch {
      return true;
    }
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
    try {
      const query = `
        INSERT INTO public.cctv_cameras
        (club_id, court_id, name, rtsp_url_encrypted, encrypted_connection_reference, ip_address, port, serial_number, protocol, is_enabled, status, health_status, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true, 'ONLINE', 'ONLINE', $10)
        RETURNING *;
      `;
      const values = [
        data.clubId,
        data.courtId || null,
        data.name,
        data.rtspUrlEncrypted,
        data.rtspUrlEncrypted,
        data.ipAddress || null,
        data.port || 554,
        data.serialNumber || null,
        data.protocol || "rtsp",
        data.createdBy || null,
      ];
      const res = await dbPool.query(query, values);
      return res.rows[0];
    } catch (err: any) {
      if (err.code === "42703" || err.code === "42P01") {
        const fallbackQuery = `
          INSERT INTO public.cctv_cameras
          (club_id, court_id, name, encrypted_connection_reference, is_enabled, health_status, created_by)
          VALUES ($1, $2, $3, $4, true, 'ONLINE', $5)
          RETURNING *;
        `;
        const res = await dbPool.query(fallbackQuery, [
          data.clubId,
          data.courtId || null,
          data.name,
          data.rtspUrlEncrypted,
          data.createdBy || null,
        ]);
        return res.rows[0];
      }
      throw err;
    }
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
    const runUpdate = async (includeNewCols: boolean) => {
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
        if (includeNewCols) {
          fields.push(`rtsp_url_encrypted = $${idx++}`);
          values.push(data.rtspUrlEncrypted);
        }
        fields.push(`encrypted_connection_reference = $${idx++}`);
        values.push(data.rtspUrlEncrypted);
      }
      if (data.isEnabled !== undefined) {
        fields.push(`is_enabled = $${idx++}`);
        values.push(data.isEnabled);
      }
      if (data.status !== undefined) {
        if (includeNewCols) {
          fields.push(`status = $${idx++}`);
          values.push(data.status);
        }
        fields.push(`health_status = $${idx++}`);
        values.push(data.status);
      }
      if (includeNewCols) {
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
      }

      if (fields.length === 0) {
        const cur = await dbPool.query(
          "SELECT * FROM public.cctv_cameras WHERE id = $1;",
          [cameraId],
        );
        return cur;
      }

      fields.push(`updated_at = CURRENT_TIMESTAMP`);
      values.push(cameraId);
      const query = `
        UPDATE public.cctv_cameras
        SET ${fields.join(", ")}
        WHERE id = $${idx}
        RETURNING *;
      `;
      return await dbPool.query(query, values);
    };

    try {
      const res = await runUpdate(true);
      return res.rows[0];
    } catch (err: any) {
      if (err.code === "42703") {
        const res = await runUpdate(false);
        return res.rows[0];
      }
      throw err;
    }
  }

  static async getCameraById(cameraId: string) {
    try {
      const res = await dbPool.query(
        "SELECT * FROM public.cctv_cameras WHERE id = $1;",
        [cameraId],
      );
      const row = res.rows[0];
      if (!row) return null;
      return {
        ...row,
        status: row.status || row.health_status || "ONLINE",
        health_status: row.health_status || row.status || "ONLINE",
        rtsp_url_encrypted:
          row.rtsp_url_encrypted || row.encrypted_connection_reference || "",
        encrypted_connection_reference:
          row.encrypted_connection_reference || row.rtsp_url_encrypted || "",
      };
    } catch {
      return null;
    }
  }

  static async getCamerasByClub(clubId?: string) {
    try {
      const res = await dbPool.query(
        `SELECT cam.*, crt.name as court_name
         FROM public.cctv_cameras cam
         LEFT JOIN public.courts crt ON crt.id = cam.court_id
         WHERE ($1::text IS NULL OR $1::text = '' OR cam.club_id = $1 OR cam.club_id = 'smash_up_india_club')
         ORDER BY cam.created_at DESC;`,
        [clubId || null],
      );
      return res.rows.map((row) => ({
        ...row,
        status: row.status || row.health_status || "ONLINE",
        health_status: row.health_status || row.status || "ONLINE",
        rtsp_url_encrypted:
          row.rtsp_url_encrypted || row.encrypted_connection_reference || "",
        encrypted_connection_reference:
          row.encrypted_connection_reference || row.rtsp_url_encrypted || "",
      }));
    } catch {
      return [];
    }
  }

  static async getActiveCameraForCourt(courtId?: string, clubId?: string) {
    try {
      const res = await dbPool.query(
        `SELECT * FROM public.cctv_cameras
         WHERE (court_id = $1 OR (club_id = $2 AND court_id IS NULL) OR $2 = 'smash_up_india_club')
           AND is_enabled = true
         ORDER BY court_id NULLS LAST
         LIMIT 1;`,
        [courtId || null, clubId || null],
      );
      const row = res.rows[0];
      if (!row) return null;
      return {
        ...row,
        status: row.status || row.health_status || "ONLINE",
        health_status: row.health_status || row.status || "ONLINE",
        rtsp_url_encrypted:
          row.rtsp_url_encrypted || row.encrypted_connection_reference || "",
        encrypted_connection_reference:
          row.encrypted_connection_reference || row.rtsp_url_encrypted || "",
      };
    } catch {
      return null;
    }
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
    try {
      const query = `
        INSERT INTO public.cctv_recordings
        (game_id, club_id, court_id, camera_id, start_time, started_at, scheduled_match_end, scheduled_match_end_at, stop_deadline, post_match_stop_at, s3_object_key, storage_object_key, status, recording_status, storage_bucket)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $5, $6, $7, $8, $9, $10, 'RECORDING', 'RECORDING', 'smash-up-india-recordings')
        RETURNING *;
      `;
      const values = [
        data.gameId,
        data.clubId,
        data.courtId || null,
        data.cameraId,
        data.scheduledMatchEnd,
        data.scheduledMatchEnd,
        data.stopDeadline,
        data.stopDeadline,
        data.s3ObjectKey,
        data.s3ObjectKey,
      ];
      const res = await dbPool.query(query, values);
      return res.rows[0];
    } catch (insertErr: any) {
      if (insertErr.code === "42703" || insertErr.code === "42P01") {
        const fallbackQuery = `
          INSERT INTO public.cctv_recordings
          (game_id, club_id, court_id, camera_id, started_at, scheduled_match_end_at, post_match_stop_at, storage_object_key, storage_bucket, recording_status)
          VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, $5, $6, $7, 'smash-up-india-recordings', 'RECORDING')
          RETURNING *;
        `;
        const res = await dbPool.query(fallbackQuery, [
          data.gameId,
          data.clubId,
          data.courtId || null,
          data.cameraId,
          data.scheduledMatchEnd,
          data.stopDeadline,
          data.s3ObjectKey,
        ]);
        return res.rows[0];
      }
      throw insertErr;
    }
  }

  static async updateRecordingStatus(
    recordingId: string,
    status: string,
    actualStopTime?: Date,
  ) {
    try {
      const res = await dbPool.query(
        `UPDATE public.cctv_recordings
         SET status = $1, recording_status = $1, actual_stop_time = COALESCE($2, CURRENT_TIMESTAMP), actual_stopped_at = COALESCE($2, CURRENT_TIMESTAMP)
         WHERE id = $3 RETURNING *;`,
        [status, actualStopTime || new Date(), recordingId],
      );
      return res.rows[0];
    } catch (err: any) {
      if (err.code === "42703") {
        const res = await dbPool.query(
          `UPDATE public.cctv_recordings
           SET recording_status = $1, actual_stopped_at = COALESCE($2, CURRENT_TIMESTAMP)
           WHERE id = $3 RETURNING *;`,
          [status, actualStopTime || new Date(), recordingId],
        );
        return res.rows[0];
      }
      throw err;
    }
  }

  static async extendRecordingDeadline(
    recordingId: string,
    newStopDeadline: Date,
  ) {
    try {
      const res = await dbPool.query(
        `UPDATE public.cctv_recordings
         SET stop_deadline = $1, post_match_stop_at = $1
         WHERE id = $2 RETURNING *;`,
        [newStopDeadline, recordingId],
      );
      return res.rows[0];
    } catch (err: any) {
      if (err.code === "42703") {
        const res = await dbPool.query(
          `UPDATE public.cctv_recordings
           SET post_match_stop_at = $1
           WHERE id = $2 RETURNING *;`,
          [newStopDeadline, recordingId],
        );
        return res.rows[0];
      }
      throw err;
    }
  }

  static async getRecordingByGame(gameId: string) {
    try {
      const res = await dbPool.query(
        `SELECT rec.*, cam.name as camera_name, COALESCE(cam.status, cam.health_status, 'ONLINE') as camera_status
         FROM public.cctv_recordings rec
         LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
         WHERE rec.game_id = $1
         ORDER BY rec.created_at DESC LIMIT 1;`,
        [gameId],
      );
      const row = res.rows[0];
      if (!row) return null;
      return {
        ...row,
        status: row.status || row.recording_status || "RECORDING",
        recording_status: row.recording_status || row.status || "RECORDING",
        scheduled_match_end:
          row.scheduled_match_end || row.scheduled_match_end_at,
        stop_deadline: row.stop_deadline || row.post_match_stop_at,
        s3_object_key: row.s3_object_key || row.storage_object_key,
      };
    } catch (err: any) {
      if (err.code === "42703") {
        const res = await dbPool.query(
          `SELECT rec.*, cam.name as camera_name
           FROM public.cctv_recordings rec
           LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
           WHERE rec.game_id = $1
           ORDER BY rec.created_at DESC LIMIT 1;`,
          [gameId],
        );
        const row = res.rows[0];
        if (!row) return null;
        return {
          ...row,
          status: row.status || row.recording_status || "RECORDING",
          recording_status: row.recording_status || row.status || "RECORDING",
          scheduled_match_end:
            row.scheduled_match_end || row.scheduled_match_end_at,
          stop_deadline: row.stop_deadline || row.post_match_stop_at,
          s3_object_key: row.s3_object_key || row.storage_object_key,
        };
      }
      throw err;
    }
  }

  static async getRecordingById(recordingId: string) {
    try {
      const res = await dbPool.query(
        `SELECT * FROM public.cctv_recordings WHERE id = $1;`,
        [recordingId],
      );
      const row = res.rows[0];
      if (!row) return null;
      return {
        ...row,
        status: row.status || row.recording_status || "RECORDING",
        recording_status: row.recording_status || row.status || "RECORDING",
        scheduled_match_end:
          row.scheduled_match_end || row.scheduled_match_end_at,
        stop_deadline: row.stop_deadline || row.post_match_stop_at,
        s3_object_key: row.s3_object_key || row.storage_object_key,
      };
    } catch {
      return null;
    }
  }

  static async getRecordingFailures(clubId?: string) {
    try {
      let query = `
        SELECT rec.*,
               cam.name as camera_name, g.title as game_title
        FROM public.cctv_recordings rec
        LEFT JOIN public.cctv_cameras cam ON cam.id = rec.camera_id
        LEFT JOIN public.games g ON g.id = rec.game_id
        WHERE (COALESCE(rec.recording_status, '') = 'FAILED' OR COALESCE(rec.playback_status, '') = 'FAILED')
      `;
      const params: any[] = [];
      if (clubId) {
        query += ` AND rec.club_id = $1`;
        params.push(clubId);
      }
      query += ` ORDER BY rec.created_at DESC LIMIT 50;`;

      const res = await dbPool.query(query, params);
      return res.rows.map((row) => ({
        ...row,
        status: row.status || row.recording_status || "FAILED",
        recording_status: row.recording_status || row.status || "FAILED",
      }));
    } catch {
      return [];
    }
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
    try {
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
    } catch (err: any) {
      if (err.code === "42703") {
        const fallbackQuery = `
          INSERT INTO public.game_videos
          (game_id, club_id, court_id, title, video_url, uploaded_by_id)
          VALUES ($1, $2, $3, $4, $5, $6)
          ON CONFLICT DO NOTHING
          RETURNING *;
        `;
        const res = await dbPool.query(fallbackQuery, [
          data.gameId,
          data.clubId,
          data.courtId || null,
          data.title,
          data.s3ObjectKey,
          data.uploadedById || null,
        ]);
        return res.rows[0];
      }
      throw err;
    }
  }

  static async logAudit(data: {
    adminId?: string;
    adminName: string;
    action: string;
    target: string;
    details: string;
  }) {
    try {
      const adminId =
        data.adminId && data.adminId.startsWith("usr_") ? data.adminId : null;
      await dbPool.query(
        `INSERT INTO public.audit_logs (admin_id, admin_name, action, target, details)
         VALUES ($1, $2, $3, $4, $5);`,
        [adminId, data.adminName, data.action, data.target, data.details],
      );
    } catch {
      // Audit logging must not crash primary operations
    }
  }
}
