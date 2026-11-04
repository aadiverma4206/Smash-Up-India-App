-- Migration 023: Ensure club_id exists on public.games with foreign key and index
-- Description: Supports club-scoped match queries, manager dashboard metrics, and match normalization.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'games' 
          AND column_name = 'club_id'
    ) THEN
        ALTER TABLE public.games 
        ADD COLUMN club_id VARCHAR(64) REFERENCES public.clubs(id) DEFAULT 'smash_up_india_club';
    END IF;

    UPDATE public.games 
    SET club_id = 'smash_up_india_club' 
    WHERE club_id IS NULL;

    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE schemaname = 'public' 
          AND tablename = 'games' 
          AND indexname = 'idx_games_club_date_status'
    ) THEN
        CREATE INDEX idx_games_club_date_status ON public.games(club_id, match_date, status);
    END IF;
END $$;
