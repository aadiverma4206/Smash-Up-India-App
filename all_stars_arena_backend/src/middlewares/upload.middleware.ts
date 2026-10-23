import multer from "multer";

const storage = multer.memoryStorage();

export const uploadAvatarMiddleware = multer({
  storage,
  limits: {
    fileSize: 20 * 1024 * 1024,
  },
  fileFilter: (_req, file, cb) => {
    if (!file) return cb(null, false);
    cb(null, true);
  },
}).any();
