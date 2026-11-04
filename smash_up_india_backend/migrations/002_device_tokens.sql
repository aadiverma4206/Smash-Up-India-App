-- 002_device_tokens.sql
-- Table for user FCM / push notification device tokens
CREATE TABLE IF NOT EXISTS public.user_device_tokens (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('dev_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    device_type VARCHAR(32) DEFAULT 'ANDROID' NOT NULL, -- ANDROID, IOS, WEB
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_device_token UNIQUE (user_id, device_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.user_device_tokens(user_id);
