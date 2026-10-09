import { Router } from 'express';
import {
  getDashboardController,
  getManagerClubController,
  getManagerCourtsController,
  getCourtSlotsController,
  createCourtController,
  updateCourtPricingController,
  simulatePricingController,
  createGameController,
  updateGameController,
  startGameController,
  completeGameController,
  cancelGameController,
  getManagerBookingsController,
  getPendingRequestsController,
  approveSlotRequestController,
  rejectSlotRequestController,
  getClubMatchesController,
  getClubHistoryController,
  getPendingGamesController,
  approvePlayerGameController,
  rejectPlayerGameController,
  getAllPlayersController,
  blockPlayerController,
  unblockPlayerController,
  submitMatchScoreController,
  getMatchRecordingController,
  stopMatchRecordingController,
  getGameDetailsController,
  getManagerProfileController,
  uploadManagerAvatarController,
} from './manager.controller.js';
import { uploadAvatarMiddleware } from '../../middlewares/upload.middleware.js';
import { validateRequest } from '../../middlewares/validate.middleware.js';
import {
  createCourtSchema,
  updateCourtPricingSchema,
  simulatePricingSchema,
  createGameSchema,
} from './manager.schema.js';
import { authenticateToken, requireRole } from '../../middlewares/auth.middleware.js';

const router = Router();

router.use(authenticateToken);
router.use(requireRole([1, 2])); // For MANAGER (Role 2) and ADMIN (Role 1)

// Dashboard & Club Scope
router.get('/dashboard', getDashboardController);
router.get('/club', getManagerClubController);

// Court Pitch Management & Slots
router.get('/courts', getManagerCourtsController);
router.get('/courts/:courtId/slots', getCourtSlotsController);
router.post('/courts', validateRequest(createCourtSchema), createCourtController);
router.put('/courts/:id/pricing', validateRequest(updateCourtPricingSchema), updateCourtPricingController);
router.post('/pricing/simulate', validateRequest(simulatePricingSchema), simulatePricingController);

// Match & Game Management
router.get('/games/pending', getPendingGamesController);
router.get('/games', getClubMatchesController);
router.get('/games/:id', getGameDetailsController);
router.post('/games', validateRequest(createGameSchema), createGameController);
router.put('/games/:id', updateGameController);
router.post('/games/:id/approve', approvePlayerGameController);
router.post('/games/:id/accept', approvePlayerGameController);
router.post('/games/:id/reject', rejectPlayerGameController);
router.post('/games/:id/start', startGameController);
router.post('/games/:id/complete', completeGameController);
router.post('/games/:id/cancel', cancelGameController);
router.post('/games/:id/score', submitMatchScoreController);

// CCTV & Recording Management for Match
router.get('/games/:id/recording', getMatchRecordingController);
router.post('/games/:id/recording/stop', stopMatchRecordingController);

// Slot Requests (Player waitlist & slot invites)
router.get('/requests', getPendingRequestsController);
router.post('/requests/:id/approve', approveSlotRequestController);
router.post('/requests/:id/reject', rejectSlotRequestController);

// Matches & Bookings
router.get('/matches', getClubMatchesController);
router.get('/history', getClubHistoryController);
router.get('/bookings', getManagerBookingsController);

// All Players & Player Moderation (Block/Unblock)
router.get('/players', getAllPlayersController);
router.post('/players/:id/block', blockPlayerController);
router.post('/players/:id/unblock', unblockPlayerController);

// Manager Profile & AWS S3 Avatar Upload
router.get('/profile', getManagerProfileController);
router.post('/profile/avatar', uploadAvatarMiddleware, uploadManagerAvatarController);

export default router;
