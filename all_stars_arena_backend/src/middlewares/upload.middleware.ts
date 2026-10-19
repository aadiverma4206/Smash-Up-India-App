import multer from "multer";
import { ApiError } from "../utils/apiResponse.js";

// Configure multer memory storage
const storage = multer.memoryStorage();

// File filter for images (JPEG, PNG, WebP)
const imageFileFilter = (
  req: any,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback,
) => {
  const allowedMimeTypes = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
  ];
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(
      new ApiError(
        400,
        "Invalid file format. Only JPEG, PNG, and WebP images are allowed.",
      ) as any,
      false,
    );
  }
};

// 5 MB file size limit
export const uploadAvatarMiddleware = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5 MB max
  },
  fileFilter: imageFileFilter,
}).single("profileImage");
