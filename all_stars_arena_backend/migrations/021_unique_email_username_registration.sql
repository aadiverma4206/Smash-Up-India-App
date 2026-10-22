-- Migration 021: Unique email-based username generation for new players
-- Extracts username from email prefix (before @), checks availability in public.users,
-- and assigns an alternative unique username if already taken.

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

    -- Determine base username:
    -- If p_name is provided, use it as initial base candidate; otherwise derive from email prefix
    IF p_name IS NOT NULL AND TRIM(p_name) <> '' THEN
        v_base_username := TRIM(p_name);
    ELSE
        v_base_username := SUBSTRING(v_email FROM 1 FOR POSITION('@' IN v_email) - 1);
        -- Strip any '+' email tag if present (e.g., user+tag -> user)
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

    -- Ensure uniqueness in public.users (case-insensitive check)
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

    INSERT INTO public.player_details (user_id) VALUES (v_user_id);

    -- Sync identity history for newly registered user
    INSERT INTO public.user_identity_history (user_id, identity_type, identity_value, normalized_value)
    VALUES
        (v_user_id, 'EMAIL', p_email, v_email),
        (v_user_id, 'PHONE', p_phone, v_phone)
    ON CONFLICT DO NOTHING;

    RETURN v_user_id;
END;
$function$;
