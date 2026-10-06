import { Router } from 'express';
import {
  getPostsController,
  createPostController,
  likePostController,
  getPollsController,
  votePollController,
} from './community.controller.js';
import { authenticateToken } from '../../middlewares/auth.middleware.js';

const router = Router();

router.get('/posts', getPostsController);
router.get('/polls', getPollsController);

router.use(authenticateToken);
router.post('/posts', createPostController);
router.post('/posts/:id/like', likePostController);
router.post('/polls/:id/vote', votePollController);

export default router;
