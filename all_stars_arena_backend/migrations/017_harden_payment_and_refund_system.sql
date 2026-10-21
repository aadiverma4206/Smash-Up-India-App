-- Migration: 017_harden_payment_and_refund_system.sql
-- Harden payment orders purpose constraint, track payment method & audit refunds on game_players

-- 1. Expand purpose check on payment_orders to include match payments
ALTER TABLE public.payment_orders DROP CONSTRAINT IF EXISTS payment_orders_purpose_check;
ALTER TABLE public.payment_orders ADD CONSTRAINT payment_orders_purpose_check 
  CHECK (purpose IN ('WALLET_TOPUP', 'MATCH_JOIN', 'MATCH_CREATION'));

-- 2. Add audit and refund tracking columns to game_players
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS payment_method VARCHAR(32) DEFAULT 'WALLET';
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS payment_reference VARCHAR(128);
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS refund_status VARCHAR(32) DEFAULT 'NOT_REFUNDED';
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS refund_reference VARCHAR(128);
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS refund_amount NUMERIC(10,2) DEFAULT 0.00;
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMP WITH TIME ZONE;

-- 3. Partial unique index to prevent reuse of payment references across active player registrations
CREATE UNIQUE INDEX IF NOT EXISTS uq_game_players_paid_ref 
  ON public.game_players(payment_reference) 
  WHERE payment_reference IS NOT NULL AND payment_reference <> '' AND payment_status = 'PAID';

