import { Router } from 'express';
import {
  getNotificationsController,
  markNotificationReadController,
  markAllReadController,
} from './notifications.controller.js';
import { validateRequest } from '../../middlewares/validate.middleware.js';
import { markNotificationReadSchema } from './notifications.schema.js';
import { authenticateToken } from '../../middlewares/auth.middleware.js';

const router = Router();

router.use(authenticateToken);

router.get('/', getNotificationsController);
router.patch('/:id/read', validateRequest(markNotificationReadSchema), markNotificationReadController);
router.patch('/read-all', markAllReadController);

export default router;
