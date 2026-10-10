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
  JWT_EXPIRES_IN: z.string().default('7d'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),
  RAZORPAY_KEY_ID: z.string().optional().default(''),
  RAZORPAY_KEY_SECRET: z.string().optional().default(''),
  RAZORPAY_WEBHOOK_SECRET: z.string().optional().default(''),
  RESEND_API_KEY: z.string().optional().default(''),
  EMAIL_FROM: z.string().default('ALL STARS ARENA <no-reply@allstarsarena.com>'),

  // Static Camera Configuration (Optional default camera)
  CAMERA_HOST: z.string().optional().default(''),
  CAMERA_RTSP_PORT: z.coerce.number().default(554),
  CAMERA_USERNAME: z.string().optional().default(''),
  CAMERA_PASSWORD: z.string().optional().default(''),
  CAMERA_RTSP_PATH: z.string().optional().default(''),
  CAMERA_PROTOCOL: z.string().default('rtsp'),

  // Camera Security & Networking
  CAMERA_CREDENTIAL_ENCRYPTION_KEY: z
    .string()
    .default(
      process.env.CCTV_CREDENTIAL_ENCRYPTION_KEY ||
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    ),
  CCTV_CREDENTIAL_ENCRYPTION_KEY: z
    .string()
    .default(
      process.env.CAMERA_CREDENTIAL_ENCRYPTION_KEY ||
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    ),
  CAMERA_CONNECTION_TIMEOUT_MS: z.coerce.number().default(5000),
  CAMERA_RECONNECT_INTERVAL_MS: z.coerce.number().default(5000),

  // Recording Lifecycle & Storage Parameters
  RECORDING_POST_MATCH_MINUTES: z.coerce.number().default(15),
  RECORDING_SEGMENT_SECONDS: z.coerce.number().default(300),
  RECORDING_MAX_RETRIES: z.coerce.number().default(3),
  RECORDING_MAX_CONCURRENT: z.coerce.number().default(5),
  RECORDING_TEMP_DIR: z.string().default('temp_recordings'),
  FFMPEG_PATH: z.string().default('ffmpeg'),

  // AWS S3 Storage
  AWS_REGION: z.string().default(process.env.AWS_S3_REGION || 'ap-south-1'),
  AWS_S3_REGION: z.string().default(process.env.AWS_REGION || 'ap-south-1'),
  AWS_S3_BUCKET: z.string().default(process.env.AWS_S3_BUCKET_NAME || 'all-stars-arena-recordings'),
  AWS_S3_BUCKET_NAME: z.string().default(process.env.AWS_S3_BUCKET || 'all-stars-arena-recordings'),
  AWS_ACCESS_KEY_ID: z.string().optional().default(process.env.AWS_S3_ACCESS_KEY_ID || ''),
  AWS_SECRET_ACCESS_KEY: z.string().optional().default(process.env.AWS_S3_SECRET_ACCESS_KEY || ''),
  AWS_S3_ACCESS_KEY_ID: z.string().optional().default(process.env.AWS_ACCESS_KEY_ID || ''),
  AWS_S3_SECRET_ACCESS_KEY: z.string().optional().default(process.env.AWS_SECRET_ACCESS_KEY || ''),
  AWS_S3_ENDPOINT: z.string().optional().default(''),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:', parsedEnv.error.format());
  throw new Error('Invalid environment variables');
}

export const env = parsedEnv.data;
