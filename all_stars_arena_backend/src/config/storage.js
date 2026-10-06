import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { env } from './env.js';
import { logger } from './logger.js';

export const s3Client = new S3Client({
  region: env.AWS_S3_REGION,
  endpoint: env.AWS_S3_ENDPOINT || undefined,
  forcePathStyle: Boolean(env.AWS_S3_ENDPOINT),
  credentials:
    env.AWS_S3_ACCESS_KEY_ID && env.AWS_S3_SECRET_ACCESS_KEY
      ? {
          accessKeyId: env.AWS_S3_ACCESS_KEY_ID,
          secretAccessKey: env.AWS_S3_SECRET_ACCESS_KEY,
        }
      : undefined,
});

export const getSignedPlaybackUrl = async (objectKey, expiresInSeconds = 3600) => {
  try {
    const command = new GetObjectCommand({
      Bucket: env.AWS_S3_BUCKET_NAME,
      Key: objectKey,
    });
    return await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
  } catch (err) {
    logger.error({ err }, `Error generating signed playback URL for key ${objectKey}`);
    throw new Error('Could not generate playback URL');
  }
};
