-- Migration 022: Rename player_details to player_wallets, reset zero-transaction balances to 0.00, and update wallet functions

-- 1. Rename table player_details to player_wallets
ALTER TABLE IF EXISTS public.player_details RENAME TO player_wallets;

-- 2. Create view player_details pointing to player_wallets for full backward-compatibility with profile queries
CREATE OR REPLACE VIEW public.player_details AS
    SELECT * FROM public.player_wallets;

-- 3. Reset wallet_balance to 0.00 for users who have no successful wallet transactions in the database
UPDATE public.player_wallets
SET wallet_balance = 0.00,
    updated_at = CURRENT_TIMESTAMP
WHERE user_id NOT IN (
    SELECT DISTINCT user_id FROM public.wallet_transactions WHERE status = 'SUCCESS'
);

-- 4. Update set_wallet_pin stored function to use player_wallets
CREATE OR REPLACE FUNCTION public.set_wallet_pin(
    p_user_id VARCHAR(64),
    p_pin VARCHAR(16)
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_pin IS NULL OR p_pin !~ '^[0-9]{6}$' THEN
        RAISE EXCEPTION 'Wallet PIN must be exactly 6 numeric digits';
    END IF;

    UPDATE public.player_wallets
    SET wallet_pin_hash = crypt(p_pin, gen_salt('bf')),
        wallet_pin_set_at = CURRENT_TIMESTAMP,
        wallet_pin_failed_attempts = 0,
        wallet_pin_locked_until = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        INSERT INTO public.player_wallets (
            user_id,
            wallet_balance,
            wallet_pin_hash,
            wallet_pin_set_at,
            wallet_pin_failed_attempts,
            wallet_pin_locked_until
        )
        VALUES (
            p_user_id,
            0.00,
            crypt(p_pin, gen_salt('bf')),
            CURRENT_TIMESTAMP,
            0,
            NULL
        );
    END IF;
END;
$$;

-- 5. Update verify_wallet_pin stored function to use player_wallets
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
    FROM public.player_wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND OR v_hash IS NULL THEN
        RETURN FALSE;
    END IF;

    IF v_locked_until IS NOT NULL AND v_locked_until > CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'WALLET_PIN_LOCKED';
    END IF;

    IF p_pin IS NULL OR p_pin !~ '^[0-9]{6}$' THEN
        v_failed := COALESCE(v_failed, 0) + 1;
        IF v_failed >= 5 THEN
            UPDATE public.player_wallets
            SET wallet_pin_failed_attempts = v_failed,
                wallet_pin_locked_until = CURRENT_TIMESTAMP + INTERVAL '15 minutes',
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
            RAISE EXCEPTION 'WALLET_PIN_LOCKED';
        ELSE
            UPDATE public.player_wallets
            SET wallet_pin_failed_attempts = v_failed,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
        END IF;
        RETURN FALSE;
    END IF;

    IF v_hash = crypt(p_pin, v_hash) THEN
        UPDATE public.player_wallets
        SET wallet_pin_failed_attempts = 0,
            wallet_pin_locked_until = NULL,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = p_user_id;
        RETURN TRUE;
    ELSE
        v_failed := COALESCE(v_failed, 0) + 1;
        IF v_failed >= 5 THEN
            UPDATE public.player_wallets
            SET wallet_pin_failed_attempts = v_failed,
                wallet_pin_locked_until = CURRENT_TIMESTAMP + INTERVAL '15 minutes',
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
            RAISE EXCEPTION 'WALLET_PIN_LOCKED';
        ELSE
            UPDATE public.player_wallets
            SET wallet_pin_failed_attempts = v_failed,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = p_user_id;
        END IF;
        RETURN FALSE;
    END IF;
END;
$$;

-- 6. Update apply_transaction_to_wallet trigger function to use player_wallets
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

    SELECT pw.wallet_balance
    INTO v_current_balance
    FROM public.player_wallets pw
    WHERE pw.user_id = NEW.user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Player wallet does not exist';
    END IF;

    IF NEW.status <> 'SUCCESS' THEN
        NEW.balance_after := v_current_balance;
        RETURN NEW;
    END IF;

    IF NEW.type IN ('WELCOME_BONUS', 'CHALLENGE_REWARD') THEN
        RAISE EXCEPTION 'Bonus amounts are disabled across the platform';
    END IF;

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

    UPDATE public.player_wallets
    SET
        wallet_balance = v_new_balance,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id;

    NEW.balance_after := v_new_balance;
    RETURN NEW;
END;
$$;

-- 7. Update join_game_with_wallet stored function to use player_wallets
CREATE OR REPLACE FUNCTION public.join_game_with_wallet(
    p_user_id character varying,
    p_game_id character varying,
    p_position character varying DEFAULT 'MID'::character varying
)
RETURNS character varying
LANGUAGE plpgsql
AS $function$
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
    SELECT entry_fee, CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END, status 
    INTO v_entry_fee, v_max_players, v_game_status
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
        FROM public.player_wallets WHERE user_id = p_user_id FOR UPDATE;

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
        v_assigned_team := 'TEAM_A';
    ELSE
        v_assigned_team := 'TEAM_B';
    END IF;

    INSERT INTO public.game_players (game_id, user_id, team, position, status)
    VALUES (p_game_id, p_user_id, v_assigned_team, p_position::public.pickle_position, 'CONFIRMED')
    RETURNING id INTO v_roster_id;

    RETURN v_roster_id;
END;
$function$;

-- 8. Update register_player to insert into player_wallets
CREATE OR REPLACE FUNCTION public.register_player(
    p_name character varying,
    p_email character varying,
    p_phone character varying,
    p_password_hash character varying,
    p_city character varying DEFAULT 'Raipur'::character varying
)
RETURNS character varying
LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_id VARCHAR(64);
    v_email VARCHAR(255);
    v_phone VARCHAR(32);
    v_username VARCHAR(120);
    v_base_username VARCHAR(120);
    v_candidate VARCHAR(120);
    v_counter INT := 1;
    v_ends_with_digit BOOLEAN;
BEGIN
    v_email := LOWER(TRIM(p_email));
    v_phone := TRIM(p_phone);

    IF v_email = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Email is required.';
    END IF;

    IF v_phone = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Phone number is required.';
    END IF;

    IF p_password_hash IS NULL OR TRIM(p_password_hash) = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Password hash is required.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.user_identity_history
        WHERE identity_type = 'EMAIL' AND normalized_value = v_email
    ) THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: This email has already been registered.' USING ERRCODE = '23505';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.user_identity_history
        WHERE identity_type = 'PHONE' AND normalized_value = v_phone
    ) THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: This phone number has already been registered.' USING ERRCODE = '23505';
    END IF;

    IF p_name IS NOT NULL AND TRIM(p_name) <> '' THEN
        v_base_username := TRIM(p_name);
    ELSE
        v_base_username := SUBSTRING(v_email FROM 1 FOR POSITION('@' IN v_email) - 1);
        IF POSITION('+' IN v_base_username) > 0 THEN
            v_base_username := SUBSTRING(v_base_username FROM 1 FOR POSITION('+' IN v_base_username) - 1);
        END IF;
        v_base_username := REGEXP_REPLACE(v_base_username, '[^a-zA-Z0-9._-]', '', 'g');
        v_base_username := REGEXP_REPLACE(v_base_username, '^[._-]+|[._-]+$', '', 'g');
        IF v_base_username IS NULL OR TRIM(v_base_username) = '' THEN
            v_base_username := 'player';
        END IF;
    END IF;

    IF LENGTH(v_base_username) > 50 THEN
        v_base_username := SUBSTRING(v_base_username FROM 1 FOR 50);
    END IF;

    v_candidate := v_base_username;
    v_ends_with_digit := (v_base_username ~ '[0-9]$');

    WHILE EXISTS (SELECT 1 FROM public.users WHERE LOWER(name) = LOWER(v_candidate)) LOOP
        IF v_ends_with_digit THEN
            v_candidate := v_base_username || '_' || v_counter;
        ELSE
            v_candidate := v_base_username || v_counter;
        END IF;
        v_counter := v_counter + 1;
        IF v_counter > 100 THEN
            v_candidate := v_base_username || '_' || FLOOR(1000 + RANDOM() * 9000)::INT;
        END IF;
    END LOOP;

    v_username := v_candidate;

    INSERT INTO public.users (
        name,
        email,
        phone,
        password_hash,
        role_id,
        city,
        status
    ) VALUES (
        v_username,
        v_email,
        v_phone,
        p_password_hash,
        3,
        COALESCE(NULLIF(TRIM(p_city), ''), 'Raipur'),
        'ACTIVE'
    ) RETURNING id INTO v_user_id;

    -- Create player wallet record in player_wallets
    INSERT INTO public.player_wallets (user_id, wallet_balance)
    VALUES (v_user_id, 0.00)
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO public.user_identity_history (user_id, identity_type, identity_value, normalized_value)
    VALUES
        (v_user_id, 'EMAIL', p_email, v_email),
        (v_user_id, 'PHONE', p_phone, v_phone)
    ON CONFLICT DO NOTHING;

    RETURN v_user_id;
END;
$function$;
