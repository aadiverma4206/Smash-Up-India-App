import { z } from "zod";

export const getPostsSchema = z.object({
  query: z.object({
    city: z.string().optional().default("Raipur"),
    limit: z.coerce.number().int().min(1).max(50).default(20),
  }),
});

export const getPollsSchema = z.object({
  query: z.object({
    city: z.string().optional().default("Raipur"),
  }),
});

export const createPostSchema = z.object({
  body: z.object({
    content: z.string().min(1, "Post content is required"),
    imageUrl: z.string().optional(),
    tags: z.array(z.string()).optional().default([]),
    city: z.string().optional().default("Raipur"),
  }),
});

export const likePostSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Post ID is required"),
  }),
});

export const votePollSchema = z.object({
  params: z.object({
    id: z.string().min(1, "Poll ID is required"),
  }),
  body: z.object({
    optionId: z.coerce.string().min(1, "Option ID is required"),
  }),
});
