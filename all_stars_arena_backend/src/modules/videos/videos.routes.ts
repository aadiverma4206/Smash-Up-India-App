import { Router, Request, Response, NextFunction } from "express";
import {
  getVideoMetadata,
  getVideoPlaybackUrl,
  streamVideoFileController,
} from "./videos.controller.js";
import { validateRequest } from "../../middlewares/validate.middleware.js";
import {
  getVideoMetadataSchema,
  getVideoPlaybackUrlSchema,
} from "./videos.schema.js";
import {
  authenticateToken,
  optionalAuthenticateToken,
} from "../../middlewares/auth.middleware.js";

const router = Router();

// 1. Direct Video Streaming with HTTP Byte-Range support (HEAD & GET)
// Uses optional token authentication so mobile video_player and ExoPlayer can stream via URI with ?token= or directly
router.head("/:filename", optionalAuthenticateToken, streamVideoFileController);

router.get(
  "/:id",
  optionalAuthenticateToken,
  (req: Request, res: Response, next: NextFunction) => {
    const idOrFilename = req.params.id;
    if (
      idOrFilename.endsWith(".mp4") ||
      idOrFilename.startsWith("match_") ||
      idOrFilename.includes(".")
    ) {
      return streamVideoFileController(req, res, next);
    }
    // Otherwise requires authentication for internal metadata check
    return authenticateToken(req as any, res, (err) => {
      if (err) return next(err);
      return validateRequest(getVideoMetadataSchema)(req, res, () => {
        getVideoMetadata(req as any, res, next);
      });
    });
  },
);

// 2. Playback URL generation for S3 pre-signed objects
router.get(
  "/:id/playback-url",
  authenticateToken,
  validateRequest(getVideoPlaybackUrlSchema),
  getVideoPlaybackUrl,
);

router.get(
  "/:id/playback",
  authenticateToken,
  validateRequest(getVideoPlaybackUrlSchema),
  getVideoPlaybackUrl,
);

router.post(
  "/:id/playback",
  authenticateToken,
  validateRequest(getVideoPlaybackUrlSchema),
  getVideoPlaybackUrl,
);

export default router;
