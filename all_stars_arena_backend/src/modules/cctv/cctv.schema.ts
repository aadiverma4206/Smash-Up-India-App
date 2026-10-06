import { z } from 'zod';

export const createCctvCameraSchema = z.object({
  body: z.object({
    clubId: z.string().min(1, 'Club ID is required'),
    courtId: z.string().optional(),
    name: z.string().min(2, 'Camera name is required'),
    rtspUrl: z.string().url('Invalid RTSP / HTTP camera stream URL'),
    ipAddress: z.string().optional(),
    port: z.number().int().optional().default(554),
  }),
});

export const updateCctvCameraSchema = z.object({
  params: z.object({
    cameraId: z.string().min(1, 'Camera ID is required'),
  }),
  body: z.object({
    name: z.string().optional(),
    courtId: z.string().optional(),
    rtspUrl: z.string().url().optional(),
    ipAddress: z.string().optional(),
    port: z.number().int().optional(),
    isEnabled: z.boolean().optional(),
  }),
});

export const testCameraSchema = z.object({
  params: z.object({
    cameraId: z.string().min(1, 'Camera ID is required'),
  }),
});

export const getClubCamerasSchema = z.object({
  params: z.object({
    clubId: z.string().min(1, 'Club ID is required'),
  }),
});

export const startRecordingSchema = z.object({
  body: z.object({
    gameId: z.string().min(1, 'Game ID is required'),
    cameraId: z.string().min(1, 'Camera ID is required'),
  }),
});

export const stopRecordingSchema = z.object({
  params: z.object({
    recordingId: z.string().min(1, 'Recording ID is required'),
  }),
});

export const extendRecordingSchema = z.object({
  params: z.object({
    recordingId: z.string().min(1, 'Recording ID is required'),
  }),
  body: z.object({
    additionalMinutes: z
      .number()
      .int()
      .min(5, 'Minimum extension is 5 minutes')
      .max(60, 'Maximum extension is 60 minutes'),
  }),
});

export const getPlaybackUrlSchema = z.object({
  params: z.object({
    gameId: z.string().min(1, 'Game ID is required'),
  }),
});
