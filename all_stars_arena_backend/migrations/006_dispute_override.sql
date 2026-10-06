-- 006_dispute_override.sql
-- Function to resolve match score disputes by Admin/OPS
CREATE OR REPLACE FUNCTION public.resolve_match_dispute(
    p_dispute_id VARCHAR(64),
    p_admin_id VARCHAR(64),
    p_winner_override VARCHAR(16),
    p_score_override VARCHAR(32),
    p_adjudicator_notes TEXT
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_dispute public.match_disputes%ROWTYPE;
BEGIN
    SELECT * INTO v_dispute FROM public.match_disputes WHERE id = p_dispute_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Dispute not found';
    END IF;

    UPDATE public.match_disputes
    SET status = 'RESOLVED',
        winner_override = p_winner_override,
        score_override = p_score_override,
        adjudicator_notes = p_adjudicator_notes,
        resolved_at = CURRENT_TIMESTAMP
    WHERE id = p_dispute_id;

    RETURN TRUE;
END;
$$;
