-- Migration: 019_restore_entry_fee_and_match_integrity.sql
-- Description: Ensure entry_fee column and constraints exist on public.games with strict integrity checks.
-- Date: 2026-10-22

DO $$
BEGIN
    -- 1. Ensure entry_fee column exists on public.games
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'games'
          AND column_name = 'entry_fee'
    ) THEN
        ALTER TABLE public.games
        ADD COLUMN entry_fee NUMERIC(10,2) DEFAULT 200.00 NOT NULL;
    END IF;

    -- 2. Ensure non-negative check constraint exists
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'games_entry_fee_check'
    ) THEN
        ALTER TABLE public.games
        ADD CONSTRAINT games_entry_fee_check CHECK (entry_fee >= 0);
    END IF;
END $$;

-- 3. Optimized composite index for court booking, date and entry fee queries
CREATE INDEX IF NOT EXISTS idx_games_court_date_fee ON public.games(court_id, match_date, entry_fee);
CREATE INDEX IF NOT EXISTS idx_games_entry_fee ON public.games(entry_fee);
