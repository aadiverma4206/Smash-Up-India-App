-- Fix register_player function to correctly check duplicates and update user_identity_history
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
    v_digits VARCHAR(32);
BEGIN
    v_email := LOWER(TRIM(p_email));
    v_phone := TRIM(p_phone);
    v_digits := REGEXP_REPLACE(v_phone, '[^0-9]', '', 'g');

    IF TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Name is required.';
    END IF;

    IF v_email = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Email is required.';
    END IF;

    IF v_phone = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Phone number is required.';
    END IF;

    IF p_password_hash IS NULL OR TRIM(p_password_hash) = '' THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: Password hash is required.';
    END IF;

    -- Check if email exists in public.users OR public.user_identity_history
    IF EXISTS (
        SELECT 1 FROM public.users WHERE LOWER(TRIM(email)) = v_email
        UNION
        SELECT 1 FROM public.user_identity_history WHERE identity_type = 'EMAIL' AND LOWER(TRIM(normalized_value)) = v_email
    ) THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: An account with this email address has already been registered.' USING ERRCODE = '23505';
    END IF;

    -- Check if phone exists in public.users OR public.user_identity_history
    IF EXISTS (
        SELECT 1 FROM public.users
        WHERE TRIM(phone) = v_phone
           OR TRIM(phone) = CASE WHEN v_phone LIKE '+91%' THEN SUBSTRING(v_phone FROM 4) ELSE '+91' || v_phone END
           OR (v_digits <> '' AND LENGTH(v_digits) >= 10 AND RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 10) = RIGHT(v_digits, 10))
        UNION
        SELECT 1 FROM public.user_identity_history
        WHERE (identity_type = 'PHONE' AND TRIM(normalized_value) = v_phone)
           OR (v_digits <> '' AND LENGTH(v_digits) >= 10 AND identity_type = 'PHONE' AND RIGHT(REGEXP_REPLACE(normalized_value, '[^0-9]', '', 'g'), 10) = RIGHT(v_digits, 10))
    ) THEN
        RAISE EXCEPTION 'REGISTRATION FAILED: An account with this phone number has already been registered.' USING ERRCODE = '23505';
    END IF;

    INSERT INTO public.users (
        name,
        email,
        phone,
        password_hash,
        role_id,
        city,
        status
    ) VALUES (
        TRIM(p_name),
        v_email,
        v_phone,
        p_password_hash,
        3,
        COALESCE(NULLIF(TRIM(p_city), ''), 'Raipur'),
        'ACTIVE'
    ) RETURNING id INTO v_user_id;

    INSERT INTO public.player_details (user_id) VALUES (v_user_id);

    -- Sync identity history for newly registered user
    INSERT INTO public.user_identity_history (user_id, identity_type, normalized_value)
    VALUES
        (v_user_id, 'EMAIL', v_email),
        (v_user_id, 'PHONE', v_phone)
    ON CONFLICT DO NOTHING;

    RETURN v_user_id;
END;
$function$;
