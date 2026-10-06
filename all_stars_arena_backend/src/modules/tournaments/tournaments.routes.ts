import { Router } from 'express';
import {
  getTournamentsController,
  getTournamentByIdController,
  registerTeamController,
} from './tournaments.controller.js';
import { authenticateToken, requireRole } from '../../middlewares/auth.middleware.js';

const router = Router();

router.get('/', getTournamentsController);
router.get('/:id', getTournamentByIdController);

router.use(authenticateToken);
router.post('/:id/register', requireRole([3]), registerTeamController);

export default router;
