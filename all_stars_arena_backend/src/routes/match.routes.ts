import { Router } from 'express';
import {
  getLiveMatchesController,
  getMatchDetailsController,
  updateScoreController,
} from '../controllers/match.controller.js';
import { validateRequest } from '../middlewares/validate.middleware.js';
import { getMatchDetailsSchema, updateScoreSchema } from './match.schema.js';
import { authenticateToken } from '../middlewares/auth.middleware.js';

const router = Router();

router.get('/live', getLiveMatchesController);
router.get('/:gameId', validateRequest(getMatchDetailsSchema), getMatchDetailsController);
router.post('/:gameId/score', authenticateToken, validateRequest(updateScoreSchema), updateScoreController);

export default router;
