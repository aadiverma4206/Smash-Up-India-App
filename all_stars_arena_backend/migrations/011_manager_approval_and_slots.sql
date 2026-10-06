-- 011_manager_approval_and_slots.sql
-- Safe, Idempotent Database Patch for Match Approvals, Rejections, Court Slots & Manager Management

-- 1. Add approval_status and rejection_reason to games table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'approval_status'
    ) THEN
        ALTER TABLE public.games ADD COLUMN approval_status VARCHAR(32) DEFAULT 'APPROVED';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'rejection_reason'
    ) THEN
        ALTER TABLE public.games ADD COLUMN rejection_reason TEXT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'manager_id'
    ) THEN
        ALTER TABLE public.games ADD COLUMN manager_id VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 2. Add constraint for valid approval statuses
ALTER TABLE public.games DROP CONSTRAINT IF EXISTS games_approval_status_check;
ALTER TABLE public.games ADD CONSTRAINT games_approval_status_check 
    CHECK (approval_status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED'));

-- 3. Ensure player_match_results table exists (from 004 migration)
CREATE TABLE IF NOT EXISTS public.player_match_results (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('pmr_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    team public.team_side NOT NULL,
    goals_scored INT DEFAULT 0 NOT NULL,
    assists INT DEFAULT 0 NOT NULL,
    rating NUMERIC(3,1) DEFAULT 7.0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_player_match_result UNIQUE (game_id, user_id)
);

-- 4. Safe Performance Indexes
CREATE INDEX IF NOT EXISTS idx_games_approval_status ON public.games(approval_status);
CREATE INDEX IF NOT EXISTS idx_games_court_date_times ON public.games(court_id, match_date, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_games_club_date_status ON public.games(club_id, match_date, status);
CREATE INDEX IF NOT EXISTS idx_player_match_results_game ON public.player_match_results(game_id);
CREATE INDEX IF NOT EXISTS idx_player_match_results_user ON public.player_match_results(user_id);
