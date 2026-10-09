-- 012_notifications_table_upgrade.sql
-- Ensure public.notifications table has full support for Flutter PlayerNotification / NotificationModel

CREATE TABLE IF NOT EXISTS public.notifications (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('notif_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    message TEXT NOT NULL DEFAULT '',
    type VARCHAR(64) NOT NULL DEFAULT 'SYSTEM',
    data JSONB DEFAULT '{}'::jsonb,
    link_url VARCHAR(512),
    club_id VARCHAR(64) REFERENCES public.clubs(id) ON DELETE SET NULL,
    game_id VARCHAR(64) REFERENCES public.games(id) ON DELETE SET NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS body TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS type VARCHAR(64) DEFAULT 'SYSTEM';
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS link_url VARCHAR(512);
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS club_id VARCHAR(64);
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS game_id VARCHAR(64);
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

UPDATE public.notifications SET body = message WHERE (body IS NULL OR body = '') AND message IS NOT NULL;
UPDATE public.notifications SET message = body WHERE (message IS NULL OR message = '') AND body IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
