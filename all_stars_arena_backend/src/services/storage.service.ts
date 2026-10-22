import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import fs from "fs";
import path from "path";
import crypto from "crypto";
import { env } from "../config/env.config.js";
import { logger } from "../utils/logger.js";

const s3Region = env.AWS_REGION || env.AWS_S3_REGION || "ap-south-1";
const s3Bucket =
  env.AWS_S3_BUCKET || env.AWS_S3_BUCKET_NAME || "all-stars-arena-recordings";
const s3AccessKey = env.AWS_ACCESS_KEY_ID || env.AWS_S3_ACCESS_KEY_ID;
const s3SecretKey = env.AWS_SECRET_ACCESS_KEY || env.AWS_S3_SECRET_ACCESS_KEY;

export const s3Client = new S3Client({
  region: s3Region,
  endpoint: env.AWS_S3_ENDPOINT || undefined,
  forcePathStyle: Boolean(env.AWS_S3_ENDPOINT),
  credentials: {
    accessKeyId: s3AccessKey || "AKIAIOSFODNN7EXAMPLE",
    secretAccessKey: s3SecretKey || "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  },
});

export const getSignedPlaybackUrl = async (
  objectKey: string,
  expiresInSeconds = 3600,
): Promise<string> => {
  if (!objectKey) return "";
  if (
    objectKey.startsWith("/api/") ||
    objectKey.startsWith("http://") ||
    objectKey.startsWith("https://")
  ) {
    return objectKey;
  }
  try {
    const command = new GetObjectCommand({
      Bucket: s3Bucket,
      Key: objectKey,
    });

    return await getSignedUrl(s3Client, command, {
      expiresIn: expiresInSeconds,
    });
  } catch (err: any) {
    logger.warn(
      `Could not generate S3 signed URL for key ${objectKey}: ${err.message}. Falling back to local video endpoint.`,
    );
    return objectKey.startsWith("/")
      ? objectKey
      : `/api/videos/${path.basename(objectKey)}`;
  }
};

export const uploadRecordingToS3 = async (
  objectKey: string,
  body: Buffer | Uint8Array,
  contentType = "video/mp4",
) => {
  try {
    const command = new PutObjectCommand({
      Bucket: s3Bucket,
      Key: objectKey,
      Body: body,
      ContentType: contentType,
      ServerSideEncryption: "AES256",
    });

    await s3Client.send(command);
    logger.info(`Successfully uploaded recording to S3: ${objectKey}`);
    return { objectKey, bucket: s3Bucket };
  } catch (err: any) {
    logger.error(`Error uploading recording to S3 key ${objectKey}:`, err);
    throw err;
  }
};

export const uploadLocalFileToS3 = async (
  localFilePath: string,
  objectKey: string,
  options?: { contentType?: string; maxRetries?: number },
): Promise<{ objectKey: string; bucket: string; sizeBytes: number }> => {
  if (!fs.existsSync(localFilePath)) {
    throw new Error(`Local file not found for S3 upload: ${localFilePath}`);
  }

  const stats = await fs.promises.stat(localFilePath);
  if (stats.size === 0) {
    throw new Error(`Local recording file is empty: ${localFilePath}`);
  }

  const maxRetries = options?.maxRetries ?? env.RECORDING_MAX_RETRIES ?? 3;
  const contentType = options?.contentType ?? "video/mp4";

  let attempt = 0;
  let lastError: any = null;

  while (attempt < maxRetries) {
    attempt++;
    try {
      const fileBuffer = await fs.promises.readFile(localFilePath);
      const command = new PutObjectCommand({
        Bucket: s3Bucket,
        Key: objectKey,
        Body: fileBuffer,
        ContentType: contentType,
        ServerSideEncryption: "AES256",
      });

      await s3Client.send(command);
      logger.info(
        `[S3 Upload] Successfully uploaded recording (${stats.size} bytes) to s3://${s3Bucket}/${objectKey} on attempt ${attempt}`,
      );
      return { objectKey, bucket: s3Bucket, sizeBytes: stats.size };
    } catch (err: any) {
      lastError = err;
      logger.warn(
        `[S3 Upload] Attempt ${attempt}/${maxRetries} failed for ${objectKey}: ${err.message}`,
      );
      if (attempt < maxRetries) {
        await new Promise((res) => setTimeout(res, 500 * Math.pow(2, attempt)));
      }
    }
  }

  logger.error(
    { lastError },
    `[S3 Upload] Failed to upload ${localFilePath} to ${objectKey} after ${maxRetries} attempts`,
  );
  throw (
    lastError ||
    new Error(`Failed to upload ${objectKey} after ${maxRetries} attempts`)
  );
};

export const safeDeleteLocalFile = async (filePath: string): Promise<void> => {
  try {
    if (filePath && fs.existsSync(filePath)) {
      await fs.promises.unlink(filePath);
      logger.info(
        `[Cleanup] Deleted local temporary recording file: ${filePath}`,
      );

      const dir = path.dirname(filePath);
      const remaining = await fs.promises.readdir(dir);
      if (remaining.length === 0) {
        await fs.promises.rmdir(dir);
      }
    }
  } catch (err: any) {
    logger.warn(
      { err },
      `[Cleanup] Non-fatal error cleaning up local file: ${filePath}`,
    );
  }
};

export const uploadProfileImageToS3 = async (
  userId: string,
  buffer: Buffer,
  mimeType: string,
  extension: string,
): Promise<{ objectKey: string; publicUrl: string }> => {
  const fileUuid = crypto.randomUUID();
  const safeExtension = (extension || "jpg").replaceAll(/[^a-zA-Z0-9]/g, "");
  const objectKey = `players/${userId}/profile/${fileUuid}.${safeExtension}`;

  try {
    const command = new PutObjectCommand({
      Bucket: s3Bucket,
      Key: objectKey,
      Body: buffer,
      ContentType: mimeType,
      ServerSideEncryption: "AES256",
    });

    await s3Client.send(command);
    logger.info(`Successfully uploaded profile image to S3: ${objectKey}`);

    let publicUrl = "";
    if (env.AWS_S3_ENDPOINT) {
      publicUrl = `${env.AWS_S3_ENDPOINT}/${s3Bucket}/${objectKey}`;
    } else {
      publicUrl = `https://${s3Bucket}.s3.${s3Region}.amazonaws.com/${objectKey}`;
    }

    return { objectKey, publicUrl };
  } catch (err: any) {
    logger.error(`Error uploading avatar to S3 key ${objectKey}:`, err);
    throw err;
  }
};

export const deleteS3Object = async (objectKey: string) => {
  if (!objectKey) return;
  try {
    const command = new DeleteObjectCommand({
      Bucket: s3Bucket,
      Key: objectKey,
    });
    await s3Client.send(command);
    logger.info(`Deleted object from S3: ${objectKey}`);
  } catch (err) {
    logger.error({ err }, `Error deleting object ${objectKey} from S3`);
  }
};

export const deleteRecordingFromS3 = deleteS3Object;
