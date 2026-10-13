import { z } from 'zod';

export const createCctvCameraSchema = z.object({
  body: z.object({
    clubId: z.string().min(1, 'Club ID is required'),
    courtId: z.string().optional(),
    name: z.string().min(2, 'Camera name is required'),
    rtspUrl: z.string().min(5, 'Camera stream URL is required'),
    ipAddress: z.string().optional(),
    port: z.number().int().optional().default(554),
    serialNumber: z.string().optional(),
    protocol: z.string().optional().default('rtsp'),
  }),
});

export const updateCctvCameraSchema = z.object({
  params: z.object({
    cameraId: z.string().min(1, 'Camera ID is required'),
  }),
  body: z.object({
    name: z.string().optional(),
    courtId: z.string().optional(),
    rtspUrl: z.string().min(5).optional(),
    ipAddress: z.string().optional(),
    port: z.number().int().optional(),
    serialNumber: z.string().optional(),
    protocol: z.string().optional(),
    isEnabled: z.boolean().optional(),
  }),
});

export const toggleCameraSchema = z.object({
  params: z.object({
    cameraId: z.string().min(1, 'Camera ID is required'),
  }),
  body: z.object({
    isEnabled: z.boolean(),
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
    cameraId: z.string().optional(),
  }),
});

export const stopRecordingSchema = z.object({
  params: z.object({
    recordingId: z.string().min(1, 'Recording ID is required'),
  }),
  body: z
    .object({
      reason: z.string().optional(),
    })
    .optional(),
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

export const createLiveStreamSessionSchema = z.object({
  body: z.object({
    channel: z.coerce.number().int().min(1).max(4, 'Channel must be between 1 and 4'),
    streamType: z.enum(['main', 'sub']).optional().default('main'),
  }),
});

export const getLiveCameraStatusSchema = z.object({
  params: z.object({
    channel: z.coerce.number().int().min(1).max(4, 'Channel must be between 1 and 4'),
  }),
});
