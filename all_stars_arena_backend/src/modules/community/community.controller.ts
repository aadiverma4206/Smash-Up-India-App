import { Request, Response } from "express";
import { dbPool } from "../../config/db.config.js";
import { ApiResponse, ApiError } from "../../utils/apiResponse.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { AuthenticatedRequest } from "../../types/index.js";

export const getPostsController = asyncHandler(
  async (req: Request, res: Response) => {
    const city = (req.query.city as string) || "Raipur";
    const limit = Math.min(50, Number(req.query.limit) || 20);

    const postsRes = await dbPool.query(
      `SELECT p.*, u.name as author_name, u.profile_image_url as author_avatar
     FROM public.community_posts p
     JOIN public.users u ON u.id = p.author_id
     WHERE p.city = $1
     ORDER BY p.created_at DESC LIMIT $2;`,
      [city, limit],
    );

    res
      .status(200)
      .json(ApiResponse.success("Community posts retrieved", postsRes.rows));
  },
);

export const createPostController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { content, imageUrl, tags = [], city = "Raipur" } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");
    if (!content) throw new ApiError(400, "Post content is required");

    const postRes = await dbPool.query(
      `INSERT INTO public.community_posts (city, author_id, content, image_url, tags)
     VALUES ($1, $2, $3, $4, $5) RETURNING *;`,
      [city, userId, content, imageUrl || null, JSON.stringify(tags)],
    );

    res
      .status(201)
      .json(ApiResponse.success("Post created successfully", postRes.rows[0]));
  },
);

export const likePostController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: postId } = req.params;

    if (!userId) throw new ApiError(401, "Unauthorized");

    // Trigger trg_sync_post_likes automatically increments likes_count!
    await dbPool.query(
      `INSERT INTO public.post_likes (post_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;`,
      [postId, userId],
    );

    res.status(200).json(ApiResponse.success("Post liked successfully"));
  },
);

export const getPollsController = asyncHandler(
  async (req: Request, res: Response) => {
    const city = (req.query.city as string) || "Raipur";

    const pollsRes = await dbPool.query(
      `SELECT * FROM public.polls WHERE city = $1 ORDER BY created_at DESC LIMIT 10;`,
      [city],
    );

    const polls = [];
    for (const poll of pollsRes.rows) {
      const optsRes = await dbPool.query(
        `SELECT * FROM public.poll_options WHERE poll_id = $1 ORDER BY id ASC;`,
        [poll.id],
      );
      polls.push({
        ...poll,
        options: optsRes.rows,
      });
    }

    res.status(200).json(ApiResponse.success("Polls retrieved", polls));
  },
);

export const votePollController = asyncHandler(
  async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const { id: pollId } = req.params;
    const { optionId } = req.body;

    if (!userId) throw new ApiError(401, "Unauthorized");
    if (!optionId) throw new ApiError(400, "Option ID is required");

    // Trigger trg_sync_poll_votes automatically increments votes_count!
    await dbPool.query(
      `INSERT INTO public.poll_votes (poll_id, user_id, option_id) VALUES ($1, $2, $3);`,
      [pollId, userId, optionId],
    );

    res.status(200).json(ApiResponse.success("Vote recorded successfully"));
  },
);
