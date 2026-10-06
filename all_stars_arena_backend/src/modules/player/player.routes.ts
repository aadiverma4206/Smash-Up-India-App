import { Router } from 'express';
import {
  getPlayerProfile,
  updatePlayerProfile,
  uploadPlayerAvatar,
  deletePlayerAvatar,
  getPlayerStats,
  getPlayerHistory,
  getDashboardSummary,
  getMyMatches,
  getPlayerRequestsController,
} from './player.controller.js';
import { validateRequest } from '../../middlewares/validate.middleware.js';
import { updatePlayerProfileSchema } from './player.schema.js';
import { uploadAvatarMiddleware } from '../../middlewares/upload.middleware.js';
import { authenticateToken, requireRole } from '../../middlewares/auth.middleware.js';

const router = Router();

router.use(authenticateToken);
router.use(requireRole([3])); // Exclusively for PLAYER accounts

router.get('/profile', getPlayerProfile);
router.put('/profile', validateRequest(updatePlayerProfileSchema), updatePlayerProfile);
router.post('/profile/image', uploadAvatarMiddleware, uploadPlayerAvatar);
router.post('/profile/avatar', uploadAvatarMiddleware, uploadPlayerAvatar);
router.delete('/profile/image', deletePlayerAvatar);
router.delete('/profile/avatar', deletePlayerAvatar);
router.get('/stats', getPlayerStats);
router.get('/history', getPlayerHistory);
router.get('/dashboard-summary', getDashboardSummary);
router.get('/my-matches', getMyMatches);
router.get('/requests', getPlayerRequestsController);

export default router;