-- 4. Update join_game_with_wallet stored procedure to record payment_method and payment_reference
DROP FUNCTION IF EXISTS public.join_game_with_wallet(VARCHAR, VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public.join_game_with_wallet(
    p_user_id VARCHAR(64),
    p_game_id VARCHAR(64),
    p_position VARCHAR(16)
) RETURNS VARCHAR(64) LANGUAGE plpgsql AS $$
DECLARE
    v_entry_fee NUMERIC(10,2);
    v_max_players INT;
    v_current_count INT;
    v_game_status VARCHAR(32);
    v_wallet_balance NUMERIC(10,2);
    v_team_a_count INT;
    v_team_b_count INT;
    v_assigned_team public.team_side;
    v_roster_id VARCHAR(64);
    v_tx_id VARCHAR(64);
    v_new_balance NUMERIC(10,2);
BEGIN
    SELECT entry_fee, max_players, status INTO v_entry_fee, v_max_players, v_game_status
    FROM public.games WHERE id = p_game_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Match not found';
    END IF;

    IF v_game_status IN ('CANCELLED', 'COMPLETED') THEN
        RAISE EXCEPTION 'Cannot join a match that is %', v_game_status;
    END IF;

    IF EXISTS (SELECT 1 FROM public.game_players WHERE game_id = p_game_id AND user_id = p_user_id) THEN
        RAISE EXCEPTION 'You have already joined this match roster';
    END IF;

    SELECT COUNT(*) INTO v_current_count FROM public.game_players WHERE game_id = p_game_id;
    IF v_current_count >= v_max_players THEN
        RAISE EXCEPTION 'Match is already at full capacity';
    END IF;

    IF v_entry_fee > 0 THEN
        SELECT wallet_balance INTO v_wallet_balance
        FROM public.player_details WHERE user_id = p_user_id FOR UPDATE;

        IF v_wallet_balance IS NULL OR v_wallet_balance < v_entry_fee THEN
            RAISE EXCEPTION 'INSUFFICIENT_WALLET_BALANCE';
        END IF;

        INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
        VALUES (p_user_id, 'PAYMENT', v_entry_fee, 0, 'SUCCESS', 'Entry fee for joining match', p_game_id)
        RETURNING id, balance_after INTO v_tx_id, v_new_balance;

        INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
        VALUES (v_tx_id, p_user_id, 'DEBIT', v_entry_fee, v_new_balance, 'Entry fee for joining match', 'SUCCESS', p_game_id)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    SELECT COUNT(*) INTO v_team_a_count FROM public.game_players WHERE game_id = p_game_id AND team = 'TEAM_A';
    SELECT COUNT(*) INTO v_team_b_count FROM public.game_players WHERE game_id = p_game_id AND team = 'TEAM_B';

    IF v_team_a_count <= v_team_b_count THEN
        v_assigned_team := 'TEAM_A'::public.team_side;
    ELSE
        v_assigned_team := 'TEAM_B'::public.team_side;
    END IF;

    INSERT INTO public.game_players (game_id, user_id, team, position, payment_status, payment_method, payment_reference)
    VALUES (p_game_id, p_user_id, v_assigned_team, UPPER(p_position)::public.football_position, 'PAID', 'WALLET', v_tx_id)
    RETURNING id INTO v_roster_id;

    IF v_current_count + 1 >= v_max_players THEN
        UPDATE public.games SET status = 'FULL', updated_at = CURRENT_TIMESTAMP WHERE id = p_game_id;
    END IF;

    RETURN v_roster_id;
END;
$$;

-- 5. Fix settle_wallet_payment to prevent duplicate credit (rely on authoritative trg_apply_transaction trigger)
CREATE OR REPLACE FUNCTION public.settle_wallet_payment(
    p_payment_order_id VARCHAR(64),
    p_provider_payment_id VARCHAR(128)
) RETURNS VARCHAR(64) LANGUAGE plpgsql AS $$
DECLARE
    v_user_id VARCHAR(64);
    v_amount_paise BIGINT;
    v_amount_rupees NUMERIC(10,2);
    v_order_status VARCHAR(32);
    v_purpose VARCHAR(32);
    v_tx_id VARCHAR(64);
    v_new_balance NUMERIC(10,2);
BEGIN
    -- 1. Fetch payment order with row lock
    SELECT user_id, amount_paise, status, purpose INTO v_user_id, v_amount_paise, v_order_status, v_purpose
    FROM public.payment_orders
    WHERE id = p_payment_order_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment order % not found', p_payment_order_id;
    END IF;

    -- Enforce that ONLY WALLET_TOPUP orders can ever be settled as a wallet credit
    IF v_purpose <> 'WALLET_TOPUP' THEN
        RAISE EXCEPTION 'Payment order % is not a WALLET_TOPUP order (purpose: %)', p_payment_order_id, v_purpose;
    END IF;

    -- 2. Idempotency: If already settled as PAID, return existing transaction ID
    IF v_order_status = 'PAID' THEN
        SELECT id INTO v_tx_id FROM public.transactions
        WHERE reference_id = p_payment_order_id LIMIT 1;
        IF v_tx_id IS NOT NULL THEN
            RETURN v_tx_id;
        END IF;

        SELECT id INTO v_tx_id FROM public.wallet_transactions
        WHERE reference_id = p_payment_order_id LIMIT 1;
        IF v_tx_id IS NOT NULL THEN
            RETURN v_tx_id;
        END IF;

        RETURN 'ALREADY_SETTLED';
    END IF;

    v_amount_rupees := (v_amount_paise::NUMERIC / 100.0);

    -- 3. Record in authoritative transactions ledger
    -- trg_apply_transaction automatically locks player_details FOR UPDATE and credits wallet_balance exactly once
    INSERT INTO public.transactions (
        user_id,
        type,
        amount,
        balance_after,
        status,
        description,
        reference_id
    ) VALUES (
        v_user_id,
        'WALLET_TOPUP',
        v_amount_rupees,
        0,
        'SUCCESS',
        'Wallet Top-Up via Razorpay',
        p_payment_order_id
    ) RETURNING id, balance_after INTO v_tx_id, v_new_balance;

    -- 4. Keep wallet_transactions in sync
    INSERT INTO public.wallet_transactions (
        id,
        user_id,
        transaction_type,
        amount,
        balance_after,
        description,
        status,
        reference_id,
        provider_payment_id
    ) VALUES (
        v_tx_id,
        v_user_id,
        'TOPUP',
        v_amount_rupees,
        v_new_balance,
        'Wallet Top-Up via Razorpay',
        'SUCCESS',
        p_payment_order_id,
        p_provider_payment_id
    ) ON CONFLICT (id) DO UPDATE SET balance_after = EXCLUDED.balance_after;

    -- 5. Mark payment_order as PAID
    UPDATE public.payment_orders
    SET status = 'PAID',
        paid_at = CURRENT_TIMESTAMP,
        provider_payment_id = p_provider_payment_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_payment_order_id;

    RETURN v_tx_id;
END;
$$;


