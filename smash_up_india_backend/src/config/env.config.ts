import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { fileURLToPath } from "url";
import { z } from "zod";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Priority 1: smash_up_india_backend/.env
// Priority 2: cwd/smash_up_india_backend/.env
// Priority 3: cwd/.env
const candidateEnvFiles = [
  path.resolve(__dirname, "../../.env"),
  path.resolve(process.cwd(), "smash_up_india_backend", ".env"),
  path.resolve(process.cwd(), ".env"),
];

let loadedEnv = false;
for (const envPath of candidateEnvFiles) {
  if (fs.existsSync(envPath)) {
    const res = dotenv.config({ path: envPath });
    if (res.parsed?.DATABASE_URL) {
      loadedEnv = true;
      break;
    }
  }
}
if (!loadedEnv) {
  dotenv.config();
}

const envSchema = z.object({
  PORT: z.string().default("8599"),
  NODE_ENV: z
    .enum(["development", "production", "test"])
    .default("development"),
  CORS_ORIGIN: z.string().default("*"),
  DATABASE_URL: z
    .string()
    .default("postgresql://postgres:system@127.0.0.1:5432/smash_up_india"),
  JWT_SECRET: z.string().default("supersecret_smash_up_india_access_key_2026"),
  JWT_REFRESH_SECRET: z
    .string()
    .default("supersecret_smash_up_india_refresh_key_2026"),
  JWT_EXPIRES_IN: z.string().default("7d"),
  JWT_REFRESH_EXPIRES_IN: z.string().default("30d"),
  RAZORPAY_KEY_ID: z.string().optional().default(""),
  RAZORPAY_KEY_SECRET: z.string().optional().default(""),
  RAZORPAY_WEBHOOK_SECRET: z.string().optional().default(""),
  RESEND_API_KEY: z.string().optional().default(""),
  EMAIL_FROM: z.string().default("SMASH UP INDIA <no-reply@smashupindia.com>"),

  BACKEND_URL: z.string().default("http://10.0.2.2:8599"),
  AUTO_FREE_PORT: z.string().optional().default("true"),

  GOOGLE_APPLICATION_CREDENTIALS: z
    .string()
    .optional()
    .default("./smash-up-india-firebase.json"),
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().optional().default(""),
  FIREBASE_PROJECT_ID: z.string().optional().default("smash-up-india"),

  CAMERA_HOST: z.string().optional().default("192.168.1.2"),
  CAMERA_RTSP_PORT: z.coerce.number().default(554),
  CAMERA_TCP_PORT: z.coerce.number().default(37777),
  CAMERA_HTTP_PORT: z.coerce.number().default(80),
  CAMERA_USERNAME: z.string().optional().default("admin"),
  CAMERA_PASSWORD: z.string().optional().default("admin@123"),
  CAMERA_RTSP_PATH: z
    .string()
    .optional()
    .default("/cam/realmonitor?channel=1&subtype=0"),
  CAMERA_PROTOCOL: z.string().default("rtsp"),
  CAMERA_SERIAL_NUMBER: z.string().optional().default("3L04789PAZ01138"),
  CAMERA_DEVICE_NAME: z.string().optional().default("Botivate"),

  CAMERA_CREDENTIAL_ENCRYPTION_KEY: z
    .string()
    .default(
      process.env.CCTV_CREDENTIAL_ENCRYPTION_KEY ||
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    ),
  CCTV_CREDENTIAL_ENCRYPTION_KEY: z
    .string()
    .default(
      process.env.CAMERA_CREDENTIAL_ENCRYPTION_KEY ||
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    ),
  CAMERA_CONNECTION_TIMEOUT_MS: z.coerce.number().default(5000),
  CAMERA_RECONNECT_INTERVAL_MS: z.coerce.number().default(5000),

  RECORDING_OUTPUT_DIR: z.string().default("./recordings"),
  RECORDING_TEMP_DIR: z.string().default("temp_recordings"),
  RECORDING_DURATION_MINUTES: z.coerce.number().default(120),
  RECORDING_POST_MATCH_MINUTES: z.coerce.number().default(5),
  RECORDING_SEGMENT_SECONDS: z.coerce.number().default(300),
  RECORDING_MAX_RETRIES: z.coerce.number().default(3),
  RECORDING_MAX_CONCURRENT: z.coerce.number().default(5),
  FFMPEG_PATH: z
    .string()
    .default(
      process.env.FFMPEG_PATH ||
        (process.platform === "win32" &&
        process.env.LOCALAPPDATA &&
        fs.existsSync(
          path.join(
            process.env.LOCALAPPDATA,
            "Microsoft",
            "WinGet",
            "Links",
            "ffmpeg.exe",
          ),
        )
          ? path.join(
              process.env.LOCALAPPDATA,
              "Microsoft",
              "WinGet",
              "Links",
              "ffmpeg.exe",
            )
          : "ffmpeg"),
    ),

  AWS_REGION: z.string().default(process.env.AWS_S3_REGION || "ap-south-1"),
  AWS_S3_REGION: z.string().default(process.env.AWS_REGION || "ap-south-1"),
  AWS_S3_BUCKET: z
    .string()
    .default(process.env.AWS_S3_BUCKET_NAME || "smash-up-india-recordings"),
  AWS_S3_BUCKET_NAME: z
    .string()
    .default(process.env.AWS_S3_BUCKET || "smash-up-india-recordings"),
  AWS_ACCESS_KEY_ID: z
    .string()
    .optional()
    .default(process.env.AWS_S3_ACCESS_KEY_ID || ""),
  AWS_SECRET_ACCESS_KEY: z
    .string()
    .optional()
    .default(process.env.AWS_S3_SECRET_ACCESS_KEY || ""),
  AWS_S3_ACCESS_KEY_ID: z
    .string()
    .optional()
    .default(process.env.AWS_ACCESS_KEY_ID || ""),
  AWS_S3_SECRET_ACCESS_KEY: z
    .string()
    .optional()
    .default(process.env.AWS_SECRET_ACCESS_KEY || ""),
  AWS_S3_ENDPOINT: z.string().optional().default(""),
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error("❌ Invalid environment variables:", parsedEnv.error.format());
  throw new Error("Invalid environment variables");
}

export const env = parsedEnv.data;

export const getDefaultRtspUrl = (channel = 1, subtype = 0): string => {
  if (!env.CAMERA_HOST) return "";
  const username = env.CAMERA_USERNAME || "admin";
  const rawPass = env.CAMERA_PASSWORD || "";
  const encodedPass = encodeURIComponent(rawPass);
  const auth = username ? `${username}:${encodedPass}@` : "";
  const host = env.CAMERA_HOST || "192.168.1.2";
  const port = env.CAMERA_RTSP_PORT || 554;

  let pathStr =
    env.CAMERA_RTSP_PATH ||
    `/cam/realmonitor?channel=${channel}&subtype=${subtype}`;
  if (pathStr.includes("channel=")) {
    pathStr = pathStr.replace(/channel=\d+/, `channel=${channel}`);
  }
  if (pathStr.includes("subtype=")) {
    pathStr = pathStr.replace(/subtype=\d+/, `subtype=${subtype}`);
  }

  const formattedPath = pathStr.startsWith("/") ? pathStr : `/${pathStr}`;
  return `${env.CAMERA_PROTOCOL || "rtsp"}://${auth}${host}:${port}${formattedPath}`;
};
