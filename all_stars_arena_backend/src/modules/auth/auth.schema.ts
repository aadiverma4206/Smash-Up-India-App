import { z } from 'zod';

const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$/;

export const registerSendOtpSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email address'),
    phone: z.string().regex(/^\+?[0-9]{10,15}$/, 'Invalid phone number (E.164 format expected)'),
    city: z.string().optional().default('Raipur'),
  }),
});

export const registerVerifyOtpSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    phone: z.string().regex(/^\+?[0-9]{10,15}$/, 'Invalid phone number'),
    emailOtp: z.string().length(6, 'Email OTP must be 6 digits'),
  }),
});

export const registerPlayerSchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Invalid email address'),
    phone: z.string().regex(/^\+?[0-9]{10,15}$/, 'Invalid phone number'),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(
        passwordRegex,
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
      ),
    city: z.string().optional().default('Raipur'),
    verificationToken: z.string().min(1, 'Verification token is required'),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    identifier: z.string().min(1, 'Email or Phone is required'),
    password: z.string().min(1, 'Password is required'),
    device: z
      .object({
        deviceInfo: z.string().optional(),
        ipAddress: z.string().optional(),
      })
      .nullish()
      .transform((val) => val ?? {}),
  }),
});

export const forgotSendOtpSchema = z.object({
  body: z.object({
    identifier: z.string().min(1, 'Email or Phone is required'),
  }),
});

export const forgotVerifyOtpSchema = z.object({
  body: z.object({
    identifier: z.string().min(1, 'Email or Phone is required'),
    otp: z.string().length(6, 'OTP must be 6 digits'),
  }),
});

export const resetPasswordSchema = z.object({
  body: z.object({
    resetToken: z.string().min(1, 'Reset token is required'),
    newPassword: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(
        passwordRegex,
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
      ),
  }),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }),
});

export const fcmTokenSchema = z.object({
  body: z.object({
    token: z.string().min(1, 'Device push token is required'),
    platform: z.enum(['ANDROID', 'IOS', 'WEB']).default('ANDROID'),
    deviceInfo: z.string().optional(),
  }),
});

export const deleteFcmTokenSchema = z.object({
  body: z.object({
    token: z.string().min(1, 'Device push token is required'),
  }),
});

export const revokeSessionSchema = z.object({
  params: z.object({
    id: z.string().min(1, 'Session ID is required'),
  }),
});

export const resendOtpSchema = z.object({
  body: z
    .object({
      email: z.string().email('Invalid email address').optional(),
      identifier: z.string().optional(),
    })
    .refine((data) => Boolean(data.email || data.identifier), {
      message: 'Either email or identifier is required',
    }),
});
