import admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { env } from './env.config.js';
import { logger } from '../utils/logger.js';

let firebaseApp: admin.app.App | null = null;

export const initFirebaseAdmin = (): admin.app.App | null => {
  if (firebaseApp) return firebaseApp;

  try {
    if (admin.apps.length > 0) {
      firebaseApp = admin.apps[0]!;
      return firebaseApp;
    }

    // 1. Resolve GOOGLE_APPLICATION_CREDENTIALS file path reliably
    const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || env.GOOGLE_APPLICATION_CREDENTIALS;
    if (credPath) {
      const currentDir = typeof __dirname !== 'undefined' ? __dirname : process.cwd();
      const candidates = [
        path.isAbsolute(credPath) ? credPath : path.resolve(process.cwd(), credPath),
        path.isAbsolute(credPath) ? credPath : path.resolve(process.cwd(), 'all_stars_arena_backend', credPath),
        path.isAbsolute(credPath) ? credPath : path.resolve(currentDir, '..', '..', credPath),
      ];

      const resolvedPath = candidates.find((p) => fs.existsSync(p));

      if (resolvedPath && fs.existsSync(resolvedPath)) {
        try {
          const fileContent = fs.readFileSync(resolvedPath, 'utf8');
          const serviceAccount = JSON.parse(fileContent);

          if (serviceAccount && serviceAccount.type === 'service_account' && serviceAccount.private_key) {
            firebaseApp = admin.initializeApp({
              credential: admin.credential.cert(serviceAccount),
              projectId: serviceAccount.project_id || env.FIREBASE_PROJECT_ID,
            });
            logger.info(`🔥 [Firebase Admin SDK] Initialized with service account file (${path.basename(resolvedPath)})`);
            return firebaseApp;
          }
        } catch (fileErr: any) {
          logger.warn(`Failed to parse service account JSON file at ${path.basename(resolvedPath)}: ${fileErr.message}`);
        }
      }
    }

    // 2. Try loading service account from inline FIREBASE_SERVICE_ACCOUNT_JSON env string
    if (env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      try {
        const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
        if (serviceAccount && serviceAccount.private_key) {
          firebaseApp = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id || env.FIREBASE_PROJECT_ID,
          });
          logger.info('🔥 [Firebase Admin SDK] Initialized with inline Service Account JSON');
          return firebaseApp;
        }
      } catch (parseErr: any) {
        logger.warn(`Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: ${parseErr.message}`);
      }
    }

    // 3. Fallback to Application Default Credentials
    try {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: env.FIREBASE_PROJECT_ID,
      });
      logger.info('🔥 [Firebase Admin SDK] Initialized with Application Default Credentials');
      return firebaseApp;
    } catch (adcErr: any) {
      logger.warn(`⚠️ [Firebase Admin SDK] Application Default Credentials failed: ${adcErr.message}`);
    }

    logger.warn('⚠️ [Firebase Admin SDK] No valid Firebase credentials found.');
    return null;
  } catch (err: any) {
    logger.warn(`⚠️ [Firebase Admin SDK] Initialization failed: ${err.message}`);
    return null;
  }
};

export const getFirebaseMessaging = (): admin.messaging.Messaging | null => {
  const app = initFirebaseAdmin();
  if (!app) return null;
  try {
    return admin.messaging(app);
  } catch (err: any) {
    logger.warn(`Could not get Firebase Messaging instance: ${err.message}`);
    return null;
  }
};
