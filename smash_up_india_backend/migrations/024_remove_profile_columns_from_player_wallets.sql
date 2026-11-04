-- Migration 024: Remove player profile columns from player_wallets table
-- Removes: position, preferred_foot, skill_level, elo_rating, ovr_rating, badges, secondary_position

-- 1. Drop index on elo_rating if exists
DROP INDEX IF EXISTS public.idx_player_elo;

-- 2. Drop dependent view player_details CASCADE
DROP VIEW IF EXISTS public.player_details CASCADE;

-- 3. Drop check constraints if exist
ALTER TABLE public.player_wallets DROP CONSTRAINT IF EXISTS player_details_elo_rating_check;
ALTER TABLE public.player_wallets DROP CONSTRAINT IF EXISTS player_details_ovr_rating_check;

-- 4. Drop columns from player_wallets
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS "position" CASCADE;
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS preferred_foot CASCADE;
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS skill_level CASCADE;
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS elo_rating CASCADE;
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS ovr_rating CASCADE;
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS badges CASCADE;
ALTER TABLE public.player_wallets DROP COLUMN IF EXISTS secondary_position CASCADE;

-- 5. Recreate player_details view pointing to player_wallets
CREATE OR REPLACE VIEW public.player_details AS
    SELECT * FROM public.player_wallets;

-- 6. Update finalize_match_result() stored trigger function
CREATE OR REPLACE FUNCTION public.finalize_match_result() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
BEGIN
    IF NEW.is_final IS DISTINCT FROM TRUE THEN
        RETURN NEW;
    END IF;

    FOR rec IN
        SELECT gp.user_id, gp.team
        FROM public.game_players gp
        WHERE gp.game_id = NEW.game_id
    LOOP
        UPDATE public.player_stats SET
            matches_played = matches_played + 1,
            wins   = wins   + CASE WHEN (rec.team='TEAM_A' AND NEW.team_a_score>NEW.team_b_score)
                                     OR (rec.team='TEAM_B' AND NEW.team_b_score>NEW.team_a_score) THEN 1 ELSE 0 END,
            draws  = draws  + CASE WHEN NEW.team_a_score = NEW.team_b_score THEN 1 ELSE 0 END,
            losses = losses + CASE WHEN (rec.team='TEAM_A' AND NEW.team_a_score<NEW.team_b_score)
                                     OR (rec.team='TEAM_B' AND NEW.team_b_score<NEW.team_a_score) THEN 1 ELSE 0 END,
            points = points + CASE WHEN (rec.team='TEAM_A' AND NEW.team_a_score>NEW.team_b_score)
                                     OR (rec.team='TEAM_B' AND NEW.team_b_score>NEW.team_a_score) THEN 3
                                   WHEN NEW.team_a_score = NEW.team_b_score THEN 1
                                   ELSE 0 END,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = rec.user_id;
    END LOOP;

    RETURN NEW;
END;
$$;

-- 7. Update reward_completed_challenge() so it doesn't fail on missing badges column
CREATE OR REPLACE FUNCTION public.reward_completed_challenge()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_target INT;
BEGIN
    SELECT target_count
    INTO v_target
    FROM public.challenges WHERE id = NEW.challenge_id;

    IF NEW.current_progress >= v_target AND NOT COALESCE(OLD.is_completed, FALSE) THEN
        NEW.is_completed := TRUE;
        NEW.completed_at := CURRENT_TIMESTAMP;
    END IF;

    RETURN NEW;
END;
$$;
