import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import crypto from 'crypto';
import { env } from '../config/env.config.js';
import { logger } from '../utils/logger.js';

const s3Client = new S3Client({
  region: env.AWS_S3_REGION,
  endpoint: env.AWS_S3_ENDPOINT || undefined,
  forcePathStyle: Boolean(env.AWS_S3_ENDPOINT), // Required for MinIO / Local S3
  credentials:
    env.AWS_S3_ACCESS_KEY_ID && env.AWS_S3_SECRET_ACCESS_KEY
      ? {
          accessKeyId: env.AWS_S3_ACCESS_KEY_ID,
          secretAccessKey: env.AWS_S3_SECRET_ACCESS_KEY,
        }
      : undefined,
});

/**
 * Generate short-lived signed URL for private S3 objects (e.g. CCTV recordings or private profile images)
 */
export const getSignedPlaybackUrl = async (
  objectKey: string,
  expiresInSeconds = 3600
): Promise<string> => {
  try {
    const command = new GetObjectCommand({
      Bucket: env.AWS_S3_BUCKET_NAME,
      Key: objectKey,
    });

    return await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
  } catch (err: any) {
    logger.error(`Error generating signed playback URL for key ${objectKey}:`, err);
    throw new Error('Could not generate playback URL');
  }
};

/**
 * Upload recording file stream/buffer to S3 bucket
 */
export const uploadRecordingToS3 = async (
  objectKey: string,
  body: Buffer | Uint8Array,
  contentType = 'video/mp4'
) => {
  try {
    const command = new PutObjectCommand({
      Bucket: env.AWS_S3_BUCKET_NAME,
      Key: objectKey,
      Body: body,
      ContentType: contentType,
    });

    await s3Client.send(command);
    logger.info(`Successfully uploaded recording to S3: ${objectKey}`);
    return { objectKey, bucket: env.AWS_S3_BUCKET_NAME };
  } catch (err: any) {
    logger.error(`Error uploading recording to S3 key ${objectKey}:`, err);
    throw err;
  }
};

/**
 * Upload player profile avatar image to S3 in user-scoped path: players/{userId}/profile/{uuid}.ext
 */
export const uploadProfileImageToS3 = async (
  userId: string,
  buffer: Buffer,
  mimeType: string,
  extension: string
): Promise<{ objectKey: string; publicUrl: string }> => {
  const fileUuid = crypto.randomUUID();
  const safeExtension = (extension || 'jpg').replaceAll(/[^a-zA-Z0-9]/g, '');
  const objectKey = `players/${userId}/profile/${fileUuid}.${safeExtension}`;

  try {
    const command = new PutObjectCommand({
      Bucket: env.AWS_S3_BUCKET_NAME,
      Key: objectKey,
      Body: buffer,
      ContentType: mimeType,
    });

    await s3Client.send(command);
    logger.info(`Successfully uploaded profile image to S3: ${objectKey}`);

    let publicUrl = '';
    if (env.AWS_S3_ENDPOINT) {
      publicUrl = `${env.AWS_S3_ENDPOINT}/${env.AWS_S3_BUCKET_NAME}/${objectKey}`;
    } else {
      publicUrl = `https://${env.AWS_S3_BUCKET_NAME}.s3.${env.AWS_S3_REGION}.amazonaws.com/${objectKey}`;
    }

    return { objectKey, publicUrl };
  } catch (err: any) {
    logger.error(`Error uploading avatar to S3 key ${objectKey}:`, err);
    throw err;
  }
};

/**
 * Delete object from S3
 */
export const deleteS3Object = async (objectKey: string) => {
  if (!objectKey) return;
  try {
    const command = new DeleteObjectCommand({
      Bucket: env.AWS_S3_BUCKET_NAME,
      Key: objectKey,
    });
    await s3Client.send(command);
    logger.info(`Deleted object from S3: ${objectKey}`);
  } catch (err) {
    logger.error({ err }, `Error deleting object ${objectKey} from S3`);
  }
};

export const deleteRecordingFromS3 = deleteS3Object;
