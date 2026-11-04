-- 004_player_match_results.sql
-- Table for tracking individual player match performance & ratings
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

CREATE INDEX IF NOT EXISTS idx_player_match_results_game ON public.player_match_results(game_id);
CREATE INDEX IF NOT EXISTS idx_player_match_results_user ON public.player_match_results(user_id);
