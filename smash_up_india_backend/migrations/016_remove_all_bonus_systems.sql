-- Migration: 016_remove_all_bonus_systems.sql
-- Disable and remove all bonus amounts across the entire application (Welcome Bonus, Challenge Bonus, etc.)

-- 1. Drop the welcome bonus trigger on player_details
DROP TRIGGER IF EXISTS trg_grant_welcome_bonus ON public.player_details;

-- 2. Make grant_welcome_bonus a no-op function so it never creates bonus transactions
CREATE OR REPLACE FUNCTION public.grant_welcome_bonus()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Disabled permanently: No bonus amount to be given to players
    RETURN NEW;
END;
$$;

-- 3. Update reward_completed_challenge to award badges only, never credit wallet bonus
CREATE OR REPLACE FUNCTION public.reward_completed_challenge()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_target INT;
    v_badge VARCHAR(64);
BEGIN
    SELECT target_count, reward_badge
    INTO v_target, v_badge
    FROM public.challenges WHERE id = NEW.challenge_id;

    IF NEW.current_progress >= v_target AND NOT COALESCE(OLD.is_completed, FALSE) THEN
        NEW.is_completed := TRUE;
        NEW.completed_at := CURRENT_TIMESTAMP;

        -- No wallet bonus is awarded. Only badges.
        UPDATE public.player_details
        SET badges = badges || to_jsonb(v_badge)
        WHERE user_id = NEW.user_id AND NOT (badges @> to_jsonb(v_badge));
    END IF;

    RETURN NEW;
END;
$$;

-- 4. Set challenge default reward_wallet_bonus to 0 and zero out existing challenges
ALTER TABLE public.challenges ALTER COLUMN reward_wallet_bonus SET DEFAULT 0.00;
UPDATE public.challenges SET reward_wallet_bonus = 0.00;

-- 5. Harden apply_transaction_to_wallet to strictly disallow any bonus credits
CREATE OR REPLACE FUNCTION public.apply_transaction_to_wallet()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
    v_role_id         SMALLINT;
    v_current_balance NUMERIC(12,2);
    v_new_balance     NUMERIC(12,2);
    v_is_credit       BOOLEAN;
BEGIN
    SELECT u.role_id
    INTO v_role_id
    FROM public.users u
    WHERE u.id = NEW.user_id
    FOR UPDATE;

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'User does not exist';
    END IF;

    IF v_role_id <> 3 THEN
        RAISE EXCEPTION 'Only PLAYER accounts have a wallet';
    END IF;

    SELECT pd.wallet_balance
    INTO v_current_balance
    FROM public.player_details pd
    WHERE pd.user_id = NEW.user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Player wallet does not exist';
    END IF;

    IF NEW.status <> 'SUCCESS' THEN
        NEW.balance_after := v_current_balance;
        RETURN NEW;
    END IF;

    -- Block any bonus credit attempts
    IF NEW.type IN ('WELCOME_BONUS', 'CHALLENGE_REWARD') THEN
        RAISE EXCEPTION 'Bonus amounts are disabled across the platform';
    END IF;

    -- Only genuine user wallet topups and system refunds credit the wallet
    v_is_credit := NEW.type IN ('WALLET_TOPUP', 'REFUND');

    IF v_is_credit THEN
        v_new_balance := v_current_balance + NEW.amount;
        IF v_new_balance > 200000.00 THEN
            RAISE EXCEPTION 'Wallet balance cannot exceed Rs. 2,00,000';
        END IF;
    ELSE
        v_new_balance := v_current_balance - NEW.amount;
        IF v_new_balance < 0 THEN
            RAISE EXCEPTION 'Insufficient wallet balance';
        END IF;
    END IF;

    UPDATE public.player_details
    SET
        wallet_balance = v_new_balance,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id;

    NEW.balance_after := v_new_balance;

    RETURN NEW;
END;
$$;

-- 6. Remove the automatically credited welcome bonus from existing player wallets
UPDATE public.player_details
SET wallet_balance = GREATEST(0, wallet_balance - 1000.00),
    updated_at = CURRENT_TIMESTAMP
WHERE user_id IN (
    SELECT DISTINCT user_id FROM public.transactions WHERE type = 'WELCOME_BONUS'
);
