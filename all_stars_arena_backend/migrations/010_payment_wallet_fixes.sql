-- 010_payment_wallet_fixes.sql
-- Safe, Idempotent Database Patch for Payment Orders, Wallet Settlement, and Wallet PIN

-- 1. Performance and Idempotency Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_reference_id ON public.transactions(reference_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON public.transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_orders_user_status ON public.payment_orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_provider_order ON public.payment_orders(provider_order_id);

-- 2. Stored Function: settle_wallet_payment
-- Uses 'PAID' (consistent with payment_orders_status_check constraint)
-- Credits wallet atomically via authoritative transactions ledger (trigger trg_apply_transaction)
-- Keeps wallet_transactions synchronized for backwards compatibility
CREATE OR REPLACE FUNCTION public.settle_wallet_payment(
    p_payment_order_id VARCHAR(64),
    p_provider_payment_id VARCHAR(128)
) RETURNS VARCHAR(64) LANGUAGE plpgsql AS $$
DECLARE
    v_user_id VARCHAR(64);
    v_amount_paise BIGINT;
    v_amount_rupees NUMERIC(10,2);
    v_order_status VARCHAR(32);
    v_tx_id VARCHAR(64);
    v_new_balance NUMERIC(10,2);
BEGIN
    -- 1. Fetch payment order with row lock
    SELECT user_id, amount_paise, status INTO v_user_id, v_amount_paise, v_order_status
    FROM public.payment_orders
    WHERE id = p_payment_order_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment order % not found', p_payment_order_id;
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
    -- trg_apply_transaction automatically locks player_details FOR UPDATE and credits wallet_balance
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
    ) ON CONFLICT (id) DO NOTHING;

    -- 5. Mark payment_order as PAID (valid status in payment_orders_status_check constraint)
    UPDATE public.payment_orders
    SET status = 'PAID',
        paid_at = CURRENT_TIMESTAMP,
        provider_payment_id = p_provider_payment_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_payment_order_id;

    RETURN v_tx_id;
END;
$$;

-- 3. Stored Function: set_wallet_pin
-- Validates exactly 6 numeric digits, stores bcrypt hash via pgcrypto, resets lock & failed counters
CREATE OR REPLACE FUNCTION public.set_wallet_pin(
    p_user_id VARCHAR(64),
    p_pin VARCHAR(16)
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_pin IS NULL OR p_pin !~ '^[0-9]{6}$' THEN
        RAISE EXCEPTION 'Wallet PIN must be exactly 6 numeric digits';
    END IF;

    UPDATE public.player_details
    SET wallet_pin_hash = crypt(p_pin, gen_salt('bf')),
        wallet_pin_set_at = CURRENT_TIMESTAMP,
        wallet_pin_failed_attempts = 0,
        wallet_pin_locked_until = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.player_details (
            user_id,
            wallet_pin_hash,
            wallet_pin_set_at,
            wallet_pin_failed_attempts,
            wallet_pin_locked_until
        )
        VALUES (
            p_user_id,
            crypt(p_pin, gen_salt('bf')),
            CURRENT_TIMESTAMP,
            0,
            NULL
        );
    END IF;
END;
$$;

-- 4. Stored Function: verify_wallet_pin
-- Enforces row lock, validates hash, tracks failed attempts, locks for 15 minutes after 5 failures, resets on success
CREATE OR REPLACE FUNCTION public.verify_wallet_pin(
    p_user_id VARCHAR(64),
    p_pin VARCHAR(16)
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_hash VARCHAR(255);
    v_failed INT;
    v_locked_until TIMESTAMP WITH TIME ZONE;
BEGIN
    SELECT wallet_pin_hash, wallet_pin_failed_attempts, wallet_pin_locked_until
    INTO v_hash, v_failed, v_locked_until
    FROM public.player_details
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND OR v_hash IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Check if currently locked
    IF v_locked_until IS NOT NULL AND v_locked_until > CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'WALLET_PIN_LOCKED';
    END IF;

    -- Validate format
    IF p_pin IS NULL OR p_pin !~ '^[0-9]{6}$' THEN
        v_failed := COALESCE(v_failed, 0) + 1;
        IF v_failed >= 5 THEN
            UPDATE public.player_details
            SET wallet_pin_failed_attempts = v_failed,
                wallet_pin_locked_until = CURRENT_TIMESTAMP + INTERVAL '15 minutes',
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
            RAISE EXCEPTION 'WALLET_PIN_LOCKED';
        ELSE
            UPDATE public.player_details
            SET wallet_pin_failed_attempts = v_failed,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
        END IF;
        RETURN FALSE;
    END IF;

    -- Compare hash
    IF v_hash = crypt(p_pin, v_hash) THEN
        -- Success: reset failed attempts
        UPDATE public.player_details
        SET wallet_pin_failed_attempts = 0,
            wallet_pin_locked_until = NULL,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = p_user_id;
        RETURN TRUE;
    ELSE
        -- Failed: increment attempts and lock after 5
        v_failed := COALESCE(v_failed, 0) + 1;
        IF v_failed >= 5 THEN
            UPDATE public.player_details
            SET wallet_pin_failed_attempts = v_failed,
                wallet_pin_locked_until = CURRENT_TIMESTAMP + INTERVAL '15 minutes',
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
            RAISE EXCEPTION 'WALLET_PIN_LOCKED';
        ELSE
            UPDATE public.player_details
            SET wallet_pin_failed_attempts = v_failed,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
        END IF;
        RETURN FALSE;
    END IF;
END;
$$;
