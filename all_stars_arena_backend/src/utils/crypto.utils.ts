import crypto from 'crypto';
import { env } from '../config/env.config.js';

const ALGORITHM = 'aes-256-gcm';

/**
 * Encrypt sensitive string (such as RTSP password or camera stream URL)
 */
export const encryptSecret = (text: string): string => {
  const key = Buffer.from(env.CCTV_CREDENTIAL_ENCRYPTION_KEY, 'hex');
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');

  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
};

/**
 * Decrypt encrypted secret string
 */
export const decryptSecret = (encryptedText: string): string => {
  const key = Buffer.from(env.CCTV_CREDENTIAL_ENCRYPTION_KEY, 'hex');
  const parts = encryptedText.split(':');
  if (parts.length !== 3) {
    throw new Error('Invalid encrypted format');
  }

  const iv = Buffer.from(parts[0], 'hex');
  const authTag = Buffer.from(parts[1], 'hex');
  const encrypted = parts[2];

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
};
