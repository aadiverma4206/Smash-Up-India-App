import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('5000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  CORS_ORIGIN: z.string().default('*'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().default('supersecret_all_stars_arena_access_key_2026'),
  JWT_REFRESH_SECRET: z.string().default('supersecret_all_stars_arena_refresh_key_2026'),
  JWT_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
  RAZORPAY_KEY_ID: z.string().optional().default(''),
  RAZORPAY_KEY_SECRET: z.string().optional().default(''),
  RAZORPAY_WEBHOOK_SECRET: z.string().optional().default(''),
  RESEND_API_KEY: z.string().optional().default(''),
  EMAIL_FROM: z.string().default('ALL STARS ARENA <no-reply@allstarsarena.com>'),
  CCTV_CREDENTIAL_ENCRYPTION_KEY: z
    .string()
    .default('0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'),
  AWS_S3_REGION: z.string().default('ap-south-1'),
  AWS_S3_BUCKET_NAME: z.string().default('all-stars-arena-recordings'),
  AWS_S3_ACCESS_KEY_ID: z.string().optional().default(''),
  AWS_S3_SECRET_ACCESS_KEY: z.string().optional().default(''),
  AWS_S3_ENDPOINT: z.string().optional().default(''),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:', parsedEnv.error.format());
  throw new Error('Invalid environment variables');
}

export const env = parsedEnv.data;
