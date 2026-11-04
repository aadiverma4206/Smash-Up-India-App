-- 003_club_rejection_reason.sql
-- Add rejection reason column to clubs table if not present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='clubs' AND column_name='rejection_reason'
    ) THEN
        ALTER TABLE public.clubs ADD COLUMN rejection_reason TEXT;
    END IF;
END $$;
