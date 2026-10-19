import { Request, Response } from "express";
import fs from "fs";
import path from "path";
import { dbPool } from "../../config/db.config.js";
import { getSignedPlaybackUrl } from "../../services/storage.service.js";
import { CctvRecordingService } from "../../services/cctvRecording.service.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";
import { logger } from "../../utils/logger.js";

export const getVideoMetadata = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { id: videoId } = req.params;
    const userId = req.user?.id;
    const userRole = req.user?.roleId || 3;

    const videoRes = await dbPool.query(
      `SELECT gv.*, cam.name as camera_name, cam.camera_type
     FROM public.game_videos gv
     LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
     WHERE gv.id = $1;`,
      [videoId],
    );

    if (videoRes.rows.length === 0) {
      throw new ApiError(404, "Video recording not found", "VIDEO_NOT_FOUND");
    }

    const video = videoRes.rows[0];

    // Authorization check
    if (userRole === 3 && userId) {
      const isParticipant = await dbPool.query(
        "SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;",
        [video.game_id, userId],
      );
      if (isParticipant.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: Only match participants can access video recordings",
          "FORBIDDEN_RECORDING_ACCESS",
        );
      }
    } else if (userRole === 2 && userId) {
      const isClubMgr = await dbPool.query(
        "SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;",
        [video.club_id, userId],
      );
      if (isClubMgr.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You do not manage the club hosting this video",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
    }

    res
      .status(200)
      .json(ApiResponse.success("Video metadata retrieved", video));
  },
);

export const getVideoPlaybackUrl = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const { id: videoId } = req.params;
    const userId = req.user?.id;
    const userRole = req.user?.roleId || 3;

    const videoRes = await dbPool.query(
      `SELECT gv.*, cam.name as camera_name, cam.camera_type
     FROM public.game_videos gv
     LEFT JOIN public.cctv_cameras cam ON cam.id = gv.cctv_id
     WHERE gv.id = $1;`,
      [videoId],
    );

    if (videoRes.rows.length === 0) {
      throw new ApiError(404, "Video recording not found", "VIDEO_NOT_FOUND");
    }

    const video = videoRes.rows[0];

    // Authorization check
    if (userRole === 3 && userId) {
      const isParticipant = await dbPool.query(
        "SELECT 1 FROM public.game_players WHERE game_id = $1 AND user_id = $2;",
        [video.game_id, userId],
      );
      if (isParticipant.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: Only match participants can access video recordings",
          "FORBIDDEN_RECORDING_ACCESS",
        );
      }
    } else if (userRole === 2 && userId) {
      const isClubMgr = await dbPool.query(
        "SELECT 1 FROM public.club_managers WHERE club_id = $1 AND user_id = $2;",
        [video.club_id, userId],
      );
      if (isClubMgr.rows.length === 0) {
        throw new ApiError(
          403,
          "Forbidden: You do not manage the club hosting this video",
          "FORBIDDEN_CLUB_SCOPE",
        );
      }
    }

    if (video.status !== "AVAILABLE") {
      throw new ApiError(
        400,
        "Recording is currently being processed or unavailable",
        "RECORDING_PROCESSING",
      );
    }

    const playbackUrl = await getSignedPlaybackUrl(video.video_url, 3600); // 1-hour pre-signed URL

    res.status(200).json(
      ApiResponse.success("Signed playback URL generated", {
        videoId: video.id,
        gameId: video.game_id,
        title: video.title,
        playbackUrl,
        expiresInSeconds: 3600,
      }),
    );
  },
);

/**
 * Stream Recorded Video MP4 File with HTTP Byte-Range Support (GET & HEAD /api/videos/:filename)
 */
export const streamVideoFileController = asyncHandler(
  async (req: Request, res: Response) => {
    const filename = req.params.filename || req.params.id;
    if (!filename) {
      throw new ApiError(400, "Filename is required", "MISSING_FILENAME");
    }

    // Resolve safe absolute file path
    const filePath = CctvRecordingService.getVideoFilePath(filename);

    let stat: fs.Stats;
    try {
      stat = await fs.promises.stat(filePath);
    } catch (err: any) {
      throw new ApiError(
        404,
        `Video file not accessible: ${filename}`,
        "VIDEO_NOT_FOUND",
      );
    }

    const fileSize = stat.size;
    const isHead = req.method === "HEAD";
    const isDownload =
      req.query.download === "1" || req.query.download === "true";

    // Standard Video Headers
    res.setHeader("Content-Type", "video/mp4");
    res.setHeader("Accept-Ranges", "bytes");
    res.setHeader("Cache-Control", "public, max-age=86400");

    if (isDownload) {
      res.setHeader(
        "Content-Disposition",
        `attachment; filename="${path.basename(filename)}"`,
      );
    }

    const range = req.headers.range;

    if (range) {
      // Range format: "bytes=start-end" or "bytes=start-"
      const match = range.match(/bytes=(\d+)-(\d*)/);
      if (!match) {
        res.setHeader("Content-Range", `bytes */${fileSize}`);
        res.status(416).end();
        return;
      }

      const start = parseInt(match[1], 10);
      const end = match[2] ? parseInt(match[2], 10) : fileSize - 1;

      // Check invalid range boundaries
      if (start >= fileSize || end >= fileSize || start > end || start < 0) {
        res.setHeader("Content-Range", `bytes */${fileSize}`);
        res.status(416).end();
        return;
      }

      const chunkSize = end - start + 1;
      res.status(206);
      res.setHeader("Content-Range", `bytes ${start}-${end}/${fileSize}`);
      res.setHeader("Content-Length", chunkSize);

      if (isHead) {
        res.end();
        return;
      }

      const fileStream = fs.createReadStream(filePath, { start, end });
      fileStream.on("error", (err) => {
        logger.error({ err }, `Error streaming video file chunk: ${filename}`);
        if (!res.headersSent) res.status(500).end();
      });
      fileStream.pipe(res);
    } else {
      res.status(200);
      res.setHeader("Content-Length", fileSize);

      if (isHead) {
        res.end();
        return;
      }

      const fileStream = fs.createReadStream(filePath);
      fileStream.on("error", (err) => {
        logger.error({ err }, `Error streaming full video file: ${filename}`);
        if (!res.headersSent) res.status(500).end();
      });
      fileStream.pipe(res);
    }
  },
);
