import { Router } from 'express';
import { getVideoMetadata, getVideoPlaybackUrl } from './videos.controller.js';
import { validateRequest } from '../../middlewares/validate.middleware.js';
import { getVideoMetadataSchema, getVideoPlaybackUrlSchema } from './videos.schema.js';
import { authenticateToken } from '../../middlewares/auth.middleware.js';

const router = Router();

router.use(authenticateToken);

router.get('/:id', validateRequest(getVideoMetadataSchema), getVideoMetadata);
router.get('/:id/playback-url', validateRequest(getVideoPlaybackUrlSchema), getVideoPlaybackUrl);

export default router;
