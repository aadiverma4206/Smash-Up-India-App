import crypto from "crypto";
import { env } from "../config/env.config.js";

const ALGORITHM = "aes-256-gcm";

const getKeyBuffer = (): Buffer => {
  const rawKey =
    env.CAMERA_CREDENTIAL_ENCRYPTION_KEY ||
    env.CCTV_CREDENTIAL_ENCRYPTION_KEY ||
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

  if (/^[0-9a-fA-F]{64}$/.test(rawKey)) {
    return Buffer.from(rawKey, "hex");
  }

  return crypto.createHash("sha256").update(rawKey, "utf8").digest();
};

export const encryptSecret = (text: string): string => {
  if (!text) return "";
  const key = getKeyBuffer();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(text, "utf8", "hex");
  encrypted += cipher.final("hex");
  const authTag = cipher.getAuthTag().toString("hex");

  return `${iv.toString("hex")}:${authTag}:${encrypted}`;
};

export const decryptSecret = (encryptedText: string): string => {
  if (!encryptedText) return "";
  const key = getKeyBuffer();
  const parts = encryptedText.split(":");
  if (parts.length !== 3) {
    throw new Error("Invalid encrypted format. Expected iv:authTag:ciphertext");
  }

  const iv = Buffer.from(parts[0], "hex");
  const authTag = Buffer.from(parts[1], "hex");
  const encrypted = parts[2];

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(encrypted, "hex", "utf8");
  decrypted += decipher.final("utf8");

  return decrypted;
};

export const redactRtspUrl = (rawUrl: string): string => {
  if (!rawUrl) return "";
  try {
    const schemeIndex = rawUrl.indexOf("://");
    const atIndex = rawUrl.lastIndexOf("@");
    if (schemeIndex !== -1 && atIndex !== -1 && atIndex > schemeIndex) {
      const scheme = rawUrl.slice(0, schemeIndex + 3);
      const hostAndPath = rawUrl.slice(atIndex + 1);
      return `${scheme}***:***@${hostAndPath}`;
    }
    return rawUrl.replace(
      /^([a-zA-Z0-9+.-]+:\/\/)([^:]+):(.*)@([^@]+)$/,
      "$1***:***@$4",
    );
  } catch (_) {
    return "[REDACTED_URL]";
  }
};
