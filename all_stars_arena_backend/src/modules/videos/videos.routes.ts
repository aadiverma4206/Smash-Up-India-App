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

router.head("/:filename", optionalAuthenticateToken, streamVideoFileController);

router.get(
  "/:id/stream",
  optionalAuthenticateToken,
  streamVideoFileController,
);

router.get(
  "/:id",
  optionalAuthenticateToken,
  (req: Request, res: Response, next: NextFunction) => {
    const idOrFilename = req.params.id;
    if (
      idOrFilename.endsWith(".mp4") ||
      idOrFilename.startsWith("match_") ||
      idOrFilename.includes(".") ||
      Boolean(req.headers.range) ||
      Boolean(req.headers.accept?.includes("video")) ||
      req.query.stream === "true" ||
      req.query.playback === "true"
    ) {
      return streamVideoFileController(req, res, next);
    }

    return authenticateToken(req as any, res, (err) => {
      if (err) return next(err);
      return validateRequest(getVideoMetadataSchema)(req, res, () => {
        getVideoMetadata(req as any, res, next);
      });
    });
  },
);

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
