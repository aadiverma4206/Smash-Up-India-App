import crypto from 'crypto';
import { env } from '../config/env.config.js';

const ALGORITHM = 'aes-256-gcm';

/**
 * Derives a valid 32-byte (256-bit) buffer key from environment configuration
 */
const getKeyBuffer = (): Buffer => {
  const rawKey =
    env.CAMERA_CREDENTIAL_ENCRYPTION_KEY ||
    env.CCTV_CREDENTIAL_ENCRYPTION_KEY ||
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  if (/^[0-9a-fA-F]{64}$/.test(rawKey)) {
    return Buffer.from(rawKey, 'hex');
  }

  // Fallback to SHA-256 digest to securely normalize any passphrase to 32 bytes
  return crypto.createHash('sha256').update(rawKey, 'utf8').digest();
};

/**
 * Encrypt sensitive string (such as RTSP password or camera stream URL)
 * Uses AES-256-GCM with a unique 16-byte cryptographically random IV and authentication tag
 */
export const encryptSecret = (text: string): string => {
  if (!text) return '';
  const key = getKeyBuffer();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');

  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
};

/**
 * Decrypt encrypted secret string with authenticated integrity check
 */
export const decryptSecret = (encryptedText: string): string => {
  if (!encryptedText) return '';
  const key = getKeyBuffer();
  const parts = encryptedText.split(':');
  if (parts.length !== 3) {
    throw new Error('Invalid encrypted format. Expected iv:authTag:ciphertext');
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

/**
 * Redacts credentials (username, password) from RTSP/HTTP URLs for safe structured logging
 */
export const redactRtspUrl = (rawUrl: string): string => {
  if (!rawUrl) return '';
  try {
    // Regex matches protocol://username:password@host...
    return rawUrl.replace(
      /^([a-zA-Z0-9+.-]+:\/\/)([^:]+):([^@]+)@(.*)$/,
      '$1***:***@$4'
    );
  } catch (_) {
    return '[REDACTED_URL]';
  }
};
