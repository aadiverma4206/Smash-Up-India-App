-- 005_switch_team.sql
-- Function for switching player team side before match start
CREATE OR REPLACE FUNCTION public.switch_player_team(
    p_user_id VARCHAR(64),
    p_game_id VARCHAR(64)
) RETURNS VARCHAR(16) LANGUAGE plpgsql AS $$
DECLARE
    v_current_team public.team_side;
    v_new_team public.team_side;
    v_game_status public.match_status;
    v_team_capacity INT;
    v_new_team_count INT;
    v_max_players INT;
BEGIN
    SELECT status, max_players INTO v_game_status, v_max_players
    FROM public.games WHERE id = p_game_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Game not found';
    END IF;

    IF v_game_status NOT IN ('OPEN_FOR_JOINING', 'FULL') THEN
        RAISE EXCEPTION 'Cannot switch team when game status is %', v_game_status;
    END IF;

    SELECT team INTO v_current_team
    FROM public.game_players
    WHERE game_id = p_game_id AND user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Player has not joined this game';
    END IF;

    v_new_team := CASE WHEN v_current_team = 'TEAM_A' THEN 'TEAM_B'::public.team_side ELSE 'TEAM_A'::public.team_side END;
    v_team_capacity := v_max_players / 2;

    SELECT COUNT(*) INTO v_new_team_count
    FROM public.game_players
    WHERE game_id = p_game_id AND team = v_new_team;

    IF v_new_team_count >= v_team_capacity THEN
        RAISE EXCEPTION 'Target team % is already full (max % players)', v_new_team, v_team_capacity;
    END IF;

    UPDATE public.game_players
    SET team = v_new_team
    WHERE game_id = p_game_id AND user_id = p_user_id;

    RETURN v_new_team::VARCHAR;
END;
$$;
