--
-- PostgreSQL database dump
--

\restrict Y9DoR07p2vb0Y3TtE7OpwIKPi5MpCbDbB7ZLBlMjGJ9eGVgAi5sKkJuCZZpJQg8

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-10-03 12:17:28

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 3079 OID 18942)
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- TOC entry 6224 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- TOC entry 3 (class 3079 OID 17641)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 6225 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 2 (class 3079 OID 17630)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 6226 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 1219 (class 1247 OID 17686)
-- Name: admin_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.admin_type AS ENUM (
    'SUPER_ADMIN',
    'OPS_ADMIN',
    'FINANCE_ADMIN'
);


ALTER TYPE public.admin_type OWNER TO postgres;

--
-- TOC entry 1255 (class 1247 OID 17832)
-- Name: booking_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.booking_status AS ENUM (
    'CONFIRMED',
    'CANCELLED',
    'REFUND_PENDING',
    'REFUNDED',
    'REFUND_REJECTED'
);


ALTER TYPE public.booking_status OWNER TO postgres;

--
-- TOC entry 1270 (class 1247 OID 17882)
-- Name: dispute_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.dispute_status AS ENUM (
    'OPEN',
    'RESOLVED',
    'DISMISSED'
);


ALTER TYPE public.dispute_status OWNER TO postgres;

--
-- TOC entry 1222 (class 1247 OID 17694)
-- Name: foot_preference; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.foot_preference AS ENUM (
    'Right',
    'Left',
    'Both'
);


ALTER TYPE public.foot_preference OWNER TO postgres;

--
-- TOC entry 1228 (class 1247 OID 17712)
-- Name: football_position; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.football_position AS ENUM (
    'GK',
    'CB',
    'LB',
    'RB',
    'LWB',
    'RWB',
    'DEF',
    'CDM',
    'CM',
    'CAM',
    'LM',
    'RM',
    'MID',
    'ST',
    'CF',
    'LW',
    'RW',
    'FWD',
    'WING'
);


ALTER TYPE public.football_position OWNER TO postgres;

--
-- TOC entry 1243 (class 1247 OID 17786)
-- Name: match_format; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.match_format AS ENUM (
    '1v1',
    '2v2',
    '3v3',
    '4v4',
    '5v5',
    '6v6',
    '7v7',
    '8v8',
    '9v9',
    '11v11'
);


ALTER TYPE public.match_format OWNER TO postgres;

--
-- TOC entry 1246 (class 1247 OID 17808)
-- Name: match_privacy; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.match_privacy AS ENUM (
    'PUBLIC',
    'PRIVATE'
);


ALTER TYPE public.match_privacy OWNER TO postgres;

--
-- TOC entry 1249 (class 1247 OID 17814)
-- Name: match_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.match_status AS ENUM (
    'OPEN_FOR_JOINING',
    'FULL',
    'ONGOING',
    'COMPLETED',
    'CANCELLED'
);


ALTER TYPE public.match_status OWNER TO postgres;

--
-- TOC entry 1282 (class 1247 OID 17922)
-- Name: otp_channel; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.otp_channel AS ENUM (
    'SMS',
    'EMAIL',
    'WHATSAPP'
);


ALTER TYPE public.otp_channel OWNER TO postgres;

--
-- TOC entry 1279 (class 1247 OID 17908)
-- Name: otp_purpose; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.otp_purpose AS ENUM (
    'REGISTRATION',
    'LOGIN',
    'PASSWORD_RESET',
    'WALLET_TOPUP',
    'PHONE_CHANGE',
    'EMAIL_CHANGE'
);


ALTER TYPE public.otp_purpose OWNER TO postgres;

--
-- TOC entry 1240 (class 1247 OID 17780)
-- Name: pitch_environment; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pitch_environment AS ENUM (
    'Indoor',
    'Outdoor'
);


ALTER TYPE public.pitch_environment OWNER TO postgres;

--
-- TOC entry 1234 (class 1247 OID 17762)
-- Name: pitch_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pitch_status AS ENUM (
    'AVAILABLE',
    'BLOCKED',
    'MAINTENANCE'
);


ALTER TYPE public.pitch_status OWNER TO postgres;

--
-- TOC entry 1237 (class 1247 OID 17770)
-- Name: pitch_surface; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pitch_surface AS ENUM (
    '3G Turf',
    'Synthetic Grass',
    'Natural Grass',
    'Rubber Futsal'
);


ALTER TYPE public.pitch_surface OWNER TO postgres;

--
-- TOC entry 1225 (class 1247 OID 17702)
-- Name: skill_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.skill_level AS ENUM (
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional'
);


ALTER TYPE public.skill_level OWNER TO postgres;

--
-- TOC entry 1252 (class 1247 OID 17826)
-- Name: team_side; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.team_side AS ENUM (
    'TEAM_A',
    'TEAM_B'
);


ALTER TYPE public.team_side OWNER TO postgres;

--
-- TOC entry 1273 (class 1247 OID 17890)
-- Name: ticket_priority; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_priority AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'URGENT'
);


ALTER TYPE public.ticket_priority OWNER TO postgres;

--
-- TOC entry 1276 (class 1247 OID 17900)
-- Name: ticket_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_status AS ENUM (
    'OPEN',
    'ASSIGNED',
    'RESOLVED'
);


ALTER TYPE public.ticket_status OWNER TO postgres;

--
-- TOC entry 1264 (class 1247 OID 17864)
-- Name: tournament_format; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tournament_format AS ENUM (
    'Knockout',
    'Round-Robin'
);


ALTER TYPE public.tournament_format OWNER TO postgres;

--
-- TOC entry 1267 (class 1247 OID 17870)
-- Name: tournament_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tournament_status AS ENUM (
    'UPCOMING',
    'TEAM_PENDING',
    'CONFIRMED',
    'ONGOING',
    'COMPLETED'
);


ALTER TYPE public.tournament_status OWNER TO postgres;

--
-- TOC entry 1261 (class 1247 OID 17856)
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_status AS ENUM (
    'PENDING',
    'SUCCESS',
    'FAILED'
);


ALTER TYPE public.transaction_status OWNER TO postgres;

--
-- TOC entry 1258 (class 1247 OID 17844)
-- Name: transaction_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_type AS ENUM (
    'WALLET_TOPUP',
    'PAYMENT',
    'REFUND',
    'WELCOME_BONUS',
    'CHALLENGE_REWARD'
);


ALTER TYPE public.transaction_type OWNER TO postgres;

--
-- TOC entry 1216 (class 1247 OID 17680)
-- Name: user_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_status AS ENUM (
    'ACTIVE',
    'SUSPENDED'
);


ALTER TYPE public.user_status OWNER TO postgres;

--
-- TOC entry 1231 (class 1247 OID 17752)
-- Name: venue_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.venue_status AS ENUM (
    'PENDING',
    'ACTIVE',
    'SUSPENDED',
    'REJECTED'
);


ALTER TYPE public.venue_status OWNER TO postgres;

--
-- TOC entry 275 (class 1255 OID 18271)
-- Name: apply_refund_tier(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.apply_refund_tier() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_hours_before NUMERIC;
    v_booking_ts TIMESTAMP;
BEGIN
    IF NEW.status = 'CANCELLED' AND OLD.status = 'CONFIRMED' THEN
        v_booking_ts := (NEW.booking_date + NEW.start_time);
        v_hours_before := EXTRACT(EPOCH FROM (v_booking_ts - CURRENT_TIMESTAMP)) / 3600.0;

        IF v_hours_before > 24 THEN
            NEW.refund_tier := '100%';
            NEW.refund_amount := NEW.amount_paid;
        ELSIF v_hours_before >= 12 THEN
            NEW.refund_tier := '50%';
            NEW.refund_amount := ROUND(NEW.amount_paid * 0.5, 2);
        ELSE
            NEW.refund_tier := '0%';
            NEW.refund_amount := 0.00;
        END IF;
        NEW.status := 'REFUND_PENDING';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.apply_refund_tier() OWNER TO postgres;

--
-- TOC entry 520 (class 1255 OID 18607)
-- Name: apply_transaction_to_wallet(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.apply_transaction_to_wallet() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
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

    v_is_credit :=
        NEW.type IN
        (
            'WALLET_TOPUP',
            'REFUND',
            'WELCOME_BONUS',
            'CHALLENGE_REWARD'
        );

    IF v_is_credit THEN

        v_new_balance := v_current_balance + NEW.amount;

        IF v_new_balance > 200000.00 THEN
            RAISE EXCEPTION
                'Wallet balance cannot exceed Rs. 2,00,000';
        END IF;

    ELSE

        v_new_balance := v_current_balance - NEW.amount;

        IF v_new_balance < 0 THEN
            RAISE EXCEPTION
                'Insufficient wallet balance';
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


ALTER FUNCTION public.apply_transaction_to_wallet() OWNER TO postgres;

--
-- TOC entry 350 (class 1255 OID 18393)
-- Name: assign_waitlist_order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.assign_waitlist_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_next INT;
BEGIN
    IF NEW.waitlist_order IS NULL OR NEW.waitlist_order = 0 THEN
        SELECT COALESCE(MAX(waitlist_order), 0) + 1 INTO v_next
        FROM game_waitlist WHERE game_id = NEW.game_id;
        NEW.waitlist_order := v_next;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.assign_waitlist_order() OWNER TO postgres;

--
-- TOC entry 571 (class 1255 OID 18864)
-- Name: block_audit_log_mutation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.block_audit_log_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs is append-only: % is not permitted', TG_OP;
END;
$$;


ALTER FUNCTION public.block_audit_log_mutation() OWNER TO postgres;

--
-- TOC entry 505 (class 1255 OID 19820)
-- Name: block_transaction_mutation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.block_transaction_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION
        'transactions is an immutable financial ledger: % is not permitted',
        TG_OP
        USING ERRCODE = '42501';
END;
$$;


ALTER FUNCTION public.block_transaction_mutation() OWNER TO postgres;

--
-- TOC entry 459 (class 1255 OID 18221)
-- Name: calculate_court_price(character varying, date, time without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_court_price(p_court_id character varying, p_date date, p_start_time time without time zone) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    c courts%ROWTYPE;
    v_price NUMERIC(10,2);
    v_is_weekend BOOLEAN;
    v_is_peak BOOLEAN;
BEGIN
    SELECT * INTO c FROM courts WHERE id = p_court_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Court % not found', p_court_id;
    END IF;

    v_is_weekend := EXTRACT(ISODOW FROM p_date) IN (6, 7);
    v_is_peak := p_start_time >= c.peak_window_start AND p_start_time < c.peak_window_end;

    v_price := c.base_price;
    IF v_is_weekend THEN
        v_price := v_price * c.weekend_multiplier;
    ELSIF v_is_peak THEN
        v_price := v_price * c.peak_multiplier;
    END IF;

    RETURN ROUND(v_price, 2);
END;
$$;


ALTER FUNCTION public.calculate_court_price(p_court_id character varying, p_date date, p_start_time time without time zone) OWNER TO postgres;

--
-- TOC entry 298 (class 1255 OID 19704)
-- Name: capture_user_identity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.capture_user_identity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- ========================================================
    -- NEW USER
    -- ========================================================

    IF TG_OP = 'INSERT' THEN

        INSERT INTO public.user_identity_history
        (
            user_id,
            identity_type,
            identity_value,
            normalized_value
        )
        VALUES
        (
            NEW.id,
            'EMAIL',
            NEW.email,
            LOWER(TRIM(NEW.email))
        );

        INSERT INTO public.user_identity_history
        (
            user_id,
            identity_type,
            identity_value,
            normalized_value
        )
        VALUES
        (
            NEW.id,
            'PHONE',
            NEW.phone,
            TRIM(NEW.phone)
        );

        RETURN NEW;

    END IF;


    -- ========================================================
    -- USER UPDATE
    -- ========================================================

    IF TG_OP = 'UPDATE' THEN

        -- ----------------------------------------------------
        -- EMAIL CHANGED
        -- ----------------------------------------------------

        IF LOWER(TRIM(OLD.email))
           IS DISTINCT FROM LOWER(TRIM(NEW.email))
        THEN

            INSERT INTO public.user_identity_history
            (
                user_id,
                identity_type,
                identity_value,
                normalized_value
            )
            VALUES
            (
                NEW.id,
                'EMAIL',
                NEW.email,
                LOWER(TRIM(NEW.email))
            );

        END IF;


        -- ----------------------------------------------------
        -- PHONE CHANGED
        -- ----------------------------------------------------

        IF TRIM(OLD.phone)
           IS DISTINCT FROM TRIM(NEW.phone)
        THEN

            INSERT INTO public.user_identity_history
            (
                user_id,
                identity_type,
                identity_value,
                normalized_value
            )
            VALUES
            (
                NEW.id,
                'PHONE',
                NEW.phone,
                TRIM(NEW.phone)
            );

        END IF;


        RETURN NEW;

    END IF;


    RETURN NEW;

END;
$$;


ALTER FUNCTION public.capture_user_identity() OWNER TO postgres;

--
-- TOC entry 471 (class 1255 OID 18841)
-- Name: check_assigned_staff_is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_assigned_staff_is_admin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_role_id SMALLINT;
BEGIN
    IF NEW.assigned_staff_id IS NOT NULL THEN
        SELECT role_id INTO v_role_id FROM users WHERE id = NEW.assigned_staff_id;
        IF v_role_id <> 1 THEN
            RAISE EXCEPTION 'Only an ADMIN account can be assigned a support ticket';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_assigned_staff_is_admin() OWNER TO postgres;

--
-- TOC entry 454 (class 1255 OID 18269)
-- Name: check_booking_user_is_player(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_booking_user_is_player() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_role_id SMALLINT;
BEGIN
    SELECT role_id INTO v_role_id FROM users WHERE id = NEW.user_id;
    IF v_role_id <> 3 THEN
        RAISE EXCEPTION 'Only PLAYER accounts can make court bookings';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_booking_user_is_player() OWNER TO postgres;

--
-- TOC entry 485 (class 1255 OID 18178)
-- Name: check_manager_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_manager_role() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_role_id SMALLINT;
BEGIN
    SELECT role_id INTO v_role_id FROM users WHERE id = NEW.user_id;
    IF v_role_id NOT IN (1, 2) THEN  -- ADMIN or MANAGER only
        RAISE EXCEPTION 'Only MANAGER or ADMIN accounts can be assigned to manage a club';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_manager_role() OWNER TO postgres;

--
-- TOC entry 413 (class 1255 OID 18736)
-- Name: check_poll_option_matches_poll(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_poll_option_matches_poll() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_poll_id VARCHAR(64);
BEGIN
    SELECT poll_id INTO v_poll_id FROM poll_options WHERE id = NEW.option_id;
    IF v_poll_id IS DISTINCT FROM NEW.poll_id THEN
        RAISE EXCEPTION 'Selected option does not belong to this poll';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_poll_option_matches_poll() OWNER TO postgres;

--
-- TOC entry 300 (class 1255 OID 18070)
-- Name: create_admin_account(character varying, character varying, character varying, character varying, character varying, public.admin_type, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_admin_account(p_created_by_owner_id character varying, p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_admin_type public.admin_type DEFAULT 'OPS_ADMIN'::public.admin_type, p_city character varying DEFAULT 'Raipur'::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id VARCHAR(64);
    v_is_owner BOOLEAN;
BEGIN
    SELECT is_owner INTO v_is_owner FROM admin_details WHERE user_id = p_created_by_owner_id;
    IF COALESCE(v_is_owner, FALSE) IS NOT TRUE THEN
        RAISE EXCEPTION 'Only the platform owner can create new admin accounts';
    END IF;

    INSERT INTO users (name, email, phone, password_hash, role_id, city)
    VALUES (p_name, p_email, p_phone, p_password_hash, 1, p_city)
    RETURNING id INTO v_user_id;

    INSERT INTO admin_details (user_id, admin_type, is_owner, created_by_admin_id)
    VALUES (v_user_id, p_admin_type, FALSE, p_created_by_owner_id);

    RETURN v_user_id;
END;
$$;


ALTER FUNCTION public.create_admin_account(p_created_by_owner_id character varying, p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_admin_type public.admin_type, p_city character varying) OWNER TO postgres;

--
-- TOC entry 348 (class 1255 OID 18069)
-- Name: create_manager_account(character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_manager_account(p_created_by_admin_id character varying, p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_city character varying DEFAULT 'Raipur'::character varying, p_employee_code character varying DEFAULT NULL::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id VARCHAR(64);
    v_creator_role_id SMALLINT;
BEGIN
    SELECT role_id INTO v_creator_role_id FROM users WHERE id = p_created_by_admin_id;
    IF v_creator_role_id IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION 'Only an admin can create a manager account';
    END IF;

    INSERT INTO users (name, email, phone, password_hash, role_id, city)
    VALUES (p_name, p_email, p_phone, p_password_hash, 2, p_city)
    RETURNING id INTO v_user_id;

    INSERT INTO manager_details (user_id, created_by_admin_id, employee_code)
    VALUES (v_user_id, p_created_by_admin_id, p_employee_code);

    RETURN v_user_id;
END;
$$;


ALTER FUNCTION public.create_manager_account(p_created_by_admin_id character varying, p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_city character varying, p_employee_code character varying) OWNER TO postgres;

--
-- TOC entry 448 (class 1255 OID 77337)
-- Name: create_payment_order(character varying, character varying, integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_payment_order(p_user_id character varying, p_provider character varying, p_amount_paise integer, p_idempotency_key character varying, p_wallet_pin character varying DEFAULT NULL::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      DECLARE
          v_order_id VARCHAR(64);
      BEGIN
          -- Top-up payment orders via Razorpay do NOT require PIN verification.
          INSERT INTO public.payment_orders (
              user_id,
              provider,
              amount_paise,
              idempotency_key,
              status,
              created_at,
              updated_at
          ) VALUES (
              p_user_id,
              p_provider,
              p_amount_paise,
              p_idempotency_key,
              'PENDING',
              CURRENT_TIMESTAMP,
              CURRENT_TIMESTAMP
          )
          ON CONFLICT (user_id, idempotency_key) DO UPDATE
          SET updated_at = CURRENT_TIMESTAMP
          RETURNING id INTO v_order_id;

          RETURN v_order_id;
      END;
      $$;


ALTER FUNCTION public.create_payment_order(p_user_id character varying, p_provider character varying, p_amount_paise integer, p_idempotency_key character varying, p_wallet_pin character varying) OWNER TO postgres;

--
-- TOC entry 420 (class 1255 OID 19835)
-- Name: create_payment_order(character varying, character varying, bigint, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_payment_order(p_user_id character varying, p_provider character varying, p_amount_paise bigint, p_idempotency_key character varying, p_wallet_pin character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_order_id VARCHAR(64);
    v_pin_ok   BOOLEAN;
BEGIN
    -- Basic validation (unchanged from before)
    IF p_user_id IS NULL OR TRIM(p_user_id) = '' THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;

    IF p_provider IS NULL OR TRIM(p_provider) = '' THEN
        RAISE EXCEPTION 'Payment provider is required';
    END IF;

    IF p_amount_paise IS NULL OR p_amount_paise <= 0 OR p_amount_paise > 5000000 THEN
        RAISE EXCEPTION 'Invalid payment amount. Maximum allowed is Rs. 50,000';
    END IF;

    IF p_idempotency_key IS NULL OR LENGTH(TRIM(p_idempotency_key)) < 16 THEN
        RAISE EXCEPTION 'A valid idempotency key is required';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.users u
        WHERE u.id = p_user_id AND u.role_id = 3 AND u.status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'Only active PLAYER accounts can create wallet payment orders';
    END IF;

    -- Wallet PIN gate: must exist and must be correct before we let the user
    -- start a top-up. This raises its own exception (locked / not set /
    -- wrong PIN) if it fails, so we don't need to duplicate that logic here.
    v_pin_ok := public.verify_wallet_pin(p_user_id, p_wallet_pin);
    IF NOT v_pin_ok THEN
        RAISE EXCEPTION 'Incorrect wallet PIN';
    END IF;

    -- Clear out any of this user's own stale orders first (keeps the
    -- idempotency lookup below honest)
    PERFORM public.expire_stale_payment_orders();

    -- Idempotency: same request returns the same (still-valid) order
    SELECT po.id INTO v_order_id
    FROM public.payment_orders po
    WHERE po.user_id = p_user_id
      AND po.idempotency_key = TRIM(p_idempotency_key)
    FOR UPDATE;

    IF FOUND THEN
        IF EXISTS (
            SELECT 1 FROM public.payment_orders po
            WHERE po.id = v_order_id
              AND (po.amount_paise <> p_amount_paise OR po.provider <> TRIM(p_provider))
        ) THEN
            RAISE EXCEPTION 'Idempotency key was already used with different payment details';
        END IF;
        RETURN v_order_id;
    END IF;

    -- Create NEW payment order, valid for exactly 5 minutes
    INSERT INTO public.payment_orders (
        user_id, provider, idempotency_key, amount_paise,
        currency, purpose, status, metadata, expires_at
    )
    VALUES (
        p_user_id, TRIM(p_provider), TRIM(p_idempotency_key), p_amount_paise,
        'INR', 'WALLET_TOPUP', 'CREATED', '{}'::jsonb,
        CURRENT_TIMESTAMP + INTERVAL '5 minutes'
    )
    RETURNING id INTO v_order_id;

    RETURN v_order_id;
END;
$$;


ALTER FUNCTION public.create_payment_order(p_user_id character varying, p_provider character varying, p_amount_paise bigint, p_idempotency_key character varying, p_wallet_pin character varying) OWNER TO postgres;

--
-- TOC entry 568 (class 1255 OID 18468)
-- Name: create_player_stats_row(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_player_stats_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO player_stats(user_id) VALUES (NEW.user_id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_player_stats_row() OWNER TO postgres;

--
-- TOC entry 502 (class 1255 OID 18358)
-- Name: enforce_game_player_rules(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enforce_game_player_rules() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_role_id SMALLINT;
    v_max INT;
    v_current_count INT;
BEGIN
    SELECT role_id INTO v_role_id FROM users WHERE id = NEW.user_id;
    IF v_role_id = 2 THEN
        RAISE EXCEPTION 'Club Managers cannot occupy a player slot in a game';
    END IF;
    IF v_role_id = 1 THEN
        RAISE EXCEPTION 'Admins cannot occupy a player slot in a game';
    END IF;

    SELECT max_players INTO v_max FROM games WHERE id = NEW.game_id;
    SELECT COUNT(*) INTO v_current_count FROM game_players WHERE game_id = NEW.game_id;

    IF v_current_count >= v_max THEN
        RAISE EXCEPTION 'Game roster is already full (max % players)', v_max;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.enforce_game_player_rules() OWNER TO postgres;

--
-- TOC entry 405 (class 1255 OID 18060)
-- Name: enforce_role_detail_match(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.enforce_role_detail_match() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_role_id SMALLINT;
    v_creator_role_id SMALLINT;
BEGIN
    SELECT role_id INTO v_role_id FROM users WHERE id = NEW.user_id;

    IF TG_TABLE_NAME = 'admin_details' AND v_role_id <> 1 THEN
        RAISE EXCEPTION 'User % does not have role ADMIN, cannot insert into admin_details', NEW.user_id;
    ELSIF TG_TABLE_NAME = 'manager_details' AND v_role_id <> 2 THEN
        RAISE EXCEPTION 'User % does not have role MANAGER, cannot insert into manager_details', NEW.user_id;
    ELSIF TG_TABLE_NAME = 'player_details' AND v_role_id <> 3 THEN
        RAISE EXCEPTION 'User % does not have role PLAYER, cannot insert into player_details', NEW.user_id;
    END IF;

    -- Extra hard rule: manager_details.created_by_admin_id MUST really be an admin
    IF TG_TABLE_NAME = 'manager_details' THEN
        SELECT role_id INTO v_creator_role_id FROM users WHERE id = NEW.created_by_admin_id;
        IF v_creator_role_id IS DISTINCT FROM 1 THEN
            RAISE EXCEPTION 'Only an ADMIN account can create a manager account (created_by_admin_id must belong to an admin)';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.enforce_role_detail_match() OWNER TO postgres;

--
-- TOC entry 449 (class 1255 OID 19834)
-- Name: expire_stale_payment_orders(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.expire_stale_payment_orders() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE public.payment_orders
    SET status = 'EXPIRED',
        updated_at = CURRENT_TIMESTAMP
    WHERE status IN ('CREATED', 'PENDING')
      AND expires_at < CURRENT_TIMESTAMP;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


ALTER FUNCTION public.expire_stale_payment_orders() OWNER TO postgres;

--
-- TOC entry 500 (class 1255 OID 18470)
-- Name: finalize_match_result(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.finalize_match_result() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_avg_elo_a NUMERIC;
    v_avg_elo_b NUMERIC;
    v_expected_a NUMERIC;
    v_expected_b NUMERIC;
    v_actual_a NUMERIC;
    v_actual_b NUMERIC;
    v_goal_diff INT;
    v_k_adj NUMERIC;
    rec RECORD;
    v_result_for_team NUMERIC;
BEGIN
    IF NEW.is_final IS DISTINCT FROM TRUE THEN
        RETURN NEW;
    END IF;

    SELECT AVG(pd.elo_rating) INTO v_avg_elo_a
    FROM game_players gp JOIN player_details pd ON pd.user_id = gp.user_id
    WHERE gp.game_id = NEW.game_id AND gp.team = 'TEAM_A';

    SELECT AVG(pd.elo_rating) INTO v_avg_elo_b
    FROM game_players gp JOIN player_details pd ON pd.user_id = gp.user_id
    WHERE gp.game_id = NEW.game_id AND gp.team = 'TEAM_B';

    v_avg_elo_a := COALESCE(v_avg_elo_a, 1500);
    v_avg_elo_b := COALESCE(v_avg_elo_b, 1500);

    v_expected_a := 1.0 / (1.0 + POWER(10.0, (v_avg_elo_b - v_avg_elo_a) / 400.0));
    v_expected_b := 1.0 - v_expected_a;

    IF NEW.team_a_score > NEW.team_b_score THEN
        v_actual_a := 1.0; v_actual_b := 0.0;
    ELSIF NEW.team_a_score < NEW.team_b_score THEN
        v_actual_a := 0.0; v_actual_b := 1.0;
    ELSE
        v_actual_a := 0.5; v_actual_b := 0.5;
    END IF;

    v_goal_diff := ABS(NEW.team_a_score - NEW.team_b_score);
    v_k_adj := 32 * (1 + LEAST(v_goal_diff, 5) * 0.1);

    FOR rec IN
        SELECT gp.user_id, gp.team, pd.elo_rating
        FROM game_players gp JOIN player_details pd ON pd.user_id = gp.user_id
        WHERE gp.game_id = NEW.game_id
    LOOP
        IF rec.team = 'TEAM_A' THEN
            v_result_for_team := v_actual_a - v_expected_a;
        ELSE
            v_result_for_team := v_actual_b - v_expected_b;
        END IF;

        UPDATE player_details
        SET elo_rating = GREATEST(0, ROUND(rec.elo_rating + v_k_adj * v_result_for_team))
        WHERE user_id = rec.user_id;

        UPDATE player_stats SET
            matches_played = matches_played + 1,
            wins   = wins   + CASE WHEN (rec.team='TEAM_A' AND NEW.team_a_score>NEW.team_b_score)
                                     OR (rec.team='TEAM_B' AND NEW.team_b_score>NEW.team_a_score) THEN 1 ELSE 0 END,
            draws  = draws  + CASE WHEN NEW.team_a_score = NEW.team_b_score THEN 1 ELSE 0 END,
            losses = losses + CASE WHEN (rec.team='TEAM_A' AND NEW.team_a_score<NEW.team_b_score)
                                     OR (rec.team='TEAM_B' AND NEW.team_b_score<NEW.team_a_score) THEN 1 ELSE 0 END,
            clean_sheets = clean_sheets + CASE
                              WHEN rec.team = 'TEAM_A' AND NEW.team_b_score = 0 THEN 1
                              WHEN rec.team = 'TEAM_B' AND NEW.team_a_score = 0 THEN 1
                              ELSE 0 END,
            points = points + CASE
                        WHEN (rec.team='TEAM_A' AND NEW.team_a_score>NEW.team_b_score)
                          OR (rec.team='TEAM_B' AND NEW.team_b_score>NEW.team_a_score) THEN 3
                        WHEN NEW.team_a_score = NEW.team_b_score THEN 1
                        ELSE 0 END,
            win_rate = CASE WHEN (matches_played + 1) > 0
                       THEN ROUND(100.0 * (wins + CASE WHEN (rec.team='TEAM_A' AND NEW.team_a_score>NEW.team_b_score)
                                                          OR (rec.team='TEAM_B' AND NEW.team_b_score>NEW.team_a_score) THEN 1 ELSE 0 END)
                                   / (matches_played + 1))
                       ELSE 0 END
        WHERE user_id = rec.user_id;
    END LOOP;

    UPDATE games
    SET team_a_score = NEW.team_a_score,
        team_b_score = NEW.team_b_score,
        winner_team = CASE WHEN NEW.team_a_score > NEW.team_b_score THEN 'TEAM_A'
                            WHEN NEW.team_b_score > NEW.team_a_score THEN 'TEAM_B'
                            ELSE 'DRAW' END,
        status = 'COMPLETED'
    WHERE id = NEW.game_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.finalize_match_result() OWNER TO postgres;

--
-- TOC entry 556 (class 1255 OID 19742)
-- Name: get_login_user(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_login_user(p_identifier character varying) RETURNS TABLE(id character varying, role_id smallint, name character varying, email character varying, phone character varying, password_hash character varying, status public.user_status, failed_login_count integer, locked_until timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN

    RETURN QUERY

    SELECT
        u.id,
        u.role_id,
        u.name,
        u.email,
        u.phone,
        u.password_hash,
        u.status,
        u.failed_login_count,
        u.locked_until

    FROM public.users u

    WHERE
        LOWER(TRIM(u.email))
            = LOWER(TRIM(p_identifier))

        OR

        TRIM(u.phone)
            = TRIM(p_identifier)

    LIMIT 1;

END;
$$;


ALTER FUNCTION public.get_login_user(p_identifier character varying) OWNER TO postgres;

--
-- TOC entry 475 (class 1255 OID 19849)
-- Name: get_payment_order_status(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_payment_order_status(p_user_id character varying, p_payment_order_id character varying) RETURNS TABLE(payment_order_id character varying, amount_paise bigint, amount_rupees numeric, provider character varying, status character varying, created_at timestamp with time zone, expires_at timestamp with time zone, paid_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
BEGIN

    RETURN QUERY
    SELECT
        po.id,
        po.amount_paise,
        ROUND(po.amount_paise / 100.0, 2),
        po.provider,
        po.status,
        po.created_at,
        po.expires_at,
        po.paid_at
    FROM public.payment_orders po
    WHERE po.id = p_payment_order_id
      AND po.user_id = p_user_id;

END;
$$;


ALTER FUNCTION public.get_payment_order_status(p_user_id character varying, p_payment_order_id character varying) OWNER TO postgres;

--
-- TOC entry 542 (class 1255 OID 19848)
-- Name: get_wallet_transaction_history(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_wallet_transaction_history(p_user_id character varying, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0) RETURNS TABLE(transaction_id character varying, transaction_type public.transaction_type, amount numeric, balance_after numeric, transaction_status public.transaction_status, description text, reference_id character varying, created_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
    SELECT
        t.id,
        t.type,
        t.amount,
        t.balance_after,
        t.status,
        t.description,
        t.reference_id,
        t.created_at
    FROM public.transactions t
    WHERE t.user_id = p_user_id
    ORDER BY t.created_at DESC, t.id DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 100)
    OFFSET GREATEST(p_offset, 0);
$$;


ALTER FUNCTION public.get_wallet_transaction_history(p_user_id character varying, p_limit integer, p_offset integer) OWNER TO postgres;

--
-- TOC entry 415 (class 1255 OID 18609)
-- Name: grant_welcome_bonus(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.grant_welcome_bonus() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO transactions (user_id, type, amount, balance_after, status, description)
    VALUES (NEW.user_id, 'WELCOME_BONUS', 1000.00, 0, 'SUCCESS', 'Welcome bonus on registration');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.grant_welcome_bonus() OWNER TO postgres;

--
-- TOC entry 495 (class 1255 OID 18103)
-- Name: guard_otp_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.guard_otp_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.is_used = TRUE AND NEW.is_used = FALSE THEN
        RAISE EXCEPTION 'A used OTP cannot be marked unused';
    END IF;
    IF NEW.attempt_count > NEW.max_attempts THEN
        RAISE EXCEPTION 'OTP max attempts exceeded';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.guard_otp_update() OWNER TO postgres;

--
-- TOC entry 410 (class 1255 OID 19860)
-- Name: join_game_with_wallet(character varying, character varying, public.football_position); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position public.football_position) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
    v_role_id          SMALLINT;
    v_user_status      public.user_status;

    v_entry_fee        NUMERIC(10,2);
    v_game_status      public.match_status;
    v_max_players      INT;

    v_player_count     INT;

    v_team_a_count     INT;
    v_team_b_count     INT;

    v_team_capacity    INT;
    v_selected_team    public.team_side;

    v_balance          NUMERIC(12,2);

    v_tx_id            VARCHAR(64);
    v_game_player_id   BIGINT;
BEGIN

    /*
     * ============================================================
     * 1. VALIDATE USER
     * ============================================================
     */

    SELECT
        u.role_id,
        u.status
    INTO
        v_role_id,
        v_user_status
    FROM public.users u
    WHERE u.id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Player account not found';
    END IF;


    IF v_role_id <> 3 THEN
        RAISE EXCEPTION 'Only PLAYER accounts can join games';
    END IF;


    IF v_user_status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Only ACTIVE players can join games';
    END IF;


    /*
     * ============================================================
     * 2. POSITION VALIDATION
     * ============================================================
     */

    IF p_position IS NULL THEN
        RAISE EXCEPTION 'Player position is required';
    END IF;


    /*
     * ============================================================
     * 3. LOCK GAME ROW
     *
     * This is VERY IMPORTANT.
     *
     * It prevents two players from simultaneously calculating
     * the same team count.
     * ============================================================
     */

    SELECT
        g.entry_fee,
        g.status,
        g.max_players
    INTO
        v_entry_fee,
        v_game_status,
        v_max_players
    FROM public.games g
    WHERE g.id = p_game_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION 'Game not found';
    END IF;


    /*
     * ============================================================
     * 4. GAME MUST BE OPEN
     * ============================================================
     */

    IF v_game_status <> 'OPEN_FOR_JOINING' THEN
        RAISE EXCEPTION
            'Game is not open for joining. Current status: %',
            v_game_status;
    END IF;


    /*
     * ============================================================
     * 5. MAX PLAYERS SAFETY
     *
     * Your games table already requires an even max_players.
     * Each team therefore gets exactly half capacity.
     * ============================================================
     */

    IF v_max_players < 2 OR v_max_players % 2 <> 0 THEN
        RAISE EXCEPTION
            'Invalid game configuration: max_players must be an even number >= 2';
    END IF;


    v_team_capacity := v_max_players / 2;


    /*
     * ============================================================
     * 6. DUPLICATE JOIN CHECK
     * ============================================================
     */

    IF EXISTS (
        SELECT 1
        FROM public.game_players gp
        WHERE gp.game_id = p_game_id
          AND gp.user_id = p_user_id
    ) THEN

        RAISE EXCEPTION
            'Player has already joined this game';

    END IF;


    /*
     * ============================================================
     * 7. COUNT CURRENT PLAYERS
     *
     * Game row is already locked, so concurrent joins for this
     * same game cannot modify the decision simultaneously.
     * ============================================================
     */

    SELECT COUNT(*)
    INTO v_player_count
    FROM public.game_players gp
    WHERE gp.game_id = p_game_id;


    IF v_player_count >= v_max_players THEN

        RAISE EXCEPTION
            'Game roster is already full';

    END IF;


    /*
     * ============================================================
     * 8. COUNT TEAM PLAYERS
     * ============================================================
     */

    SELECT
        COUNT(*) FILTER (WHERE gp.team = 'TEAM_A'),
        COUNT(*) FILTER (WHERE gp.team = 'TEAM_B')
    INTO
        v_team_a_count,
        v_team_b_count
    FROM public.game_players gp
    WHERE gp.game_id = p_game_id;


    /*
     * ============================================================
     * 9. AUTOMATIC TEAM BALANCING
     *
     * Rules:
     *
     * TEAM A < TEAM B  -> TEAM A
     * TEAM B < TEAM A  -> TEAM B
     * Equal            -> TEAM A
     *
     * Capacity is checked as an additional safety layer.
     * ============================================================
     */

    IF v_team_a_count < v_team_b_count
       AND v_team_a_count < v_team_capacity THEN

        v_selected_team := 'TEAM_A';

    ELSIF v_team_b_count < v_team_a_count
       AND v_team_b_count < v_team_capacity THEN

        v_selected_team := 'TEAM_B';

    ELSIF v_team_a_count = v_team_b_count
       AND v_team_a_count < v_team_capacity THEN

        v_selected_team := 'TEAM_A';

    ELSIF v_team_a_count < v_team_capacity THEN

        v_selected_team := 'TEAM_A';

    ELSIF v_team_b_count < v_team_capacity THEN

        v_selected_team := 'TEAM_B';

    ELSE

        RAISE EXCEPTION
            'Both teams are already full';

    END IF;


    /*
     * ============================================================
     * 10. LOCK PLAYER WALLET
     *
     * Even free games keep this lock harmlessly; for paid games
     * it guarantees balance consistency.
     * ============================================================
     */

    SELECT pd.wallet_balance
    INTO v_balance
    FROM public.player_details pd
    WHERE pd.user_id = p_user_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Player wallet not found';

    END IF;


    /*
     * ============================================================
     * 11. FREE GAME
     *
     * No wallet transaction required.
     * ============================================================
     */

    IF v_entry_fee = 0 THEN

        INSERT INTO public.game_players (
            game_id,
            user_id,
            team,
            position
        )
        VALUES (
            p_game_id,
            p_user_id,
            v_selected_team,
            p_position
        )
        RETURNING id
        INTO v_game_player_id;


        RETURN v_game_player_id;

    END IF;


    /*
     * ============================================================
     * 12. WALLET BALANCE CHECK
     * ============================================================
     */

    IF v_balance < v_entry_fee THEN

        RAISE EXCEPTION
            'Insufficient wallet balance. Required: Rs. %, Available: Rs. %',
            v_entry_fee,
            v_balance;

    END IF;


    /*
     * ============================================================
     * 13. CREATE PAYMENT TRANSACTION
     *
     * Existing wallet trigger handles the actual balance deduction.
     * ============================================================
     */

    INSERT INTO public.transactions (
        user_id,
        type,
        amount,
        balance_after,
        status,
        description,
        reference_id
    )
    VALUES (
        p_user_id,
        'PAYMENT',
        v_entry_fee,
        0,
        'SUCCESS',
        'Game entry fee payment',
        p_game_id
    )
    RETURNING id
    INTO v_tx_id;


    /*
     * ============================================================
     * 14. INSERT PLAYER INTO SELECTED TEAM
     *
     * IMPORTANT:
     * TEAM IS DATABASE GENERATED.
     * POSITION COMES FROM VALIDATED ENUM.
     * ============================================================
     */

    INSERT INTO public.game_players (
        game_id,
        user_id,
        team,
        position
    )
    VALUES (
        p_game_id,
        p_user_id,
        v_selected_team,
        p_position
    )
    RETURNING id
    INTO v_game_player_id;


    /*
     * ============================================================
     * 15. RETURN ROSTER ID
     * ============================================================
     */

    RETURN v_game_player_id;

END;
$$;


ALTER FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position public.football_position) OWNER TO postgres;

--
-- TOC entry 541 (class 1255 OID 19746)
-- Name: logout_all_sessions(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logout_all_sessions(p_user_id character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_count INTEGER;

BEGIN

    UPDATE public.user_sessions

    SET
        is_revoked = TRUE

    WHERE
        user_id = p_user_id

        AND is_revoked = FALSE;


    GET DIAGNOSTICS
        v_count = ROW_COUNT;


    RETURN v_count;

END;
$$;


ALTER FUNCTION public.logout_all_sessions(p_user_id character varying) OWNER TO postgres;

--
-- TOC entry 356 (class 1255 OID 19745)
-- Name: logout_session(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logout_session(p_user_id character varying, p_session_id character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_updated INTEGER;

BEGIN

    UPDATE public.user_sessions

    SET
        is_revoked = TRUE

    WHERE
        id = p_session_id

        AND user_id = p_user_id

        AND is_revoked = FALSE

        AND expires_at > CURRENT_TIMESTAMP;


    GET DIAGNOSTICS
        v_updated = ROW_COUNT;


    RETURN v_updated = 1;

END;
$$;


ALTER FUNCTION public.logout_session(p_user_id character varying, p_session_id character varying) OWNER TO postgres;

--
-- TOC entry 490 (class 1255 OID 18936)
-- Name: prevent_role_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_role_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF OLD.role_id IS DISTINCT FROM NEW.role_id THEN

        RAISE EXCEPTION
            'ROLE CHANGE NOT ALLOWED: User % already has a permanent role.',
            OLD.id
            USING ERRCODE = '42501';

    END IF;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.prevent_role_change() OWNER TO postgres;

--
-- TOC entry 575 (class 1255 OID 19676)
-- Name: prevent_user_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_user_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    RAISE EXCEPTION
        'USER ACCOUNT DELETION IS NOT ALLOWED. Use account suspension instead.'
        USING ERRCODE = '42501';

    RETURN OLD;

END;
$$;


ALTER FUNCTION public.prevent_user_delete() OWNER TO postgres;

--
-- TOC entry 474 (class 1255 OID 18395)
-- Name: promote_from_waitlist(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.promote_from_waitlist() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_next_waitlisted RECORD;
BEGIN
    SELECT * INTO v_next_waitlisted
    FROM game_waitlist
    WHERE game_id = OLD.game_id
    ORDER BY waitlist_order ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF FOUND THEN
        INSERT INTO game_players (game_id, user_id, team, position)
        VALUES (OLD.game_id, v_next_waitlisted.user_id, OLD.team, v_next_waitlisted.position);

        DELETE FROM game_waitlist WHERE id = v_next_waitlisted.id;

        UPDATE game_waitlist
        SET waitlist_order = waitlist_order - 1
        WHERE game_id = OLD.game_id AND waitlist_order > v_next_waitlisted.waitlist_order;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.promote_from_waitlist() OWNER TO postgres;

--
-- TOC entry 580 (class 1255 OID 17939)
-- Name: protect_base_roles(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_base_roles() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'roles table is fixed (1=ADMIN, 2=MANAGER, 3=PLAYER) and cannot be modified or deleted from';
END;
$$;


ALTER FUNCTION public.protect_base_roles() OWNER TO postgres;

--
-- TOC entry 470 (class 1255 OID 18940)
-- Name: protect_owner_account(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_owner_account() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_is_owner BOOLEAN;
BEGIN

    -- Owner status admin_details se check hoga
    SELECT ad.is_owner
    INTO v_is_owner
    FROM public.admin_details ad
    WHERE ad.user_id = OLD.id;

    -- Agar ye owner account hai
    IF COALESCE(v_is_owner, FALSE) = TRUE THEN

        -- Owner ko suspend nahi kar sakte
        IF NEW.status = 'SUSPENDED' THEN
            RAISE EXCEPTION
                'OWNER PROTECTION: Owner cannot be suspended.'
                USING ERRCODE = '42501';
        END IF;

        -- Owner ka role ADMIN hi rahega
        IF NEW.role_id IS DISTINCT FROM 1 THEN
            RAISE EXCEPTION
                'OWNER PROTECTION: Owner role cannot be changed.'
                USING ERRCODE = '42501';
        END IF;

    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.protect_owner_account() OWNER TO postgres;

--
-- TOC entry 370 (class 1255 OID 18938)
-- Name: protect_owner_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_owner_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_is_owner BOOLEAN;
BEGIN

    SELECT ad.is_owner
    INTO v_is_owner
    FROM public.admin_details ad
    WHERE ad.user_id = OLD.id;

    IF COALESCE(v_is_owner, FALSE) = TRUE THEN
        RAISE EXCEPTION
            'OWNER ACCOUNT CANNOT BE DELETED: %',
            OLD.id
            USING ERRCODE = '42501';
    END IF;

    RETURN OLD;
END;
$$;


ALTER FUNCTION public.protect_owner_delete() OWNER TO postgres;

--
-- TOC entry 341 (class 1255 OID 18066)
-- Name: protect_owner_flag(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_owner_flag() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.is_owner = TRUE AND NEW.is_owner = FALSE THEN
        RAISE EXCEPTION 'Owner flag cannot be removed from the founder account';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.protect_owner_flag() OWNER TO postgres;

--
-- TOC entry 528 (class 1255 OID 18064)
-- Name: protect_owner_on_users(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.protect_owner_on_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_is_owner BOOLEAN;
BEGIN
    SELECT is_owner INTO v_is_owner FROM admin_details WHERE user_id = OLD.id;
    IF COALESCE(v_is_owner, FALSE) THEN
        IF NEW.status = 'SUSPENDED' THEN
            RAISE EXCEPTION 'Owner account can never be suspended';
        END IF;
        IF NEW.role_id <> 1 THEN
            RAISE EXCEPTION 'Owner account can never be demoted from ADMIN';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.protect_owner_on_users() OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 19744)
-- Name: record_failed_login(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.record_failed_login(p_user_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE public.users

    SET
        failed_login_count =
            failed_login_count + 1,

        locked_until =
            CASE

                WHEN failed_login_count + 1 >= 5

                THEN CURRENT_TIMESTAMP
                     + INTERVAL '15 minutes'

                ELSE locked_until

            END,

        updated_at = CURRENT_TIMESTAMP

    WHERE id = p_user_id
      AND status = 'ACTIVE';

END;
$$;


ALTER FUNCTION public.record_failed_login(p_user_id character varying) OWNER TO postgres;

--
-- TOC entry 508 (class 1255 OID 19743)
-- Name: record_successful_login(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.record_successful_login(p_user_id character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

    UPDATE public.users

    SET
        failed_login_count = 0,
        locked_until = NULL,
        last_login_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP

    WHERE id = p_user_id
      AND status = 'ACTIVE';

END;
$$;


ALTER FUNCTION public.record_successful_login(p_user_id character varying) OWNER TO postgres;

--
-- TOC entry 377 (class 1255 OID 19741)
-- Name: register_player(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.register_player(p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_city character varying DEFAULT 'Raipur'::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id VARCHAR(64);
    v_email VARCHAR(255);
    v_phone VARCHAR(32);
BEGIN
    v_email := LOWER(TRIM(p_email));
    v_phone := TRIM(p_phone);

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

    RETURN v_user_id;
END;
$$;


ALTER FUNCTION public.register_player(p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_city character varying) OWNER TO postgres;

--
-- TOC entry 504 (class 1255 OID 18781)
-- Name: reward_completed_challenge(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reward_completed_challenge() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_target INT;
    v_bonus NUMERIC(8,2);
    v_badge VARCHAR(64);
BEGIN
    SELECT target_count, reward_wallet_bonus, reward_badge
    INTO v_target, v_bonus, v_badge
    FROM challenges WHERE id = NEW.challenge_id;

    IF NEW.current_progress >= v_target AND NOT COALESCE(OLD.is_completed, FALSE) THEN
        NEW.is_completed := TRUE;
        NEW.completed_at := CURRENT_TIMESTAMP;

        INSERT INTO transactions (user_id, type, amount, balance_after, status, description, reference_id)
        VALUES (NEW.user_id, 'CHALLENGE_REWARD', v_bonus, 0, 'SUCCESS',
                'Challenge completed: ' || v_badge, NEW.challenge_id);

        UPDATE player_details
        SET badges = badges || to_jsonb(v_badge)
        WHERE user_id = NEW.user_id AND NOT (badges @> to_jsonb(v_badge));
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.reward_completed_challenge() OWNER TO postgres;

--
-- TOC entry 434 (class 1255 OID 17929)
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    NEW.updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;

END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

--
-- TOC entry 554 (class 1255 OID 19828)
-- Name: set_wallet_pin(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_wallet_pin(p_user_id character varying, p_pin character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
      BEGIN
          UPDATE public.player_details
          SET wallet_pin_hash = crypt(p_pin, gen_salt('bf')),
              wallet_pin_set_at = CURRENT_TIMESTAMP,
              wallet_pin_failed_attempts = 0,
              wallet_pin_locked_until = NULL,
              updated_at = CURRENT_TIMESTAMP
          WHERE user_id = p_user_id;

          IF NOT FOUND THEN
              INSERT INTO public.player_details (user_id, wallet_pin_hash, wallet_pin_set_at)
              VALUES (p_user_id, crypt(p_pin, gen_salt('bf')), CURRENT_TIMESTAMP);
          END IF;
      END;
      $$;


ALTER FUNCTION public.set_wallet_pin(p_user_id character varying, p_pin character varying) OWNER TO postgres;

--
-- TOC entry 499 (class 1255 OID 19824)
-- Name: settle_wallet_payment(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.settle_wallet_payment(p_payment_order_id character varying, p_provider_payment_id character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
      DECLARE
          v_user_id VARCHAR(64);
          v_amount_paise INT;
          v_amount_rupees NUMERIC(10,2);
          v_order_status VARCHAR(32);
          v_tx_id VARCHAR(64);
          v_new_balance NUMERIC(10,2);
      BEGIN
          -- 1. Fetch payment order with lock
          SELECT user_id, amount_paise, status INTO v_user_id, v_amount_paise, v_order_status
          FROM public.payment_orders
          WHERE id = p_payment_order_id FOR UPDATE;

          IF NOT FOUND THEN
              RAISE EXCEPTION 'Payment order % not found', p_payment_order_id;
          END IF;

          -- 2. If already completed, return existing transaction ID
          IF v_order_status = 'COMPLETED' THEN
              SELECT id INTO v_tx_id FROM public.wallet_transactions
              WHERE reference_id = p_payment_order_id LIMIT 1;
              RETURN v_tx_id;
          END IF;

          v_amount_rupees := (v_amount_paise::NUMERIC / 100.0);

          -- 3. Update player_details wallet_balance
          UPDATE public.player_details
          SET wallet_balance = COALESCE(wallet_balance, 0.00) + v_amount_rupees,
              updated_at = CURRENT_TIMESTAMP
          WHERE user_id = v_user_id
          RETURNING wallet_balance INTO v_new_balance;

          IF NOT FOUND THEN
              INSERT INTO public.player_details (user_id, wallet_balance)
              VALUES (v_user_id, v_amount_rupees)
              RETURNING wallet_balance INTO v_new_balance;
          END IF;

          -- 4. Record wallet_transaction
          INSERT INTO public.wallet_transactions (
              user_id,
              transaction_type,
              amount,
              balance_after,
              description,
              status,
              reference_id,
              provider_payment_id
          ) VALUES (
              v_user_id,
              'TOPUP',
              v_amount_rupees,
              v_new_balance,
              'Wallet Top-Up via Razorpay',
              'SUCCESS',
              p_payment_order_id,
              p_provider_payment_id
          ) RETURNING id INTO v_tx_id;

          -- 5. Mark payment_order as COMPLETED
          UPDATE public.payment_orders
          SET status = 'COMPLETED',
              provider_payment_id = p_provider_payment_id,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = p_payment_order_id;

          RETURN v_tx_id;
      END;
      $$;


ALTER FUNCTION public.settle_wallet_payment(p_payment_order_id character varying, p_provider_payment_id character varying) OWNER TO postgres;

--
-- TOC entry 512 (class 1255 OID 18328)
-- Name: snapshot_game_creator_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.snapshot_game_creator_role() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT r.role_name INTO NEW.creator_role_name
    FROM users u JOIN roles r ON r.id = u.role_id
    WHERE u.id = NEW.creator_id;

    IF NEW.creator_role_name IS NULL THEN
        RAISE EXCEPTION 'Creator user % not found', NEW.creator_id;
    END IF;

    -- Rule: if creator is a PLAYER, they auto-occupy Slot #1 (TEAM_A).
    -- The actual insert into game_players happens app-side right after
    -- this insert returns, using the same game id.
    NEW.created_by_player := (NEW.creator_role_name = 'PLAYER');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.snapshot_game_creator_role() OWNER TO postgres;

--
-- TOC entry 467 (class 1255 OID 52735)
-- Name: switch_player_team(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.switch_player_team(p_user_id character varying, p_game_id character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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


ALTER FUNCTION public.switch_player_team(p_user_id character varying, p_game_id character varying) OWNER TO postgres;

--
-- TOC entry 550 (class 1255 OID 18360)
-- Name: sync_game_status_on_roster_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_game_status_on_roster_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_game_id VARCHAR(64);
    v_max INT;
    v_count INT;
    v_status match_status;
BEGIN
    v_game_id := COALESCE(NEW.game_id, OLD.game_id);
    SELECT max_players, status INTO v_max, v_status FROM games WHERE id = v_game_id;
    SELECT COUNT(*) INTO v_count FROM game_players WHERE game_id = v_game_id;

    IF v_status IN ('OPEN_FOR_JOINING', 'FULL') THEN
        IF v_count >= v_max THEN
            UPDATE games SET status = 'FULL' WHERE id = v_game_id AND status <> 'FULL';
        ELSE
            UPDATE games SET status = 'OPEN_FOR_JOINING' WHERE id = v_game_id AND status <> 'OPEN_FOR_JOINING';
        END IF;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.sync_game_status_on_roster_change() OWNER TO postgres;

--
-- TOC entry 438 (class 1255 OID 18738)
-- Name: sync_poll_votes_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_poll_votes_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE poll_options SET votes_count = votes_count + 1 WHERE id = NEW.option_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE poll_options SET votes_count = GREATEST(0, votes_count - 1) WHERE id = OLD.option_id;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.sync_poll_votes_count() OWNER TO postgres;

--
-- TOC entry 307 (class 1255 OID 18656)
-- Name: sync_post_likes_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_post_likes_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.sync_post_likes_count() OWNER TO postgres;

--
-- TOC entry 552 (class 1255 OID 18544)
-- Name: sync_tournament_team_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_tournament_team_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tournament_id VARCHAR(64);
    v_max INT;
    v_count INT;
BEGIN
    v_tournament_id := COALESCE(NEW.tournament_id, OLD.tournament_id);
    SELECT max_teams INTO v_max FROM tournaments WHERE id = v_tournament_id FOR UPDATE;
    SELECT COUNT(*) INTO v_count FROM tournament_teams WHERE tournament_id = v_tournament_id;

    IF TG_OP = 'INSERT' AND v_count > v_max THEN
        RAISE EXCEPTION 'Tournament already has the maximum number of teams (%)', v_max;
    END IF;

    UPDATE tournaments SET registered_teams_count = v_count WHERE id = v_tournament_id;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.sync_tournament_team_count() OWNER TO postgres;

--
-- TOC entry 531 (class 1255 OID 19829)
-- Name: verify_wallet_pin(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_wallet_pin(p_user_id character varying, p_pin character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
      DECLARE
          v_hash TEXT;
      BEGIN
          SELECT wallet_pin_hash INTO v_hash
          FROM public.player_details
          WHERE user_id = p_user_id;

          IF v_hash IS NULL THEN
              RETURN FALSE;
          END IF;

          RETURN (v_hash = crypt(p_pin, v_hash));
      END;
      $$;


ALTER FUNCTION public.verify_wallet_pin(p_user_id character varying, p_pin character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 228 (class 1259 OID 17985)
-- Name: admin_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_details (
    user_id character varying(64) NOT NULL,
    admin_type public.admin_type DEFAULT 'OPS_ADMIN'::public.admin_type NOT NULL,
    is_owner boolean DEFAULT false NOT NULL,
    designation character varying(120),
    created_by_admin_id character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_details OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 18844)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    admin_id character varying(64),
    admin_name character varying(120) NOT NULL,
    action character varying(64) NOT NULL,
    target character varying(150) NOT NULL,
    details text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 18843)
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO postgres;

--
-- TOC entry 6234 (class 0 OID 0)
-- Dependencies: 260
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- TOC entry 269 (class 1259 OID 19864)
-- Name: cctv_cameras; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cctv_cameras (
    id character varying(64) DEFAULT ('cam_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    club_id character varying(64) NOT NULL,
    court_id character varying(64),
    name character varying(150) NOT NULL,
    rtsp_url_encrypted text NOT NULL,
    ip_address character varying(64),
    port integer DEFAULT 554,
    is_enabled boolean DEFAULT true NOT NULL,
    status character varying(32) DEFAULT 'ONLINE'::character varying NOT NULL,
    last_health_check_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    encrypted_connection_reference text,
    health_status character varying(32) DEFAULT 'ONLINE'::character varying,
    camera_type character varying(32) DEFAULT 'RTSP_DOME'::character varying,
    connection_type character varying(32) DEFAULT 'RTSP'::character varying,
    stream_reference character varying(255),
    created_by character varying(64)
);


ALTER TABLE public.cctv_cameras OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 19931)
-- Name: cctv_recording_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cctv_recording_events (
    id character varying(64) DEFAULT ('ev_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    recording_id character varying(64) NOT NULL,
    event_type character varying(64) NOT NULL,
    actor_user_id character varying(64),
    event_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.cctv_recording_events OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 19893)
-- Name: cctv_recordings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cctv_recordings (
    id character varying(64) DEFAULT ('rec_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    game_id character varying(64) NOT NULL,
    club_id character varying(64) NOT NULL,
    court_id character varying(64),
    camera_id character varying(64),
    start_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    scheduled_match_end timestamp with time zone NOT NULL,
    stop_deadline timestamp with time zone NOT NULL,
    actual_stop_time timestamp with time zone,
    s3_object_key character varying(512),
    status character varying(32) DEFAULT 'RECORDING'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    recording_status character varying(32) DEFAULT 'RECORDING'::character varying,
    post_match_stop_at timestamp with time zone,
    scheduled_match_end_at timestamp with time zone
);


ALTER TABLE public.cctv_recordings OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 18759)
-- Name: challenge_progress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.challenge_progress (
    challenge_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    current_progress integer DEFAULT 0 NOT NULL,
    is_completed boolean DEFAULT false NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT challenge_progress_current_progress_check CHECK ((current_progress >= 0))
);


ALTER TABLE public.challenge_progress OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 18740)
-- Name: challenges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.challenges (
    id character varying(64) DEFAULT ('ch_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    title character varying(150) NOT NULL,
    description text NOT NULL,
    target_count integer DEFAULT 5 NOT NULL,
    reward_badge character varying(64) NOT NULL,
    reward_wallet_bonus numeric(8,2) DEFAULT 200.00 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT challenges_reward_wallet_bonus_check CHECK (((reward_wallet_bonus >= (0)::numeric) AND (reward_wallet_bonus <= (350)::numeric))),
    CONSTRAINT challenges_target_count_check CHECK ((target_count > 0))
);


ALTER TABLE public.challenges OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 18160)
-- Name: club_managers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.club_managers (
    club_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.club_managers OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 18126)
-- Name: clubs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clubs (
    id character varying(64) DEFAULT ('clb_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    name character varying(150) NOT NULL,
    address text NOT NULL,
    city character varying(64) NOT NULL,
    latitude numeric(10,6),
    longitude numeric(10,6),
    open_time time without time zone DEFAULT '06:00:00'::time without time zone NOT NULL,
    close_time time without time zone DEFAULT '23:00:00'::time without time zone NOT NULL,
    amenities jsonb DEFAULT '["Floodlights", "Washrooms", "Parking"]'::jsonb NOT NULL,
    status public.venue_status DEFAULT 'PENDING'::public.venue_status NOT NULL,
    club_image_url character varying(512),
    rating numeric(3,2) DEFAULT 5.00 NOT NULL,
    reviews_count integer DEFAULT 0 NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_club_hours CHECK ((close_time > open_time)),
    CONSTRAINT clubs_latitude_check CHECK (((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric))),
    CONSTRAINT clubs_longitude_check CHECK (((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric))),
    CONSTRAINT clubs_rating_check CHECK (((rating >= 0.0) AND (rating <= 5.0))),
    CONSTRAINT clubs_reviews_count_check CHECK ((reviews_count >= 0))
);


ALTER TABLE public.clubs OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 18611)
-- Name: community_posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.community_posts (
    id character varying(64) DEFAULT ('post_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    city character varying(64) NOT NULL,
    author_id character varying(64) NOT NULL,
    content text NOT NULL,
    image_url character varying(512),
    likes_count integer DEFAULT 0 NOT NULL,
    tags jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT community_posts_content_check CHECK ((char_length(content) > 0)),
    CONSTRAINT community_posts_likes_count_check CHECK ((likes_count >= 0))
);


ALTER TABLE public.community_posts OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 18222)
-- Name: court_bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.court_bookings (
    id character varying(64) DEFAULT ('bkg_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    court_id character varying(64) NOT NULL,
    club_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    booking_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    amount_paid numeric(10,2) NOT NULL,
    status public.booking_status DEFAULT 'CONFIRMED'::public.booking_status NOT NULL,
    refund_tier character varying(16) DEFAULT '100%'::character varying,
    refund_amount numeric(10,2) DEFAULT 0.00,
    cancellation_reason text,
    rejection_reason text,
    refunded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_booking_times CHECK ((end_time > start_time)),
    CONSTRAINT chk_refund_not_exceed CHECK ((refund_amount <= amount_paid)),
    CONSTRAINT court_bookings_amount_paid_check CHECK ((amount_paid >= (0)::numeric)),
    CONSTRAINT court_bookings_refund_amount_check CHECK ((refund_amount >= (0)::numeric))
);


ALTER TABLE public.court_bookings OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 18180)
-- Name: courts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courts (
    id character varying(64) DEFAULT ('crt_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    club_id character varying(64) NOT NULL,
    name character varying(120) NOT NULL,
    environment public.pitch_environment DEFAULT 'Outdoor'::public.pitch_environment NOT NULL,
    surface public.pitch_surface DEFAULT '3G Turf'::public.pitch_surface NOT NULL,
    base_price numeric(10,2) NOT NULL,
    peak_multiplier numeric(3,2) DEFAULT 1.50 NOT NULL,
    weekend_multiplier numeric(3,2) DEFAULT 1.75 NOT NULL,
    peak_window_start time without time zone DEFAULT '17:00:00'::time without time zone NOT NULL,
    peak_window_end time without time zone DEFAULT '21:00:00'::time without time zone NOT NULL,
    status public.pitch_status DEFAULT 'AVAILABLE'::public.pitch_status NOT NULL,
    image_url character varying(512),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT courts_base_price_check CHECK ((base_price >= (0)::numeric)),
    CONSTRAINT courts_peak_multiplier_check CHECK ((peak_multiplier >= 1.0)),
    CONSTRAINT courts_weekend_multiplier_check CHECK ((weekend_multiplier >= 1.0))
);


ALTER TABLE public.courts OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 28192)
-- Name: game_activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_activity_logs (
    id character varying(64) DEFAULT ('act_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    game_id character varying(64) NOT NULL,
    actor_id character varying(64),
    actor_name character varying(150),
    actor_role_name character varying(32) DEFAULT 'PLAYER'::character varying NOT NULL,
    action_type character varying(64) NOT NULL,
    details text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.game_activity_logs OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 18331)
-- Name: game_players; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_players (
    id bigint NOT NULL,
    game_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    team public.team_side NOT NULL,
    "position" public.football_position DEFAULT 'MID'::public.football_position NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    payment_status character varying(32) DEFAULT 'PAID'::character varying
);


ALTER TABLE public.game_players OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 18330)
-- Name: game_players_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.game_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.game_players_id_seq OWNER TO postgres;

--
-- TOC entry 6235 (class 0 OID 0)
-- Dependencies: 239
-- Name: game_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.game_players_id_seq OWNED BY public.game_players.id;


--
-- TOC entry 272 (class 1259 OID 28159)
-- Name: game_slot_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_slot_requests (
    id character varying(64) DEFAULT ('req_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    game_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    "position" character varying(16) DEFAULT 'MID'::character varying NOT NULL,
    status character varying(32) DEFAULT 'PENDING'::character varying NOT NULL,
    rejection_reason text,
    payment_status character varying(32) DEFAULT 'PAID'::character varying NOT NULL,
    entry_fee numeric(10,2) DEFAULT 0.00 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.game_slot_requests OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 18897)
-- Name: game_videos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_videos (
    id character varying(64) DEFAULT ('vid_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    game_id character varying(64) NOT NULL,
    club_id character varying(64) NOT NULL,
    court_id character varying(64),
    title character varying(255) NOT NULL,
    video_url character varying(512) NOT NULL,
    uploaded_by_id character varying(64),
    status character varying(32) DEFAULT 'AVAILABLE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.game_videos OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 18363)
-- Name: game_waitlist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_waitlist (
    id bigint NOT NULL,
    game_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    team_preference public.team_side,
    "position" public.football_position DEFAULT 'MID'::public.football_position NOT NULL,
    waitlist_order integer DEFAULT 1 NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT game_waitlist_waitlist_order_check CHECK ((waitlist_order > 0))
);


ALTER TABLE public.game_waitlist OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 18362)
-- Name: game_waitlist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.game_waitlist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.game_waitlist_id_seq OWNER TO postgres;

--
-- TOC entry 6236 (class 0 OID 0)
-- Dependencies: 241
-- Name: game_waitlist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.game_waitlist_id_seq OWNED BY public.game_waitlist.id;


--
-- TOC entry 238 (class 1259 OID 18273)
-- Name: games; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.games (
    id character varying(64) DEFAULT ('gam_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    title character varying(200) NOT NULL,
    club_id character varying(64),
    court_id character varying(64),
    creator_id character varying(64) NOT NULL,
    creator_role_name character varying(32) NOT NULL,
    created_by_player boolean DEFAULT true NOT NULL,
    format public.match_format DEFAULT '11v11'::public.match_format NOT NULL,
    max_players integer DEFAULT 22 NOT NULL,
    entry_fee numeric(10,2) DEFAULT 200.00 NOT NULL,
    skill_requirement public.skill_level DEFAULT 'Intermediate'::public.skill_level,
    privacy public.match_privacy DEFAULT 'PUBLIC'::public.match_privacy NOT NULL,
    match_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    status public.match_status DEFAULT 'OPEN_FOR_JOINING'::public.match_status NOT NULL,
    team_a_score integer,
    team_b_score integer,
    winner_team character varying(16) DEFAULT NULL::character varying,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_game_times CHECK ((end_time > start_time)),
    CONSTRAINT games_entry_fee_check CHECK ((entry_fee >= (0)::numeric)),
    CONSTRAINT games_max_players_check CHECK (((max_players >= 2) AND ((max_players % 2) = 0))),
    CONSTRAINT games_team_a_score_check CHECK (((team_a_score IS NULL) OR (team_a_score >= 0))),
    CONSTRAINT games_team_b_score_check CHECK (((team_b_score IS NULL) OR (team_b_score >= 0)))
);


ALTER TABLE public.games OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 18398)
-- Name: live_score_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.live_score_logs (
    id bigint NOT NULL,
    game_id character varying(64) NOT NULL,
    team_a_score integer DEFAULT 0 NOT NULL,
    team_b_score integer DEFAULT 0 NOT NULL,
    updated_by_user_id character varying(64),
    is_final boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT live_score_logs_team_a_score_check CHECK ((team_a_score >= 0)),
    CONSTRAINT live_score_logs_team_b_score_check CHECK ((team_b_score >= 0))
);


ALTER TABLE public.live_score_logs OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 18397)
-- Name: live_score_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.live_score_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.live_score_logs_id_seq OWNER TO postgres;

--
-- TOC entry 6237 (class 0 OID 0)
-- Dependencies: 243
-- Name: live_score_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.live_score_logs_id_seq OWNED BY public.live_score_logs.id;


--
-- TOC entry 229 (class 1259 OID 18007)
-- Name: manager_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manager_details (
    user_id character varying(64) NOT NULL,
    created_by_admin_id character varying(64) NOT NULL,
    employee_code character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.manager_details OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 18783)
-- Name: match_disputes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_disputes (
    id character varying(64) DEFAULT ('dsp_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    game_id character varying(64) NOT NULL,
    reported_by_id character varying(64) NOT NULL,
    disputed_score character varying(32) NOT NULL,
    reason text NOT NULL,
    status public.dispute_status DEFAULT 'OPEN'::public.dispute_status NOT NULL,
    winner_override character varying(16),
    score_override character varying(32),
    adjudicator_notes text,
    dismissal_reason text,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.match_disputes OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 18867)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id character varying(64) DEFAULT ('notif_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    user_id character varying(64),
    title character varying(200) NOT NULL,
    message text NOT NULL,
    link_url character varying(255),
    club_id character varying(64),
    game_id character varying(64),
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 18072)
-- Name: otp_verifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp_verifications (
    id bigint NOT NULL,
    user_id character varying(64),
    identifier character varying(255) NOT NULL,
    channel public.otp_channel NOT NULL,
    purpose public.otp_purpose NOT NULL,
    otp_hash character varying(255) NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 5 NOT NULL,
    is_used boolean DEFAULT false NOT NULL,
    used_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_otp_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT otp_verifications_attempt_count_check CHECK ((attempt_count >= 0))
);


ALTER TABLE public.otp_verifications OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 18071)
-- Name: otp_verifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.otp_verifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.otp_verifications_id_seq OWNER TO postgres;

--
-- TOC entry 6238 (class 0 OID 0)
-- Dependencies: 231
-- Name: otp_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.otp_verifications_id_seq OWNED BY public.otp_verifications.id;


--
-- TOC entry 266 (class 1259 OID 19755)
-- Name: payment_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_orders (
    id character varying(64) DEFAULT ('pay_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    user_id character varying(64) NOT NULL,
    provider character varying(32) NOT NULL,
    provider_order_id character varying(128),
    provider_payment_id character varying(128),
    idempotency_key character varying(128) NOT NULL,
    amount_paise bigint NOT NULL,
    currency character(3) DEFAULT 'INR'::bpchar NOT NULL,
    purpose character varying(32) DEFAULT 'WALLET_TOPUP'::character varying NOT NULL,
    status character varying(24) DEFAULT 'CREATED'::character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    paid_at timestamp with time zone,
    expires_at timestamp with time zone DEFAULT (CURRENT_TIMESTAMP + '00:05:00'::interval) NOT NULL,
    CONSTRAINT payment_orders_amount_paise_check CHECK (((amount_paise > 0) AND (amount_paise <= 5000000))),
    CONSTRAINT payment_orders_currency_check CHECK ((currency = 'INR'::bpchar)),
    CONSTRAINT payment_orders_purpose_check CHECK (((purpose)::text = 'WALLET_TOPUP'::text)),
    CONSTRAINT payment_orders_status_check CHECK (((status)::text = ANY ((ARRAY['CREATED'::character varying, 'PENDING'::character varying, 'PAID'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying, 'REFUNDED'::character varying, 'EXPIRED'::character varying])::text[])))
);


ALTER TABLE public.payment_orders OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 19798)
-- Name: payment_webhook_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_webhook_events (
    id bigint NOT NULL,
    provider character varying(32) NOT NULL,
    event_id character varying(255) NOT NULL,
    event_type character varying(128) NOT NULL,
    payment_order_id character varying(64),
    signature_verified boolean DEFAULT false NOT NULL,
    payload jsonb NOT NULL,
    processing_status character varying(24) DEFAULT 'RECEIVED'::character varying NOT NULL,
    received_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    processed_at timestamp with time zone,
    CONSTRAINT payment_webhook_events_processing_status_check CHECK (((processing_status)::text = ANY ((ARRAY['RECEIVED'::character varying, 'PROCESSED'::character varying, 'FAILED'::character varying, 'IGNORED'::character varying])::text[])))
);


ALTER TABLE public.payment_webhook_events OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 19797)
-- Name: payment_webhook_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_webhook_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_webhook_events_id_seq OWNER TO postgres;

--
-- TOC entry 6239 (class 0 OID 0)
-- Dependencies: 267
-- Name: payment_webhook_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_webhook_events_id_seq OWNED BY public.payment_webhook_events.id;


--
-- TOC entry 230 (class 1259 OID 18026)
-- Name: player_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_details (
    user_id character varying(64) NOT NULL,
    "position" public.football_position DEFAULT 'CM'::public.football_position NOT NULL,
    preferred_foot public.foot_preference DEFAULT 'Right'::public.foot_preference NOT NULL,
    skill_level public.skill_level DEFAULT 'Intermediate'::public.skill_level NOT NULL,
    elo_rating integer DEFAULT 1500 NOT NULL,
    ovr_rating integer DEFAULT 70 NOT NULL,
    badges jsonb DEFAULT '["NewRecruit"]'::jsonb NOT NULL,
    wallet_balance numeric(12,2) DEFAULT 0.00 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    wallet_pin_hash character varying(255),
    wallet_pin_set_at timestamp with time zone,
    wallet_pin_failed_attempts integer DEFAULT 0 NOT NULL,
    wallet_pin_locked_until timestamp with time zone,
    secondary_position character varying(16),
    CONSTRAINT player_details_elo_rating_check CHECK ((elo_rating >= 0)),
    CONSTRAINT player_details_ovr_rating_check CHECK (((ovr_rating >= 40) AND (ovr_rating <= 99))),
    CONSTRAINT player_details_wallet_balance_check CHECK (((wallet_balance >= (0)::numeric) AND (wallet_balance <= 200000.00)))
);


ALTER TABLE public.player_details OWNER TO postgres;

--
-- TOC entry 6240 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN player_details.wallet_pin_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_details.wallet_pin_hash IS 'bcrypt hash (via pgcrypto crypt/gen_salt) of the player''s 6-digit wallet PIN. NULL until they set one. Never store the raw PIN anywhere.';


--
-- TOC entry 245 (class 1259 OID 18427)
-- Name: player_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_stats (
    user_id character varying(64) NOT NULL,
    matches_played integer DEFAULT 0 NOT NULL,
    wins integer DEFAULT 0 NOT NULL,
    draws integer DEFAULT 0 NOT NULL,
    losses integer DEFAULT 0 NOT NULL,
    clean_sheets integer DEFAULT 0 NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    win_rate integer DEFAULT 0 NOT NULL,
    goals_scored integer DEFAULT 0 NOT NULL,
    assists integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_stats_sum CHECK ((((wins + draws) + losses) <= matches_played)),
    CONSTRAINT player_stats_assists_check CHECK ((assists >= 0)),
    CONSTRAINT player_stats_clean_sheets_check CHECK ((clean_sheets >= 0)),
    CONSTRAINT player_stats_draws_check CHECK ((draws >= 0)),
    CONSTRAINT player_stats_goals_scored_check CHECK ((goals_scored >= 0)),
    CONSTRAINT player_stats_losses_check CHECK ((losses >= 0)),
    CONSTRAINT player_stats_matches_played_check CHECK ((matches_played >= 0)),
    CONSTRAINT player_stats_points_check CHECK ((points >= 0)),
    CONSTRAINT player_stats_win_rate_check CHECK (((win_rate >= 0) AND (win_rate <= 100))),
    CONSTRAINT player_stats_wins_check CHECK ((wins >= 0))
);


ALTER TABLE public.player_stats OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 18695)
-- Name: poll_options; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.poll_options (
    id character varying(64) DEFAULT ('opt_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    poll_id character varying(64) NOT NULL,
    text character varying(255) NOT NULL,
    votes_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT poll_options_votes_count_check CHECK ((votes_count >= 0))
);


ALTER TABLE public.poll_options OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 18712)
-- Name: poll_votes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.poll_votes (
    poll_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    option_id character varying(64) NOT NULL,
    voted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.poll_votes OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 18683)
-- Name: polls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.polls (
    id character varying(64) DEFAULT ('poll_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    city character varying(64) NOT NULL,
    question text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.polls OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 18658)
-- Name: post_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_comments (
    id character varying(64) DEFAULT ('cm_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    post_id character varying(64) NOT NULL,
    author_id character varying(64) NOT NULL,
    text text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT post_comments_text_check CHECK ((char_length(text) > 0))
);


ALTER TABLE public.post_comments OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 18638)
-- Name: post_likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_likes (
    post_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.post_likes OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 17930)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id smallint NOT NULL,
    role_name character varying(32) NOT NULL,
    description character varying(255)
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 18811)
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.support_tickets (
    id character varying(64) DEFAULT ('tk_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 12)) NOT NULL,
    user_id character varying(64) NOT NULL,
    subject character varying(255) NOT NULL,
    description text,
    category character varying(64) DEFAULT 'GENERAL'::character varying NOT NULL,
    priority public.ticket_priority DEFAULT 'MEDIUM'::public.ticket_priority NOT NULL,
    status public.ticket_status DEFAULT 'OPEN'::public.ticket_status NOT NULL,
    assigned_staff_id character varying(64),
    resolution_notes text,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.support_tickets OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 18546)
-- Name: tournament_bracket_matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournament_bracket_matches (
    id character varying(64) DEFAULT ('tbm_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    tournament_id character varying(64) NOT NULL,
    round_name character varying(32) NOT NULL,
    team_a_id character varying(64),
    team_b_id character varying(64),
    score character varying(32) DEFAULT 'TBD'::character varying,
    winner_team_id character varying(64),
    match_order integer DEFAULT 1 NOT NULL,
    CONSTRAINT chk_distinct_teams CHECK (((team_a_id)::text IS DISTINCT FROM (team_b_id)::text)),
    CONSTRAINT chk_winner_is_participant CHECK (((winner_team_id IS NULL) OR (((winner_team_id)::text = (team_a_id)::text) OR ((winner_team_id)::text = (team_b_id)::text))))
);


ALTER TABLE public.tournament_bracket_matches OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 18513)
-- Name: tournament_teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournament_teams (
    id character varying(64) DEFAULT ('tm_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    tournament_id character varying(64) NOT NULL,
    name character varying(120) NOT NULL,
    captain_id character varying(64) NOT NULL,
    logo character varying(64) DEFAULT '⚡'::character varying,
    status character varying(32) DEFAULT 'CONFIRMED'::character varying NOT NULL,
    registered_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tournament_teams OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 18472)
-- Name: tournaments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tournaments (
    id character varying(64) DEFAULT ('trn_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    title character varying(200) NOT NULL,
    tagline character varying(255),
    club_id character varying(64),
    city character varying(64) NOT NULL,
    format public.tournament_format DEFAULT 'Knockout'::public.tournament_format NOT NULL,
    banner_url character varying(512),
    start_date date NOT NULL,
    end_date date NOT NULL,
    entry_fee numeric(10,2) DEFAULT 2500.00 NOT NULL,
    prize_pool character varying(150),
    max_teams integer DEFAULT 8 NOT NULL,
    registered_teams_count integer DEFAULT 0 NOT NULL,
    status public.tournament_status DEFAULT 'UPCOMING'::public.tournament_status NOT NULL,
    champion_team_id character varying(64) DEFAULT NULL::character varying,
    rules jsonb DEFAULT '[]'::jsonb NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_registered_lte_max CHECK ((registered_teams_count <= max_teams)),
    CONSTRAINT chk_tournament_dates CHECK ((end_date >= start_date)),
    CONSTRAINT tournaments_entry_fee_check CHECK ((entry_fee >= (0)::numeric)),
    CONSTRAINT tournaments_max_teams_check CHECK ((max_teams >= 2)),
    CONSTRAINT tournaments_registered_teams_count_check CHECK ((registered_teams_count >= 0))
);


ALTER TABLE public.tournaments OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 18581)
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transactions (
    id character varying(64) DEFAULT ('tx_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    user_id character varying(64) NOT NULL,
    type public.transaction_type NOT NULL,
    amount numeric(10,2) NOT NULL,
    balance_after numeric(12,2) NOT NULL,
    status public.transaction_status DEFAULT 'SUCCESS'::public.transaction_status NOT NULL,
    description text,
    reference_id character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_topup_max CHECK (((type <> 'WALLET_TOPUP'::public.transaction_type) OR (amount <= 50000.00))),
    CONSTRAINT transactions_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT transactions_balance_after_check CHECK (((balance_after >= (0)::numeric) AND (balance_after <= 200000.00)))
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 19716)
-- Name: user_identity_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_identity_history (
    id bigint NOT NULL,
    user_id character varying(64) NOT NULL,
    identity_type character varying(10) NOT NULL,
    identity_value character varying(255) NOT NULL,
    normalized_value character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_identity_type CHECK (((identity_type)::text = ANY ((ARRAY['EMAIL'::character varying, 'PHONE'::character varying])::text[])))
);


ALTER TABLE public.user_identity_history OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 19715)
-- Name: user_identity_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_identity_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_identity_history_id_seq OWNER TO postgres;

--
-- TOC entry 6241 (class 0 OID 0)
-- Dependencies: 264
-- Name: user_identity_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_identity_history_id_seq OWNED BY public.user_identity_history.id;


--
-- TOC entry 233 (class 1259 OID 18105)
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sessions (
    id character varying(64) DEFAULT ('sess_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 20)) NOT NULL,
    user_id character varying(64) NOT NULL,
    refresh_token_hash character varying(255) NOT NULL,
    device_info text,
    ip_address character varying(64),
    is_revoked boolean DEFAULT false NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 17942)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id character varying(64) DEFAULT ('usr_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    role_id smallint NOT NULL,
    name character varying(120) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(32) NOT NULL,
    password_hash character varying(255) NOT NULL,
    status public.user_status DEFAULT 'ACTIVE'::public.user_status NOT NULL,
    city character varying(64) DEFAULT 'Raipur'::character varying NOT NULL,
    bio text,
    profile_image_url character varying(512) DEFAULT '/assets/images/avatars/default-avatar.jpg'::character varying,
    email_verified boolean DEFAULT false NOT NULL,
    phone_verified boolean DEFAULT false NOT NULL,
    failed_login_count integer DEFAULT 0 NOT NULL,
    locked_until timestamp with time zone,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    latest_otp character varying(10),
    date_of_birth date,
    CONSTRAINT chk_email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT chk_phone_format CHECK (((phone)::text ~ '^\+?[0-9]{10,15}$'::text))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 77311)
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallet_transactions (
    id character varying(64) DEFAULT ('tx_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    user_id character varying(64) NOT NULL,
    transaction_type character varying(32) NOT NULL,
    amount numeric(10,2) NOT NULL,
    balance_after numeric(10,2) NOT NULL,
    description text NOT NULL,
    status character varying(32) DEFAULT 'SUCCESS'::character varying NOT NULL,
    reference_id character varying(64),
    provider_payment_id character varying(128),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.wallet_transactions OWNER TO postgres;

--
-- TOC entry 5625 (class 2604 OID 18847)
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- TOC entry 5555 (class 2604 OID 18334)
-- Name: game_players id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_players ALTER COLUMN id SET DEFAULT nextval('public.game_players_id_seq'::regclass);


--
-- TOC entry 5559 (class 2604 OID 18366)
-- Name: game_waitlist id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist ALTER COLUMN id SET DEFAULT nextval('public.game_waitlist_id_seq'::regclass);


--
-- TOC entry 5563 (class 2604 OID 18401)
-- Name: live_score_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_score_logs ALTER COLUMN id SET DEFAULT nextval('public.live_score_logs_id_seq'::regclass);


--
-- TOC entry 5510 (class 2604 OID 18075)
-- Name: otp_verifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_verifications ALTER COLUMN id SET DEFAULT nextval('public.otp_verifications_id_seq'::regclass);


--
-- TOC entry 5643 (class 2604 OID 19801)
-- Name: payment_webhook_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_webhook_events ALTER COLUMN id SET DEFAULT nextval('public.payment_webhook_events_id_seq'::regclass);


--
-- TOC entry 5633 (class 2604 OID 19719)
-- Name: user_identity_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_identity_history ALTER COLUMN id SET DEFAULT nextval('public.user_identity_history_id_seq'::regclass);


--
-- TOC entry 6172 (class 0 OID 17985)
-- Dependencies: 228
-- Data for Name: admin_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_details (user_id, admin_type, is_owner, designation, created_by_admin_id, created_at) FROM stdin;
usr_e55abb463db8392d	SUPER_ADMIN	t	Super Admin	\N	2026-09-29 15:20:21.207044+05:30
\.


--
-- TOC entry 6205 (class 0 OID 18844)
-- Dependencies: 261
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, admin_id, admin_name, action, target, details, created_at) FROM stdin;
1	usr_2cd11304a4ea973d	manager_test_1790748611090@example.com	ADD_CCTV_CAMERA	Camera:cam_9abba445bb45f0af	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_eadcbf1843fa28e7'	2026-09-30 11:40:12.323153+05:30
2	usr_6b892eeb30401c97	manager_test_1790749918195@example.com	ADD_CCTV_CAMERA	Camera:cam_40c894785dddab6c	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_892ccefe31f5cb2b'	2026-09-30 12:01:59.21576+05:30
3	usr_791dcac02f2279ba	manager_test_1790749957131@example.com	ADD_CCTV_CAMERA	Camera:cam_5f148c0111dd1aca	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_55f167dc8cfe986a'	2026-09-30 12:02:38.214291+05:30
4	usr_b1d7ea4b904ef79c	wf_manager_1790750795839@example.com	MATCH_CANCELLED	gam_87e6cc5754d47c1f	Heavy rainfall alert on turf	2026-09-30 12:16:36.158848+05:30
5	usr_7fa7260cfb9e0c26	wf_manager_1790750815653@example.com	MATCH_CANCELLED	gam_8aace32d261bc885	Heavy rainfall alert on turf	2026-09-30 12:16:56.338419+05:30
6	usr_66623e82cb6ddd26	manager_test_1790750816733@example.com	ADD_CCTV_CAMERA	Camera:cam_bdaa2b07772c9e89	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_72bca0f7c06e9462'	2026-09-30 12:16:57.700807+05:30
7	usr_c641dbc8e3c7bf62	wf_manager_1790751284036@example.com	MATCH_CANCELLED	gam_a88a0501a7d378ea	Heavy rainfall alert on turf	2026-09-30 12:24:44.465915+05:30
8	usr_31a34b67a1c9070a	manager_test_1790751284061@example.com	ADD_CCTV_CAMERA	Camera:cam_19e44156c5f55537	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_fea958bb77af0b4a'	2026-09-30 12:24:45.079055+05:30
9	usr_0385a239ccd5b41d	wf_manager_1790751664506@example.com	MATCH_CANCELLED	gam_2033f60bab02b5e3	Heavy rainfall alert on turf	2026-09-30 12:31:04.922045+05:30
10	usr_8d8d233cb1520d3e	manager_test_1790751664390@example.com	ADD_CCTV_CAMERA	Camera:cam_1f03add983833a47	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_0b9a81b26d0bd865'	2026-09-30 12:31:05.377679+05:30
11	usr_e43d0fd722732ad0	manager_test_1790751921507@example.com	ADD_CCTV_CAMERA	Camera:cam_33d4d72849e9973f	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_25399b493711d9f6'	2026-09-30 12:35:22.305117+05:30
12	usr_adc575328dc2453a	wf_manager_1790751939764@example.com	MATCH_CANCELLED	gam_a1614442619b1202	Heavy rainfall alert on turf	2026-09-30 12:35:40.238331+05:30
13	usr_5dd9bc34451d7881	manager_test_1790751939692@example.com	ADD_CCTV_CAMERA	Camera:cam_19dbdc75295365a8	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_025c31836a629034'	2026-09-30 12:35:40.739189+05:30
14	usr_5cfc9ba5df459c07	wf_manager_1790752080144@example.com	MATCH_CANCELLED	gam_5931555baab6ee99	Heavy rainfall alert on turf	2026-09-30 12:38:01.679798+05:30
15	usr_6bc672c4761b5a78	wf_manager_1790752097446@example.com	MATCH_CANCELLED	gam_4d9201df36534559	Heavy rainfall alert on turf	2026-09-30 12:38:18.040423+05:30
16	usr_046291f5a26cbfef	manager_test_1790752097453@example.com	ADD_CCTV_CAMERA	Camera:cam_4ef7e8d07b9b56d9	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_92405048365e7300'	2026-09-30 12:38:18.605392+05:30
17	usr_8ba4c28082ef21a7	wf_manager_1790752141036@example.com	MATCH_CANCELLED	gam_766d2fd26a9125d4	Heavy rainfall alert on turf	2026-09-30 12:39:01.579082+05:30
18	usr_ae2a15190a816afa	manager_test_1790752141176@example.com	ADD_CCTV_CAMERA	Camera:cam_6fe09c8a3e4341d5	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_557caf9c1fe836f4'	2026-09-30 12:39:02.272104+05:30
19	usr_f8b3a9c750f5c30e	manager_test_1790756403131@example.com	ADD_CCTV_CAMERA	Camera:cam_3e085ad22d7697d2	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_801bf7fe32c1a126'	2026-09-30 13:50:04.369383+05:30
20	usr_4f9318878fbd93df	wf_manager_1790756601463@example.com	MATCH_CANCELLED	gam_32c59557874e14a2	Heavy rainfall alert on turf	2026-09-30 13:53:21.928991+05:30
21	usr_3956d119b0e3e452	wf_manager_1790848588497@example.com	MATCH_CANCELLED	gam_e75822285a6ada14	Heavy rainfall alert on turf	2026-10-01 15:26:29.593849+05:30
22	usr_ea7d22375987cbb3	manager_test_1790848588497@example.com	ADD_CCTV_CAMERA	Camera:cam_ef21f4ac2ccd29db	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_203d6f7e50d4fe28'	2026-10-01 15:26:30.578371+05:30
23	usr_77d1efe4afbc4c7f	wf_manager_1790848991248@example.com	MATCH_CANCELLED	gam_e050071b75905b49	Heavy rainfall alert on turf	2026-10-01 15:33:11.783786+05:30
24	usr_4b2405663fda6e40	wf_manager_1790849348212@example.com	MATCH_CANCELLED	gam_581ee86abd2a312c	Heavy rainfall alert on turf	2026-10-01 15:39:09.248316+05:30
25	usr_a0ea1d4f298d4a7e	manager_test_1790849348214@example.com	ADD_CCTV_CAMERA	Camera:cam_e4823ff1eddc1614	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_bd9db684bdb40a72'	2026-10-01 15:39:09.903969+05:30
26	usr_a7b005600886fb63	wf_manager_1790849831155@example.com	MATCH_CANCELLED	gam_dd724d1c83d95503	Heavy rainfall alert on turf	2026-10-01 15:47:11.639234+05:30
27	usr_bd31992cc995573f	manager_test_1790849831200@example.com	ADD_CCTV_CAMERA	Camera:cam_060f36cf6d5da7e2	Added CCTV Camera 'Court 1 Dome Camera' for Club 'clb_1d096e1583a08995'	2026-10-01 15:47:12.188904+05:30
\.


--
-- TOC entry 6213 (class 0 OID 19864)
-- Dependencies: 269
-- Data for Name: cctv_cameras; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cctv_cameras (id, club_id, court_id, name, rtsp_url_encrypted, ip_address, port, is_enabled, status, last_health_check_at, created_at, updated_at, encrypted_connection_reference, health_status, camera_type, connection_type, stream_reference, created_by) FROM stdin;
cam_9abba445bb45f0af	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	Court 1 Dome Camera	b7a13cfb2b61ebfc3e7a7ea8cc7fad63:377cccae332fd2503373c69168c9631d:d3147f955f31882f242b513b7eaeda964d2fc132efbc49223beac082e724eeef742e143966cc52ac8dcac0d89f6e9ab92fcfc636	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 11:40:12.321574+05:30	2026-09-30 11:40:16.342867+05:30	b7a13cfb2b61ebfc3e7a7ea8cc7fad63:377cccae332fd2503373c69168c9631d:d3147f955f31882f242b513b7eaeda964d2fc132efbc49223beac082e724eeef742e143966cc52ac8dcac0d89f6e9ab92fcfc636	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_40c894785dddab6c	clb_892ccefe31f5cb2b	crt_810d213d14af855f	Court 1 Dome Camera	98e2853b18789543fc6587edf193d592:a79300b42f9657d0d5ff125e54c21362:13236d0871a220330b7b87c34a3590c9e7d912fca435a055fa056c791e098a02e5bd1efd79ac2099768cb48be045d77fd4fae498	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:01:59.214416+05:30	2026-09-30 12:02:03.22668+05:30	98e2853b18789543fc6587edf193d592:a79300b42f9657d0d5ff125e54c21362:13236d0871a220330b7b87c34a3590c9e7d912fca435a055fa056c791e098a02e5bd1efd79ac2099768cb48be045d77fd4fae498	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_5f148c0111dd1aca	clb_55f167dc8cfe986a	crt_01216d2cc902d161	Court 1 Dome Camera	013be0437650564d7afcff792225b263:edb86dc6439dc74519b5f2711d70858b:993111446f359f9025ef2501b98be2a977a64311ded516b27043348b30eac574065695a42c5279ca61ebde95d7238fcfdb332daa	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:02:38.212131+05:30	2026-09-30 12:02:42.238576+05:30	013be0437650564d7afcff792225b263:edb86dc6439dc74519b5f2711d70858b:993111446f359f9025ef2501b98be2a977a64311ded516b27043348b30eac574065695a42c5279ca61ebde95d7238fcfdb332daa	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_bdaa2b07772c9e89	clb_72bca0f7c06e9462	crt_f44ec4c076698469	Court 1 Dome Camera	01a2b703fe8859d178f9b8288d627a94:ebd8e6c06a625cd1f281c1dc9424d755:57ac778845cccd54cdbd61b004c0b195dd69f13708f2893e328513f5fc6d097863b9d606951fb265c364d091c56822ff476bf827	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:16:57.699457+05:30	2026-09-30 12:17:01.723401+05:30	01a2b703fe8859d178f9b8288d627a94:ebd8e6c06a625cd1f281c1dc9424d755:57ac778845cccd54cdbd61b004c0b195dd69f13708f2893e328513f5fc6d097863b9d606951fb265c364d091c56822ff476bf827	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_19e44156c5f55537	clb_fea958bb77af0b4a	crt_d0477e882694ef6e	Court 1 Dome Camera	3fcd9954d481c663341c055c073a9987:79d5d5b64c052b4556c62bdf5da9104a:a0d067c9c9cc0a2647faaea10513d407e881c59b2d8b14be44fc653ec5a66d0bd8e3523102045881bb17555c84e2a6ee7db4fb12	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:24:45.077823+05:30	2026-09-30 12:24:49.089529+05:30	3fcd9954d481c663341c055c073a9987:79d5d5b64c052b4556c62bdf5da9104a:a0d067c9c9cc0a2647faaea10513d407e881c59b2d8b14be44fc653ec5a66d0bd8e3523102045881bb17555c84e2a6ee7db4fb12	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_1f03add983833a47	clb_0b9a81b26d0bd865	crt_622120525008f799	Court 1 Dome Camera	373740d15c4b0d135a7c5cc374434fe3:bbf62af62ae6d3a2ff9a4706a5671263:9d65403bd0b0b582f9420383a3ee4b22b96e11de927105a704e5c3048c03fa4e98f03051419d10b27a9f723af78fc3f5dba40e71	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:31:05.376374+05:30	2026-09-30 12:31:09.399747+05:30	373740d15c4b0d135a7c5cc374434fe3:bbf62af62ae6d3a2ff9a4706a5671263:9d65403bd0b0b582f9420383a3ee4b22b96e11de927105a704e5c3048c03fa4e98f03051419d10b27a9f723af78fc3f5dba40e71	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_33d4d72849e9973f	clb_25399b493711d9f6	crt_e9aebd84d1a45b5e	Court 1 Dome Camera	a264a9563f412b301e44621e47ffa532:02418cca2423f55eaf869fc9898c10af:8ed1acf8c30d9c066c2f6602852e52c01edee33e887aea7b0c2573a23a1dfd3b2d91b7e06d3d6d83cc1d16a18447771da16e6e71	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:35:22.304088+05:30	2026-09-30 12:35:26.318378+05:30	a264a9563f412b301e44621e47ffa532:02418cca2423f55eaf869fc9898c10af:8ed1acf8c30d9c066c2f6602852e52c01edee33e887aea7b0c2573a23a1dfd3b2d91b7e06d3d6d83cc1d16a18447771da16e6e71	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_19dbdc75295365a8	clb_025c31836a629034	crt_0dbfee05854ba0b5	Court 1 Dome Camera	c1d5d462475aa06cbf0a2c30c491a0cd:9d7f755543abc19e8d3bbb458c96958f:3f59f09473e0633475804fd769cafd6dbaa22196c6017b3e58626bfb189c7a49376dd50513867a04ad11b2835e22feb15e9256c5	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:35:40.737782+05:30	2026-09-30 12:35:44.760416+05:30	c1d5d462475aa06cbf0a2c30c491a0cd:9d7f755543abc19e8d3bbb458c96958f:3f59f09473e0633475804fd769cafd6dbaa22196c6017b3e58626bfb189c7a49376dd50513867a04ad11b2835e22feb15e9256c5	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_4ef7e8d07b9b56d9	clb_92405048365e7300	crt_78bfec32ffaeb5d4	Court 1 Dome Camera	a27b1ab6cd71c6481d4a5f563f6a635d:e70f9d810adc96c1dd4693a9c36f5c40:07d663decc390eef3391195bccf10f92c410f464955ba59cc4e14cf30bfad23bc96ee758dd7a0065ae66f342096185772b6f3304	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:38:18.603472+05:30	2026-09-30 12:38:22.620099+05:30	a27b1ab6cd71c6481d4a5f563f6a635d:e70f9d810adc96c1dd4693a9c36f5c40:07d663decc390eef3391195bccf10f92c410f464955ba59cc4e14cf30bfad23bc96ee758dd7a0065ae66f342096185772b6f3304	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_6fe09c8a3e4341d5	clb_557caf9c1fe836f4	crt_10af24b2592f7d44	Court 1 Dome Camera	1ec1ddc19d4ef4ebd23b7ac8c5cc9ba3:97dd6f46f6ce7a5d6e54164c6c6df34d:7475a6c97ec18b9dddeee7839de7cc351149e5c30f76acad903a269ce69343e98a7a323d3d6b108d89900b81965c491b722e6fb1	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 12:39:02.270393+05:30	2026-09-30 12:39:06.292487+05:30	1ec1ddc19d4ef4ebd23b7ac8c5cc9ba3:97dd6f46f6ce7a5d6e54164c6c6df34d:7475a6c97ec18b9dddeee7839de7cc351149e5c30f76acad903a269ce69343e98a7a323d3d6b108d89900b81965c491b722e6fb1	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_3e085ad22d7697d2	clb_801bf7fe32c1a126	crt_a318fdf4adfb970d	Court 1 Dome Camera	65552e32d48f9ae3c7a7d3b5b098a2ca:74e52578097d8897521bf311009d91e7:cec7d1e8b84a4fcb69b20c6b67404b1b70fe88b16d69d078124f1f9d42bf89ee7dc7099e9518bddccec1efcb8bc52f74ac661c53	192.168.1.100	554	t	OFFLINE	\N	2026-09-30 13:50:04.368039+05:30	2026-09-30 13:50:08.394867+05:30	65552e32d48f9ae3c7a7d3b5b098a2ca:74e52578097d8897521bf311009d91e7:cec7d1e8b84a4fcb69b20c6b67404b1b70fe88b16d69d078124f1f9d42bf89ee7dc7099e9518bddccec1efcb8bc52f74ac661c53	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_ef21f4ac2ccd29db	clb_203d6f7e50d4fe28	crt_661588e4de60b612	Court 1 Dome Camera	d8d4c7e3c6fcac8821ceb864bb60236f:92836d0a7dab9ad645415a0b036e8b1a:309a01ec97462bc50d94ccf5b57aa597780e65d937b272d9ddc7b15e4472406ee6a9216522f4f3a97e5bab42794be64cf4c5fc47	192.168.1.100	554	t	OFFLINE	\N	2026-10-01 15:26:30.576066+05:30	2026-10-01 15:26:34.60581+05:30	d8d4c7e3c6fcac8821ceb864bb60236f:92836d0a7dab9ad645415a0b036e8b1a:309a01ec97462bc50d94ccf5b57aa597780e65d937b272d9ddc7b15e4472406ee6a9216522f4f3a97e5bab42794be64cf4c5fc47	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_e4823ff1eddc1614	clb_bd9db684bdb40a72	crt_7e9a7b9d0edb53ea	Court 1 Dome Camera	b387b7d409b34cb801a73cba47da344f:de9552b577649d95454158b38fe518f6:629eff50e26a7d15d35e5a41d917bff28a8981fb9ca56759d3226c8ca7dde8e3d2c12fb29d2b15340a925d66e754193ee2d4dbc2	192.168.1.100	554	t	OFFLINE	\N	2026-10-01 15:39:09.902216+05:30	2026-10-01 15:39:13.920172+05:30	b387b7d409b34cb801a73cba47da344f:de9552b577649d95454158b38fe518f6:629eff50e26a7d15d35e5a41d917bff28a8981fb9ca56759d3226c8ca7dde8e3d2c12fb29d2b15340a925d66e754193ee2d4dbc2	OFFLINE	RTSP_DOME	RTSP	\N	\N
cam_060f36cf6d5da7e2	clb_1d096e1583a08995	crt_90b396ef6fc9e519	Court 1 Dome Camera	68cb614c86124bc8af696adf8b86585d:6f4343f27dc4cbfec4077cfe6919efd7:1c60e06c3bb4613deff10ec517c2ae74f5d6409ac0d7ebd72f50d735c073c5d2563f96661378832305bfb2e2c593724a417117f8	192.168.1.100	554	t	OFFLINE	\N	2026-10-01 15:47:12.187695+05:30	2026-10-01 15:47:16.207346+05:30	68cb614c86124bc8af696adf8b86585d:6f4343f27dc4cbfec4077cfe6919efd7:1c60e06c3bb4613deff10ec517c2ae74f5d6409ac0d7ebd72f50d735c073c5d2563f96661378832305bfb2e2c593724a417117f8	OFFLINE	RTSP_DOME	RTSP	\N	\N
\.


--
-- TOC entry 6215 (class 0 OID 19931)
-- Dependencies: 271
-- Data for Name: cctv_recording_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cctv_recording_events (id, recording_id, event_type, actor_user_id, event_time, metadata, created_at) FROM stdin;
\.


--
-- TOC entry 6214 (class 0 OID 19893)
-- Dependencies: 270
-- Data for Name: cctv_recordings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cctv_recordings (id, game_id, club_id, court_id, camera_id, start_time, scheduled_match_end, stop_deadline, actual_stop_time, s3_object_key, status, created_at, recording_status, post_match_stop_at, scheduled_match_end_at) FROM stdin;
\.


--
-- TOC entry 6201 (class 0 OID 18759)
-- Dependencies: 257
-- Data for Name: challenge_progress; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.challenge_progress (challenge_id, user_id, current_progress, is_completed, completed_at) FROM stdin;
\.


--
-- TOC entry 6200 (class 0 OID 18740)
-- Dependencies: 256
-- Data for Name: challenges; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.challenges (id, title, description, target_count, reward_badge, reward_wallet_bonus, created_at) FROM stdin;
\.


--
-- TOC entry 6179 (class 0 OID 18160)
-- Dependencies: 235
-- Data for Name: club_managers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.club_managers (club_id, user_id, assigned_at) FROM stdin;
clb_eadcbf1843fa28e7	usr_2cd11304a4ea973d	2026-09-30 11:40:12.263592+05:30
clb_892ccefe31f5cb2b	usr_6b892eeb30401c97	2026-09-30 12:01:59.185854+05:30
clb_55f167dc8cfe986a	usr_791dcac02f2279ba	2026-09-30 12:02:38.147899+05:30
clb_eadcbf1843fa28e7	usr_6b892eeb30401c97	2026-09-30 12:03:16.274157+05:30
clb_eadcbf1843fa28e7	usr_9e1cc12535965c8a	2026-09-30 12:05:29.325038+05:30
clb_eadcbf1843fa28e7	usr_8b558de699670318	2026-09-30 12:06:05.769695+05:30
clb_eadcbf1843fa28e7	usr_99e86453b77b20f8	2026-09-30 12:06:44.649201+05:30
clb_eadcbf1843fa28e7	usr_a749ad15a4b83f56	2026-09-30 12:07:50.811401+05:30
clb_eadcbf1843fa28e7	usr_de3c7a69b61ef701	2026-09-30 12:08:44.985163+05:30
clb_eadcbf1843fa28e7	usr_8c526a10e5c1c5cb	2026-09-30 12:09:45.659662+05:30
clb_eadcbf1843fa28e7	usr_2b1f5e605b8f2010	2026-09-30 12:11:02.868701+05:30
clb_eadcbf1843fa28e7	usr_97d87fa5a02055dc	2026-09-30 12:11:53.95602+05:30
clb_eadcbf1843fa28e7	usr_4262abd5736887a7	2026-09-30 12:13:43.782721+05:30
clb_eadcbf1843fa28e7	usr_b1d7ea4b904ef79c	2026-09-30 12:16:36.109564+05:30
clb_eadcbf1843fa28e7	usr_7fa7260cfb9e0c26	2026-09-30 12:16:56.237047+05:30
clb_72bca0f7c06e9462	usr_66623e82cb6ddd26	2026-09-30 12:16:57.663709+05:30
clb_eadcbf1843fa28e7	usr_c641dbc8e3c7bf62	2026-09-30 12:24:44.403235+05:30
clb_fea958bb77af0b4a	usr_31a34b67a1c9070a	2026-09-30 12:24:45.043582+05:30
clb_eadcbf1843fa28e7	usr_0385a239ccd5b41d	2026-09-30 12:31:04.868789+05:30
clb_0b9a81b26d0bd865	usr_8d8d233cb1520d3e	2026-09-30 12:31:05.345417+05:30
clb_25399b493711d9f6	usr_e43d0fd722732ad0	2026-09-30 12:35:22.270708+05:30
clb_eadcbf1843fa28e7	usr_adc575328dc2453a	2026-09-30 12:35:40.167774+05:30
clb_025c31836a629034	usr_5dd9bc34451d7881	2026-09-30 12:35:40.702393+05:30
clb_eadcbf1843fa28e7	usr_5cfc9ba5df459c07	2026-09-30 12:38:01.382902+05:30
clb_eadcbf1843fa28e7	usr_6bc672c4761b5a78	2026-09-30 12:38:17.972913+05:30
clb_92405048365e7300	usr_046291f5a26cbfef	2026-09-30 12:38:18.55966+05:30
clb_eadcbf1843fa28e7	usr_8ba4c28082ef21a7	2026-09-30 12:39:01.499466+05:30
clb_557caf9c1fe836f4	usr_ae2a15190a816afa	2026-09-30 12:39:02.229848+05:30
clb_801bf7fe32c1a126	usr_f8b3a9c750f5c30e	2026-09-30 13:50:04.290551+05:30
clb_eadcbf1843fa28e7	usr_4f9318878fbd93df	2026-09-30 13:53:21.86416+05:30
clb_eadcbf1843fa28e7	usr_3956d119b0e3e452	2026-10-01 15:26:29.467091+05:30
clb_203d6f7e50d4fe28	usr_ea7d22375987cbb3	2026-10-01 15:26:30.5106+05:30
clb_eadcbf1843fa28e7	usr_77d1efe4afbc4c7f	2026-10-01 15:33:11.717178+05:30
clb_eadcbf1843fa28e7	usr_4b2405663fda6e40	2026-10-01 15:39:09.149951+05:30
clb_bd9db684bdb40a72	usr_a0ea1d4f298d4a7e	2026-10-01 15:39:09.862141+05:30
clb_eadcbf1843fa28e7	usr_a7b005600886fb63	2026-10-01 15:47:11.576257+05:30
clb_1d096e1583a08995	usr_bd31992cc995573f	2026-10-01 15:47:12.154684+05:30
\.


--
-- TOC entry 6178 (class 0 OID 18126)
-- Dependencies: 234
-- Data for Name: clubs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clubs (id, name, address, city, latitude, longitude, open_time, close_time, amenities, status, club_image_url, rating, reviews_count, description, created_at, updated_at) FROM stdin;
clb_eadcbf1843fa28e7	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 11:40:12.261029+05:30	2026-09-30 11:40:12.261029+05:30
clb_892ccefe31f5cb2b	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:01:59.184659+05:30	2026-09-30 12:01:59.184659+05:30
clb_55f167dc8cfe986a	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:02:38.145914+05:30	2026-09-30 12:02:38.145914+05:30
clb_72bca0f7c06e9462	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:16:57.662078+05:30	2026-09-30 12:16:57.662078+05:30
clb_fea958bb77af0b4a	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:24:45.042276+05:30	2026-09-30 12:24:45.042276+05:30
clb_0b9a81b26d0bd865	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:31:05.344459+05:30	2026-09-30 12:31:05.344459+05:30
clb_25399b493711d9f6	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:35:22.269205+05:30	2026-09-30 12:35:22.269205+05:30
clb_025c31836a629034	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:35:40.700736+05:30	2026-09-30 12:35:40.700736+05:30
clb_92405048365e7300	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:38:18.558229+05:30	2026-09-30 12:38:18.558229+05:30
clb_557caf9c1fe836f4	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 12:39:02.228387+05:30	2026-09-30 12:39:02.228387+05:30
clb_801bf7fe32c1a126	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-09-30 13:50:04.285806+05:30	2026-09-30 13:50:04.285806+05:30
clb_203d6f7e50d4fe28	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-10-01 15:26:30.507526+05:30	2026-10-01 15:26:30.507526+05:30
clb_bd9db684bdb40a72	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-10-01 15:39:09.860211+05:30	2026-10-01 15:39:09.860211+05:30
clb_1d096e1583a08995	All Stars Turf Raipur	VIP Road, Raipur	Raipur	\N	\N	06:00:00	23:00:00	["Floodlights", "Washrooms", "Parking"]	ACTIVE	\N	5.00	0	\N	2026-10-01 15:47:12.15331+05:30	2026-10-01 15:47:12.15331+05:30
\.


--
-- TOC entry 6194 (class 0 OID 18611)
-- Dependencies: 250
-- Data for Name: community_posts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.community_posts (id, city, author_id, content, image_url, likes_count, tags, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 6181 (class 0 OID 18222)
-- Dependencies: 237
-- Data for Name: court_bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.court_bookings (id, court_id, club_id, user_id, booking_date, start_time, end_time, amount_paid, status, refund_tier, refund_amount, cancellation_reason, rejection_reason, refunded_at, created_at, updated_at) FROM stdin;
bkg_ec5253631ff6bf0b	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_26cd79c91e36a2ec	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:01:58.667687+05:30	2026-09-30 12:01:58.679418+05:30
bkg_140285675baee74e	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_1b2be606008073f9	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:02:37.687405+05:30	2026-09-30 12:02:37.700184+05:30
bkg_3fae24061251f44e	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_70cf84b74a8d0975	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:16:57.254635+05:30	2026-09-30 12:16:57.264932+05:30
bkg_1c2c4847b238d203	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_426334eee09db891	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:24:44.479411+05:30	2026-09-30 12:24:44.491467+05:30
bkg_4fd49dcc9ab82f72	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_1e93ccb241b92f8d	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:31:04.98587+05:30	2026-09-30 12:31:04.995095+05:30
bkg_cf06dee88f973686	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_11fdc7381d901c43	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:35:40.246454+05:30	2026-09-30 12:35:40.258388+05:30
bkg_0182da6dfda8e356	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_507a98d2112c5563	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:38:18.015916+05:30	2026-09-30 12:38:18.029013+05:30
bkg_ebd066cad9f200c3	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_50634ff073aa77b9	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 12:39:01.613758+05:30	2026-09-30 12:39:01.626231+05:30
bkg_99bcd86e474c9a3e	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_58e3c108ab31e109	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-09-30 13:50:37.555692+05:30	2026-09-30 13:50:37.567777+05:30
bkg_2f4e1409abfd641c	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_86b3e6d40335e6f1	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-10-01 15:26:29.646889+05:30	2026-10-01 15:26:29.709312+05:30
bkg_c2a85226b33663c5	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_16c2144c0df7f485	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-10-01 15:39:09.126515+05:30	2026-10-01 15:39:09.146111+05:30
bkg_b1eb271cc373e0bb	crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	usr_2bad6dc1de996b96	2026-10-15	18:00:00	19:00:00	2174.00	REFUND_PENDING	100%	2174.00	Schedule conflict	\N	\N	2026-10-01 15:47:11.618612+05:30	2026-10-01 15:47:11.632421+05:30
\.


--
-- TOC entry 6180 (class 0 OID 18180)
-- Dependencies: 236
-- Data for Name: courts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.courts (id, club_id, name, environment, surface, base_price, peak_multiplier, weekend_multiplier, peak_window_start, peak_window_end, status, image_url, created_at, updated_at) FROM stdin;
crt_e50c6d9bec53f0e7	clb_eadcbf1843fa28e7	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 11:40:12.264584+05:30	2026-09-30 11:40:12.264584+05:30
crt_810d213d14af855f	clb_892ccefe31f5cb2b	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:01:59.187525+05:30	2026-09-30 12:01:59.187525+05:30
crt_01216d2cc902d161	clb_55f167dc8cfe986a	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:02:38.15121+05:30	2026-09-30 12:02:38.15121+05:30
crt_f44ec4c076698469	clb_72bca0f7c06e9462	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:16:57.666014+05:30	2026-09-30 12:16:57.666014+05:30
crt_d0477e882694ef6e	clb_fea958bb77af0b4a	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:24:45.04571+05:30	2026-09-30 12:24:45.04571+05:30
crt_622120525008f799	clb_0b9a81b26d0bd865	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:31:05.347064+05:30	2026-09-30 12:31:05.347064+05:30
crt_e9aebd84d1a45b5e	clb_25399b493711d9f6	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:35:22.272898+05:30	2026-09-30 12:35:22.272898+05:30
crt_0dbfee05854ba0b5	clb_025c31836a629034	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:35:40.704707+05:30	2026-09-30 12:35:40.704707+05:30
crt_78bfec32ffaeb5d4	clb_92405048365e7300	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:38:18.563121+05:30	2026-09-30 12:38:18.563121+05:30
crt_10af24b2592f7d44	clb_557caf9c1fe836f4	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 12:39:02.232083+05:30	2026-09-30 12:39:02.232083+05:30
crt_a318fdf4adfb970d	clb_801bf7fe32c1a126	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-09-30 13:50:04.292018+05:30	2026-09-30 13:50:04.292018+05:30
crt_661588e4de60b612	clb_203d6f7e50d4fe28	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-10-01 15:26:30.512754+05:30	2026-10-01 15:26:30.512754+05:30
crt_7e9a7b9d0edb53ea	clb_bd9db684bdb40a72	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-10-01 15:39:09.86544+05:30	2026-10-01 15:39:09.86544+05:30
crt_90b396ef6fc9e519	clb_1d096e1583a08995	Pitch 1 (5v5)	Outdoor	3G Turf	1200.00	1.50	1.75	17:00:00	21:00:00	AVAILABLE	\N	2026-10-01 15:47:12.156766+05:30	2026-10-01 15:47:12.156766+05:30
\.


--
-- TOC entry 6217 (class 0 OID 28192)
-- Dependencies: 273
-- Data for Name: game_activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_activity_logs (id, game_id, actor_id, actor_name, actor_role_name, action_type, details, created_at) FROM stdin;
act_c3ab29f75f1d7cd6	gam_5611ccb901e728af	usr_6b892eeb30401c97	manager_test_1790749918195@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:02:03.264971+05:30
act_425abf8bd8393529	gam_5611ccb901e728af	usr_6b892eeb30401c97	manager_test_1790749918195@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:02:03.285973+05:30
act_bf0e2a456ad09b17	gam_26de53da21e63242	usr_791dcac02f2279ba	manager_test_1790749957131@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:02:42.399563+05:30
act_626fe74b6e6e6d6a	gam_26de53da21e63242	usr_791dcac02f2279ba	manager_test_1790749957131@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:02:42.435535+05:30
act_4b1e195337126ffc	gam_bbd02484152bfd57	usr_2d339c1c8a60a7bf	wf_player_1790750383881@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:09:45.740754+05:30
act_08d9b25dd72fe6ca	gam_bbd02484152bfd57	usr_8c526a10e5c1c5cb	wf_manager_1790750383881@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790750383881@example.com: Heavy rainfall alert on turf	2026-09-30 12:09:45.964011+05:30
act_b60f2af8f43b1d5c	gam_c967608774d9003e	usr_c04f1863db4f19c1	wf_player_1790750512255@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:11:54.037299+05:30
act_3f2ca2c03d0131ce	gam_c967608774d9003e	usr_97d87fa5a02055dc	wf_manager_1790750512255@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:11:54.147973+05:30
act_5cb4b4c88c51f111	gam_fd482c54fc356742	usr_39ea6b242671d81c	wf_player_1790750623527@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:13:43.800093+05:30
act_de78729a039135af	gam_fd482c54fc356742	usr_4262abd5736887a7	wf_manager_1790750623527@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:13:43.838056+05:30
act_21bae3a12ab71cfe	gam_87e6cc5754d47c1f	usr_1a92cc3ed067921f	wf_player_1790750795839@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:16:36.131751+05:30
act_9d954115af60ca75	gam_87e6cc5754d47c1f	usr_b1d7ea4b904ef79c	wf_manager_1790750795839@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:16:36.145751+05:30
act_fa40938f072c0ac9	gam_87e6cc5754d47c1f	usr_b1d7ea4b904ef79c	wf_manager_1790750795839@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790750795839@example.com: Heavy rainfall alert on turf	2026-09-30 12:16:36.158848+05:30
act_424f1321bb32bbb8	gam_8aace32d261bc885	usr_fe8e1e4957015c39	wf_player_1790750815653@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:16:56.287067+05:30
act_bfccceca3c41bdff	gam_8aace32d261bc885	usr_7fa7260cfb9e0c26	wf_manager_1790750815653@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:16:56.312576+05:30
act_cbd32c9d63e8e009	gam_8aace32d261bc885	usr_7fa7260cfb9e0c26	wf_manager_1790750815653@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790750815653@example.com: Heavy rainfall alert on turf	2026-09-30 12:16:56.338419+05:30
act_745ca540dd102df6	gam_f6e46a446e817541	usr_66623e82cb6ddd26	manager_test_1790750816733@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:17:01.868366+05:30
act_94c80ff1a8342aa8	gam_f6e46a446e817541	usr_66623e82cb6ddd26	manager_test_1790750816733@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:17:01.894534+05:30
act_78f4e4f9d1922f90	gam_a88a0501a7d378ea	usr_332b68556f881273	wf_player_1790751284036@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:24:44.433379+05:30
act_24214d46ec9038f4	gam_a88a0501a7d378ea	usr_c641dbc8e3c7bf62	wf_manager_1790751284036@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:24:44.449664+05:30
act_85b8576bcd25516e	gam_a88a0501a7d378ea	usr_c641dbc8e3c7bf62	wf_manager_1790751284036@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790751284036@example.com: Heavy rainfall alert on turf	2026-09-30 12:24:44.465915+05:30
act_faf4c9b5a1f067a3	gam_b907d464d302dc5e	usr_31a34b67a1c9070a	manager_test_1790751284061@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:24:49.13095+05:30
act_47b4dc51fd2da83e	gam_b907d464d302dc5e	usr_31a34b67a1c9070a	manager_test_1790751284061@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:24:49.158222+05:30
act_788c594269398a22	gam_2033f60bab02b5e3	usr_fb4c3d97481d72eb	wf_player_1790751664506@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:31:04.892632+05:30
act_cf54839007c2e673	gam_2033f60bab02b5e3	usr_0385a239ccd5b41d	wf_manager_1790751664506@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:31:04.905661+05:30
act_51d5cf8fdfebd43d	gam_2033f60bab02b5e3	usr_0385a239ccd5b41d	wf_manager_1790751664506@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790751664506@example.com: Heavy rainfall alert on turf	2026-09-30 12:31:04.922045+05:30
act_9bc82f56f377e78b	gam_f6585e12cc2e86db	usr_8d8d233cb1520d3e	manager_test_1790751664390@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:31:09.448336+05:30
act_03dbcd8f200d0c40	gam_f6585e12cc2e86db	usr_8d8d233cb1520d3e	manager_test_1790751664390@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:31:09.468266+05:30
act_dfeb094eb62a0066	gam_9b5724754c596a8e	usr_e43d0fd722732ad0	manager_test_1790751921507@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:35:26.35817+05:30
act_bf0ffe1dd4232f34	gam_9b5724754c596a8e	usr_e43d0fd722732ad0	manager_test_1790751921507@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:35:26.382516+05:30
act_849583fcc3dcdd00	gam_a1614442619b1202	usr_e5af181f986f06b3	wf_player_1790751939764@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:35:40.203116+05:30
act_16d5eab2a1618b68	gam_a1614442619b1202	usr_adc575328dc2453a	wf_manager_1790751939764@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:35:40.222546+05:30
act_b85db1e64c2f515d	gam_a1614442619b1202	usr_adc575328dc2453a	wf_manager_1790751939764@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790751939764@example.com: Heavy rainfall alert on turf	2026-09-30 12:35:40.238331+05:30
act_183920c99f2eac87	gam_d444dab37116089f	usr_5dd9bc34451d7881	manager_test_1790751939692@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:35:44.800546+05:30
act_80e6d5b70cf49736	gam_d444dab37116089f	usr_5dd9bc34451d7881	manager_test_1790751939692@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:35:44.825184+05:30
act_4d5df5555fdd77cf	gam_4d9201df36534559	usr_afbec60a362f096d	wf_player_1790752097446@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:38:18.003036+05:30
act_44d6afffde3bd09a	gam_4d9201df36534559	usr_6bc672c4761b5a78	wf_manager_1790752097446@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:38:18.021359+05:30
act_ee8ff333ecb6dc5b	gam_4d9201df36534559	usr_6bc672c4761b5a78	wf_manager_1790752097446@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790752097446@example.com: Heavy rainfall alert on turf	2026-09-30 12:38:18.040423+05:30
act_2c733ecaf9717ddb	gam_0833fb53de38015c	usr_046291f5a26cbfef	manager_test_1790752097453@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:38:22.760619+05:30
act_25a6179a422defee	gam_0833fb53de38015c	usr_046291f5a26cbfef	manager_test_1790752097453@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:38:22.791181+05:30
act_7407fa765dfb0fb8	gam_766d2fd26a9125d4	usr_3b955f3d4bb859f2	wf_player_1790752141036@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 12:39:01.536639+05:30
act_6bce2626bc8a81dc	gam_766d2fd26a9125d4	usr_8ba4c28082ef21a7	wf_manager_1790752141036@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 12:39:01.557635+05:30
act_9a7a816afbdad471	gam_766d2fd26a9125d4	usr_8ba4c28082ef21a7	wf_manager_1790752141036@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790752141036@example.com: Heavy rainfall alert on turf	2026-09-30 12:39:01.579082+05:30
act_e73ab445dca6cbf6	gam_5c0611138195cfbc	usr_ae2a15190a816afa	manager_test_1790752141176@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 12:39:06.433888+05:30
act_97012a327bcdf588	gam_5c0611138195cfbc	usr_ae2a15190a816afa	manager_test_1790752141176@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 12:39:06.458897+05:30
act_be56a4f75851ca11	gam_0ef5866bd945c307	usr_f8b3a9c750f5c30e	manager_test_1790756403131@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-09-30 13:50:08.48417+05:30
act_0f8c059c6f569134	gam_0ef5866bd945c307	usr_f8b3a9c750f5c30e	manager_test_1790756403131@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-09-30 13:50:08.518438+05:30
act_7f7c670ecdcfaa15	gam_32c59557874e14a2	usr_8279dc24442d924a	wf_player_1790756601463@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-09-30 13:53:21.893677+05:30
act_c2c6ca20399d3935	gam_32c59557874e14a2	usr_4f9318878fbd93df	wf_manager_1790756601463@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-09-30 13:53:21.907434+05:30
act_10e10ef58241a559	gam_32c59557874e14a2	usr_4f9318878fbd93df	wf_manager_1790756601463@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790756601463@example.com: Heavy rainfall alert on turf	2026-09-30 13:53:21.928991+05:30
act_413ef92f888ccfd9	gam_2210d508be115b28	usr_771ffc659cac6f5f	\N	PLAYER	MATCH_CREATED	Player hosted new match: 11v11 Football Showdown	2026-10-01 12:00:42.715259+05:30
act_2f90e319509575d7	gam_e75822285a6ada14	usr_8cf6038983567937	\N	PLAYER	MATCH_CREATED	Player hosted new match: Workflow Test Match 5v5	2026-10-01 15:26:29.509182+05:30
act_a8f6d8aa319eb278	gam_e75822285a6ada14	usr_8cf6038983567937	wf_player_1790848588497@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-10-01 15:26:29.528738+05:30
act_db7ca0f1e836c761	gam_e75822285a6ada14	usr_3956d119b0e3e452	wf_manager_1790848588497@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790848588497@example.com: Heavy rainfall alert on turf	2026-10-01 15:26:29.593849+05:30
act_f8c5b20537ceb1b6	gam_ef81f6e5d3401102	usr_ea7d22375987cbb3	manager_test_1790848588497@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-10-01 15:26:34.661204+05:30
act_dd73b341aa8c1bab	gam_ef81f6e5d3401102	usr_ea7d22375987cbb3	manager_test_1790848588497@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-10-01 15:26:34.698223+05:30
act_01161203329bdc9a	gam_e050071b75905b49	usr_372a9de0c155953d	\N	PLAYER	MATCH_CREATED	Player hosted new match: Workflow Test Match 5v5	2026-10-01 15:33:11.732222+05:30
act_6c6963e431078a5f	gam_e050071b75905b49	usr_372a9de0c155953d	wf_player_1790848991248@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-10-01 15:33:11.747488+05:30
act_ae18f329c8d27270	gam_e050071b75905b49	usr_77d1efe4afbc4c7f	wf_manager_1790848991248@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-10-01 15:33:11.765335+05:30
act_618af0b00f0e85ba	gam_e050071b75905b49	usr_77d1efe4afbc4c7f	wf_manager_1790848991248@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790848991248@example.com: Heavy rainfall alert on turf	2026-10-01 15:33:11.783786+05:30
act_781681ff596ae47d	gam_581ee86abd2a312c	usr_258e0b7430df83ca	\N	PLAYER	MATCH_CREATED	Player hosted new match: Workflow Test Match 5v5	2026-10-01 15:39:09.172982+05:30
act_d43c738634e08636	gam_581ee86abd2a312c	usr_258e0b7430df83ca	wf_player_1790849348212@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-10-01 15:39:09.195614+05:30
act_6190bdfa2fec1932	gam_581ee86abd2a312c	usr_4b2405663fda6e40	wf_manager_1790849348212@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-10-01 15:39:09.220808+05:30
act_a782c7fed153af53	gam_581ee86abd2a312c	usr_4b2405663fda6e40	wf_manager_1790849348212@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790849348212@example.com: Heavy rainfall alert on turf	2026-10-01 15:39:09.248316+05:30
act_12c8787bf76a1790	gam_ec058933f94ee983	usr_a0ea1d4f298d4a7e	manager_test_1790849348214@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-10-01 15:39:13.960974+05:30
act_4540f5425a25f4ff	gam_ec058933f94ee983	usr_a0ea1d4f298d4a7e	manager_test_1790849348214@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-10-01 15:39:13.987635+05:30
act_6c573ea7638686a0	gam_dd724d1c83d95503	usr_a1bd125a6a3dd41a	\N	PLAYER	MATCH_CREATED	Player hosted new match: Workflow Test Match 5v5	2026-10-01 15:47:11.59449+05:30
act_6daea5e2472b95dc	gam_dd724d1c83d95503	usr_a1bd125a6a3dd41a	wf_player_1790849831155@example.com	PLAYER	SLOT_REQUESTED	Player requested slot in position ST	2026-10-01 15:47:11.608584+05:30
act_d6119f30a653fb75	gam_dd724d1c83d95503	usr_a7b005600886fb63	wf_manager_1790849831155@example.com	MANAGER	SLOT_APPROVED	Manager approved Workflow Player for TEAM_A in position ST	2026-10-01 15:47:11.622392+05:30
act_1b36fbcab5f9fe67	gam_dd724d1c83d95503	usr_a7b005600886fb63	wf_manager_1790849831155@example.com	MANAGER	MATCH_CANCELLED	Match cancelled by manager wf_manager_1790849831155@example.com: Heavy rainfall alert on turf	2026-10-01 15:47:11.639234+05:30
act_55b8a6b6291397c2	gam_9a598b7b8a9764fb	usr_bd31992cc995573f	manager_test_1790849831200@example.com	MANAGER	MATCH_STARTED	Match status changed to ONGOING	2026-10-01 15:47:16.248745+05:30
act_bfa0070e2d74842d	gam_9a598b7b8a9764fb	usr_bd31992cc995573f	manager_test_1790849831200@example.com	MANAGER	MATCH_COMPLETED	Final Score: Team A 3 - 2 Team B	2026-10-01 15:47:16.269698+05:30
\.


--
-- TOC entry 6184 (class 0 OID 18331)
-- Dependencies: 240
-- Data for Name: game_players; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_players (id, game_id, user_id, team, "position", joined_at, payment_status) FROM stdin;
3	gam_87e6cc5754d47c1f	usr_1a92cc3ed067921f	TEAM_A	ST	2026-09-30 12:16:36.145751+05:30	PAID
4	gam_8aace32d261bc885	usr_fe8e1e4957015c39	TEAM_A	ST	2026-09-30 12:16:56.312576+05:30	PAID
5	gam_a88a0501a7d378ea	usr_332b68556f881273	TEAM_A	ST	2026-09-30 12:24:44.449664+05:30	PAID
6	gam_2033f60bab02b5e3	usr_fb4c3d97481d72eb	TEAM_A	ST	2026-09-30 12:31:04.905661+05:30	PAID
7	gam_a1614442619b1202	usr_e5af181f986f06b3	TEAM_A	ST	2026-09-30 12:35:40.222546+05:30	PAID
9	gam_4d9201df36534559	usr_afbec60a362f096d	TEAM_A	ST	2026-09-30 12:38:18.021359+05:30	PAID
10	gam_766d2fd26a9125d4	usr_3b955f3d4bb859f2	TEAM_A	ST	2026-09-30 12:39:01.557635+05:30	PAID
11	gam_32c59557874e14a2	usr_8279dc24442d924a	TEAM_A	ST	2026-09-30 13:53:21.907434+05:30	PAID
13	gam_e75822285a6ada14	usr_8cf6038983567937	TEAM_A	ST	2026-10-01 15:26:29.493211+05:30	PAID
14	gam_e050071b75905b49	usr_372a9de0c155953d	TEAM_A	ST	2026-10-01 15:33:11.765335+05:30	PAID
15	gam_581ee86abd2a312c	usr_258e0b7430df83ca	TEAM_A	ST	2026-10-01 15:39:09.220808+05:30	PAID
16	gam_dd724d1c83d95503	usr_a1bd125a6a3dd41a	TEAM_A	ST	2026-10-01 15:47:11.622392+05:30	PAID
12	gam_2210d508be115b28	usr_771ffc659cac6f5f	TEAM_A	ST	2026-10-01 12:00:42.701508+05:30	PAID
\.


--
-- TOC entry 6216 (class 0 OID 28159)
-- Dependencies: 272
-- Data for Name: game_slot_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_slot_requests (id, game_id, user_id, "position", status, rejection_reason, payment_status, entry_fee, created_at, updated_at) FROM stdin;
req_5e20b7b408882760	gam_bbd02484152bfd57	usr_2d339c1c8a60a7bf	ST	PENDING	\N	PAID	500.00	2026-09-30 12:09:45.735923+05:30	2026-09-30 12:09:45.735923+05:30
req_1c3d7344e526c7f4	gam_c967608774d9003e	usr_c04f1863db4f19c1	ST	PENDING	\N	PAID	500.00	2026-09-30 12:11:54.034092+05:30	2026-09-30 12:11:54.034092+05:30
req_9caf665d4b8691e7	gam_fd482c54fc356742	usr_39ea6b242671d81c	ST	PENDING	\N	PAID	500.00	2026-09-30 12:13:43.798834+05:30	2026-09-30 12:13:43.798834+05:30
req_729407024a191374	gam_87e6cc5754d47c1f	usr_1a92cc3ed067921f	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:16:36.129755+05:30	2026-09-30 12:16:36.145751+05:30
req_4de8aa9b6b2479d3	gam_8aace32d261bc885	usr_fe8e1e4957015c39	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:16:56.282741+05:30	2026-09-30 12:16:56.312576+05:30
req_867c2b8e4e6afa51	gam_a88a0501a7d378ea	usr_332b68556f881273	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:24:44.43113+05:30	2026-09-30 12:24:44.449664+05:30
req_b73daa964192f35e	gam_2033f60bab02b5e3	usr_fb4c3d97481d72eb	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:31:04.891013+05:30	2026-09-30 12:31:04.905661+05:30
req_ff2384bafd4abe1d	gam_a1614442619b1202	usr_e5af181f986f06b3	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:35:40.20037+05:30	2026-09-30 12:35:40.222546+05:30
req_10f50654098bb36c	gam_4d9201df36534559	usr_afbec60a362f096d	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:38:18.000913+05:30	2026-09-30 12:38:18.021359+05:30
req_5198b1c56da1b75e	gam_766d2fd26a9125d4	usr_3b955f3d4bb859f2	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 12:39:01.534017+05:30	2026-09-30 12:39:01.557635+05:30
req_cbdfd43672bbe3e3	gam_32c59557874e14a2	usr_8279dc24442d924a	ST	CANCELLED	\N	REFUNDED	500.00	2026-09-30 13:53:21.888154+05:30	2026-09-30 13:53:21.907434+05:30
req_4a9df0a815cd8af4	gam_2210d508be115b28	usr_771ffc659cac6f5f	ST	APPROVED	\N	PAID	200.00	2026-10-01 12:00:42.708953+05:30	2026-10-01 12:00:42.708953+05:30
req_498ce3fc9c34ac44	gam_e75822285a6ada14	usr_8cf6038983567937	ST	CANCELLED	\N	REFUNDED	500.00	2026-10-01 15:26:29.502677+05:30	2026-10-01 15:26:29.527433+05:30
req_c1cf133ef9422c79	gam_e050071b75905b49	usr_372a9de0c155953d	ST	CANCELLED	\N	REFUNDED	500.00	2026-10-01 15:33:11.745962+05:30	2026-10-01 15:33:11.765335+05:30
req_ba05127ded2a3db3	gam_581ee86abd2a312c	usr_258e0b7430df83ca	ST	CANCELLED	\N	REFUNDED	500.00	2026-10-01 15:39:09.193008+05:30	2026-10-01 15:39:09.220808+05:30
req_25e5f208b9b89b47	gam_dd724d1c83d95503	usr_a1bd125a6a3dd41a	ST	CANCELLED	\N	REFUNDED	500.00	2026-10-01 15:47:11.607111+05:30	2026-10-01 15:47:11.622392+05:30
\.


--
-- TOC entry 6207 (class 0 OID 18897)
-- Dependencies: 263
-- Data for Name: game_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_videos (id, game_id, club_id, court_id, title, video_url, uploaded_by_id, status, created_at) FROM stdin;
vid_60ef292695bb6b85	gam_6e330e1d9b09af84	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 11:40:16.434547+05:30
vid_014ff3efd1acc0c0	gam_5611ccb901e728af	clb_892ccefe31f5cb2b	crt_810d213d14af855f	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:02:03.287787+05:30
vid_22c960d0bdc34177	gam_26de53da21e63242	clb_55f167dc8cfe986a	crt_01216d2cc902d161	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:02:42.439064+05:30
vid_362945da90855f4e	gam_f6e46a446e817541	clb_72bca0f7c06e9462	crt_f44ec4c076698469	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:17:01.896505+05:30
vid_ef0432b7fb4c4ddd	gam_b907d464d302dc5e	clb_fea958bb77af0b4a	crt_d0477e882694ef6e	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:24:49.160413+05:30
vid_78d2d15e2409d8b7	gam_f6585e12cc2e86db	clb_0b9a81b26d0bd865	crt_622120525008f799	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:31:09.469974+05:30
vid_9b6c265d966c5f39	gam_9b5724754c596a8e	clb_25399b493711d9f6	crt_e9aebd84d1a45b5e	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:35:26.385004+05:30
vid_4652903fb5787512	gam_d444dab37116089f	clb_025c31836a629034	crt_0dbfee05854ba0b5	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:35:44.827229+05:30
vid_631159068f2a0dd1	gam_0833fb53de38015c	clb_92405048365e7300	crt_78bfec32ffaeb5d4	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:38:22.793299+05:30
vid_528c06ab54b042b3	gam_5c0611138195cfbc	clb_557caf9c1fe836f4	crt_10af24b2592f7d44	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 12:39:06.460855+05:30
vid_849fbd70ef637c39	gam_0ef5866bd945c307	clb_801bf7fe32c1a126	crt_a318fdf4adfb970d	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-09-30 13:50:08.520999+05:30
vid_665c9900cdfcaed5	gam_ef81f6e5d3401102	clb_203d6f7e50d4fe28	crt_661588e4de60b612	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-10-01 15:26:34.700792+05:30
vid_622a4713ab4b8a50	gam_ec058933f94ee983	clb_bd9db684bdb40a72	crt_7e9a7b9d0edb53ea	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-10-01 15:39:13.989865+05:30
vid_2ea517d1d364ed25	gam_9a598b7b8a9764fb	clb_1d096e1583a08995	crt_90b396ef6fc9e519	Match Recording	recordings/test.mp4	\N	AVAILABLE	2026-10-01 15:47:16.27138+05:30
\.


--
-- TOC entry 6186 (class 0 OID 18363)
-- Dependencies: 242
-- Data for Name: game_waitlist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_waitlist (id, game_id, user_id, team_preference, "position", waitlist_order, joined_at) FROM stdin;
\.


--
-- TOC entry 6182 (class 0 OID 18273)
-- Dependencies: 238
-- Data for Name: games; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.games (id, title, club_id, court_id, creator_id, creator_role_name, created_by_player, format, max_players, entry_fee, skill_requirement, privacy, match_date, start_time, end_time, status, team_a_score, team_b_score, winner_team, description, created_at, updated_at) FROM stdin;
gam_6e330e1d9b09af84	Manager Match	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_2cd11304a4ea973d	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 11:40:12.267395+05:30	2026-09-30 11:40:16.431794+05:30
gam_5611ccb901e728af	Manager Match	clb_892ccefe31f5cb2b	crt_810d213d14af855f	usr_6b892eeb30401c97	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:01:59.18855+05:30	2026-09-30 12:02:03.284973+05:30
gam_26de53da21e63242	Manager Match	clb_55f167dc8cfe986a	crt_01216d2cc902d161	usr_791dcac02f2279ba	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:02:38.152599+05:30	2026-09-30 12:02:42.433571+05:30
gam_bbd02484152bfd57	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_2d339c1c8a60a7bf	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-10-05	19:00:00	20:30:00	OPEN_FOR_JOINING	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:09:45.691234+05:30	2026-09-30 12:09:45.691234+05:30
gam_c967608774d9003e	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_c04f1863db4f19c1	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-10-11	19:00:00	20:30:00	OPEN_FOR_JOINING	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:11:53.995579+05:30	2026-09-30 12:11:53.995579+05:30
gam_fd482c54fc356742	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_39ea6b242671d81c	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-11-05	19:00:00	20:30:00	OPEN_FOR_JOINING	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:13:43.789666+05:30	2026-09-30 12:13:43.789666+05:30
gam_87e6cc5754d47c1f	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_1a92cc3ed067921f	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-12-01	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:16:36.11826+05:30	2026-09-30 12:16:36.158848+05:30
gam_8aace32d261bc885	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_fe8e1e4957015c39	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-10-13	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:16:56.260729+05:30	2026-09-30 12:16:56.338419+05:30
gam_f6e46a446e817541	Manager Match	clb_72bca0f7c06e9462	crt_f44ec4c076698469	usr_66623e82cb6ddd26	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:16:57.66721+05:30	2026-09-30 12:17:01.893454+05:30
gam_a88a0501a7d378ea	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_332b68556f881273	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2027-01-01	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:24:44.417673+05:30	2026-09-30 12:24:44.465915+05:30
gam_b907d464d302dc5e	Manager Match	clb_fea958bb77af0b4a	crt_d0477e882694ef6e	usr_31a34b67a1c9070a	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:24:45.046799+05:30	2026-09-30 12:24:49.157157+05:30
gam_2033f60bab02b5e3	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_fb4c3d97481d72eb	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2027-01-10	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:31:04.879809+05:30	2026-09-30 12:31:04.922045+05:30
gam_f6585e12cc2e86db	Manager Match	clb_0b9a81b26d0bd865	crt_622120525008f799	usr_8d8d233cb1520d3e	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:31:05.348105+05:30	2026-09-30 12:31:09.467293+05:30
gam_9b5724754c596a8e	Manager Match	clb_25399b493711d9f6	crt_e9aebd84d1a45b5e	usr_e43d0fd722732ad0	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:35:22.27434+05:30	2026-09-30 12:35:26.381612+05:30
gam_a1614442619b1202	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_e5af181f986f06b3	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-11-29	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:35:40.183299+05:30	2026-09-30 12:35:40.238331+05:30
gam_d444dab37116089f	Manager Match	clb_025c31836a629034	crt_0dbfee05854ba0b5	usr_5dd9bc34451d7881	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:35:40.706242+05:30	2026-09-30 12:35:44.82394+05:30
gam_4d9201df36534559	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_afbec60a362f096d	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-12-03	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:38:17.985895+05:30	2026-09-30 12:38:18.040423+05:30
gam_0833fb53de38015c	Manager Match	clb_92405048365e7300	crt_78bfec32ffaeb5d4	usr_046291f5a26cbfef	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:38:18.564899+05:30	2026-09-30 12:38:22.789933+05:30
gam_766d2fd26a9125d4	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_3b955f3d4bb859f2	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-12-19	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 12:39:01.517011+05:30	2026-09-30 12:39:01.579082+05:30
gam_5c0611138195cfbc	Manager Match	clb_557caf9c1fe836f4	crt_10af24b2592f7d44	usr_ae2a15190a816afa	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 12:39:02.233807+05:30	2026-09-30 12:39:06.457738+05:30
gam_0ef5866bd945c307	Manager Match	clb_801bf7fe32c1a126	crt_a318fdf4adfb970d	usr_f8b3a9c750f5c30e	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-09-30	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-09-30 13:50:04.297379+05:30	2026-09-30 13:50:08.517161+05:30
gam_32c59557874e14a2	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_8279dc24442d924a	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-11-12	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-09-30 13:53:21.876373+05:30	2026-09-30 13:53:21.928991+05:30
gam_2210d508be115b28	11v11 Football Showdown	clb_892ccefe31f5cb2b	crt_e50c6d9bec53f0e7	usr_771ffc659cac6f5f	PLAYER	t	11v11	22	200.00	Beginner	PUBLIC	2026-10-02	18:00:00	19:30:00	OPEN_FOR_JOINING	\N	\N	\N	\N	2026-10-01 12:00:42.687959+05:30	2026-10-01 12:00:42.687959+05:30
gam_e75822285a6ada14	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_8cf6038983567937	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-11-08	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-10-01 15:26:29.489982+05:30	2026-10-01 15:26:29.593849+05:30
gam_ef81f6e5d3401102	Manager Match	clb_203d6f7e50d4fe28	crt_661588e4de60b612	usr_ea7d22375987cbb3	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-10-01	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-10-01 15:26:30.515384+05:30	2026-10-01 15:26:34.696748+05:30
gam_e050071b75905b49	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_372a9de0c155953d	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-12-07	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-10-01 15:33:11.72974+05:30	2026-10-01 15:33:11.783786+05:30
gam_581ee86abd2a312c	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_258e0b7430df83ca	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2026-10-15	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-10-01 15:39:09.170085+05:30	2026-10-01 15:39:09.248316+05:30
gam_ec058933f94ee983	Manager Match	clb_bd9db684bdb40a72	crt_7e9a7b9d0edb53ea	usr_a0ea1d4f298d4a7e	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-10-01	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-10-01 15:39:09.867039+05:30	2026-10-01 15:39:13.986481+05:30
gam_dd724d1c83d95503	Workflow Test Match 5v5	clb_eadcbf1843fa28e7	crt_e50c6d9bec53f0e7	usr_a1bd125a6a3dd41a	PLAYER	t	5v5	10	500.00	Beginner	PUBLIC	2027-01-18	19:00:00	20:30:00	CANCELLED	\N	\N	\N	Test match for slot approval workflow	2026-10-01 15:47:11.592295+05:30	2026-10-01 15:47:11.639234+05:30
gam_9a598b7b8a9764fb	Manager Match	clb_1d096e1583a08995	crt_90b396ef6fc9e519	usr_bd31992cc995573f	MANAGER	f	11v11	22	200.00	Intermediate	PUBLIC	2026-10-01	18:00:00	19:30:00	COMPLETED	3	2	TEAM_A	\N	2026-10-01 15:47:12.157869+05:30	2026-10-01 15:47:16.268954+05:30
\.


--
-- TOC entry 6188 (class 0 OID 18398)
-- Dependencies: 244
-- Data for Name: live_score_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.live_score_logs (id, game_id, team_a_score, team_b_score, updated_by_user_id, is_final, created_at) FROM stdin;
1	gam_6e330e1d9b09af84	3	2	usr_2cd11304a4ea973d	t	2026-09-30 11:40:16.420043+05:30
2	gam_5611ccb901e728af	3	2	usr_6b892eeb30401c97	t	2026-09-30 12:02:03.278422+05:30
3	gam_26de53da21e63242	3	2	usr_791dcac02f2279ba	t	2026-09-30 12:02:42.423892+05:30
4	gam_f6e46a446e817541	3	2	usr_66623e82cb6ddd26	t	2026-09-30 12:17:01.885148+05:30
5	gam_b907d464d302dc5e	3	2	usr_31a34b67a1c9070a	t	2026-09-30 12:24:49.149037+05:30
6	gam_f6585e12cc2e86db	3	2	usr_8d8d233cb1520d3e	t	2026-09-30 12:31:09.461183+05:30
7	gam_9b5724754c596a8e	3	2	usr_e43d0fd722732ad0	t	2026-09-30 12:35:26.37396+05:30
8	gam_d444dab37116089f	3	2	usr_5dd9bc34451d7881	t	2026-09-30 12:35:44.816336+05:30
9	gam_0833fb53de38015c	3	2	usr_046291f5a26cbfef	t	2026-09-30 12:38:22.782164+05:30
10	gam_5c0611138195cfbc	3	2	usr_ae2a15190a816afa	t	2026-09-30 12:39:06.450229+05:30
11	gam_0ef5866bd945c307	3	2	usr_f8b3a9c750f5c30e	t	2026-09-30 13:50:08.50223+05:30
12	gam_ef81f6e5d3401102	3	2	usr_ea7d22375987cbb3	t	2026-10-01 15:26:34.682037+05:30
13	gam_ec058933f94ee983	3	2	usr_a0ea1d4f298d4a7e	t	2026-10-01 15:39:13.977994+05:30
14	gam_9a598b7b8a9764fb	3	2	usr_bd31992cc995573f	t	2026-10-01 15:47:16.262255+05:30
\.


--
-- TOC entry 6173 (class 0 OID 18007)
-- Dependencies: 229
-- Data for Name: manager_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.manager_details (user_id, created_by_admin_id, employee_code, created_at) FROM stdin;
usr_2868a49c6aa551f5	usr_e55abb463db8392d	\N	2026-09-29 15:33:09.732347+05:30
usr_2cd11304a4ea973d	usr_e55abb463db8392d	EMP_001	2026-09-30 11:40:11.684183+05:30
usr_6b892eeb30401c97	usr_e55abb463db8392d	EMP_001	2026-09-30 12:01:58.690929+05:30
usr_791dcac02f2279ba	usr_e55abb463db8392d	EMP_001	2026-09-30 12:02:37.522217+05:30
usr_9e1cc12535965c8a	usr_e55abb463db8392d	\N	2026-09-30 12:05:29.256271+05:30
usr_8b558de699670318	usr_e55abb463db8392d	\N	2026-09-30 12:06:05.703459+05:30
usr_99e86453b77b20f8	usr_e55abb463db8392d	\N	2026-09-30 12:06:44.580307+05:30
usr_a749ad15a4b83f56	usr_e55abb463db8392d	\N	2026-09-30 12:07:50.443186+05:30
usr_de3c7a69b61ef701	usr_e55abb463db8392d	\N	2026-09-30 12:08:44.665091+05:30
usr_8c526a10e5c1c5cb	usr_e55abb463db8392d	\N	2026-09-30 12:09:45.293739+05:30
usr_2b1f5e605b8f2010	usr_e55abb463db8392d	\N	2026-09-30 12:11:02.801639+05:30
usr_97d87fa5a02055dc	usr_e55abb463db8392d	\N	2026-09-30 12:11:53.604643+05:30
usr_4262abd5736887a7	usr_e55abb463db8392d	\N	2026-09-30 12:13:43.720247+05:30
usr_b1d7ea4b904ef79c	usr_e55abb463db8392d	\N	2026-09-30 12:16:36.042436+05:30
usr_7fa7260cfb9e0c26	usr_e55abb463db8392d	\N	2026-09-30 12:16:56.130232+05:30
usr_66623e82cb6ddd26	usr_e55abb463db8392d	EMP_001	2026-09-30 12:16:57.102498+05:30
usr_c641dbc8e3c7bf62	usr_e55abb463db8392d	\N	2026-09-30 12:24:44.31919+05:30
usr_31a34b67a1c9070a	usr_e55abb463db8392d	EMP_001	2026-09-30 12:24:44.513539+05:30
usr_0385a239ccd5b41d	usr_e55abb463db8392d	\N	2026-09-30 12:31:04.793055+05:30
usr_8d8d233cb1520d3e	usr_e55abb463db8392d	EMP_001	2026-09-30 12:31:04.7928+05:30
usr_e43d0fd722732ad0	usr_e55abb463db8392d	EMP_001	2026-09-30 12:35:21.783838+05:30
usr_adc575328dc2453a	usr_e55abb463db8392d	\N	2026-09-30 12:35:40.07508+05:30
usr_5dd9bc34451d7881	usr_e55abb463db8392d	EMP_001	2026-09-30 12:35:40.112289+05:30
usr_5cfc9ba5df459c07	usr_e55abb463db8392d	\N	2026-09-30 12:38:01.036421+05:30
usr_6bc672c4761b5a78	usr_e55abb463db8392d	\N	2026-09-30 12:38:17.881255+05:30
usr_046291f5a26cbfef	usr_e55abb463db8392d	EMP_001	2026-09-30 12:38:17.959253+05:30
usr_8ba4c28082ef21a7	usr_e55abb463db8392d	\N	2026-09-30 12:39:01.393994+05:30
usr_ae2a15190a816afa	usr_e55abb463db8392d	EMP_001	2026-09-30 12:39:01.638572+05:30
usr_f8b3a9c750f5c30e	usr_e55abb463db8392d	EMP_001	2026-09-30 13:50:03.556262+05:30
usr_4f9318878fbd93df	usr_e55abb463db8392d	\N	2026-09-30 13:53:21.784266+05:30
usr_3956d119b0e3e452	usr_e55abb463db8392d	\N	2026-10-01 15:26:29.334537+05:30
usr_ea7d22375987cbb3	usr_e55abb463db8392d	EMP_001	2026-10-01 15:26:29.487198+05:30
usr_77d1efe4afbc4c7f	usr_e55abb463db8392d	\N	2026-10-01 15:33:11.627342+05:30
usr_4b2405663fda6e40	usr_e55abb463db8392d	\N	2026-10-01 15:39:09.02113+05:30
usr_a0ea1d4f298d4a7e	usr_e55abb463db8392d	EMP_001	2026-10-01 15:39:09.096588+05:30
usr_a7b005600886fb63	usr_e55abb463db8392d	\N	2026-10-01 15:47:11.482114+05:30
usr_bd31992cc995573f	usr_e55abb463db8392d	EMP_001	2026-10-01 15:47:11.613754+05:30
\.


--
-- TOC entry 6202 (class 0 OID 18783)
-- Dependencies: 258
-- Data for Name: match_disputes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.match_disputes (id, game_id, reported_by_id, disputed_score, reason, status, winner_override, score_override, adjudicator_notes, dismissal_reason, resolved_at, created_at) FROM stdin;
\.


--
-- TOC entry 6206 (class 0 OID 18867)
-- Dependencies: 262
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, title, message, link_url, club_id, game_id, is_read, created_at) FROM stdin;
\.


--
-- TOC entry 6176 (class 0 OID 18072)
-- Dependencies: 232
-- Data for Name: otp_verifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.otp_verifications (id, user_id, identifier, channel, purpose, otp_hash, attempt_count, max_attempts, is_used, used_at, expires_at, ip_address, created_at) FROM stdin;
3	\N	player@gmail.com	EMAIL	REGISTRATION	535082	0	5	t	2026-09-29 12:55:21.06345+05:30	2026-09-29 13:04:47.787+05:30	\N	2026-09-29 12:54:47.792513+05:30
4	\N	yuvi23@gmail.com	EMAIL	REGISTRATION	628021	0	5	t	2026-09-29 13:28:18.158415+05:30	2026-09-29 13:37:53.198+05:30	\N	2026-09-29 13:27:53.203323+05:30
5	\N	rudra12@gmail.com	EMAIL	REGISTRATION	701078	0	5	t	2026-09-29 13:52:30.191608+05:30	2026-09-29 14:02:08.799+05:30	\N	2026-09-29 13:52:08.824569+05:30
17	usr_f87296a72c33648b	test_player_1790751284025@example.com	EMAIL	PASSWORD_RESET	$2b$10$SWgCsHW7lBWg6by62eFlneuN7unwqMfvyms7AcyTX2S7omNi/r6Wq	0	5	t	2026-09-30 12:24:46.177598+05:30	2026-09-30 12:34:45.821+05:30	\N	2026-09-30 12:24:45.824882+05:30
6	usr_4b474011146a3a70	yuvi23@gmail.com	EMAIL	PASSWORD_RESET	691309	2	5	t	2026-09-29 14:02:31.349628+05:30	2026-09-29 14:10:46.221+05:30	\N	2026-09-29 14:00:46.230896+05:30
7	usr_2868a49c6aa551f5	roshan12@gmail.com	EMAIL	PASSWORD_RESET	104343	0	5	t	2026-09-29 15:35:02.461173+05:30	2026-09-29 15:44:35.392+05:30	\N	2026-09-29 15:34:35.397402+05:30
34	usr_87256bb5c03dd033	test_player_1790849831152@example.com	EMAIL	PASSWORD_RESET	$2b$10$iBfo1B5ffbbM2JvYxoVR6.m8pRpUN.Avxi02eMX1TlyFkgTKjzT/6	0	5	t	2026-10-01 15:47:13.382664+05:30	2026-10-01 15:57:13.011+05:30	\N	2026-10-01 15:47:13.014986+05:30
8	\N	test_player_1790748611094@example.com	EMAIL	REGISTRATION	$2b$10$bD.CxZD6944RVfDnf.96guCQHKQxj0S1nwGdc.mWPYqXUsvVzvo..	1	5	t	2026-09-30 11:40:12.252988+05:30	2026-09-30 11:50:11.408+05:30	\N	2026-09-30 11:40:11.414888+05:30
31	\N	test_player_1790849348188@example.com	EMAIL	REGISTRATION	$2b$10$5tKZKOSqcrM0I4eHKWgzlen8i4QHy0UoSJGP29rPGrbybMBsFTtiG	1	5	t	2026-10-01 15:39:09.451576+05:30	2026-10-01 15:49:08.718+05:30	\N	2026-10-01 15:39:08.726441+05:30
9	usr_fb3b4ae1787a833c	test_player_1790748611094@example.com	EMAIL	PASSWORD_RESET	$2b$10$KpxRv6s78eN7sLb3G0rGgOLTuvEgUV6Z5Q5O63QyT2auo9aFCXB.G	0	5	t	2026-09-30 11:40:13.818294+05:30	2026-09-30 11:50:13.437+05:30	\N	2026-09-30 11:40:13.440427+05:30
18	\N	test_player_1790751664425@example.com	EMAIL	REGISTRATION	$2b$10$YBrD2vfD0oQvcPBoNGFX1.VGGXYOtV7A6HFi0n8it9pzaac1cXnI6	1	5	t	2026-09-30 12:31:05.09542+05:30	2026-09-30 12:41:04.535+05:30	\N	2026-09-30 12:31:04.543536+05:30
10	\N	test_player_1790749918179@example.com	EMAIL	REGISTRATION	$2b$10$Cs6yog1Es6E7bQ1XaPmcXuaRCpGpU/16rrkMHwWtow5efszo74ySO	1	5	t	2026-09-30 12:01:59.076221+05:30	2026-09-30 12:11:58.414+05:30	\N	2026-09-30 12:01:58.422827+05:30
26	\N	test_player_1790756565966@example.com	EMAIL	REGISTRATION	$2b$10$f0GVSP9jkOx0Kx9fD37S8uhrHoqF6K5YnnRdNM8CQpAAij97vLB9q	1	5	t	2026-09-30 13:52:46.894021+05:30	2026-09-30 14:02:46.042+05:30	\N	2026-09-30 13:52:46.051474+05:30
11	usr_a16b19a7d0fed768	test_player_1790749918179@example.com	EMAIL	PASSWORD_RESET	$2b$10$OgRoOrB9Y1i6m.kdI12FsOPLGb95sPhiLbo8STKo/4yLQWhKJ4toG	0	5	t	2026-09-30 12:02:00.381503+05:30	2026-09-30 12:12:00.022+05:30	\N	2026-09-30 12:02:00.025626+05:30
19	usr_6b06fb2b57910aaa	test_player_1790751664425@example.com	EMAIL	PASSWORD_RESET	$2b$10$kOUaanRuvLTrQQ83sqFiMuBL6kn1wzrFTXeDynWWR/r/3ursq60rS	0	5	t	2026-09-30 12:31:06.540141+05:30	2026-09-30 12:41:06.188+05:30	\N	2026-09-30 12:31:06.19258+05:30
12	\N	test_player_1790749957063@example.com	EMAIL	REGISTRATION	$2b$10$hMihR884yQtNYs8Lrj03puEzr7L5E3T5ePiadSIFIkvxBBp1OLQre	1	5	t	2026-09-30 12:02:37.76247+05:30	2026-09-30 12:12:37.188+05:30	\N	2026-09-30 12:02:37.195221+05:30
13	usr_d47727393c5cf58d	test_player_1790749957063@example.com	EMAIL	PASSWORD_RESET	$2b$10$dwS872t8aD1isstMuXNmN.zBWoyDXVWSlkxe7io0qcAvwb5HEWTs2	0	5	t	2026-09-30 12:02:39.374228+05:30	2026-09-30 12:12:38.985+05:30	\N	2026-09-30 12:02:38.989268+05:30
20	\N	test_player_1790751939728@example.com	EMAIL	REGISTRATION	$2b$10$aGQMgZSCAceYt6esubCe3uOFmnlpeRdZGhypSIDvPKmmIRqjRP8K2	1	5	t	2026-09-30 12:35:40.497815+05:30	2026-09-30 12:45:39.968+05:30	\N	2026-09-30 12:35:39.974845+05:30
14	\N	test_player_1790750816743@example.com	EMAIL	REGISTRATION	$2b$10$cLMn3LUrIZjvkxj/DJUPWuEGB9teHCy6LzRBcv96M9CoJKmEFLDpK	1	5	t	2026-09-30 12:16:57.42444+05:30	2026-09-30 12:26:56.858+05:30	\N	2026-09-30 12:16:56.866066+05:30
15	usr_c693284ad8ad5abe	test_player_1790750816743@example.com	EMAIL	PASSWORD_RESET	$2b$10$aKi6ZGw.5QzRD0XyGieshO.J9immp0rX0/XkozE9PFFViorwYhMam	0	5	t	2026-09-30 12:16:58.796024+05:30	2026-09-30 12:26:58.444+05:30	\N	2026-09-30 12:16:58.448222+05:30
27	usr_65fa9d3936098493	test_player_1790756565966@example.com	EMAIL	PASSWORD_RESET	$2b$10$tRj.0MmAB15pbNYQyo20Deu8e1PiyTv9r.uCXP/Q5od439okkMDe.	0	5	t	2026-09-30 13:52:48.509669+05:30	2026-09-30 14:02:48.073+05:30	\N	2026-09-30 13:52:48.079562+05:30
21	usr_551f76650073a64a	test_player_1790751939728@example.com	EMAIL	PASSWORD_RESET	$2b$10$rZkAZfPMwEzPzJn3V403c.Jb3MjUMyhFENz.NW2bfYppMnH76ROzW	0	5	t	2026-09-30 12:35:41.897487+05:30	2026-09-30 12:45:41.541+05:30	\N	2026-09-30 12:35:41.545155+05:30
16	\N	test_player_1790751284025@example.com	EMAIL	REGISTRATION	$2b$10$.BjI2u15f2P3VAgnrqNZk.wLryjMw6Q0mhU6.ZO5Ep3q7vkoYcRm.	1	5	t	2026-09-30 12:24:44.826006+05:30	2026-09-30 12:34:44.144+05:30	\N	2026-09-30 12:24:44.150938+05:30
22	\N	test_player_1790752097407@example.com	EMAIL	REGISTRATION	$2b$10$5HsijmGsJoJXUuyg0QXSnevqi0ULdPM8F2e7wE2EVbaLkQRR4r7m6	1	5	t	2026-09-30 12:38:22.567476+05:30	2026-09-30 12:48:17.533+05:30	\N	2026-09-30 12:38:17.538433+05:30
23	usr_3fd88a7c51a18416	test_player_1790752097407@example.com	EMAIL	PASSWORD_RESET	111813	0	5	f	\N	2026-09-30 12:48:23.544+05:30	\N	2026-09-30 12:38:23.547642+05:30
28	usr_2868a49c6aa551f5	roshan12@gmail.com	EMAIL	PASSWORD_RESET	494497	1	5	t	2026-09-30 17:46:57.150966+05:30	2026-09-30 17:56:02.646+05:30	\N	2026-09-30 17:46:02.65123+05:30
24	\N	test_player_1790752142116@example.com	EMAIL	REGISTRATION	$2b$10$BYrKZtMW7rNR8cdBMHm0ke0wGMfTHO5NfC.kgsgTvQcq0qRSI7hHq	1	5	t	2026-09-30 12:39:13.155072+05:30	2026-09-30 12:49:02.195+05:30	\N	2026-09-30 12:39:02.199719+05:30
32	usr_962f5f2641636fae	test_player_1790849348188@example.com	EMAIL	PASSWORD_RESET	$2b$10$PIiyAgNNavjkxT2BZbgZd.JPVkN9chL7ne5T2hyPqjIBATgLHYZj.	0	5	t	2026-10-01 15:39:11.287537+05:30	2026-10-01 15:49:10.856+05:30	\N	2026-10-01 15:39:10.860875+05:30
25	usr_249c7f996e96c57d	test_player_1790752142116@example.com	EMAIL	PASSWORD_RESET	$2b$10$rjnQGWqNlEcbK6LCxSeSae2MW6oH97QDo4rnCaZS2ULmYzfl/5vPm	0	5	t	2026-09-30 12:39:24.997483+05:30	2026-09-30 12:49:14.148+05:30	\N	2026-09-30 12:39:14.15201+05:30
29	\N	test_player_1790848588500@example.com	EMAIL	REGISTRATION	$2b$10$br6DHZJcX.lZIsiSrCAuT.kYRrBcolCHG9VXjgeTYNPSOxbW248qK	1	5	t	2026-10-01 15:26:30.152597+05:30	2026-10-01 15:36:29.101+05:30	\N	2026-10-01 15:26:29.114394+05:30
30	usr_8cb0d6db3214a9bc	test_player_1790848588500@example.com	EMAIL	PASSWORD_RESET	$2b$10$CwHmyrPXy4iK4zGPCyeszuOG/JjhzFiLEIeIm8X5KmnfFB7BcJbUG	0	5	t	2026-10-01 15:26:32.351917+05:30	2026-10-01 15:36:31.92+05:30	\N	2026-10-01 15:26:31.924878+05:30
33	\N	test_player_1790849831152@example.com	EMAIL	REGISTRATION	$2b$10$TNVyzE/P9LnNSrf8mSo2QuQgDhTTu2MIpHgxHUGb5cn8IXRA.A81S	1	5	t	2026-10-01 15:47:12.001447+05:30	2026-10-01 15:57:11.278+05:30	\N	2026-10-01 15:47:11.285858+05:30
\.


--
-- TOC entry 6210 (class 0 OID 19755)
-- Dependencies: 266
-- Data for Name: payment_orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_orders (id, user_id, provider, provider_order_id, provider_payment_id, idempotency_key, amount_paise, currency, purpose, status, metadata, created_at, updated_at, paid_at, expires_at) FROM stdin;
pay_dfe4249d9b565bb5	usr_b3d3f31095d1547a	RAZORPAY	rzp_order_mock_1790748611928	\N	idemp_1790748611794_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 11:40:11.799427+05:30	2026-09-30 12:01:58.728215+05:30	\N	2026-09-30 11:45:11.799427+05:30
pay_635b961deba5e624	usr_b3d3f31095d1547a	RAZORPAY	rzp_order_mock_1790748611989	\N	idemp_1790748611931_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 11:40:11.934534+05:30	2026-09-30 12:01:58.728215+05:30	\N	2026-09-30 11:45:11.934534+05:30
pay_e3d196bb5b742d3a	usr_42b6e7a87221c857	RAZORPAY	rzp_order_mock_1790749918833	\N	idemp_1790749918724_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:01:58.728215+05:30	2026-09-30 12:16:57.160688+05:30	\N	2026-09-30 12:06:58.728215+05:30
pay_55dee05d793ea92f	usr_42b6e7a87221c857	RAZORPAY	rzp_order_mock_1790749918889	\N	idemp_1790749918836_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:01:58.839244+05:30	2026-09-30 12:16:57.160688+05:30	\N	2026-09-30 12:06:58.839244+05:30
pay_96e994b7b5be3417	usr_d7f33014a1b8ee7e	RAZORPAY	rzp_order_mock_1790749957948	\N	idemp_1790749957810_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:02:37.816806+05:30	2026-09-30 12:16:57.160688+05:30	\N	2026-09-30 12:07:37.816806+05:30
pay_988f343124a217c6	usr_d7f33014a1b8ee7e	RAZORPAY	rzp_order_mock_1790749958012	\N	idemp_1790749957951_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:02:37.956435+05:30	2026-09-30 12:16:57.160688+05:30	\N	2026-09-30 12:07:37.956435+05:30
pay_82bb2771c0636e59	usr_483214e785cf434a	RAZORPAY	rzp_order_mock_1790750817283	\N	idemp_1790750817156_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:16:57.160688+05:30	2026-09-30 12:24:44.561131+05:30	\N	2026-09-30 12:21:57.160688+05:30
pay_091ba17fc5402d26	usr_483214e785cf434a	RAZORPAY	rzp_order_mock_1790750817350	\N	idemp_1790750817286_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:16:57.290505+05:30	2026-09-30 12:24:44.561131+05:30	\N	2026-09-30 12:21:57.290505+05:30
pay_f55c7c020f0f87a4	usr_d3fe85aa55a03730	RAZORPAY	rzp_order_mock_1790751284678	\N	idemp_1790751284557_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:24:44.561131+05:30	2026-09-30 12:30:43.029831+05:30	\N	2026-09-30 12:29:44.561131+05:30
pay_8cd94b6d66f7bc30	usr_d3fe85aa55a03730	RAZORPAY	rzp_order_mock_1790751284736	\N	idemp_1790751284681_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:24:44.684811+05:30	2026-09-30 12:30:43.029831+05:30	\N	2026-09-30 12:29:44.684811+05:30
pay_83672cdea7972248	usr_441c0e3d289b7aac	RAZORPAY	rzp_order_mock_1790751643079	\N	idemp_valid_1790751643027	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:30:43.029831+05:30	2026-09-30 12:38:18.001913+05:30	\N	2026-09-30 12:35:43.029831+05:30
pay_5309ab5a92fe3ea5	usr_441c0e3d289b7aac	RAZORPAY	rzp_order_mock_1790751643131	\N	idemp_sig_1790751643083	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:30:43.085895+05:30	2026-09-30 12:38:18.001913+05:30	\N	2026-09-30 12:35:43.085895+05:30
pay_1678202bff1a7e9b	usr_b636f1ae7e91e71f	RAZORPAY	rzp_order_mock_1790751664970	\N	idemp_valid_1790751664907	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:31:04.91048+05:30	2026-09-30 12:38:18.001913+05:30	\N	2026-09-30 12:36:04.91048+05:30
pay_a7b9199ca5c38f46	usr_b636f1ae7e91e71f	RAZORPAY	rzp_order_mock_1790751665035	\N	idemp_sig_1790751664974	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:31:04.977715+05:30	2026-09-30 12:38:18.001913+05:30	\N	2026-09-30 12:36:04.977715+05:30
pay_de8487e371acdf9f	usr_65c1f48cff9008b3	RAZORPAY	rzp_order_mock_1790751665065	\N	idemp_1790751664940_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:31:04.94466+05:30	2026-09-30 12:38:18.001913+05:30	\N	2026-09-30 12:36:04.94466+05:30
pay_10b520900584c2bc	usr_65c1f48cff9008b3	RAZORPAY	rzp_order_mock_1790751665123	\N	idemp_1790751665067_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:31:05.070553+05:30	2026-09-30 12:38:18.001913+05:30	\N	2026-09-30 12:36:05.070553+05:30
pay_ed892d325809fc29	usr_2afcf6367d1dc020	RAZORPAY	rzp_order_mock_1790751940298	\N	idemp_valid_1790751940232	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:35:40.236292+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:40:40.236292+05:30
pay_a6a589a0f5c4db0f	usr_390269341390c4dd	RAZORPAY	rzp_order_mock_1790751940338	\N	idemp_1790751940211_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:35:40.217285+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:40:40.217285+05:30
pay_50099893dc059fee	usr_2afcf6367d1dc020	RAZORPAY	rzp_order_mock_1790751940359	\N	idemp_sig_1790751940302	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:35:40.305532+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:40:40.305532+05:30
pay_6bb7d4b436dc5676	usr_390269341390c4dd	RAZORPAY	rzp_order_mock_1790751940401	\N	idemp_1790751940341_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:35:40.345834+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:40:40.345834+05:30
pay_40462c18a1ac15d7	usr_e03c44f59bbff28f	RAZORPAY	rzp_order_mock_1790752098136	\N	idemp_1790752097997_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:38:18.001913+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:43:18.001913+05:30
pay_d4d6027f49511ac7	usr_8c69afe724c09d49	RAZORPAY	rzp_order_mock_1790752098161	\N	idemp_valid_1790752098098	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:38:18.102451+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:43:18.102451+05:30
pay_1987723cfc1319b2	usr_e03c44f59bbff28f	RAZORPAY	rzp_order_mock_1790752098196	\N	idemp_1790752098139_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:38:18.143187+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:43:18.143187+05:30
pay_a0234d77710ef0a6	usr_8c69afe724c09d49	RAZORPAY	rzp_order_mock_1790752098221	\N	idemp_sig_1790752098165	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:38:18.169615+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:43:18.169615+05:30
pay_defbfc7b70c2915d	usr_a7b4c5abd3ed76c5	RAZORPAY	rzp_order_mock_1790752141678	\N	idemp_valid_1790752141605	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:39:01.610557+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:44:01.610557+05:30
pay_a9e48c6904b2ff74	usr_a7b4c5abd3ed76c5	RAZORPAY	rzp_order_mock_1790752141742	\N	idemp_sig_1790752141683	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:39:01.688645+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:44:01.688645+05:30
pay_38497ae07249f532	usr_1f42ebc28c735546	RAZORPAY	rzp_order_mock_1790752141813	\N	idemp_1790752141686_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:39:01.693468+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:44:01.693468+05:30
pay_0b4b403069bf5f7c	usr_1f42ebc28c735546	RAZORPAY	rzp_order_mock_1790752141871	\N	idemp_1790752141816_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 12:39:01.819576+05:30	2026-09-30 13:51:37.955566+05:30	\N	2026-09-30 12:44:01.819576+05:30
pay_f31c344ad1e21bc3	usr_b7675a4a677cc52c	RAZORPAY	rzp_order_mock_1790756498137	\N	idemp_1790756497948_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 13:51:37.955566+05:30	2026-10-01 15:26:29.639891+05:30	\N	2026-09-30 13:56:37.955566+05:30
pay_403a92751aba53b6	usr_b7675a4a677cc52c	RAZORPAY	rzp_order_mock_1790756498234	\N	idemp_1790756498142_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 13:51:38.148173+05:30	2026-10-01 15:26:29.639891+05:30	\N	2026-09-30 13:56:38.148173+05:30
pay_cf2d935972169955	usr_386a8db5450ed2bf	RAZORPAY	rzp_order_mock_1790756630289	\N	idemp_valid_1790756630224	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 13:53:50.232523+05:30	2026-10-01 15:26:29.639891+05:30	\N	2026-09-30 13:58:50.232523+05:30
pay_a7a5fdb82b0e1fef	usr_386a8db5450ed2bf	RAZORPAY	rzp_order_mock_1790756630351	\N	idemp_sig_1790756630293	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-09-30 13:53:50.301024+05:30	2026-10-01 15:26:29.639891+05:30	\N	2026-09-30 13:58:50.301024+05:30
pay_86182c88f0403326	usr_aaba6c37ed2fbd00	RAZORPAY	order_TibOuADpewYfDa	\N	idemp_valid_1790848589716	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:26:29.723048+05:30	2026-10-01 15:39:09.229585+05:30	\N	2026-10-01 15:31:29.723048+05:30
pay_9dc2201621b199a9	usr_73c45d42f9750142	RAZORPAY	order_TibOuPdzDfv7d1	\N	idemp_1790848589633_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:26:29.639891+05:30	2026-10-01 15:39:09.229585+05:30	\N	2026-10-01 15:31:29.639891+05:30
pay_5846a6718547c905	usr_aaba6c37ed2fbd00	RAZORPAY	order_TibOuQOi2Fmogm	\N	idemp_sig_1790848590133	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:26:30.137499+05:30	2026-10-01 15:39:09.229585+05:30	\N	2026-10-01 15:31:30.137499+05:30
pay_956555a13e8418ff	usr_73c45d42f9750142	RAZORPAY	order_TibOudoP6GKzxL	\N	idemp_1790848590391_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:26:30.396954+05:30	2026-10-01 15:39:09.229585+05:30	\N	2026-10-01 15:31:30.396954+05:30
pay_4822e9b65f25f123	usr_e9919c23c0467ea5	RAZORPAY	order_TibcH9mCjhYgBL	\N	idemp_valid_1790849349327	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:39:09.333011+05:30	2026-10-01 15:47:11.709642+05:30	\N	2026-10-01 15:44:09.333011+05:30
pay_b48e1bcd2b19702a	usr_e9919c23c0467ea5	RAZORPAY	order_TibcHJYIKrqBSN	\N	idemp_sig_1790849349578	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:39:09.583398+05:30	2026-10-01 15:47:11.709642+05:30	\N	2026-10-01 15:44:09.583398+05:30
pay_33318ec96ff9df8a	usr_f16724c6f8d5f94d	RAZORPAY	order_TibcHcwIMiLQzx	\N	idemp_1790849349222_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:39:09.229585+05:30	2026-10-01 15:47:11.709642+05:30	\N	2026-10-01 15:44:09.229585+05:30
pay_6e158122a9fc57ee	usr_f16724c6f8d5f94d	RAZORPAY	order_TibcHnxTPIzt6L	\N	idemp_1790849350024_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:39:10.028495+05:30	2026-10-01 15:47:11.709642+05:30	\N	2026-10-01 15:44:10.028495+05:30
pay_026ed1380c70ae2b	usr_d012c52d94f984bc	RAZORPAY	order_TibklnDucUJyTW	\N	idemp_valid_1790849831714	100000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:47:11.718368+05:30	2026-10-01 16:33:10.64226+05:30	\N	2026-10-01 15:52:11.718368+05:30
pay_514729909631bae8	usr_b2c56e4b881cf6fb	RAZORPAY	order_TibklwB0s1mzgZ	\N	idemp_1790849831705_valid_12345	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:47:11.709642+05:30	2026-10-01 16:33:10.64226+05:30	\N	2026-10-01 15:52:11.709642+05:30
pay_a0cde01efc29f039	usr_d012c52d94f984bc	RAZORPAY	order_TibklwQIqNlenV	\N	idemp_sig_1790849832029	50000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:47:12.032338+05:30	2026-10-01 16:33:10.64226+05:30	\N	2026-10-01 15:52:12.032338+05:30
pay_2c09d1d89ea5250f	usr_b2c56e4b881cf6fb	RAZORPAY	order_Tibkm6LITWdPT3	\N	idemp_1790849832162_tamper_12345	10000	INR	WALLET_TOPUP	EXPIRED	{}	2026-10-01 15:47:12.165616+05:30	2026-10-01 16:33:10.64226+05:30	\N	2026-10-01 15:52:12.165616+05:30
pay_073e23865216c0a9	usr_62068e8f5fc912b3	RAZORPAY	order_TicXLVcshuf1A5	\N	idemp_1790852590638_valid_12345	50000	INR	WALLET_TOPUP	PENDING	{}	2026-10-01 16:33:10.64226+05:30	2026-10-01 16:33:11.138148+05:30	\N	2026-10-01 16:38:10.64226+05:30
pay_3da317a8ca85636f	usr_62068e8f5fc912b3	RAZORPAY	order_TicXLv3GDTZ3jK	\N	idemp_1790852591140_tamper_12345	10000	INR	WALLET_TOPUP	PENDING	{}	2026-10-01 16:33:11.143867+05:30	2026-10-01 16:33:11.512872+05:30	\N	2026-10-01 16:38:11.143867+05:30
pay_6bbc473df2073c78	usr_771ffc659cac6f5f	RAZORPAY	order_TjJUEqRDmd1TDv	\N	topup_1791003845403	50000	INR	WALLET_TOPUP	PENDING	{}	2026-10-03 10:34:06.502125+05:30	2026-10-03 10:34:06.808294+05:30	\N	2026-10-03 10:39:06.502125+05:30
pay_bbbb33321ae459b9	usr_771ffc659cac6f5f	RAZORPAY	order_TjJZxaTXLCwXeP	\N	game_pay_1791004170450	20000	INR	WALLET_TOPUP	PENDING	{}	2026-10-03 10:39:31.532012+05:30	2026-10-03 10:39:31.77957+05:30	\N	2026-10-03 10:44:31.532012+05:30
pay_b9eace0d3ad50e29	usr_771ffc659cac6f5f	RAZORPAY	order_TjJvjdhmXWPNJn	\N	topup_1791005407072	50000	INR	WALLET_TOPUP	FAILED	{"failureReason": "new row for relation \\"payment_orders\\" violates check constraint \\"payment_orders_status_check\\""}	2026-10-03 11:00:08.190779+05:30	2026-10-03 11:00:26.910983+05:30	\N	2026-10-03 11:05:08.190779+05:30
pay_c2e692e050ff0974	usr_771ffc659cac6f5f	RAZORPAY	order_TjL7sEUmGL0M74	\N	game_pay_1791009617953	10000	INR	WALLET_TOPUP	FAILED	{"failureReason": "new row for relation \\"payment_orders\\" violates check constraint \\"payment_orders_status_check\\""}	2026-10-03 12:10:19.058726+05:30	2026-10-03 12:10:40.062553+05:30	\N	2026-10-03 12:15:19.058726+05:30
\.


--
-- TOC entry 6212 (class 0 OID 19798)
-- Dependencies: 268
-- Data for Name: payment_webhook_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_webhook_events (id, provider, event_id, event_type, payment_order_id, signature_verified, payload, processing_status, received_at, processed_at) FROM stdin;
1	RAZORPAY	evt_test_dedup_1790748611997	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_b3d3f31095d1547a", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790748611997"}	PROCESSED	2026-09-30 11:40:12.000712+05:30	2026-09-30 11:40:12.0042+05:30
3	RAZORPAY	evt_test_dedup_1790749918897	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_42b6e7a87221c857", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790749918897"}	PROCESSED	2026-09-30 12:01:58.900469+05:30	2026-09-30 12:01:58.902202+05:30
5	RAZORPAY	evt_test_dedup_1790749958022	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_d7f33014a1b8ee7e", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790749958022"}	PROCESSED	2026-09-30 12:02:38.026512+05:30	2026-09-30 12:02:38.028329+05:30
7	RAZORPAY	evt_test_dedup_1790750817359	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_483214e785cf434a", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790750817359"}	PROCESSED	2026-09-30 12:16:57.363007+05:30	2026-09-30 12:16:57.364647+05:30
9	RAZORPAY	evt_test_dedup_1790751284745	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_d3fe85aa55a03730", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790751284745"}	PROCESSED	2026-09-30 12:24:44.748262+05:30	2026-09-30 12:24:44.750401+05:30
11	RAZORPAY	evt_test_1790751554621	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_d2c85356dd19365c"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790751554621"}	PROCESSED	2026-09-30 12:29:14.625089+05:30	2026-09-30 12:29:14.626976+05:30
13	RAZORPAY	evt_test_1790751643142	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_441c0e3d289b7aac"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790751643142"}	PROCESSED	2026-09-30 12:30:43.144316+05:30	2026-09-30 12:30:43.145687+05:30
15	RAZORPAY	evt_test_1790751665046	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_b636f1ae7e91e71f"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790751665046"}	PROCESSED	2026-09-30 12:31:05.049707+05:30	2026-09-30 12:31:05.051249+05:30
17	RAZORPAY	evt_test_dedup_1790751665130	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_65c1f48cff9008b3", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790751665130"}	PROCESSED	2026-09-30 12:31:05.133664+05:30	2026-09-30 12:31:05.13536+05:30
19	RAZORPAY	evt_test_1790751940373	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_2afcf6367d1dc020"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790751940373"}	PROCESSED	2026-09-30 12:35:40.376675+05:30	2026-09-30 12:35:40.378404+05:30
21	RAZORPAY	evt_test_dedup_1790751940411	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_390269341390c4dd", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790751940411"}	PROCESSED	2026-09-30 12:35:40.416749+05:30	2026-09-30 12:35:40.418516+05:30
23	RAZORPAY	evt_test_dedup_1790752098204	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_e03c44f59bbff28f", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790752098204"}	PROCESSED	2026-09-30 12:38:18.208294+05:30	2026-09-30 12:38:18.210234+05:30
25	RAZORPAY	evt_test_1790752098233	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_8c69afe724c09d49"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790752098233"}	PROCESSED	2026-09-30 12:38:18.236027+05:30	2026-09-30 12:38:18.2379+05:30
27	RAZORPAY	evt_test_1790752141755	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_a7b4c5abd3ed76c5"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790752141755"}	PROCESSED	2026-09-30 12:39:01.759265+05:30	2026-09-30 12:39:01.761355+05:30
29	RAZORPAY	evt_test_dedup_1790752141881	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_1f42ebc28c735546", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790752141881"}	PROCESSED	2026-09-30 12:39:01.884789+05:30	2026-09-30 12:39:01.886804+05:30
31	RAZORPAY	evt_test_dedup_1790756498248	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_b7675a4a677cc52c", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790756498248"}	PROCESSED	2026-09-30 13:51:38.256686+05:30	2026-09-30 13:51:38.263473+05:30
33	RAZORPAY	evt_test_1790756630363	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_386a8db5450ed2bf"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790756630363"}	PROCESSED	2026-09-30 13:53:50.370322+05:30	2026-09-30 13:53:50.372056+05:30
35	RAZORPAY	evt_test_1790848590412	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_aaba6c37ed2fbd00"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790848590412"}	PROCESSED	2026-10-01 15:26:30.418377+05:30	2026-10-01 15:26:30.42698+05:30
37	RAZORPAY	evt_test_dedup_1790848590610	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_73c45d42f9750142", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790848590610"}	PROCESSED	2026-10-01 15:26:30.617767+05:30	2026-10-01 15:26:30.620801+05:30
39	RAZORPAY	evt_test_1790849349824	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_e9919c23c0467ea5"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790849349824"}	PROCESSED	2026-10-01 15:39:09.827688+05:30	2026-10-01 15:39:09.830277+05:30
41	RAZORPAY	evt_test_dedup_1790849350235	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_f16724c6f8d5f94d", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790849350235"}	PROCESSED	2026-10-01 15:39:10.240293+05:30	2026-10-01 15:39:10.24191+05:30
43	RAZORPAY	evt_test_1790849832166	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook_mock", "notes": {"userId": "usr_d012c52d94f984bc"}, "amount": 50000, "currency": "INR"}}}, "event_id": "evt_test_1790849832166"}	PROCESSED	2026-10-01 15:47:12.169828+05:30	2026-10-01 15:47:12.171687+05:30
45	RAZORPAY	evt_test_dedup_1790849832316	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_b2c56e4b881cf6fb", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790849832316"}	PROCESSED	2026-10-01 15:47:12.319947+05:30	2026-10-01 15:47:12.321444+05:30
47	RAZORPAY	evt_test_dedup_1790852591520	payment.captured	\N	t	{"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_test_987", "notes": {"userId": "usr_62068e8f5fc912b3", "paymentOrderId": "pay_dummy_123"}, "amount": 50000, "status": "captured"}}}, "event_id": "evt_test_dedup_1790852591520"}	PROCESSED	2026-10-01 16:33:11.524839+05:30	2026-10-01 16:33:11.534427+05:30
\.


--
-- TOC entry 6174 (class 0 OID 18026)
-- Dependencies: 230
-- Data for Name: player_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_details (user_id, "position", preferred_foot, skill_level, elo_rating, ovr_rating, badges, wallet_balance, created_at, updated_at, wallet_pin_hash, wallet_pin_set_at, wallet_pin_failed_attempts, wallet_pin_locked_until, secondary_position) FROM stdin;
usr_771ffc659cac6f5f	CM	Right	Intermediate	1500	70	["NewRecruit"]	825.00	2026-09-29 12:55:42.602639+05:30	2026-10-03 12:14:18.917651+05:30	$2a$06$CYa9TbuodExpEEW2p/5jd.PtdQHOkvYMKWps53gBJvnOSnZl1oHMy	2026-10-03 12:11:56.391313+05:30	0	\N	\N
usr_4b474011146a3a70	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-29 13:28:37.809414+05:30	2026-09-29 13:28:37.809414+05:30	\N	\N	0	\N	\N
usr_a7845baf785372f9	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-29 13:52:53.104083+05:30	2026-09-29 13:52:53.104083+05:30	\N	\N	0	\N	\N
usr_1a92cc3ed067921f	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:16:35.943967+05:30	2026-09-30 12:16:36.158848+05:30	\N	\N	0	\N	\N
usr_d7f33014a1b8ee7e	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:02:37.43305+05:30	2026-09-30 12:02:37.956435+05:30	$2a$10$tPPBUCn1gerPDKyisnhehO5c.mIXjTG/g1V6t2OtIHY5vXezUDDZq	2026-09-30 12:02:37.455122+05:30	0	\N	\N
usr_e4fa19886f0b282e	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 11:40:11.382789+05:30	2026-09-30 11:40:11.582766+05:30	\N	\N	0	\N	\N
usr_d47727393c5cf58d	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:02:38.041656+05:30	2026-09-30 12:02:38.041656+05:30	\N	\N	0	\N	\N
usr_a16b19a7d0fed768	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:01:59.298554+05:30	2026-09-30 12:04:01.815016+05:30	\N	\N	0	\N	\N
usr_1fbef46f504fc1b9	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 11:40:11.984118+05:30	2026-09-30 11:40:11.984118+05:30	\N	\N	0	\N	\N
usr_b3d3f31095d1547a	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 11:40:11.405167+05:30	2026-09-30 11:40:11.934534+05:30	$2a$10$LntM25oHWDbaroxBopcPhOWteLANVGAhOcHldOYI3.VVpIk0kU53C	2026-09-30 11:40:11.432706+05:30	0	\N	\N
usr_fb3b4ae1787a833c	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 11:40:12.5215+05:30	2026-09-30 11:40:12.5215+05:30	\N	\N	0	\N	\N
usr_712ee3524ce3dde7	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:04:47.973032+05:30	2026-09-30 12:04:47.995027+05:30	\N	\N	0	\N	\N
usr_837a15479a780030	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:05:29.154158+05:30	2026-09-30 12:05:29.166447+05:30	\N	\N	0	\N	\N
usr_26cd79c91e36a2ec	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:01:58.446913+05:30	2026-09-30 12:01:58.572573+05:30	\N	\N	0	\N	\N
usr_d2c85356dd19365c	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:29:14.429098+05:30	2026-09-30 12:29:14.429098+05:30	\N	\N	0	\N	\N
usr_eb0b001d22f07016	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:06:05.601039+05:30	2026-09-30 12:06:05.613481+05:30	\N	\N	0	\N	\N
usr_42b6e7a87221c857	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:01:58.437808+05:30	2026-09-30 12:01:58.839244+05:30	$2a$10$dpcikcbozopnLgEm6RgIvuaBMml7ESJnOsjhWthX8Bqcpqvuzhqya	2026-09-30 12:01:58.457552+05:30	0	\N	\N
usr_d156636dc63e5f89	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:01:58.950252+05:30	2026-09-30 12:01:58.950252+05:30	\N	\N	0	\N	\N
usr_fe8e1e4957015c39	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:16:55.952649+05:30	2026-09-30 12:16:56.338419+05:30	\N	\N	0	\N	\N
usr_1c1c8a9a99910f99	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:06:44.478138+05:30	2026-09-30 12:06:44.490585+05:30	\N	\N	0	\N	\N
usr_1b2be606008073f9	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:02:37.369829+05:30	2026-09-30 12:02:37.549147+05:30	\N	\N	0	\N	\N
usr_c2900f81677f6b40	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:07:49.981544+05:30	2026-09-30 12:07:49.99762+05:30	\N	\N	0	\N	\N
usr_501bb44eb891425b	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:02:37.859559+05:30	2026-09-30 12:02:37.859559+05:30	\N	\N	0	\N	\N
usr_072c197d8fd4f7a3	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:08:44.224652+05:30	2026-09-30 12:08:44.244728+05:30	\N	\N	0	\N	\N
usr_a73a6f4cffbc42b8	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:29:14.534356+05:30	2026-09-30 12:29:14.534356+05:30	\N	\N	0	\N	\N
usr_2d339c1c8a60a7bf	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:09:44.742049+05:30	2026-09-30 12:09:44.759068+05:30	\N	\N	0	\N	\N
usr_d032febee8660434	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:11:02.703715+05:30	2026-09-30 12:11:02.713932+05:30	\N	\N	0	\N	\N
usr_426334eee09db891	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:24:44.210874+05:30	2026-09-30 12:24:44.366852+05:30	\N	\N	0	\N	\N
usr_c04f1863db4f19c1	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:11:53.149978+05:30	2026-09-30 12:11:53.166848+05:30	\N	\N	0	\N	\N
usr_70cf84b74a8d0975	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:16:57.003569+05:30	2026-09-30 12:16:57.1467+05:30	\N	\N	0	\N	\N
usr_39ea6b242671d81c	CM	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:13:43.628109+05:30	2026-09-30 12:13:43.638484+05:30	\N	\N	0	\N	\N
usr_332b68556f881273	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:24:44.19241+05:30	2026-09-30 12:24:44.465915+05:30	\N	\N	0	\N	\N
usr_2ecf15c886956bdd	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:30:00.57832+05:30	2026-09-30 12:30:00.57832+05:30	\N	\N	0	\N	\N
usr_483214e785cf434a	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:16:56.813757+05:30	2026-09-30 12:16:57.290505+05:30	$2a$10$ffL/xOA2jFPuuYLl99wvX.Y9w95jKjRqoLFXvqByM.CFzA85ymF22	2026-09-30 12:16:56.844423+05:30	0	\N	\N
usr_e8dd3605e526e61d	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:16:57.411336+05:30	2026-09-30 12:16:57.411336+05:30	\N	\N	0	\N	\N
usr_c693284ad8ad5abe	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:16:57.671051+05:30	2026-09-30 12:16:57.671051+05:30	\N	\N	0	\N	\N
usr_d3fe85aa55a03730	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:24:44.229513+05:30	2026-09-30 12:24:44.684811+05:30	$2a$10$O9BUOVB1qUJJVvK9RrUudu51uULrVdLDcCcwq77ZbYr0AyTA3IUb.	2026-09-30 12:24:44.247934+05:30	0	\N	\N
usr_e52ef76965d3db06	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:24:44.790603+05:30	2026-09-30 12:24:44.790603+05:30	\N	\N	0	\N	\N
usr_f87296a72c33648b	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:24:45.068578+05:30	2026-09-30 12:24:45.068578+05:30	\N	\N	0	\N	\N
usr_f28801a3540af399	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:30:42.906984+05:30	2026-09-30 12:30:42.908514+05:30	$2a$10$qCb43LKub8qaWBG9nTwa7umdpGmBUgFI8K6HtAfUZci7kcb4pJwOO	2026-09-30 12:30:42.908514+05:30	0	\N	\N
usr_441c0e3d289b7aac	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:30:42.75968+05:30	2026-09-30 12:30:43.085895+05:30	$2a$10$bDfjL4KdVIVsRNOqJ.XSNeFhhAsQOAeeOO1dVj/9eTm.PK2adu/aO	2026-09-30 12:30:42.772707+05:30	0	\N	\N
usr_b636f1ae7e91e71f	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:31:04.576239+05:30	2026-09-30 12:31:04.977715+05:30	$2a$10$iLbji3Awk/PyPsdw8edhaezJ7TQQB0cI8NftbP672ffe/HyHZamFW	2026-09-30 12:31:04.588209+05:30	0	\N	\N
usr_fb4c3d97481d72eb	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:31:04.666059+05:30	2026-09-30 12:31:04.922045+05:30	\N	\N	0	\N	\N
usr_c64529f35491354a	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:31:05.0999+05:30	2026-09-30 12:31:05.0999+05:30	\N	\N	0	\N	\N
usr_65c1f48cff9008b3	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:31:04.594927+05:30	2026-09-30 12:31:05.070553+05:30	$2a$10$TCHXlcKJ2Qfm7uc20qUHfOhCCe05uH25wBVJWRiMdIBLe6YzT16La	2026-09-30 12:31:04.612577+05:30	0	\N	\N
usr_78aacbf0e54c792a	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:31:04.76053+05:30	2026-09-30 12:31:04.762166+05:30	$2a$10$sMkfU/0HNgOVm09xVfFAfu5kFc0Qx3R1aQsJEov3T4mGaEmAX87H6	2026-09-30 12:31:04.762166+05:30	0	\N	\N
usr_1e93ccb241b92f8d	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:31:04.749571+05:30	2026-09-30 12:31:04.891732+05:30	\N	\N	0	\N	\N
usr_6b06fb2b57910aaa	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:31:05.338848+05:30	2026-09-30 12:31:05.338848+05:30	\N	\N	0	\N	\N
usr_9058099580347858	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:35:22.034125+05:30	2026-09-30 12:35:22.034125+05:30	\N	\N	0	\N	\N
usr_390269341390c4dd	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:35:39.827181+05:30	2026-09-30 12:35:40.345834+05:30	$2a$10$hekwuX.7i8lLyaPYvkooue0R7ehTToB6zEWnjzk0KeVecNHbCcEGy	2026-09-30 12:35:39.846273+05:30	0	\N	\N
usr_8b37e09a3fe45bc9	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:35:40.063464+05:30	2026-09-30 12:35:40.065852+05:30	$2a$10$JjXFOx3oUq0oJHN1pkkSeu9CHJSbw16xeZt4Zr/DPSZtyONR97mnC	2026-09-30 12:35:40.065852+05:30	0	\N	\N
usr_2afcf6367d1dc020	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:35:39.855009+05:30	2026-09-30 12:35:40.305532+05:30	$2a$10$l5h3VZYGUnQeCID9YU1eyuvMLW3F4CG0f7LKMqCIqzEaRSqiBB7za	2026-09-30 12:35:39.871293+05:30	0	\N	\N
usr_86b3e6d40335e6f1	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-10-01 15:26:28.975522+05:30	2026-10-01 15:26:29.33515+05:30	\N	\N	0	\N	\N
usr_b7675a4a677cc52c	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 13:51:37.487604+05:30	2026-09-30 13:51:38.148173+05:30	$2a$10$V0LFrmAogHTXzT8B6rA8COAm1uURfibI24kNkvAWYGfdALXMncOUu	2026-09-30 13:51:37.518374+05:30	0	\N	\N
usr_11fdc7381d901c43	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:35:39.931167+05:30	2026-09-30 12:35:40.11078+05:30	\N	\N	0	\N	\N
usr_e5af181f986f06b3	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:35:39.92299+05:30	2026-09-30 12:35:40.238331+05:30	\N	\N	0	\N	\N
usr_d83a341c2319afc3	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:35:40.442572+05:30	2026-09-30 12:35:40.442572+05:30	\N	\N	0	\N	\N
usr_551f76650073a64a	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:35:40.751793+05:30	2026-09-30 12:35:40.751793+05:30	\N	\N	0	\N	\N
usr_50634ff073aa77b9	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:39:01.245398+05:30	2026-09-30 12:39:01.477853+05:30	\N	\N	0	\N	\N
usr_d37a502d11e5da99	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:38:00.606571+05:30	2026-09-30 12:38:01.679798+05:30	\N	\N	0	\N	\N
usr_8d0907e902d9d9dd	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:39:01.421758+05:30	2026-09-30 12:39:01.424173+05:30	$2a$10$IcOUAKyYzMYhwH9zZXNrfudkXslh9ndx3knLo4I4zHNk/epIGvH3i	2026-09-30 12:39:01.424173+05:30	0	\N	\N
usr_3b955f3d4bb859f2	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:39:01.227933+05:30	2026-09-30 12:39:01.579082+05:30	\N	\N	0	\N	\N
usr_65fa9d3936098493	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 13:52:47.161825+05:30	2026-09-30 13:52:47.161825+05:30	\N	\N	0	\N	\N
usr_a7b4c5abd3ed76c5	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:39:01.204702+05:30	2026-09-30 12:39:01.688645+05:30	$2a$10$3zxigvdRqTB6JySTvQnleerGLmILa/p7AI8eYIEal7wzJXlUt4CcK	2026-09-30 12:39:01.220333+05:30	0	\N	\N
usr_507a98d2112c5563	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 12:38:17.6119+05:30	2026-09-30 12:38:17.788536+05:30	\N	\N	0	\N	\N
usr_8279dc24442d924a	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 13:53:21.66723+05:30	2026-09-30 13:53:21.928991+05:30	\N	\N	0	\N	\N
usr_1f42ebc28c735546	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:39:01.251463+05:30	2026-09-30 12:39:01.819576+05:30	$2a$10$h.gV.m/ZDM76ZWz2ulDpDOyV6lfgHpqBtPNI2CTGrPS9GSym35I/K	2026-09-30 12:39:01.303881+05:30	0	\N	\N
usr_9e9b8b953ce4c7eb	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:39:01.966584+05:30	2026-09-30 12:39:01.966584+05:30	\N	\N	0	\N	\N
usr_7f74277e048fcd18	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:38:17.931032+05:30	2026-09-30 12:38:17.933138+05:30	$2a$10$4ro85gE7jRYg.5QgN8ePWe8TUkunYwhco8rAwDwPevyq.4FEy7f2i	2026-09-30 12:38:17.933138+05:30	0	\N	\N
usr_afbec60a362f096d	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-09-30 12:38:17.7351+05:30	2026-09-30 12:38:18.040423+05:30	\N	\N	0	\N	\N
usr_249c7f996e96c57d	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:39:13.382528+05:30	2026-09-30 12:39:13.382528+05:30	\N	\N	0	\N	\N
usr_e03c44f59bbff28f	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:38:17.63146+05:30	2026-09-30 12:38:18.143187+05:30	$2a$10$CUtgSxsgYdAumzhVJxcWg.QGFIbHM6rqtagqcx1maww6oRcsWLfwa	2026-09-30 12:38:17.657602+05:30	0	\N	\N
usr_8c69afe724c09d49	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:38:17.740288+05:30	2026-09-30 12:38:18.169615+05:30	$2a$10$MypJe482I3/2eXRJdpZB5OCY4AEqxga7ho1KD9LVNnRVClskDWyaq	2026-09-30 12:38:17.756947+05:30	0	\N	\N
usr_edc9b30bd17b2c3f	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:38:18.269089+05:30	2026-09-30 12:38:18.269089+05:30	\N	\N	0	\N	\N
usr_3fd88a7c51a18416	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 12:38:22.791715+05:30	2026-09-30 12:38:22.791715+05:30	\N	\N	0	\N	\N
usr_bd5528dac05a06bc	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 13:50:03.97142+05:30	2026-09-30 13:50:03.97142+05:30	\N	\N	0	\N	\N
usr_16c2144c0df7f485	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-10-01 15:39:08.692231+05:30	2026-10-01 15:39:08.968651+05:30	\N	\N	0	\N	\N
usr_66ac9868bfa6631c	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:26:29.465411+05:30	2026-10-01 15:26:29.46767+05:30	$2a$10$P7hB5E.MQAJ.9xttR4GlmOwU2O7OW8dfT98SFb2MQMlNZq1xBfvFy	2026-10-01 15:26:29.46767+05:30	0	\N	\N
usr_8cf6038983567937	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-10-01 15:26:29.129303+05:30	2026-10-01 15:26:29.593849+05:30	\N	\N	0	\N	\N
usr_69f63c6fa32cb0fe	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 13:53:50.083187+05:30	2026-09-30 13:53:50.085042+05:30	$2a$10$/tfOqyDyjB6OZcYn06kz3Of6sJKeTm966qnWRhWKzxoujCYur93q6	2026-09-30 13:53:50.085042+05:30	0	\N	\N
usr_58e3c108ab31e109	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-09-30 13:50:37.145225+05:30	2026-09-30 13:50:37.298489+05:30	\N	\N	0	\N	\N
usr_386a8db5450ed2bf	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-09-30 13:53:49.916953+05:30	2026-09-30 13:53:50.301024+05:30	$2a$10$lPGlZ9hGS/PtZTebBqKviuqd58pOd5jm9H8YzgoS7doHVr3dU64u6	2026-09-30 13:53:49.928066+05:30	0	\N	\N
usr_372a9de0c155953d	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-10-01 15:33:11.470376+05:30	2026-10-01 15:33:11.783786+05:30	\N	\N	0	\N	\N
usr_f16724c6f8d5f94d	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:39:08.716562+05:30	2026-10-01 15:39:10.028495+05:30	$2a$10$T1fZZr6hyZOthFQW49V5ZOBbAUg2HFuEvw7UZmml04pmVNmeCw/fu	2026-10-01 15:39:08.753699+05:30	0	\N	\N
usr_191f6cef8ff784cc	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:26:30.006592+05:30	2026-10-01 15:26:30.006592+05:30	\N	\N	0	\N	\N
usr_a10542f59057b140	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:39:09.545766+05:30	2026-10-01 15:39:09.545766+05:30	\N	\N	0	\N	\N
usr_aaba6c37ed2fbd00	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:26:29.185564+05:30	2026-10-01 15:26:30.137499+05:30	$2a$10$X2hnE3Fwm80G.iqMOXXHE.sDjuotP22TqArkk4WfH9c0oCmDPxHHS	2026-10-01 15:26:29.205824+05:30	0	\N	\N
usr_73c45d42f9750142	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:26:28.988086+05:30	2026-10-01 15:26:30.396954+05:30	$2a$10$BiJlwyemxZdTpVBHXzdgd.oFqN5G3uNMjNgPO0L6r86QSzL6JW0m6	2026-10-01 15:26:29.092079+05:30	0	\N	\N
usr_8cb0d6db3214a9bc	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:26:30.633344+05:30	2026-10-01 15:26:30.633344+05:30	\N	\N	0	\N	\N
usr_05a01b29ffddd525	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:39:09.091211+05:30	2026-10-01 15:39:09.094127+05:30	$2a$10$d1NO3fB/3S9.7IgB9kMDbOrP8Val.jz0CnxP0.ygVZV9U2Ry124Xa	2026-10-01 15:39:09.094127+05:30	0	\N	\N
usr_b2c56e4b881cf6fb	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:47:11.336305+05:30	2026-10-01 15:47:12.165616+05:30	$2a$10$VmDPSSBD/A6G3ge/Ay3PfOKyzlXZ.c1FO3we0mXszH3mudWI4ZnpG	2026-10-01 15:47:11.354666+05:30	0	\N	\N
usr_e9919c23c0467ea5	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:39:08.814903+05:30	2026-10-01 15:39:09.583398+05:30	$2a$10$aPbUtW1zh27f09jL2zcu3u4SsBhYuTtu./z4J6xV8p8ZMppVugZ32	2026-10-01 15:39:08.830335+05:30	0	\N	\N
usr_258e0b7430df83ca	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-10-01 15:39:08.819806+05:30	2026-10-01 15:39:09.248316+05:30	\N	\N	0	\N	\N
usr_962f5f2641636fae	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:39:09.777615+05:30	2026-10-01 15:39:09.777615+05:30	\N	\N	0	\N	\N
usr_2bad6dc1de996b96	LW	Right	Intermediate	1500	70	["NewRecruit"]	5000.00	2026-10-01 15:47:11.327178+05:30	2026-10-01 15:47:11.502866+05:30	\N	\N	0	\N	\N
usr_a1bd125a6a3dd41a	CM	Right	Intermediate	1500	70	["NewRecruit"]	5500.00	2026-10-01 15:47:11.340322+05:30	2026-10-01 15:47:11.639234+05:30	\N	\N	0	\N	\N
usr_d012c52d94f984bc	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:47:11.359737+05:30	2026-10-01 15:47:12.032338+05:30	$2a$10$ozekBpVzHJ6Xzv/0kQXDP.E/t0x8m0QqFN/VXILu53K7Mrz/J7ibi	2026-10-01 15:47:11.370933+05:30	0	\N	\N
usr_5eb6d029937b3c22	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:47:11.55337+05:30	2026-10-01 15:47:11.555261+05:30	$2a$10$ZBmAL./Bdf7eqfOP03LONOpuPRaZ0U4kDC0o8Pf2fqn9AULlKoVpm	2026-10-01 15:47:11.555261+05:30	0	\N	\N
usr_7a1b921337c5cb3c	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:47:11.89599+05:30	2026-10-01 15:47:11.89599+05:30	\N	\N	0	\N	\N
usr_87256bb5c03dd033	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 15:47:12.256235+05:30	2026-10-01 15:47:12.256235+05:30	\N	\N	0	\N	\N
usr_62068e8f5fc912b3	CM	Right	Intermediate	1500	70	["NewRecruit"]	1000.00	2026-10-01 16:33:10.325856+05:30	2026-10-01 16:33:11.143867+05:30	$2a$10$mwMfEl0mdueSwnFg4mqV5OgVBm.NO.E8/s4265e8uXtZ8WxyTuiB6	2026-10-01 16:33:10.362022+05:30	0	\N	\N
\.


--
-- TOC entry 6189 (class 0 OID 18427)
-- Dependencies: 245
-- Data for Name: player_stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player_stats (user_id, matches_played, wins, draws, losses, clean_sheets, points, win_rate, goals_scored, assists, updated_at) FROM stdin;
usr_771ffc659cac6f5f	0	0	0	0	0	0	0	0	0	2026-09-29 12:55:42.602639+05:30
usr_4b474011146a3a70	0	0	0	0	0	0	0	0	0	2026-09-29 13:28:37.809414+05:30
usr_a7845baf785372f9	0	0	0	0	0	0	0	0	0	2026-09-29 13:52:53.104083+05:30
usr_e4fa19886f0b282e	0	0	0	0	0	0	0	0	0	2026-09-30 11:40:11.382789+05:30
usr_b3d3f31095d1547a	0	0	0	0	0	0	0	0	0	2026-09-30 11:40:11.405167+05:30
usr_1fbef46f504fc1b9	0	0	0	0	0	0	0	0	0	2026-09-30 11:40:11.984118+05:30
usr_fb3b4ae1787a833c	0	0	0	0	0	0	0	0	0	2026-09-30 11:40:12.5215+05:30
usr_42b6e7a87221c857	0	0	0	0	0	0	0	0	0	2026-09-30 12:01:58.437808+05:30
usr_26cd79c91e36a2ec	0	0	0	0	0	0	0	0	0	2026-09-30 12:01:58.446913+05:30
usr_d156636dc63e5f89	0	0	0	0	0	0	0	0	0	2026-09-30 12:01:58.950252+05:30
usr_a16b19a7d0fed768	0	0	0	0	0	0	0	0	0	2026-09-30 12:01:59.298554+05:30
usr_1b2be606008073f9	0	0	0	0	0	0	0	0	0	2026-09-30 12:02:37.369829+05:30
usr_d7f33014a1b8ee7e	0	0	0	0	0	0	0	0	0	2026-09-30 12:02:37.43305+05:30
usr_501bb44eb891425b	0	0	0	0	0	0	0	0	0	2026-09-30 12:02:37.859559+05:30
usr_d47727393c5cf58d	0	0	0	0	0	0	0	0	0	2026-09-30 12:02:38.041656+05:30
usr_712ee3524ce3dde7	0	0	0	0	0	0	0	0	0	2026-09-30 12:04:47.973032+05:30
usr_837a15479a780030	0	0	0	0	0	0	0	0	0	2026-09-30 12:05:29.154158+05:30
usr_eb0b001d22f07016	0	0	0	0	0	0	0	0	0	2026-09-30 12:06:05.601039+05:30
usr_1c1c8a9a99910f99	0	0	0	0	0	0	0	0	0	2026-09-30 12:06:44.478138+05:30
usr_c2900f81677f6b40	0	0	0	0	0	0	0	0	0	2026-09-30 12:07:49.981544+05:30
usr_072c197d8fd4f7a3	0	0	0	0	0	0	0	0	0	2026-09-30 12:08:44.224652+05:30
usr_2d339c1c8a60a7bf	0	0	0	0	0	0	0	0	0	2026-09-30 12:09:44.742049+05:30
usr_d032febee8660434	0	0	0	0	0	0	0	0	0	2026-09-30 12:11:02.703715+05:30
usr_c04f1863db4f19c1	0	0	0	0	0	0	0	0	0	2026-09-30 12:11:53.149978+05:30
usr_39ea6b242671d81c	0	0	0	0	0	0	0	0	0	2026-09-30 12:13:43.628109+05:30
usr_1a92cc3ed067921f	0	0	0	0	0	0	0	0	0	2026-09-30 12:16:35.943967+05:30
usr_fe8e1e4957015c39	0	0	0	0	0	0	0	0	0	2026-09-30 12:16:55.952649+05:30
usr_483214e785cf434a	0	0	0	0	0	0	0	0	0	2026-09-30 12:16:56.813757+05:30
usr_70cf84b74a8d0975	0	0	0	0	0	0	0	0	0	2026-09-30 12:16:57.003569+05:30
usr_e8dd3605e526e61d	0	0	0	0	0	0	0	0	0	2026-09-30 12:16:57.411336+05:30
usr_c693284ad8ad5abe	0	0	0	0	0	0	0	0	0	2026-09-30 12:16:57.671051+05:30
usr_332b68556f881273	0	0	0	0	0	0	0	0	0	2026-09-30 12:24:44.19241+05:30
usr_426334eee09db891	0	0	0	0	0	0	0	0	0	2026-09-30 12:24:44.210874+05:30
usr_d3fe85aa55a03730	0	0	0	0	0	0	0	0	0	2026-09-30 12:24:44.229513+05:30
usr_e52ef76965d3db06	0	0	0	0	0	0	0	0	0	2026-09-30 12:24:44.790603+05:30
usr_f87296a72c33648b	0	0	0	0	0	0	0	0	0	2026-09-30 12:24:45.068578+05:30
usr_d2c85356dd19365c	0	0	0	0	0	0	0	0	0	2026-09-30 12:29:14.429098+05:30
usr_a73a6f4cffbc42b8	0	0	0	0	0	0	0	0	0	2026-09-30 12:29:14.534356+05:30
usr_2ecf15c886956bdd	0	0	0	0	0	0	0	0	0	2026-09-30 12:30:00.57832+05:30
usr_441c0e3d289b7aac	0	0	0	0	0	0	0	0	0	2026-09-30 12:30:42.75968+05:30
usr_f28801a3540af399	0	0	0	0	0	0	0	0	0	2026-09-30 12:30:42.906984+05:30
usr_b636f1ae7e91e71f	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:04.576239+05:30
usr_65c1f48cff9008b3	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:04.594927+05:30
usr_fb4c3d97481d72eb	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:04.666059+05:30
usr_78aacbf0e54c792a	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:04.76053+05:30
usr_1e93ccb241b92f8d	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:04.749571+05:30
usr_c64529f35491354a	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:05.0999+05:30
usr_6b06fb2b57910aaa	0	0	0	0	0	0	0	0	0	2026-09-30 12:31:05.338848+05:30
usr_9058099580347858	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:22.034125+05:30
usr_390269341390c4dd	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:39.827181+05:30
usr_2afcf6367d1dc020	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:39.855009+05:30
usr_e5af181f986f06b3	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:39.92299+05:30
usr_11fdc7381d901c43	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:39.931167+05:30
usr_8b37e09a3fe45bc9	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:40.063464+05:30
usr_d83a341c2319afc3	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:40.442572+05:30
usr_551f76650073a64a	0	0	0	0	0	0	0	0	0	2026-09-30 12:35:40.751793+05:30
usr_d37a502d11e5da99	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:00.606571+05:30
usr_507a98d2112c5563	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:17.6119+05:30
usr_e03c44f59bbff28f	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:17.63146+05:30
usr_afbec60a362f096d	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:17.7351+05:30
usr_8c69afe724c09d49	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:17.740288+05:30
usr_7f74277e048fcd18	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:17.931032+05:30
usr_edc9b30bd17b2c3f	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:18.269089+05:30
usr_3fd88a7c51a18416	0	0	0	0	0	0	0	0	0	2026-09-30 12:38:22.791715+05:30
usr_a7b4c5abd3ed76c5	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:01.204702+05:30
usr_3b955f3d4bb859f2	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:01.227933+05:30
usr_1f42ebc28c735546	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:01.251463+05:30
usr_50634ff073aa77b9	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:01.245398+05:30
usr_8d0907e902d9d9dd	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:01.421758+05:30
usr_9e9b8b953ce4c7eb	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:01.966584+05:30
usr_249c7f996e96c57d	0	0	0	0	0	0	0	0	0	2026-09-30 12:39:13.382528+05:30
usr_bd5528dac05a06bc	0	0	0	0	0	0	0	0	0	2026-09-30 13:50:03.97142+05:30
usr_58e3c108ab31e109	0	0	0	0	0	0	0	0	0	2026-09-30 13:50:37.145225+05:30
usr_b7675a4a677cc52c	0	0	0	0	0	0	0	0	0	2026-09-30 13:51:37.487604+05:30
usr_65fa9d3936098493	0	0	0	0	0	0	0	0	0	2026-09-30 13:52:47.161825+05:30
usr_8279dc24442d924a	0	0	0	0	0	0	0	0	0	2026-09-30 13:53:21.66723+05:30
usr_386a8db5450ed2bf	0	0	0	0	0	0	0	0	0	2026-09-30 13:53:49.916953+05:30
usr_69f63c6fa32cb0fe	0	0	0	0	0	0	0	0	0	2026-09-30 13:53:50.083187+05:30
usr_73c45d42f9750142	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:28.988086+05:30
usr_86b3e6d40335e6f1	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:28.975522+05:30
usr_8cf6038983567937	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:29.129303+05:30
usr_aaba6c37ed2fbd00	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:29.185564+05:30
usr_66ac9868bfa6631c	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:29.465411+05:30
usr_191f6cef8ff784cc	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:30.006592+05:30
usr_8cb0d6db3214a9bc	0	0	0	0	0	0	0	0	0	2026-10-01 15:26:30.633344+05:30
usr_372a9de0c155953d	0	0	0	0	0	0	0	0	0	2026-10-01 15:33:11.470376+05:30
usr_16c2144c0df7f485	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:08.692231+05:30
usr_f16724c6f8d5f94d	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:08.716562+05:30
usr_e9919c23c0467ea5	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:08.814903+05:30
usr_258e0b7430df83ca	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:08.819806+05:30
usr_05a01b29ffddd525	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:09.091211+05:30
usr_a10542f59057b140	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:09.545766+05:30
usr_962f5f2641636fae	0	0	0	0	0	0	0	0	0	2026-10-01 15:39:09.777615+05:30
usr_2bad6dc1de996b96	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:11.327178+05:30
usr_a1bd125a6a3dd41a	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:11.340322+05:30
usr_b2c56e4b881cf6fb	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:11.336305+05:30
usr_d012c52d94f984bc	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:11.359737+05:30
usr_5eb6d029937b3c22	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:11.55337+05:30
usr_7a1b921337c5cb3c	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:11.89599+05:30
usr_87256bb5c03dd033	0	0	0	0	0	0	0	0	0	2026-10-01 15:47:12.256235+05:30
usr_62068e8f5fc912b3	0	0	0	0	0	0	0	0	0	2026-10-01 16:33:10.325856+05:30
\.


--
-- TOC entry 6198 (class 0 OID 18695)
-- Dependencies: 254
-- Data for Name: poll_options; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.poll_options (id, poll_id, text, votes_count) FROM stdin;
\.


--
-- TOC entry 6199 (class 0 OID 18712)
-- Dependencies: 255
-- Data for Name: poll_votes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.poll_votes (poll_id, user_id, option_id, voted_at) FROM stdin;
\.


--
-- TOC entry 6197 (class 0 OID 18683)
-- Dependencies: 253
-- Data for Name: polls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.polls (id, city, question, created_at) FROM stdin;
\.


--
-- TOC entry 6196 (class 0 OID 18658)
-- Dependencies: 252
-- Data for Name: post_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_comments (id, post_id, author_id, text, created_at) FROM stdin;
\.


--
-- TOC entry 6195 (class 0 OID 18638)
-- Dependencies: 251
-- Data for Name: post_likes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_likes (post_id, user_id, created_at) FROM stdin;
\.


--
-- TOC entry 6170 (class 0 OID 17930)
-- Dependencies: 226
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, role_name, description) FROM stdin;
1	ADMIN	Platform administrator (Super/Ops/Finance)
2	MANAGER	Club / Turf Manager
3	PLAYER	Regular player account
\.


--
-- TOC entry 6203 (class 0 OID 18811)
-- Dependencies: 259
-- Data for Name: support_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.support_tickets (id, user_id, subject, description, category, priority, status, assigned_staff_id, resolution_notes, resolved_at, created_at) FROM stdin;
\.


--
-- TOC entry 6192 (class 0 OID 18546)
-- Dependencies: 248
-- Data for Name: tournament_bracket_matches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournament_bracket_matches (id, tournament_id, round_name, team_a_id, team_b_id, score, winner_team_id, match_order) FROM stdin;
\.


--
-- TOC entry 6191 (class 0 OID 18513)
-- Dependencies: 247
-- Data for Name: tournament_teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournament_teams (id, tournament_id, name, captain_id, logo, status, registered_at) FROM stdin;
\.


--
-- TOC entry 6190 (class 0 OID 18472)
-- Dependencies: 246
-- Data for Name: tournaments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tournaments (id, title, tagline, club_id, city, format, banner_url, start_date, end_date, entry_fee, prize_pool, max_teams, registered_teams_count, status, champion_team_id, rules, description, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 6193 (class 0 OID 18581)
-- Dependencies: 249
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (id, user_id, type, amount, balance_after, status, description, reference_id, created_at) FROM stdin;
tx_0522f3c031c1c422	usr_771ffc659cac6f5f	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-29 12:55:42.602639+05:30
tx_45e4660c59a4353b	usr_4b474011146a3a70	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-29 13:28:37.809414+05:30
tx_b644b6e374ba0719	usr_a7845baf785372f9	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-29 13:52:53.104083+05:30
tx_e9f2068797caf28f	usr_b3d3f31095d1547a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 11:40:11.405167+05:30
tx_da778c5163839313	usr_e4fa19886f0b282e	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 11:40:11.382789+05:30
tx_ce4a62ae1bb30ef9	usr_1fbef46f504fc1b9	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 11:40:11.984118+05:30
tx_ea96ed47bfcf5bdc	usr_fb3b4ae1787a833c	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 11:40:12.5215+05:30
tx_4e817f7fdcb6e4db	usr_42b6e7a87221c857	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:01:58.437808+05:30
tx_9a29a16b85d04f33	usr_26cd79c91e36a2ec	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:01:58.446913+05:30
tx_e8d90f563d1a9d80	usr_d156636dc63e5f89	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:01:58.950252+05:30
tx_05db9292787cd562	usr_a16b19a7d0fed768	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:01:59.298554+05:30
tx_5ea0b0b9d9e40f13	usr_1b2be606008073f9	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:02:37.369829+05:30
tx_c3b36450cc2d860b	usr_d7f33014a1b8ee7e	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:02:37.43305+05:30
tx_9bb8768441ef8968	usr_501bb44eb891425b	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:02:37.859559+05:30
tx_7a2dbccfeac3a710	usr_d47727393c5cf58d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:02:38.041656+05:30
tx_1c83009bbf3694b9	usr_712ee3524ce3dde7	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:04:47.973032+05:30
tx_c1d464ac3f5dd37d	usr_837a15479a780030	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:05:29.154158+05:30
tx_9bd7d277921f23a8	usr_eb0b001d22f07016	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:06:05.601039+05:30
tx_870251e289e1c974	usr_1c1c8a9a99910f99	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:06:44.478138+05:30
tx_f3e45a98c88e3c3b	usr_c2900f81677f6b40	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:07:49.981544+05:30
tx_d631924b166305ce	usr_072c197d8fd4f7a3	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:08:44.224652+05:30
tx_a9842991647b7f23	usr_2d339c1c8a60a7bf	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:09:44.742049+05:30
tx_58f1db13862bea13	usr_d032febee8660434	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:11:02.703715+05:30
tx_ce01a72b9f16f4df	usr_c04f1863db4f19c1	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:11:53.149978+05:30
tx_4279e729cb5f0b03	usr_39ea6b242671d81c	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:13:43.628109+05:30
tx_edb5853acd167410	usr_1a92cc3ed067921f	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:16:35.943967+05:30
tx_2745e179aaf5db39	usr_fe8e1e4957015c39	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:16:55.952649+05:30
tx_ee739e30aa6e5d49	usr_483214e785cf434a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:16:56.813757+05:30
tx_5b4063cf451faec4	usr_70cf84b74a8d0975	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:16:57.003569+05:30
tx_b68a349b4cb823d3	usr_e8dd3605e526e61d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:16:57.411336+05:30
tx_6834e59514dfd1c9	usr_c693284ad8ad5abe	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:16:57.671051+05:30
tx_fe9a1ae57b51b3d2	usr_332b68556f881273	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:24:44.19241+05:30
tx_d3efdbd2aed11940	usr_426334eee09db891	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:24:44.210874+05:30
tx_4ec13bf118c5f073	usr_d3fe85aa55a03730	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:24:44.229513+05:30
tx_bc3f45b093e736f0	usr_e52ef76965d3db06	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:24:44.790603+05:30
tx_44727af56cca1168	usr_f87296a72c33648b	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:24:45.068578+05:30
tx_54cdc99b79385391	usr_d2c85356dd19365c	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:29:14.429098+05:30
tx_0cf63bf9b741420e	usr_a73a6f4cffbc42b8	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:29:14.534356+05:30
tx_1d6f6828bbc66402	usr_2ecf15c886956bdd	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:30:00.57832+05:30
tx_fd7a6afee7027c1f	usr_441c0e3d289b7aac	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:30:42.75968+05:30
tx_37a2a8087e2d3f35	usr_f28801a3540af399	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:30:42.906984+05:30
tx_084416868157a756	usr_b636f1ae7e91e71f	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:04.576239+05:30
tx_fcb92989d7dfe616	usr_65c1f48cff9008b3	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:04.594927+05:30
tx_b2e616019ebcb73e	usr_fb4c3d97481d72eb	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:04.666059+05:30
tx_94b5b316e797f7f2	usr_78aacbf0e54c792a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:04.76053+05:30
tx_12ff91fc12cee5a6	usr_1e93ccb241b92f8d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:04.749571+05:30
tx_6d64f4d55ee5a3b8	usr_c64529f35491354a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:05.0999+05:30
tx_2ba090f8fff194ef	usr_6b06fb2b57910aaa	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:31:05.338848+05:30
tx_1273ff96383685c6	usr_9058099580347858	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:22.034125+05:30
tx_571944741f6b47bf	usr_390269341390c4dd	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:39.827181+05:30
tx_de8c320c42676ed7	usr_2afcf6367d1dc020	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:39.855009+05:30
tx_dff7199d0e9f8fca	usr_e5af181f986f06b3	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:39.92299+05:30
tx_c234b228368b73e0	usr_11fdc7381d901c43	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:39.931167+05:30
tx_7ce7cfc25339152b	usr_8b37e09a3fe45bc9	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:40.063464+05:30
tx_2835021988e9089c	usr_d83a341c2319afc3	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:40.442572+05:30
tx_a043d7c8294e96a8	usr_551f76650073a64a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:35:40.751793+05:30
tx_5cf0ec3b60445579	usr_d37a502d11e5da99	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:00.606571+05:30
tx_26cb0f8851ddcf8c	usr_507a98d2112c5563	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:17.6119+05:30
tx_e7ad955a82dc79c0	usr_e03c44f59bbff28f	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:17.63146+05:30
tx_f8d426b6ceb10e48	usr_8c69afe724c09d49	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:17.740288+05:30
tx_6dd97d76b111b1d9	usr_afbec60a362f096d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:17.7351+05:30
tx_aeace7d51af5c88d	usr_7f74277e048fcd18	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:17.931032+05:30
tx_c2e12413b386a58b	usr_edc9b30bd17b2c3f	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:18.269089+05:30
tx_3fb9d710fecda4c5	usr_3fd88a7c51a18416	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:38:22.791715+05:30
tx_29d1d76e1fc47a73	usr_a7b4c5abd3ed76c5	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:01.204702+05:30
tx_a11ccf5792c963e5	usr_3b955f3d4bb859f2	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:01.227933+05:30
tx_664177fc8b0378c0	usr_1f42ebc28c735546	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:01.251463+05:30
tx_aaf8df0ed7cf185e	usr_50634ff073aa77b9	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:01.245398+05:30
tx_73a7319f484fe71f	usr_8d0907e902d9d9dd	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:01.421758+05:30
tx_03f5d7a0daeb5ce6	usr_9e9b8b953ce4c7eb	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:01.966584+05:30
tx_9c9372181bc58d0c	usr_249c7f996e96c57d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 12:39:13.382528+05:30
tx_4ae380df3f5c18bf	usr_bd5528dac05a06bc	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:50:03.97142+05:30
tx_5dfae2c7f6a3d173	usr_58e3c108ab31e109	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:50:37.145225+05:30
tx_dedc5977a3b49529	usr_b7675a4a677cc52c	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:51:37.487604+05:30
tx_224ac3571df70a88	usr_65fa9d3936098493	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:52:47.161825+05:30
tx_7e9b0cbe3f2d9a37	usr_8279dc24442d924a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:53:21.66723+05:30
tx_2b626bef551d1111	usr_386a8db5450ed2bf	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:53:49.916953+05:30
tx_6eea959cc6ec5307	usr_69f63c6fa32cb0fe	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-09-30 13:53:50.083187+05:30
tx_fa422bdb4239cf10	usr_73c45d42f9750142	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:28.988086+05:30
tx_dcd581f5ad66153c	usr_86b3e6d40335e6f1	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:28.975522+05:30
tx_51eaecfdc20e3236	usr_8cf6038983567937	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:29.129303+05:30
tx_07450248c166634a	usr_aaba6c37ed2fbd00	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:29.185564+05:30
tx_3c8115d96173a365	usr_66ac9868bfa6631c	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:29.465411+05:30
tx_ba481357704a30fa	usr_191f6cef8ff784cc	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:30.006592+05:30
tx_14385663de766b39	usr_8cb0d6db3214a9bc	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:26:30.633344+05:30
tx_3426140726637bee	usr_372a9de0c155953d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:33:11.470376+05:30
tx_5aae52f262d00c1b	usr_16c2144c0df7f485	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:08.692231+05:30
tx_ea8cb2bf60f9e7d8	usr_f16724c6f8d5f94d	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:08.716562+05:30
tx_95276becb2f67f93	usr_e9919c23c0467ea5	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:08.814903+05:30
tx_aefb072e7c448de3	usr_258e0b7430df83ca	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:08.819806+05:30
tx_9f93e9ff6e5809a7	usr_05a01b29ffddd525	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:09.091211+05:30
tx_87ea9899d23f3d2f	usr_a10542f59057b140	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:09.545766+05:30
tx_a37b32f3a97d46f7	usr_962f5f2641636fae	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:39:09.777615+05:30
tx_ca5a6d3ffe62140c	usr_2bad6dc1de996b96	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:11.327178+05:30
tx_c9c691b702b652d7	usr_a1bd125a6a3dd41a	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:11.340322+05:30
tx_4967296b21cdf70f	usr_b2c56e4b881cf6fb	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:11.336305+05:30
tx_b1d51855097ce301	usr_d012c52d94f984bc	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:11.359737+05:30
tx_a8bdea72d5229cfe	usr_5eb6d029937b3c22	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:11.55337+05:30
tx_f2bd28e4e023058e	usr_7a1b921337c5cb3c	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:11.89599+05:30
tx_cf67d064f217fa3f	usr_87256bb5c03dd033	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 15:47:12.256235+05:30
tx_4a0950440e1e207f	usr_62068e8f5fc912b3	WELCOME_BONUS	1000.00	1000.00	SUCCESS	Welcome bonus on registration	\N	2026-10-01 16:33:10.325856+05:30
\.


--
-- TOC entry 6209 (class 0 OID 19716)
-- Dependencies: 265
-- Data for Name: user_identity_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_identity_history (id, user_id, identity_type, identity_value, normalized_value, created_at) FROM stdin;
1	usr_771ffc659cac6f5f	EMAIL	player@gmail.com	player@gmail.com	2026-09-29 12:55:42.602639+05:30
2	usr_771ffc659cac6f5f	PHONE	9876544321	9876544321	2026-09-29 12:55:42.602639+05:30
3	usr_4b474011146a3a70	EMAIL	yuvi23@gmail.com	yuvi23@gmail.com	2026-09-29 13:28:37.809414+05:30
4	usr_4b474011146a3a70	PHONE	8899665511	8899665511	2026-09-29 13:28:37.809414+05:30
5	usr_a7845baf785372f9	EMAIL	rudra12@gmail.com	rudra12@gmail.com	2026-09-29 13:52:53.104083+05:30
6	usr_a7845baf785372f9	PHONE	9865548798	9865548798	2026-09-29 13:52:53.104083+05:30
7	usr_e55abb463db8392d	EMAIL	aadiverma4206@gmail.com	aadiverma4206@gmail.com	2026-09-29 15:20:21.207044+05:30
8	usr_e55abb463db8392d	PHONE	9754313585	9754313585	2026-09-29 15:20:21.207044+05:30
9	usr_2868a49c6aa551f5	EMAIL	roshan12@gmail.com	roshan12@gmail.com	2026-09-29 15:33:09.732347+05:30
10	usr_2868a49c6aa551f5	PHONE	96633527854	96633527854	2026-09-29 15:33:09.732347+05:30
11	usr_e4fa19886f0b282e	EMAIL	player_test_1790748611094@example.com	player_test_1790748611094@example.com	2026-09-30 11:40:11.382789+05:30
12	usr_b3d3f31095d1547a	EMAIL	wallet_player_1790748611091@example.com	wallet_player_1790748611091@example.com	2026-09-30 11:40:11.405167+05:30
13	usr_e4fa19886f0b282e	PHONE	+919788428482	+919788428482	2026-09-30 11:40:11.382789+05:30
14	usr_b3d3f31095d1547a	PHONE	+919680577767	+919680577767	2026-09-30 11:40:11.405167+05:30
15	usr_2cd11304a4ea973d	EMAIL	manager_test_1790748611090@example.com	manager_test_1790748611090@example.com	2026-09-30 11:40:11.684183+05:30
16	usr_2cd11304a4ea973d	PHONE	+919553385790	+919553385790	2026-09-30 11:40:11.684183+05:30
17	usr_1fbef46f504fc1b9	EMAIL	player_cctv_1790748611983@example.com	player_cctv_1790748611983@example.com	2026-09-30 11:40:11.984118+05:30
18	usr_1fbef46f504fc1b9	PHONE	+919466214163	+919466214163	2026-09-30 11:40:11.984118+05:30
19	usr_fb3b4ae1787a833c	EMAIL	test_player_1790748611094@example.com	test_player_1790748611094@example.com	2026-09-30 11:40:12.5215+05:30
20	usr_fb3b4ae1787a833c	PHONE	+919854882860	+919854882860	2026-09-30 11:40:12.5215+05:30
21	usr_42b6e7a87221c857	EMAIL	wallet_player_1790749918184@example.com	wallet_player_1790749918184@example.com	2026-09-30 12:01:58.437808+05:30
22	usr_42b6e7a87221c857	PHONE	+919665075188	+919665075188	2026-09-30 12:01:58.437808+05:30
23	usr_26cd79c91e36a2ec	EMAIL	player_test_1790749918186@example.com	player_test_1790749918186@example.com	2026-09-30 12:01:58.446913+05:30
24	usr_26cd79c91e36a2ec	PHONE	+919723132762	+919723132762	2026-09-30 12:01:58.446913+05:30
25	usr_6b892eeb30401c97	EMAIL	manager_test_1790749918195@example.com	manager_test_1790749918195@example.com	2026-09-30 12:01:58.690929+05:30
26	usr_6b892eeb30401c97	PHONE	+919556772977	+919556772977	2026-09-30 12:01:58.690929+05:30
27	usr_d156636dc63e5f89	EMAIL	player_cctv_1790749918949@example.com	player_cctv_1790749918949@example.com	2026-09-30 12:01:58.950252+05:30
28	usr_d156636dc63e5f89	PHONE	+919438959972	+919438959972	2026-09-30 12:01:58.950252+05:30
29	usr_a16b19a7d0fed768	EMAIL	test_player_1790749918179@example.com	test_player_1790749918179@example.com	2026-09-30 12:01:59.298554+05:30
30	usr_a16b19a7d0fed768	PHONE	+919865147252	+919865147252	2026-09-30 12:01:59.298554+05:30
31	usr_1b2be606008073f9	EMAIL	player_test_1790749957229@example.com	player_test_1790749957229@example.com	2026-09-30 12:02:37.369829+05:30
32	usr_1b2be606008073f9	PHONE	+919784395288	+919784395288	2026-09-30 12:02:37.369829+05:30
33	usr_d7f33014a1b8ee7e	EMAIL	wallet_player_1790749957293@example.com	wallet_player_1790749957293@example.com	2026-09-30 12:02:37.43305+05:30
34	usr_d7f33014a1b8ee7e	PHONE	+919678548687	+919678548687	2026-09-30 12:02:37.43305+05:30
35	usr_791dcac02f2279ba	EMAIL	manager_test_1790749957131@example.com	manager_test_1790749957131@example.com	2026-09-30 12:02:37.522217+05:30
36	usr_791dcac02f2279ba	PHONE	+919546520253	+919546520253	2026-09-30 12:02:37.522217+05:30
37	usr_501bb44eb891425b	EMAIL	player_cctv_1790749957859@example.com	player_cctv_1790749957859@example.com	2026-09-30 12:02:37.859559+05:30
38	usr_501bb44eb891425b	PHONE	+919465175309	+919465175309	2026-09-30 12:02:37.859559+05:30
39	usr_d47727393c5cf58d	EMAIL	test_player_1790749957063@example.com	test_player_1790749957063@example.com	2026-09-30 12:02:38.041656+05:30
40	usr_d47727393c5cf58d	PHONE	+919820007558	+919820007558	2026-09-30 12:02:38.041656+05:30
41	usr_712ee3524ce3dde7	EMAIL	wf_player_1790750087833@example.com	wf_player_1790750087833@example.com	2026-09-30 12:04:47.973032+05:30
42	usr_712ee3524ce3dde7	PHONE	+919653683837	+919653683837	2026-09-30 12:04:47.973032+05:30
43	usr_63e9663a151524ad	EMAIL	wf_manager_1790750087833@example.com	wf_manager_1790750087833@example.com	2026-09-30 12:04:48.084342+05:30
44	usr_63e9663a151524ad	PHONE	+919591810090	+919591810090	2026-09-30 12:04:48.084342+05:30
45	usr_837a15479a780030	EMAIL	wf_player_1790750128941@example.com	wf_player_1790750128941@example.com	2026-09-30 12:05:29.154158+05:30
46	usr_837a15479a780030	PHONE	+919630531278	+919630531278	2026-09-30 12:05:29.154158+05:30
47	usr_9e1cc12535965c8a	EMAIL	wf_manager_1790750128941@example.com	wf_manager_1790750128941@example.com	2026-09-30 12:05:29.2549+05:30
48	usr_9e1cc12535965c8a	PHONE	+919579301011	+919579301011	2026-09-30 12:05:29.2549+05:30
49	usr_eb0b001d22f07016	EMAIL	wf_player_1790750165444@example.com	wf_player_1790750165444@example.com	2026-09-30 12:06:05.601039+05:30
50	usr_eb0b001d22f07016	PHONE	+919611497055	+919611497055	2026-09-30 12:06:05.601039+05:30
51	usr_8b558de699670318	EMAIL	wf_manager_1790750165444@example.com	wf_manager_1790750165444@example.com	2026-09-30 12:06:05.702279+05:30
52	usr_8b558de699670318	PHONE	+919582643633	+919582643633	2026-09-30 12:06:05.702279+05:30
53	usr_1c1c8a9a99910f99	EMAIL	wf_player_1790750204266@example.com	wf_player_1790750204266@example.com	2026-09-30 12:06:44.478138+05:30
54	usr_1c1c8a9a99910f99	PHONE	+919675142353	+919675142353	2026-09-30 12:06:44.478138+05:30
55	usr_99e86453b77b20f8	EMAIL	wf_manager_1790750204266@example.com	wf_manager_1790750204266@example.com	2026-09-30 12:06:44.579192+05:30
56	usr_99e86453b77b20f8	PHONE	+919559131758	+919559131758	2026-09-30 12:06:44.579192+05:30
57	usr_c2900f81677f6b40	EMAIL	wf_player_1790750269394@example.com	wf_player_1790750269394@example.com	2026-09-30 12:07:49.981544+05:30
58	usr_c2900f81677f6b40	PHONE	+919690455350	+919690455350	2026-09-30 12:07:49.981544+05:30
59	usr_a749ad15a4b83f56	EMAIL	wf_manager_1790750269394@example.com	wf_manager_1790750269394@example.com	2026-09-30 12:07:50.432161+05:30
60	usr_a749ad15a4b83f56	PHONE	+919535726686	+919535726686	2026-09-30 12:07:50.432161+05:30
61	usr_072c197d8fd4f7a3	EMAIL	wf_player_1790750323584@example.com	wf_player_1790750323584@example.com	2026-09-30 12:08:44.224652+05:30
62	usr_072c197d8fd4f7a3	PHONE	+919631024742	+919631024742	2026-09-30 12:08:44.224652+05:30
63	usr_de3c7a69b61ef701	EMAIL	wf_manager_1790750323584@example.com	wf_manager_1790750323584@example.com	2026-09-30 12:08:44.662312+05:30
64	usr_de3c7a69b61ef701	PHONE	+919562140416	+919562140416	2026-09-30 12:08:44.662312+05:30
65	usr_2d339c1c8a60a7bf	EMAIL	wf_player_1790750383881@example.com	wf_player_1790750383881@example.com	2026-09-30 12:09:44.742049+05:30
66	usr_2d339c1c8a60a7bf	PHONE	+919642824887	+919642824887	2026-09-30 12:09:44.742049+05:30
198	usr_ae2a15190a816afa	PHONE	+919532164568	+919532164568	2026-09-30 12:39:01.638572+05:30
67	usr_8c526a10e5c1c5cb	EMAIL	wf_manager_1790750383881@example.com	wf_manager_1790750383881@example.com	2026-09-30 12:09:45.288967+05:30
68	usr_8c526a10e5c1c5cb	PHONE	+919538653528	+919538653528	2026-09-30 12:09:45.288967+05:30
69	usr_d032febee8660434	EMAIL	wf_player_1790750462594@example.com	wf_player_1790750462594@example.com	2026-09-30 12:11:02.703715+05:30
70	usr_d032febee8660434	PHONE	+919693126218	+919693126218	2026-09-30 12:11:02.703715+05:30
71	usr_2b1f5e605b8f2010	EMAIL	wf_manager_1790750462594@example.com	wf_manager_1790750462594@example.com	2026-09-30 12:11:02.800466+05:30
72	usr_2b1f5e605b8f2010	PHONE	+919536490731	+919536490731	2026-09-30 12:11:02.800466+05:30
73	usr_c04f1863db4f19c1	EMAIL	wf_player_1790750512255@example.com	wf_player_1790750512255@example.com	2026-09-30 12:11:53.149978+05:30
74	usr_c04f1863db4f19c1	PHONE	+919616651943	+919616651943	2026-09-30 12:11:53.149978+05:30
75	usr_97d87fa5a02055dc	EMAIL	wf_manager_1790750512255@example.com	wf_manager_1790750512255@example.com	2026-09-30 12:11:53.601521+05:30
76	usr_97d87fa5a02055dc	PHONE	+919594176337	+919594176337	2026-09-30 12:11:53.601521+05:30
77	usr_39ea6b242671d81c	EMAIL	wf_player_1790750623527@example.com	wf_player_1790750623527@example.com	2026-09-30 12:13:43.628109+05:30
78	usr_39ea6b242671d81c	PHONE	+919669049331	+919669049331	2026-09-30 12:13:43.628109+05:30
79	usr_4262abd5736887a7	EMAIL	wf_manager_1790750623527@example.com	wf_manager_1790750623527@example.com	2026-09-30 12:13:43.719288+05:30
80	usr_4262abd5736887a7	PHONE	+919532532433	+919532532433	2026-09-30 12:13:43.719288+05:30
81	usr_1a92cc3ed067921f	EMAIL	wf_player_1790750795839@example.com	wf_player_1790750795839@example.com	2026-09-30 12:16:35.943967+05:30
82	usr_1a92cc3ed067921f	PHONE	+919684860257	+919684860257	2026-09-30 12:16:35.943967+05:30
83	usr_b1d7ea4b904ef79c	EMAIL	wf_manager_1790750795839@example.com	wf_manager_1790750795839@example.com	2026-09-30 12:16:36.041289+05:30
84	usr_b1d7ea4b904ef79c	PHONE	+919516065478	+919516065478	2026-09-30 12:16:36.041289+05:30
85	usr_fe8e1e4957015c39	EMAIL	wf_player_1790750815653@example.com	wf_player_1790750815653@example.com	2026-09-30 12:16:55.952649+05:30
86	usr_fe8e1e4957015c39	PHONE	+919691997544	+919691997544	2026-09-30 12:16:55.952649+05:30
87	usr_7fa7260cfb9e0c26	EMAIL	wf_manager_1790750815653@example.com	wf_manager_1790750815653@example.com	2026-09-30 12:16:56.127651+05:30
88	usr_7fa7260cfb9e0c26	PHONE	+919554865121	+919554865121	2026-09-30 12:16:56.127651+05:30
89	usr_483214e785cf434a	EMAIL	wallet_player_1790750816657@example.com	wallet_player_1790750816657@example.com	2026-09-30 12:16:56.813757+05:30
90	usr_483214e785cf434a	PHONE	+919655995548	+919655995548	2026-09-30 12:16:56.813757+05:30
91	usr_70cf84b74a8d0975	EMAIL	player_test_1790750816875@example.com	player_test_1790750816875@example.com	2026-09-30 12:16:57.003569+05:30
92	usr_70cf84b74a8d0975	PHONE	+919781182301	+919781182301	2026-09-30 12:16:57.003569+05:30
93	usr_66623e82cb6ddd26	EMAIL	manager_test_1790750816733@example.com	manager_test_1790750816733@example.com	2026-09-30 12:16:57.102498+05:30
94	usr_66623e82cb6ddd26	PHONE	+919540046845	+919540046845	2026-09-30 12:16:57.102498+05:30
95	usr_e8dd3605e526e61d	EMAIL	player_cctv_1790750817410@example.com	player_cctv_1790750817410@example.com	2026-09-30 12:16:57.411336+05:30
96	usr_e8dd3605e526e61d	PHONE	+919495955874	+919495955874	2026-09-30 12:16:57.411336+05:30
97	usr_c693284ad8ad5abe	EMAIL	test_player_1790750816743@example.com	test_player_1790750816743@example.com	2026-09-30 12:16:57.671051+05:30
98	usr_c693284ad8ad5abe	PHONE	+919816811418	+919816811418	2026-09-30 12:16:57.671051+05:30
99	usr_332b68556f881273	EMAIL	wf_player_1790751284036@example.com	wf_player_1790751284036@example.com	2026-09-30 12:24:44.19241+05:30
100	usr_332b68556f881273	PHONE	+919696640726	+919696640726	2026-09-30 12:24:44.19241+05:30
101	usr_426334eee09db891	EMAIL	player_test_1790751284068@example.com	player_test_1790751284068@example.com	2026-09-30 12:24:44.210874+05:30
102	usr_426334eee09db891	PHONE	+919790340413	+919790340413	2026-09-30 12:24:44.210874+05:30
103	usr_d3fe85aa55a03730	EMAIL	wallet_player_1790751284094@example.com	wallet_player_1790751284094@example.com	2026-09-30 12:24:44.229513+05:30
104	usr_d3fe85aa55a03730	PHONE	+919618773506	+919618773506	2026-09-30 12:24:44.229513+05:30
105	usr_c641dbc8e3c7bf62	EMAIL	wf_manager_1790751284036@example.com	wf_manager_1790751284036@example.com	2026-09-30 12:24:44.317629+05:30
106	usr_c641dbc8e3c7bf62	PHONE	+919578765938	+919578765938	2026-09-30 12:24:44.317629+05:30
107	usr_31a34b67a1c9070a	EMAIL	manager_test_1790751284061@example.com	manager_test_1790751284061@example.com	2026-09-30 12:24:44.513539+05:30
108	usr_31a34b67a1c9070a	PHONE	+919524848857	+919524848857	2026-09-30 12:24:44.513539+05:30
109	usr_e52ef76965d3db06	EMAIL	player_cctv_1790751284790@example.com	player_cctv_1790751284790@example.com	2026-09-30 12:24:44.790603+05:30
110	usr_e52ef76965d3db06	PHONE	+919443543955	+919443543955	2026-09-30 12:24:44.790603+05:30
111	usr_f87296a72c33648b	EMAIL	test_player_1790751284025@example.com	test_player_1790751284025@example.com	2026-09-30 12:24:45.068578+05:30
112	usr_f87296a72c33648b	PHONE	+919847602960	+919847602960	2026-09-30 12:24:45.068578+05:30
113	usr_d2c85356dd19365c	EMAIL	pay_p1_1790751554318@example.com	pay_p1_1790751554318@example.com	2026-09-30 12:29:14.429098+05:30
114	usr_d2c85356dd19365c	PHONE	+919833118618	+919833118618	2026-09-30 12:29:14.429098+05:30
115	usr_a73a6f4cffbc42b8	EMAIL	pay_p2_1790751554318@example.com	pay_p2_1790751554318@example.com	2026-09-30 12:29:14.534356+05:30
116	usr_a73a6f4cffbc42b8	PHONE	+919727038732	+919727038732	2026-09-30 12:29:14.534356+05:30
117	usr_2ecf15c886956bdd	EMAIL	pay_p1_1790751600440@example.com	pay_p1_1790751600440@example.com	2026-09-30 12:30:00.57832+05:30
118	usr_2ecf15c886956bdd	PHONE	+919896107719	+919896107719	2026-09-30 12:30:00.57832+05:30
119	usr_441c0e3d289b7aac	EMAIL	pay_p1_1790751642613@example.com	pay_p1_1790751642613@example.com	2026-09-30 12:30:42.75968+05:30
120	usr_441c0e3d289b7aac	PHONE	+919852620196	+919852620196	2026-09-30 12:30:42.75968+05:30
121	usr_f28801a3540af399	EMAIL	pay_p2_1790751642613@example.com	pay_p2_1790751642613@example.com	2026-09-30 12:30:42.906984+05:30
122	usr_f28801a3540af399	PHONE	+919761893502	+919761893502	2026-09-30 12:30:42.906984+05:30
123	usr_b636f1ae7e91e71f	EMAIL	pay_p1_1790751664402@example.com	pay_p1_1790751664402@example.com	2026-09-30 12:31:04.576239+05:30
124	usr_b636f1ae7e91e71f	PHONE	+919894222180	+919894222180	2026-09-30 12:31:04.576239+05:30
125	usr_65c1f48cff9008b3	EMAIL	wallet_player_1790751664437@example.com	wallet_player_1790751664437@example.com	2026-09-30 12:31:04.594927+05:30
126	usr_65c1f48cff9008b3	PHONE	+919680706728	+919680706728	2026-09-30 12:31:04.594927+05:30
127	usr_fb4c3d97481d72eb	EMAIL	wf_player_1790751664506@example.com	wf_player_1790751664506@example.com	2026-09-30 12:31:04.666059+05:30
128	usr_fb4c3d97481d72eb	PHONE	+919636347176	+919636347176	2026-09-30 12:31:04.666059+05:30
129	usr_1e93ccb241b92f8d	EMAIL	player_test_1790751664491@example.com	player_test_1790751664491@example.com	2026-09-30 12:31:04.749571+05:30
130	usr_1e93ccb241b92f8d	PHONE	+919765844539	+919765844539	2026-09-30 12:31:04.749571+05:30
131	usr_78aacbf0e54c792a	EMAIL	pay_p2_1790751664402@example.com	pay_p2_1790751664402@example.com	2026-09-30 12:31:04.76053+05:30
132	usr_78aacbf0e54c792a	PHONE	+919713692957	+919713692957	2026-09-30 12:31:04.76053+05:30
133	usr_0385a239ccd5b41d	EMAIL	wf_manager_1790751664506@example.com	wf_manager_1790751664506@example.com	2026-09-30 12:31:04.791764+05:30
134	usr_0385a239ccd5b41d	PHONE	+919592564303	+919592564303	2026-09-30 12:31:04.791764+05:30
135	usr_8d8d233cb1520d3e	EMAIL	manager_test_1790751664390@example.com	manager_test_1790751664390@example.com	2026-09-30 12:31:04.7928+05:30
136	usr_8d8d233cb1520d3e	PHONE	+919554087186	+919554087186	2026-09-30 12:31:04.7928+05:30
137	usr_c64529f35491354a	EMAIL	player_cctv_1790751665099@example.com	player_cctv_1790751665099@example.com	2026-09-30 12:31:05.0999+05:30
138	usr_c64529f35491354a	PHONE	+919451847035	+919451847035	2026-09-30 12:31:05.0999+05:30
139	usr_6b06fb2b57910aaa	EMAIL	test_player_1790751664425@example.com	test_player_1790751664425@example.com	2026-09-30 12:31:05.338848+05:30
140	usr_6b06fb2b57910aaa	PHONE	+919859775031	+919859775031	2026-09-30 12:31:05.338848+05:30
141	usr_e43d0fd722732ad0	EMAIL	manager_test_1790751921507@example.com	manager_test_1790751921507@example.com	2026-09-30 12:35:21.783838+05:30
142	usr_e43d0fd722732ad0	PHONE	+919571466865	+919571466865	2026-09-30 12:35:21.783838+05:30
143	usr_9058099580347858	EMAIL	player_cctv_1790751922033@example.com	player_cctv_1790751922033@example.com	2026-09-30 12:35:22.034125+05:30
144	usr_9058099580347858	PHONE	+919442908608	+919442908608	2026-09-30 12:35:22.034125+05:30
145	usr_390269341390c4dd	EMAIL	wallet_player_1790751939666@example.com	wallet_player_1790751939666@example.com	2026-09-30 12:35:39.827181+05:30
146	usr_390269341390c4dd	PHONE	+919614979233	+919614979233	2026-09-30 12:35:39.827181+05:30
147	usr_2afcf6367d1dc020	EMAIL	pay_p1_1790751939684@example.com	pay_p1_1790751939684@example.com	2026-09-30 12:35:39.855009+05:30
148	usr_2afcf6367d1dc020	PHONE	+919855850131	+919855850131	2026-09-30 12:35:39.855009+05:30
149	usr_e5af181f986f06b3	EMAIL	wf_player_1790751939764@example.com	wf_player_1790751939764@example.com	2026-09-30 12:35:39.92299+05:30
150	usr_e5af181f986f06b3	PHONE	+919618054208	+919618054208	2026-09-30 12:35:39.92299+05:30
151	usr_11fdc7381d901c43	EMAIL	player_test_1790751939771@example.com	player_test_1790751939771@example.com	2026-09-30 12:35:39.931167+05:30
152	usr_11fdc7381d901c43	PHONE	+919754146379	+919754146379	2026-09-30 12:35:39.931167+05:30
153	usr_8b37e09a3fe45bc9	EMAIL	pay_p2_1790751939684@example.com	pay_p2_1790751939684@example.com	2026-09-30 12:35:40.063464+05:30
154	usr_8b37e09a3fe45bc9	PHONE	+919771713730	+919771713730	2026-09-30 12:35:40.063464+05:30
155	usr_adc575328dc2453a	EMAIL	wf_manager_1790751939764@example.com	wf_manager_1790751939764@example.com	2026-09-30 12:35:40.073643+05:30
156	usr_adc575328dc2453a	PHONE	+919588329945	+919588329945	2026-09-30 12:35:40.073643+05:30
157	usr_5dd9bc34451d7881	EMAIL	manager_test_1790751939692@example.com	manager_test_1790751939692@example.com	2026-09-30 12:35:40.112289+05:30
158	usr_5dd9bc34451d7881	PHONE	+919589188840	+919589188840	2026-09-30 12:35:40.112289+05:30
159	usr_d83a341c2319afc3	EMAIL	player_cctv_1790751940441@example.com	player_cctv_1790751940441@example.com	2026-09-30 12:35:40.442572+05:30
160	usr_d83a341c2319afc3	PHONE	+919499872589	+919499872589	2026-09-30 12:35:40.442572+05:30
161	usr_551f76650073a64a	EMAIL	test_player_1790751939728@example.com	test_player_1790751939728@example.com	2026-09-30 12:35:40.751793+05:30
162	usr_551f76650073a64a	PHONE	+919852531031	+919852531031	2026-09-30 12:35:40.751793+05:30
163	usr_d37a502d11e5da99	EMAIL	wf_player_1790752080144@example.com	wf_player_1790752080144@example.com	2026-09-30 12:38:00.606571+05:30
164	usr_d37a502d11e5da99	PHONE	+919651297221	+919651297221	2026-09-30 12:38:00.606571+05:30
165	usr_5cfc9ba5df459c07	EMAIL	wf_manager_1790752080144@example.com	wf_manager_1790752080144@example.com	2026-09-30 12:38:01.031864+05:30
166	usr_5cfc9ba5df459c07	PHONE	+919566050567	+919566050567	2026-09-30 12:38:01.031864+05:30
167	usr_507a98d2112c5563	EMAIL	player_test_1790752097472@example.com	player_test_1790752097472@example.com	2026-09-30 12:38:17.6119+05:30
168	usr_507a98d2112c5563	PHONE	+919749113959	+919749113959	2026-09-30 12:38:17.6119+05:30
169	usr_e03c44f59bbff28f	EMAIL	wallet_player_1790752097492@example.com	wallet_player_1790752097492@example.com	2026-09-30 12:38:17.63146+05:30
170	usr_e03c44f59bbff28f	PHONE	+919645483119	+919645483119	2026-09-30 12:38:17.63146+05:30
171	usr_afbec60a362f096d	EMAIL	wf_player_1790752097446@example.com	wf_player_1790752097446@example.com	2026-09-30 12:38:17.7351+05:30
172	usr_afbec60a362f096d	PHONE	+919620714081	+919620714081	2026-09-30 12:38:17.7351+05:30
173	usr_8c69afe724c09d49	EMAIL	pay_p1_1790752097464@example.com	pay_p1_1790752097464@example.com	2026-09-30 12:38:17.740288+05:30
174	usr_8c69afe724c09d49	PHONE	+919896183293	+919896183293	2026-09-30 12:38:17.740288+05:30
175	usr_6bc672c4761b5a78	EMAIL	wf_manager_1790752097446@example.com	wf_manager_1790752097446@example.com	2026-09-30 12:38:17.879841+05:30
176	usr_6bc672c4761b5a78	PHONE	+919564102935	+919564102935	2026-09-30 12:38:17.879841+05:30
177	usr_7f74277e048fcd18	EMAIL	pay_p2_1790752097464@example.com	pay_p2_1790752097464@example.com	2026-09-30 12:38:17.931032+05:30
178	usr_7f74277e048fcd18	PHONE	+919763547631	+919763547631	2026-09-30 12:38:17.931032+05:30
179	usr_046291f5a26cbfef	EMAIL	manager_test_1790752097453@example.com	manager_test_1790752097453@example.com	2026-09-30 12:38:17.959253+05:30
180	usr_046291f5a26cbfef	PHONE	+919559700590	+919559700590	2026-09-30 12:38:17.959253+05:30
181	usr_edc9b30bd17b2c3f	EMAIL	player_cctv_1790752098267@example.com	player_cctv_1790752098267@example.com	2026-09-30 12:38:18.269089+05:30
182	usr_edc9b30bd17b2c3f	PHONE	+919410999358	+919410999358	2026-09-30 12:38:18.269089+05:30
183	usr_3fd88a7c51a18416	EMAIL	test_player_1790752097407@example.com	test_player_1790752097407@example.com	2026-09-30 12:38:22.791715+05:30
184	usr_3fd88a7c51a18416	PHONE	+919852698021	+919852698021	2026-09-30 12:38:22.791715+05:30
185	usr_a7b4c5abd3ed76c5	EMAIL	pay_p1_1790752141002@example.com	pay_p1_1790752141002@example.com	2026-09-30 12:39:01.204702+05:30
186	usr_a7b4c5abd3ed76c5	PHONE	+919840632339	+919840632339	2026-09-30 12:39:01.204702+05:30
187	usr_3b955f3d4bb859f2	EMAIL	wf_player_1790752141036@example.com	wf_player_1790752141036@example.com	2026-09-30 12:39:01.227933+05:30
188	usr_3b955f3d4bb859f2	PHONE	+919628724533	+919628724533	2026-09-30 12:39:01.227933+05:30
189	usr_1f42ebc28c735546	EMAIL	wallet_player_1790752141085@example.com	wallet_player_1790752141085@example.com	2026-09-30 12:39:01.251463+05:30
190	usr_50634ff073aa77b9	EMAIL	player_test_1790752140961@example.com	player_test_1790752140961@example.com	2026-09-30 12:39:01.245398+05:30
191	usr_1f42ebc28c735546	PHONE	+919630805967	+919630805967	2026-09-30 12:39:01.251463+05:30
192	usr_50634ff073aa77b9	PHONE	+919761805747	+919761805747	2026-09-30 12:39:01.245398+05:30
193	usr_8ba4c28082ef21a7	EMAIL	wf_manager_1790752141036@example.com	wf_manager_1790752141036@example.com	2026-09-30 12:39:01.391838+05:30
194	usr_8ba4c28082ef21a7	PHONE	+919590674772	+919590674772	2026-09-30 12:39:01.391838+05:30
195	usr_8d0907e902d9d9dd	EMAIL	pay_p2_1790752141002@example.com	pay_p2_1790752141002@example.com	2026-09-30 12:39:01.421758+05:30
196	usr_8d0907e902d9d9dd	PHONE	+919723669944	+919723669944	2026-09-30 12:39:01.421758+05:30
197	usr_ae2a15190a816afa	EMAIL	manager_test_1790752141176@example.com	manager_test_1790752141176@example.com	2026-09-30 12:39:01.638572+05:30
199	usr_9e9b8b953ce4c7eb	EMAIL	player_cctv_1790752141965@example.com	player_cctv_1790752141965@example.com	2026-09-30 12:39:01.966584+05:30
200	usr_9e9b8b953ce4c7eb	PHONE	+919463283154	+919463283154	2026-09-30 12:39:01.966584+05:30
201	usr_249c7f996e96c57d	EMAIL	test_player_1790752142116@example.com	test_player_1790752142116@example.com	2026-09-30 12:39:13.382528+05:30
202	usr_249c7f996e96c57d	PHONE	+919839248870	+919839248870	2026-09-30 12:39:13.382528+05:30
203	usr_f8b3a9c750f5c30e	EMAIL	manager_test_1790756403131@example.com	manager_test_1790756403131@example.com	2026-09-30 13:50:03.556262+05:30
204	usr_f8b3a9c750f5c30e	PHONE	+919587253846	+919587253846	2026-09-30 13:50:03.556262+05:30
205	usr_bd5528dac05a06bc	EMAIL	player_cctv_1790756403970@example.com	player_cctv_1790756403970@example.com	2026-09-30 13:50:03.97142+05:30
206	usr_bd5528dac05a06bc	PHONE	+919451979561	+919451979561	2026-09-30 13:50:03.97142+05:30
207	usr_58e3c108ab31e109	EMAIL	player_test_1790756436987@example.com	player_test_1790756436987@example.com	2026-09-30 13:50:37.145225+05:30
208	usr_58e3c108ab31e109	PHONE	+919767510233	+919767510233	2026-09-30 13:50:37.145225+05:30
209	usr_b7675a4a677cc52c	EMAIL	wallet_player_1790756497318@example.com	wallet_player_1790756497318@example.com	2026-09-30 13:51:37.487604+05:30
210	usr_b7675a4a677cc52c	PHONE	+919647132330	+919647132330	2026-09-30 13:51:37.487604+05:30
211	usr_65fa9d3936098493	EMAIL	test_player_1790756565966@example.com	test_player_1790756565966@example.com	2026-09-30 13:52:47.161825+05:30
212	usr_65fa9d3936098493	PHONE	+919838651969	+919838651969	2026-09-30 13:52:47.161825+05:30
213	usr_8279dc24442d924a	EMAIL	wf_player_1790756601463@example.com	wf_player_1790756601463@example.com	2026-09-30 13:53:21.66723+05:30
214	usr_8279dc24442d924a	PHONE	+919665946044	+919665946044	2026-09-30 13:53:21.66723+05:30
215	usr_4f9318878fbd93df	EMAIL	wf_manager_1790756601463@example.com	wf_manager_1790756601463@example.com	2026-09-30 13:53:21.782978+05:30
216	usr_4f9318878fbd93df	PHONE	+919591630935	+919591630935	2026-09-30 13:53:21.782978+05:30
217	usr_386a8db5450ed2bf	EMAIL	pay_p1_1790756629783@example.com	pay_p1_1790756629783@example.com	2026-09-30 13:53:49.916953+05:30
218	usr_386a8db5450ed2bf	PHONE	+919853875013	+919853875013	2026-09-30 13:53:49.916953+05:30
219	usr_69f63c6fa32cb0fe	EMAIL	pay_p2_1790756629783@example.com	pay_p2_1790756629783@example.com	2026-09-30 13:53:50.083187+05:30
220	usr_69f63c6fa32cb0fe	PHONE	+919756770652	+919756770652	2026-09-30 13:53:50.083187+05:30
221	usr_86b3e6d40335e6f1	EMAIL	player_test_1790848588498@example.com	player_test_1790848588498@example.com	2026-10-01 15:26:28.975522+05:30
222	usr_73c45d42f9750142	EMAIL	wallet_player_1790848588496@example.com	wallet_player_1790848588496@example.com	2026-10-01 15:26:28.988086+05:30
223	usr_73c45d42f9750142	PHONE	+919637366299	+919637366299	2026-10-01 15:26:28.988086+05:30
224	usr_86b3e6d40335e6f1	PHONE	+919783790462	+919783790462	2026-10-01 15:26:28.975522+05:30
225	usr_8cf6038983567937	EMAIL	wf_player_1790848588497@example.com	wf_player_1790848588497@example.com	2026-10-01 15:26:29.129303+05:30
226	usr_8cf6038983567937	PHONE	+919610984495	+919610984495	2026-10-01 15:26:29.129303+05:30
227	usr_aaba6c37ed2fbd00	EMAIL	pay_p1_1790848588497@example.com	pay_p1_1790848588497@example.com	2026-10-01 15:26:29.185564+05:30
228	usr_aaba6c37ed2fbd00	PHONE	+919829499613	+919829499613	2026-10-01 15:26:29.185564+05:30
229	usr_3956d119b0e3e452	EMAIL	wf_manager_1790848588497@example.com	wf_manager_1790848588497@example.com	2026-10-01 15:26:29.332987+05:30
230	usr_3956d119b0e3e452	PHONE	+919587339174	+919587339174	2026-10-01 15:26:29.332987+05:30
231	usr_66ac9868bfa6631c	EMAIL	pay_p2_1790848588497@example.com	pay_p2_1790848588497@example.com	2026-10-01 15:26:29.465411+05:30
232	usr_66ac9868bfa6631c	PHONE	+919750872371	+919750872371	2026-10-01 15:26:29.465411+05:30
233	usr_ea7d22375987cbb3	EMAIL	manager_test_1790848588497@example.com	manager_test_1790848588497@example.com	2026-10-01 15:26:29.487198+05:30
234	usr_ea7d22375987cbb3	PHONE	+919567092200	+919567092200	2026-10-01 15:26:29.487198+05:30
235	usr_191f6cef8ff784cc	EMAIL	player_cctv_1790848590005@example.com	player_cctv_1790848590005@example.com	2026-10-01 15:26:30.006592+05:30
236	usr_191f6cef8ff784cc	PHONE	+919448575609	+919448575609	2026-10-01 15:26:30.006592+05:30
237	usr_8cb0d6db3214a9bc	EMAIL	test_player_1790848588500@example.com	test_player_1790848588500@example.com	2026-10-01 15:26:30.633344+05:30
238	usr_8cb0d6db3214a9bc	PHONE	+919886446059	+919886446059	2026-10-01 15:26:30.633344+05:30
239	usr_372a9de0c155953d	EMAIL	wf_player_1790848991248@example.com	wf_player_1790848991248@example.com	2026-10-01 15:33:11.470376+05:30
240	usr_372a9de0c155953d	PHONE	+919613076306	+919613076306	2026-10-01 15:33:11.470376+05:30
241	usr_77d1efe4afbc4c7f	EMAIL	wf_manager_1790848991248@example.com	wf_manager_1790848991248@example.com	2026-10-01 15:33:11.625832+05:30
242	usr_77d1efe4afbc4c7f	PHONE	+919570031891	+919570031891	2026-10-01 15:33:11.625832+05:30
243	usr_16c2144c0df7f485	EMAIL	player_test_1790849348155@example.com	player_test_1790849348155@example.com	2026-10-01 15:39:08.692231+05:30
244	usr_16c2144c0df7f485	PHONE	+919742426735	+919742426735	2026-10-01 15:39:08.692231+05:30
245	usr_f16724c6f8d5f94d	EMAIL	wallet_player_1790849348137@example.com	wallet_player_1790849348137@example.com	2026-10-01 15:39:08.716562+05:30
246	usr_f16724c6f8d5f94d	PHONE	+919641985519	+919641985519	2026-10-01 15:39:08.716562+05:30
247	usr_e9919c23c0467ea5	EMAIL	pay_p1_1790849348215@example.com	pay_p1_1790849348215@example.com	2026-10-01 15:39:08.814903+05:30
248	usr_e9919c23c0467ea5	PHONE	+919893581768	+919893581768	2026-10-01 15:39:08.814903+05:30
249	usr_258e0b7430df83ca	EMAIL	wf_player_1790849348212@example.com	wf_player_1790849348212@example.com	2026-10-01 15:39:08.819806+05:30
250	usr_258e0b7430df83ca	PHONE	+919664002345	+919664002345	2026-10-01 15:39:08.819806+05:30
251	usr_4b2405663fda6e40	EMAIL	wf_manager_1790849348212@example.com	wf_manager_1790849348212@example.com	2026-10-01 15:39:09.019558+05:30
252	usr_4b2405663fda6e40	PHONE	+919523226815	+919523226815	2026-10-01 15:39:09.019558+05:30
253	usr_05a01b29ffddd525	EMAIL	pay_p2_1790849348215@example.com	pay_p2_1790849348215@example.com	2026-10-01 15:39:09.091211+05:30
254	usr_05a01b29ffddd525	PHONE	+919716661387	+919716661387	2026-10-01 15:39:09.091211+05:30
255	usr_a0ea1d4f298d4a7e	EMAIL	manager_test_1790849348214@example.com	manager_test_1790849348214@example.com	2026-10-01 15:39:09.096588+05:30
256	usr_a0ea1d4f298d4a7e	PHONE	+919595725145	+919595725145	2026-10-01 15:39:09.096588+05:30
257	usr_a10542f59057b140	EMAIL	player_cctv_1790849349545@example.com	player_cctv_1790849349545@example.com	2026-10-01 15:39:09.545766+05:30
258	usr_a10542f59057b140	PHONE	+919415833250	+919415833250	2026-10-01 15:39:09.545766+05:30
259	usr_962f5f2641636fae	EMAIL	test_player_1790849348188@example.com	test_player_1790849348188@example.com	2026-10-01 15:39:09.777615+05:30
260	usr_962f5f2641636fae	PHONE	+919841893715	+919841893715	2026-10-01 15:39:09.777615+05:30
261	usr_2bad6dc1de996b96	EMAIL	player_test_1790849831152@example.com	player_test_1790849831152@example.com	2026-10-01 15:47:11.327178+05:30
262	usr_2bad6dc1de996b96	PHONE	+919739804287	+919739804287	2026-10-01 15:47:11.327178+05:30
263	usr_b2c56e4b881cf6fb	EMAIL	wallet_player_1790849831168@example.com	wallet_player_1790849831168@example.com	2026-10-01 15:47:11.336305+05:30
264	usr_a1bd125a6a3dd41a	EMAIL	wf_player_1790849831155@example.com	wf_player_1790849831155@example.com	2026-10-01 15:47:11.340322+05:30
265	usr_a1bd125a6a3dd41a	PHONE	+919659733868	+919659733868	2026-10-01 15:47:11.340322+05:30
269	usr_a7b005600886fb63	EMAIL	wf_manager_1790849831155@example.com	wf_manager_1790849831155@example.com	2026-10-01 15:47:11.48058+05:30
270	usr_a7b005600886fb63	PHONE	+919566949244	+919566949244	2026-10-01 15:47:11.48058+05:30
266	usr_b2c56e4b881cf6fb	PHONE	+919624607084	+919624607084	2026-10-01 15:47:11.336305+05:30
267	usr_d012c52d94f984bc	EMAIL	pay_p1_1790849831173@example.com	pay_p1_1790849831173@example.com	2026-10-01 15:47:11.359737+05:30
268	usr_d012c52d94f984bc	PHONE	+919839512179	+919839512179	2026-10-01 15:47:11.359737+05:30
271	usr_5eb6d029937b3c22	EMAIL	pay_p2_1790849831173@example.com	pay_p2_1790849831173@example.com	2026-10-01 15:47:11.55337+05:30
272	usr_5eb6d029937b3c22	PHONE	+919725123347	+919725123347	2026-10-01 15:47:11.55337+05:30
273	usr_bd31992cc995573f	EMAIL	manager_test_1790849831200@example.com	manager_test_1790849831200@example.com	2026-10-01 15:47:11.613754+05:30
274	usr_bd31992cc995573f	PHONE	+919566737899	+919566737899	2026-10-01 15:47:11.613754+05:30
275	usr_7a1b921337c5cb3c	EMAIL	player_cctv_1790849831895@example.com	player_cctv_1790849831895@example.com	2026-10-01 15:47:11.89599+05:30
276	usr_7a1b921337c5cb3c	PHONE	+919475337244	+919475337244	2026-10-01 15:47:11.89599+05:30
277	usr_87256bb5c03dd033	EMAIL	test_player_1790849831152@example.com	test_player_1790849831152@example.com	2026-10-01 15:47:12.256235+05:30
278	usr_87256bb5c03dd033	PHONE	+919855730347	+919855730347	2026-10-01 15:47:12.256235+05:30
279	usr_62068e8f5fc912b3	EMAIL	wallet_player_1790852590184@example.com	wallet_player_1790852590184@example.com	2026-10-01 16:33:10.325856+05:30
280	usr_62068e8f5fc912b3	PHONE	+919642658996	+919642658996	2026-10-01 16:33:10.325856+05:30
\.


--
-- TOC entry 6177 (class 0 OID 18105)
-- Dependencies: 233
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sessions (id, user_id, refresh_token_hash, device_info, ip_address, is_revoked, expires_at, created_at) FROM stdin;
sess_6e5a4fdc4653f0f7052c	usr_771ffc659cac6f5f	b873a16f855e82ca2a4b26a29530aca8561fc928a230e02bb7360b7a5e295894	Mobile App	127.0.0.1	f	2026-10-29 12:55:42.637+05:30	2026-09-29 12:55:42.637701+05:30
sess_ee27c90926c4afad62a1	usr_771ffc659cac6f5f	5c761ff656bbf395ac6d32ff413b8979f59c9e3317c2b728d4683a447b24bcdd	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-29 12:56:55.116+05:30	2026-09-29 12:56:55.117526+05:30
sess_59aaa630cf6f93ae36f2	usr_771ffc659cac6f5f	134128d9cb7cbb7796a6aeb610d25a07b5ccaf5996c7d1a71607a7bd629abadb	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-29 13:18:16.647+05:30	2026-09-29 13:18:16.648873+05:30
sess_6e23605a4ee79d053214	usr_a7845baf785372f9	000ee0824b26c30c4e8d874c5803f7ee47eb8b4954456a4d9ca761df48cf7877	Mobile App	127.0.0.1	f	2026-10-29 13:52:53.133+05:30	2026-09-29 13:52:53.134244+05:30
sess_ea4b1ec14235cd2469e8	usr_4b474011146a3a70	65fc69ba71b24fe07227f611f6b572aa36a3a307f9f94a766a73233b8a8ff2cf	Mobile App	127.0.0.1	t	2026-10-29 13:28:37.828+05:30	2026-09-29 13:28:37.829536+05:30
sess_0f38fad8239c000ec78d	usr_771ffc659cac6f5f	4cce5d501ebe6b5a83e980b0dca018d963973d09fa5e2b33d88676f0449f22c2	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-29 15:14:27.922+05:30	2026-09-29 15:14:27.923917+05:30
sess_b0299ed4c3ee3a5d92d2	usr_e55abb463db8392d	373c743fcfee887ff86d29230618fc212a9e5d732ee95c57517b61d1b36cb2cc	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-29 15:31:53.925+05:30	2026-09-29 15:31:53.925748+05:30
sess_66df6ecd481ab1e4f3e9	usr_2868a49c6aa551f5	3f4f4aef89d9d22e4ee69c74024d92f8ff4965d03ca6ba2f943729687db0b03c	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-29 15:33:40.752+05:30	2026-09-29 15:33:40.752641+05:30
sess_d6d31cf63e66b8c4be8a	usr_771ffc659cac6f5f	6ffd3f9ffcc4d42078439d7b019bc1977af46a52bf9a1950faadd8825feb8aa7	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-29 17:22:11.697+05:30	2026-09-29 17:22:11.69869+05:30
sess_576c3763d91db10bce63	usr_771ffc659cac6f5f	db79c44e3d35624810fa1403d55ab91e3f08cc55a03a81a5a4d0146bd3628271	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-30 10:57:43.872+05:30	2026-09-30 10:57:43.874287+05:30
sess_5f2f4ad8a1cc91571e72	usr_771ffc659cac6f5f	1958bad9a8057ee2ac54a17fd9ca5ce49adbb328a975bfad4db593b0cddd9827	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-30 11:01:21.231+05:30	2026-09-30 11:01:21.232133+05:30
sess_f0a5ff52eba350554179	usr_e4fa19886f0b282e	d9a0e81deea42d1773230d7cbd516d382b1ed009a51ff3e7e17ce5f99536fb85	Mobile App	::ffff:127.0.0.1	f	2026-10-30 11:40:11.544+05:30	2026-09-30 11:40:11.545819+05:30
sess_7fc8b171bc9b913d6ae0	usr_b3d3f31095d1547a	d75d5ab56d2718e38c7fb91e72246a6ada0ee30294d40cd21b32cfa39ec233ec	Mobile App	::ffff:127.0.0.1	f	2026-10-30 11:40:11.64+05:30	2026-09-30 11:40:11.641802+05:30
sess_ea582997fc4dcfabfa4a	usr_2cd11304a4ea973d	ae5027f37a25775de9e439ddeb6d22f2285e3ed9f61820e84d564777de24a4a8	Mobile App	::ffff:127.0.0.1	f	2026-10-30 11:40:11.977+05:30	2026-09-30 11:40:11.978703+05:30
sess_f5de3b370423b8344333	usr_1fbef46f504fc1b9	2e1548e5866255daca8af24937d0b72a6ee23d1a20077e99862bf2efb0b28869	Mobile App	::ffff:127.0.0.1	f	2026-10-30 11:40:12.258+05:30	2026-09-30 11:40:12.259203+05:30
sess_ab412285268aa71bf1cf	usr_fb3b4ae1787a833c	2938477d437994bef1defde26392e9b4888251b6e639b471947f5118169e11b1	Mobile App	::ffff:127.0.0.1	t	2026-10-30 11:40:12.858+05:30	2026-09-30 11:40:12.858726+05:30
sess_260f17bc5627215aa1bf	usr_fb3b4ae1787a833c	df2aa753b1b3b0cb6905c38956bd408ea493b7e7f0d044e2fcf78b6db74f25bd	Mobile App	127.0.0.1	t	2026-10-30 11:40:12.535+05:30	2026-09-30 11:40:12.568455+05:30
sess_e23b66d9edac1952aa74	usr_fb3b4ae1787a833c	5b3afdf7145018c238284c0a1bfd731dff67ed10f01a8ba49372ecaab1adf47a	Mobile App	::ffff:127.0.0.1	t	2026-10-30 11:40:13.139+05:30	2026-09-30 11:40:13.139859+05:30
sess_c252ac6b83fea7a90607	usr_fb3b4ae1787a833c	f11d14678bf32c867976f9d6a04f86b72d3426364b6e98e5a78e4faeb4524086	Mobile App	::ffff:127.0.0.1	t	2026-10-30 11:40:13.423+05:30	2026-09-30 11:40:13.423553+05:30
sess_31ecb5d6bf8d8acce725	usr_fb3b4ae1787a833c	1b72ed86d11bb0b39a4e42f1381f392f84ec165eecb63865210b10e85df60d6b	Mobile App	::ffff:127.0.0.1	f	2026-10-30 11:40:14.368+05:30	2026-09-30 11:40:14.369139+05:30
sess_66e41ca69651b08264b1	usr_26cd79c91e36a2ec	eac3b714c8cea2c9f9b70e3f578d9014ccaced97c87790df43318caf5dd75242	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:01:58.546+05:30	2026-09-30 12:01:58.54832+05:30
sess_f32e3c3353d47dbbc50c	usr_42b6e7a87221c857	915f63270009d17a8ccdbfaccb5daa73215dfc005a766e7e7192313f2a0ff7c4	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:01:58.593+05:30	2026-09-30 12:01:58.594826+05:30
sess_4ca6a8ad2fa38c19c547	usr_6b892eeb30401c97	59279848a9b5e9a39e4b9564e26786a60b26043ac2419bca42cccd96bfa89db7	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:01:58.943+05:30	2026-09-30 12:01:58.945024+05:30
sess_46f1e19ac7243b502d37	usr_d156636dc63e5f89	34775b1cae6af19643ea87d3a932ab467d9a73e3343fca836016c8545b4bfa55	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:01:59.182+05:30	2026-09-30 12:01:59.183075+05:30
sess_b6b8f334ef5cd0ce984c	usr_a16b19a7d0fed768	fec695d18978129e6260ad328ee8beacab92dfb2c12e3c92714e39280b63ea12	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:01:59.569+05:30	2026-09-30 12:01:59.56989+05:30
sess_2df40738c6ed0f8924aa	usr_a16b19a7d0fed768	a2624120c5f8ea24f07fc3708bb2f1813210bf9b5e092181295c3e46c31a4707	Mobile App	127.0.0.1	t	2026-10-30 12:01:59.307+05:30	2026-09-30 12:01:59.335059+05:30
sess_d310be7e6510b2d59517	usr_a16b19a7d0fed768	ecf00dd8fe38d75534206424617c9233ed11f176c1d2b4c01f693f2d7801bfd0	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:01:59.787+05:30	2026-09-30 12:01:59.787943+05:30
sess_18364a0a8e557ed29373	usr_a16b19a7d0fed768	0007391dafded69b6c014de14fd2628555619fa7dab277ad50ab1036f22453ee	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:02:00.008+05:30	2026-09-30 12:02:00.009174+05:30
sess_78cda2b99ca26a80ac64	usr_a16b19a7d0fed768	b681e937b4392dc0522f987c63ae2a877809a945798435938b6f8e2ecd6d2c16	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:02:00.814+05:30	2026-09-30 12:02:00.815245+05:30
sess_d404e89e6d4646eaa146	usr_1b2be606008073f9	7c5517e286d76217189f0a13fff89b574682b670c44a732583e0a6c91059e099	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:02:37.507+05:30	2026-09-30 12:02:37.508133+05:30
sess_ca355b35ad64cf0d06c5	usr_d7f33014a1b8ee7e	5e915af3ed0b350dbd75a97db7d24e99cb68598c6bb670de17107b0826c71916	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:02:37.637+05:30	2026-09-30 12:02:37.638362+05:30
sess_cf975b781090a174ab69	usr_791dcac02f2279ba	627a75916048d83631bf1eb803251203ef4cc29e0d062d38ae492ce78aa0c1e7	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:02:37.852+05:30	2026-09-30 12:02:37.85298+05:30
sess_ffb1d99f11386e5b82a0	usr_501bb44eb891425b	9d9c7a8b70dc8d4ae744355a3ba1ea48a9e16bb12829052e9d97c922917b8215	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:02:38.143+05:30	2026-09-30 12:02:38.143859+05:30
sess_d585c24261b6b41d349b	usr_d47727393c5cf58d	5a8a33f3f3b23acedae698fc375780643faf58065af56d10f64fc1e4545e1e18	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:02:38.439+05:30	2026-09-30 12:02:38.439855+05:30
sess_32f4de86c99fcd999f2c	usr_d47727393c5cf58d	f4379857160f522d8d1290b752e38bf2af0e741d4481b583b22b02e479e6ae33	Mobile App	127.0.0.1	t	2026-10-30 12:02:38.055+05:30	2026-09-30 12:02:38.09035+05:30
sess_38b1d056a7ec434de0e7	usr_d47727393c5cf58d	29365d8a3566a2db6d2f32a468fe3ef1db7ebaddbde743a88b5025f733a56d96	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:02:38.717+05:30	2026-09-30 12:02:38.717648+05:30
sess_993ae2addff0a4e8d69e	usr_d47727393c5cf58d	057b5cc6b3e1eb8afbcf1c53dafcb5f02961b8d7565db69e8e5d85936035f210	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:02:38.969+05:30	2026-09-30 12:02:38.96944+05:30
sess_a919450dbe77230a9371	usr_d47727393c5cf58d	62eccf9430f344438d91a8fe2d3bc5a240016934d91b9c6675eb6669b6b6ddde	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:02:39.881+05:30	2026-09-30 12:02:39.881349+05:30
sess_504f5013234e9cdcbb13	usr_712ee3524ce3dde7	d37c4b0d763cda6b18ed3c7789473d6a3a6f0a848df67e57211a95f648047a4d	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:04:48.078+05:30	2026-09-30 12:04:48.079164+05:30
sess_c3ad0843d395676a01cb	usr_837a15479a780030	f14cda812f283cdda81a7889725bf6186e117d3735a115f599d80247d85a6a55	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:05:29.248+05:30	2026-09-30 12:05:29.249171+05:30
sess_4b638c0ad10277f30fc9	usr_2868a49c6aa551f5	60063337222c8a9874c91ae23738aed2ea15b1adf63fdbfdd49510ec59b381a4	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-29 15:36:23.393+05:30	2026-09-29 15:36:23.394682+05:30
sess_a93bbafd571b90b16eb7	usr_9e1cc12535965c8a	8fd11d1fef2bf7e5be801172592f2919f283460d4f09c2f802e07f6da5fc5a95	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:05:29.318+05:30	2026-09-30 12:05:29.31872+05:30
sess_772691a02b5e0b8cdfe1	usr_eb0b001d22f07016	e73c384d72564b4db7f5a405054d9869ea29f60cbfd2a9e4000764528929fed1	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:06:05.695+05:30	2026-09-30 12:06:05.696815+05:30
sess_58ee783732a22cb5ceac	usr_8b558de699670318	33ce34e368d290b42578298ecb8ae7dbc8d543f0b2978347e6431dc67e38a59b	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:06:05.763+05:30	2026-09-30 12:06:05.764454+05:30
sess_0c087ecd15f0f9425e30	usr_1c1c8a9a99910f99	4b407eb59a0e5a88a63912aca0a090f34b7562eb5df8f2d7cc9789cc77c42632	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:06:44.572+05:30	2026-09-30 12:06:44.57347+05:30
sess_0762b8a37f05cf694c32	usr_99e86453b77b20f8	084660fb59b90f1d9d28553e8f9ed36babb6b8907e90abcb01f7002793276599	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:06:44.641+05:30	2026-09-30 12:06:44.642425+05:30
sess_c7d01f74e43e43ee8cb1	usr_c2900f81677f6b40	7263f7224befe3a754d9b83a930bd2251476e422386ec5c2ed2382181f0fc112	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:07:50.389+05:30	2026-09-30 12:07:50.402884+05:30
sess_76021d0bd83792c9637f	usr_a749ad15a4b83f56	bf7e95b72fcc53ee684f352d0a15b1ac80745c3717a3d195403d49f8adecff43	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:07:50.783+05:30	2026-09-30 12:07:50.795296+05:30
sess_381863333a0d26b8de8a	usr_072c197d8fd4f7a3	47aac7be7308ada48917fbb0f2a8e9e6e971db31bb94bb40641927f34928e543	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:08:44.64+05:30	2026-09-30 12:08:44.643875+05:30
sess_f2283039a6f7330cf009	usr_de3c7a69b61ef701	e58e7a05f88eef9d979024b10055e93d66ac56120bf9605628614d4b63e92052	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:08:44.967+05:30	2026-09-30 12:08:44.96928+05:30
sess_d769cc99b495029bda45	usr_2d339c1c8a60a7bf	ed3e6dd77976898912ab2efd9e2fd0fe589f96902d66391ba0a419d07e1db24e	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:09:45.237+05:30	2026-09-30 12:09:45.242196+05:30
sess_a88af71312ea8e9de9b9	usr_8c526a10e5c1c5cb	218fa046e36e33b6a177b8d7b4493dbd2571e097081bf22b8441d1fd49788b32	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:09:45.639+05:30	2026-09-30 12:09:45.640978+05:30
sess_c0c341108b597ae59262	usr_d032febee8660434	b235d83c5df4f764671599ca6a6d42099027e72153f51485566a5c46718a62ec	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:11:02.794+05:30	2026-09-30 12:11:02.79519+05:30
sess_0f827848a30fc6e893b3	usr_2b1f5e605b8f2010	bc06982cc6a8774f363aaed87869407412e33c7e21c4d725ffc43d9b64a5964c	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:11:02.862+05:30	2026-09-30 12:11:02.862916+05:30
sess_115108e0632695f9ff14	usr_c04f1863db4f19c1	d8b3703ba8dcb5cc1412e61cf860a2de0b96362a5f8be639f9d10e8db3c8e278	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:11:53.564+05:30	2026-09-30 12:11:53.568188+05:30
sess_9880fe7dd85ce1239326	usr_97d87fa5a02055dc	663171aff9bbfe8eca317426a50e6526988d5ab4c584b7fdd3eba4040c163244	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:11:53.929+05:30	2026-09-30 12:11:53.931534+05:30
sess_329e04e3e7adf6cadaec	usr_39ea6b242671d81c	86bda61bf39516a11c8b421f0f8cb3924c04b7c652ac6d05f44cbc7333bc01e2	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:13:43.712+05:30	2026-09-30 12:13:43.714539+05:30
sess_46c3516c84ce667e740b	usr_4262abd5736887a7	dba67ff290b8240e159af67f18a15aec7ec907d980c29f547facb1a195e68500	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:13:43.777+05:30	2026-09-30 12:13:43.778225+05:30
sess_ff280781de0e290b986d	usr_1a92cc3ed067921f	194f8a7e8d43125f74ff440bda14105f3572ba063a0a61e35a7f3ddb06446b58	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:36.033+05:30	2026-09-30 12:16:36.035458+05:30
sess_e08880105cc5ec525d2d	usr_b1d7ea4b904ef79c	431ed420bea182d3e72a67369459f435a4893afe66a3de2a76dc73cb8754664a	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:36.102+05:30	2026-09-30 12:16:36.103545+05:30
sess_b84880d7d771b17d08a2	usr_fe8e1e4957015c39	6aac9e7ee8d9be3cca12eb197a1e24b712e30f7d3476256baf1c06042adffba9	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:56.114+05:30	2026-09-30 12:16:56.116723+05:30
sess_4084b229c8ecdc8b204a	usr_7fa7260cfb9e0c26	9df00370ced2dfc47a6ba5efb69dc8dae00f11f68db2f31d70c0c2326a63b05e	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:56.221+05:30	2026-09-30 12:16:56.222771+05:30
sess_6ea627239236ba49d0c6	usr_483214e785cf434a	40af746f79bd8c4655f4594bbb45260116435c8415b8673c58abacf589cddcb2	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:57.008+05:30	2026-09-30 12:16:57.009153+05:30
sess_4c07a946e7531156872e	usr_70cf84b74a8d0975	2db2a29b2258339a9cfb67f979eaca69b21d784ed7da30a22d76b0bc668a0e31	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:57.115+05:30	2026-09-30 12:16:57.116992+05:30
sess_9e8359e447bf4ad0987b	usr_66623e82cb6ddd26	c61e126d1f67368cc19d6c40e877719f8afa98915e4d6c619f44f4dd26e1b9dc	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:57.405+05:30	2026-09-30 12:16:57.405903+05:30
sess_b2d39e5deeb490ff7c8d	usr_e8dd3605e526e61d	ee00429daa4034b629ddb2c9acff9b2e46777963633770edf7e03a689e067255	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:57.659+05:30	2026-09-30 12:16:57.66025+05:30
sess_cb87d857b25d7069858e	usr_c693284ad8ad5abe	9ab8f3b3bee6079aa4bbeea6e39d5ea1d76a513467aa7e86d9791d0222475d21	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:16:57.957+05:30	2026-09-30 12:16:57.957809+05:30
sess_7b849904b3a27299187a	usr_c693284ad8ad5abe	756785a9c37b8459690a329fe4a16a7b5ce432ed75ed04ffd528ad182c027c09	Mobile App	127.0.0.1	t	2026-10-30 12:16:57.679+05:30	2026-09-30 12:16:57.707361+05:30
sess_b7f3d50b6b7753f4a883	usr_c693284ad8ad5abe	fa6e65e102d7fe2df2d1ebc3e7b60118d535602603550c43de45e1c3b8096f26	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:16:58.182+05:30	2026-09-30 12:16:58.18321+05:30
sess_f194072160529332e824	usr_c693284ad8ad5abe	685aa9bf8be94b769e2f620685bfa24f48efc9fc0e112004a1b7d78397039ebd	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:16:58.427+05:30	2026-09-30 12:16:58.42841+05:30
sess_55c23129167e3681d4af	usr_c693284ad8ad5abe	a82c6f43788d8f0dfe7a041b94a6e7f410ac8676b7cbeff48511926b34d094df	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:16:59.27+05:30	2026-09-30 12:16:59.270803+05:30
sess_d0f4e310dd65a803ae1d	usr_332b68556f881273	3838a434c1c808779374ec52ee667e525c2ee36ee4b335a0a0e6623a0cc56401	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:44.308+05:30	2026-09-30 12:24:44.310701+05:30
sess_15c3c028e00f913b1249	usr_426334eee09db891	941e1183c2b1b10a9245e01074508d0d1ed32ea3b175647d34ee689bfd7a6ea3	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:44.333+05:30	2026-09-30 12:24:44.335317+05:30
sess_09544fc7b60c5a445af4	usr_c641dbc8e3c7bf62	5f7e8ef1bd79c2a054d6f569d7a93a0667bced88387d957b6bae28f5e6c361dd	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:44.393+05:30	2026-09-30 12:24:44.39429+05:30
sess_3e194d4294fd31f7b57e	usr_d3fe85aa55a03730	4b91a0b642956d9c2d93cba25aaefee6e967286e9d98541508d3eeacd135fb47	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:44.402+05:30	2026-09-30 12:24:44.403768+05:30
sess_1119c7beb6a305c9781c	usr_31a34b67a1c9070a	32b975eb44f62e8bd21999a182cdfc041410b4549a7dc636a412b779be7cdaa1	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:44.784+05:30	2026-09-30 12:24:44.785381+05:30
sess_0639afc4c4b3ac0d226d	usr_e52ef76965d3db06	edccf34cf838a5a579f79c77adc14ca0e34d67a550b69386f9457bd01b58c23c	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:45.039+05:30	2026-09-30 12:24:45.040509+05:30
sess_01b9af463ef42a3ef329	usr_f87296a72c33648b	1744cb34f1e55c6c4ca870bc06dfd3f0c146e534c61c875c7bf009a87c28cadf	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:24:45.352+05:30	2026-09-30 12:24:45.352889+05:30
sess_20a497c8602ade575544	usr_f87296a72c33648b	d2b892b399ee012b2a21c8476ba09065f8c43d02df1e7eff38c3352bdc691248	Mobile App	127.0.0.1	t	2026-10-30 12:24:45.077+05:30	2026-09-30 12:24:45.106132+05:30
sess_0b0cf580bde84c80e945	usr_f87296a72c33648b	089af5a2194ae683b56852a16fc757d3e1b49a15ef4de03940317f165a8616ad	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:24:45.575+05:30	2026-09-30 12:24:45.576565+05:30
sess_fce6ae1a5a7931abcac9	usr_f87296a72c33648b	b2b1ad64b3caf28539391d8704f239c84f1ff97e8d1c5eed466c6b1d330328d9	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:24:45.806+05:30	2026-09-30 12:24:45.80731+05:30
sess_ccbec1ecdfb8e74c7ca9	usr_f87296a72c33648b	2fdd166a87f9fd4ffb75c5cf21fcff1edf0ad2ac2aa2754d13d8ec4156cf79be	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:24:46.625+05:30	2026-09-30 12:24:46.626801+05:30
sess_240ca70dd37436ab9471	usr_d2c85356dd19365c	19944255efc6aa6bd0df9bfd35ce82cf9578c734352079fca87060d6e931e89d	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:29:14.527+05:30	2026-09-30 12:29:14.528896+05:30
sess_0d0cea3a5f493454c35c	usr_a73a6f4cffbc42b8	4673b85a6cbded4dffd1dbc83878d1fec25e85e0f89f91dc89eefd12bbbca0d8	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:29:14.593+05:30	2026-09-30 12:29:14.594674+05:30
sess_8bd0ff6b9ba92c078fe2	usr_441c0e3d289b7aac	c60e7d62f4cd32f79c92edfe245839210bac1ba398483ca92280bc13a14ca85c	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:30:42.901+05:30	2026-09-30 12:30:42.901557+05:30
sess_8d9b441dae5d23088877	usr_f28801a3540af399	836eba14be46130382b2c0a23ee6d69a8f2933c589fb39db7edf03e56dc939d5	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:30:43.012+05:30	2026-09-30 12:30:43.012857+05:30
sess_9fcec8c34687cbfbb536	usr_b636f1ae7e91e71f	7c3a4b367f7579fbecc9aa0284f85a7d5e3e79cfec6f6c0c3951c316e9dd56fb	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:04.752+05:30	2026-09-30 12:31:04.753239+05:30
sess_1e3e15f4c6bdc0bf28b3	usr_65c1f48cff9008b3	41940a3c23d0535ace447705f93eed4370c505377bdcbe55990ff6152d3aca36	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:04.783+05:30	2026-09-30 12:31:04.784238+05:30
sess_cebbac09d057ca9a4f32	usr_fb4c3d97481d72eb	a6bf9836770d7c61565f1bad4a2bdafc3b999a1687d98468e5043bd6ad04e5b3	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:04.782+05:30	2026-09-30 12:31:04.784242+05:30
sess_40b85cd0c02fb4c091bb	usr_0385a239ccd5b41d	d1567f9971bbf3e3c6d2f0313a1f82962aab65527b94f10f3514fa6632627452	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:04.863+05:30	2026-09-30 12:31:04.863234+05:30
sess_a4546f9a81e8e9a6197a	usr_1e93ccb241b92f8d	d9328a0c84582722d004673e153b02bf46f3078cd577aa830be1cb38e4f290c9	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:04.863+05:30	2026-09-30 12:31:04.864435+05:30
sess_36e9c9e136f2ef79482a	usr_78aacbf0e54c792a	a88775b984f747f1541cde5276f35654e5b3e17ed6f35ca784ed4f09b9af1a2f	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:04.886+05:30	2026-09-30 12:31:04.88658+05:30
sess_0c2a69c768092a2055cb	usr_8d8d233cb1520d3e	64c1d1ae5564d4d996ac179cc3ba17383ee4c7770db78b8ad7da4164d0b1b922	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:05.094+05:30	2026-09-30 12:31:05.094905+05:30
sess_8c6dbc4b1b7b5b3be66f	usr_c64529f35491354a	edebe3f1d30fb8af648dbf3439a312e6efde67f4aed07076a0546cfb7d4de26b	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:05.342+05:30	2026-09-30 12:31:05.342897+05:30
sess_86c1a47dfd02f76ec675	usr_6b06fb2b57910aaa	5854812d8e5eb835309a4244f09929f9dc2e5f91c8068dc72836280b493fa360	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:31:05.65+05:30	2026-09-30 12:31:05.651004+05:30
sess_4a2dfaefa25e78ecb787	usr_6b06fb2b57910aaa	459f16bdbbaa5ea8a3cdb506e66f92ed6b9c0378e387a55c2c025d4bff52b488	Mobile App	127.0.0.1	t	2026-10-30 12:31:05.347+05:30	2026-09-30 12:31:05.376313+05:30
sess_6f55ccc75f88d3cb873c	usr_6b06fb2b57910aaa	d6622340ce17ca35a040835a59716194ed941658ee806a40d23bf83e9623fb6e	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:31:05.909+05:30	2026-09-30 12:31:05.91064+05:30
sess_995b4b73a92bce8d51ec	usr_6b06fb2b57910aaa	c110da9947e7a798a9c0a7f2ec0c55cc6f313e6125191c94094709819fe22c54	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:31:06.174+05:30	2026-09-30 12:31:06.175694+05:30
sess_740bdea6e29d4818f43a	usr_6b06fb2b57910aaa	7613b9e7cf6eb8c5afa1cefc447badd1978eb1ad07034f28c3a0691971f5236c	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:31:06.984+05:30	2026-09-30 12:31:06.985158+05:30
sess_fb5b841b8185782ee9df	usr_e43d0fd722732ad0	2e5494885ad75fc53fdb6f9ca26facf6c852c7ed46afccb85fca430c797ee9ab	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:22.028+05:30	2026-09-30 12:35:22.029015+05:30
sess_dc06ffb9e66df9095e61	usr_9058099580347858	788f3e975259a7d857896a262e253862ef2d6a4d0b62533bd5d02a1a4a9507ba	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:22.266+05:30	2026-09-30 12:35:22.267217+05:30
sess_169e293ca5408bbc15d1	usr_390269341390c4dd	ad1cd155b149fdba737e7ffdd58a3be3c056a1de2c11e43402702924da4ae204	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.035+05:30	2026-09-30 12:35:40.036288+05:30
sess_11e7263ec6d32c696b05	usr_2afcf6367d1dc020	97b6e2f9e9a0f96d4ed8ce81e7fc2943ee1d1698ce13fd4e27d223cd87855281	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.054+05:30	2026-09-30 12:35:40.054789+05:30
sess_d308def1bd8d41caad00	usr_e5af181f986f06b3	133a695b974982f2aa452fdc615fe9a315782da598017ea94d8d1d5826b78ee9	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.065+05:30	2026-09-30 12:35:40.066362+05:30
sess_4bf8d084342027b9478e	usr_11fdc7381d901c43	9644c2fa0755383677f8f3cefd5a2d9a4aecee5d52cf2f8757febd4ddbd433c0	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.075+05:30	2026-09-30 12:35:40.076269+05:30
sess_55bf61bbd0cd92414d07	usr_adc575328dc2453a	fc23850a15062ba8070abc1c9a9f0b8e26cbdb299b78a8f61ce7aa3b9010b48d	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.159+05:30	2026-09-30 12:35:40.15987+05:30
sess_34ffc2c10f926a3aeb62	usr_8b37e09a3fe45bc9	62cf60d1dfb712b6f29b8c18c47ab08b2e7bd3523b15116d82223067bb9978a5	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.208+05:30	2026-09-30 12:35:40.209366+05:30
sess_80fef93bee40781c14d4	usr_5dd9bc34451d7881	74a00c4054c62ba32f88b2260eed5d0d3f7edb1a1967da93809fbf48f58ca820	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.434+05:30	2026-09-30 12:35:40.435178+05:30
sess_e4b81bdd87d0b6e2a1ca	usr_d83a341c2319afc3	d376c0e96b743aeeb34e2e6250b6629fcba5b37d09e3cf22b74eef06f48615a3	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:40.697+05:30	2026-09-30 12:35:40.69841+05:30
sess_235ff7058ccc5622d7a5	usr_551f76650073a64a	86f15ce1698e5d2bebd9c5871ff9f3de867d30def860c236cfe9270be7153a25	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:35:41.054+05:30	2026-09-30 12:35:41.055785+05:30
sess_300e5d450e8ae2cac0af	usr_551f76650073a64a	19f07ca2d62f3bb3bc9c955e8b7aee999cb39c020760ba023f1cce3302e97aec	Mobile App	127.0.0.1	t	2026-10-30 12:35:40.761+05:30	2026-09-30 12:35:40.797531+05:30
sess_dd5a1aa5bfa0912e1300	usr_551f76650073a64a	4b9e86e659fc60a3b0a7cead4602b4385cd97e7b62f971845669f515881d15e7	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:35:41.288+05:30	2026-09-30 12:35:41.28953+05:30
sess_89e60db3324645da67b7	usr_551f76650073a64a	3080d6cff6de2e478771b45ff1d78f0a856a340c2c6459a0c6e4139a032b7f08	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:35:41.526+05:30	2026-09-30 12:35:41.527457+05:30
sess_1c49a48ce656a39868f0	usr_551f76650073a64a	0082ce19d4585eb03f515d726316c8da1a6cc5a760f05bc5ad8e77cbda441fc8	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:35:42.351+05:30	2026-09-30 12:35:42.352215+05:30
sess_3a9dcaa246c1a35a153f	usr_d37a502d11e5da99	44545389d70778b7079114af1a9e6d7b1386df4a3a3328deafaa966a7503a629	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:00.998+05:30	2026-09-30 12:38:01.003798+05:30
sess_d53897c63553d7a4a908	usr_5cfc9ba5df459c07	d7976b904e17f05d5cf2d5cb4abc853adcf2fcbbdd47c75b576f9e309c8538d3	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:01.364+05:30	2026-09-30 12:38:01.366534+05:30
sess_42f08bc88ca46b23d61f	usr_507a98d2112c5563	085314826671d864ffe71297db55a1b7df7084ef2f2d4c6a7018a2a92ea4e48c	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:17.747+05:30	2026-09-30 12:38:17.749297+05:30
sess_e8983b5e536bc092656a	usr_e03c44f59bbff28f	08b2b22b93022695a925ac6a35a0356cddc1c32ec0a6bd41a6e08d4ae2d5f5fc	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:17.833+05:30	2026-09-30 12:38:17.834422+05:30
sess_cf689dc78e32b8d02a3b	usr_afbec60a362f096d	8e58d7c72e3b81cbca3ef258bb611ae99f02da1d4632719b25470142a6247dfc	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:17.871+05:30	2026-09-30 12:38:17.872174+05:30
sess_ecb8c0bd88ae5bb44607	usr_8c69afe724c09d49	bd9a7912cea49ce977f4c182be26626b0f4cd5bc240b1d115bdf139759f97eaf	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:17.923+05:30	2026-09-30 12:38:17.924216+05:30
sess_a3e9d1aed5be34d975b8	usr_7f74277e048fcd18	1dba1cce529da91dfead86f6178c660d42980a5cdd853dfc7dbb1a225c3b6b62	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:18.075+05:30	2026-09-30 12:38:18.075786+05:30
sess_1a5e23242d2f8a926a01	usr_6bc672c4761b5a78	9d854e77862b53cea5991cf8a3862761e8b5650d411855987306f7cad1da2794	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:17.964+05:30	2026-09-30 12:38:17.964879+05:30
sess_cf964bf27be3caaa527a	usr_046291f5a26cbfef	707ffe3e278b735135a5dcbf6c78fa400544f4fa23df4bb29bf10d28e39e8618	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:18.261+05:30	2026-09-30 12:38:18.262854+05:30
sess_ba8e0470dd53ff883b2b	usr_edc9b30bd17b2c3f	ce7b2c66f1e2d379616f0132c00c5ce3c15ec2d7f815079bff8bdc47fea06cf2	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:38:18.553+05:30	2026-09-30 12:38:18.555178+05:30
sess_a2e112acec4efd18c75e	usr_3fd88a7c51a18416	a7423bb287b65fabb04bcfaba9280b7a580da04199aed0f626dee352f72397eb	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:38:23.074+05:30	2026-09-30 12:38:23.074669+05:30
sess_56cbf106dfcdf25e4023	usr_3fd88a7c51a18416	102f142c6b5acca6023fcd97a2d8f7d6dd4f9ccc013222b62a19882a70a92fe3	Mobile App	127.0.0.1	t	2026-10-30 12:38:22.8+05:30	2026-09-30 12:38:22.82993+05:30
sess_0e472927aedda3c5795b	usr_3fd88a7c51a18416	9aab2bee41f15c25ca4f71cbcd6bd01f2f8c562ea2efb5e0abfe389445b2b4ed	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:38:23.3+05:30	2026-09-30 12:38:23.300576+05:30
sess_97f2e7e37f1d78d404bd	usr_3fd88a7c51a18416	70ae84d0ba0c4720cb49c292a76ee144570370dd3c4c32ed3ae02b0de9c70be3	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:38:23.53+05:30	2026-09-30 12:38:23.530534+05:30
sess_7a974959b82e9023ffbf	usr_3b955f3d4bb859f2	3c4451853014ecee90aa80ef5f3c22b2ca1bb592d45d7ae904a44a241770aa93	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.38+05:30	2026-09-30 12:39:01.382347+05:30
sess_7d0c89204cd230c28887	usr_a7b4c5abd3ed76c5	5b59738c84b128abc2426a8ac3f6a79a74635a945b495a5bae8131838d18afbd	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.41+05:30	2026-09-30 12:39:01.412109+05:30
sess_ea7a6ba47ff6f5745ccc	usr_50634ff073aa77b9	56ef858ba5bbb5a8e0fbe63d5d49588dee5da837e110a6813a26fca6c3b15a07	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.428+05:30	2026-09-30 12:39:01.431101+05:30
sess_4614ffc204a8ef0eddd7	usr_8ba4c28082ef21a7	3915190143fa3324a5f24362b835717402a8a5e19b9a6b48dedf8e4930f64210	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.489+05:30	2026-09-30 12:39:01.490116+05:30
sess_c6d7efc1ae4d593e7a56	usr_1f42ebc28c735546	34a3baf92202eb6c68d5ef7d1f8a7b3e71229f90c1b15de73cfb50d21280f6f8	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.501+05:30	2026-09-30 12:39:01.50343+05:30
sess_e2ed34e5347337e34fff	usr_8d0907e902d9d9dd	95face7a485fc45c1904e1b5c831767af5790d4755795915988fa4714b669756	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.577+05:30	2026-09-30 12:39:01.578489+05:30
sess_eb9359397824ff36fe52	usr_ae2a15190a816afa	6689f71ce3c7c5f441eb7cee11f6ff763acbd38594cf2a3e2e4e821312734935	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:01.959+05:30	2026-09-30 12:39:01.960407+05:30
sess_8074680b8de432293e16	usr_9e9b8b953ce4c7eb	9c645bc6bc6221fee3467dbc8e7539dae74caf580f08e5f21c46d239b4389784	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:02.224+05:30	2026-09-30 12:39:02.225134+05:30
sess_48ed2a7f578d41c4422a	usr_249c7f996e96c57d	5c2e0d80559f3df02d2bc680acbdff643884611b86eb8afffb5cf197ad76e679	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:39:13.671+05:30	2026-09-30 12:39:13.672461+05:30
sess_8491513d3ad2425394e6	usr_249c7f996e96c57d	78810134554143168ac80dbcdb90eb99a337615c24c91c20abfc31ad73a5bb96	Mobile App	127.0.0.1	t	2026-10-30 12:39:13.397+05:30	2026-09-30 12:39:13.425304+05:30
sess_9ffbe1b5040e602b144b	usr_249c7f996e96c57d	eef6b159e2471762caa421aab21ba57b7450f5ee66e2ed42e5690852fc0551fb	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:39:13.899+05:30	2026-09-30 12:39:13.900527+05:30
sess_f4f238aa21e9a940343b	usr_249c7f996e96c57d	e9e1c7b3192efa1877a27ee2ecfe2f074f551c0d832ac2a9cb0eb45fc83b1682	Mobile App	::ffff:127.0.0.1	t	2026-10-30 12:39:14.131+05:30	2026-09-30 12:39:14.132594+05:30
sess_2ea5eaa49bd6a194e7af	usr_249c7f996e96c57d	8df80774d8360e03be13ad3068aa644a45924a0ff18fbaa7ae6371af906c928c	Mobile App	::ffff:127.0.0.1	f	2026-10-30 12:39:25.456+05:30	2026-09-30 12:39:25.457728+05:30
sess_2358f9f0cb8c3db87c22	usr_771ffc659cac6f5f	76725bb18d64e6482097431b29f4ce5be8f123ed16acde85a34bbe3256ba08d2	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 11:05:50.392+05:30	2026-09-30 11:05:50.393649+05:30
sess_df3b2e0b5f4d58fd18dc	usr_771ffc659cac6f5f	20c09fe483e22349d55383f613b2df616bf4f6e98ec8cad5ff9afb93bb6e7c8f	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-30 12:45:32.009+05:30	2026-09-30 12:45:32.011426+05:30
sess_8ef4b78fcee9995db195	usr_f8b3a9c750f5c30e	e205459a25369c02a1d4366797177bf3ef256aa8aa1762180c7065b4d6614347	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:50:03.959+05:30	2026-09-30 13:50:03.960975+05:30
sess_24f0870a7b58b5eb1600	usr_bd5528dac05a06bc	b6d8a71a72dd164a0209670540cf23c7811edf0fba211d1424c7500214eaf093	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:50:04.282+05:30	2026-09-30 13:50:04.283585+05:30
sess_c80d94fe561aa640bf44	usr_58e3c108ab31e109	718793516c6e4eeb0ecdccc226587b116e35c3456a287187c8f235c237573b29	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:50:37.265+05:30	2026-09-30 13:50:37.266497+05:30
sess_c3216b51d4dd9e705d15	usr_b7675a4a677cc52c	4792d42c0b06e55d7642abf905ad92d8785ab4317dcc0f5fe95ce73d8a0aaf48	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:51:37.761+05:30	2026-09-30 13:51:37.763277+05:30
sess_53cbe4f18ac55c5ae00e	usr_65fa9d3936098493	de3cd2d23ad7ac11848bf19ed39c512c6ed946e8655ea8c9309455cdd0b03c91	Mobile App	::ffff:127.0.0.1	t	2026-10-30 13:52:47.49+05:30	2026-09-30 13:52:47.49261+05:30
sess_976c738c10dc98894c5c	usr_65fa9d3936098493	eb78c1614211cc1b53e485472be8a0e1c82d1336ddf1a42f333c250a22c15c07	Mobile App	127.0.0.1	t	2026-10-30 13:52:47.172+05:30	2026-09-30 13:52:47.202246+05:30
sess_ac92940cf17d9e51a42f	usr_65fa9d3936098493	2d2670fb32c1584b57e0423e160101c7309581f0132d386426c005484349e1f5	Mobile App	::ffff:127.0.0.1	t	2026-10-30 13:52:47.764+05:30	2026-09-30 13:52:47.766524+05:30
sess_90ea329424c67f517e98	usr_65fa9d3936098493	c9c2b6cc68d6d0348a23a97d14f3573deea65d953eadc08d259e908f0fdf3543	Mobile App	::ffff:127.0.0.1	t	2026-10-30 13:52:48.056+05:30	2026-09-30 13:52:48.059056+05:30
sess_494d56186c34851388be	usr_65fa9d3936098493	e94a48edc249a067beb1093b77b7bcea5f54406a5be9a027535fc7f068de3daf	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:52:49.07+05:30	2026-09-30 13:52:49.072444+05:30
sess_78a61d3827d26bd5d7aa	usr_8279dc24442d924a	50a6efdca015c216585d7bd794353309df580bcfc1bf2710f90d56fe19779992	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:53:21.775+05:30	2026-09-30 13:53:21.776068+05:30
sess_aad6fd9ed78e978053c5	usr_4f9318878fbd93df	ea6ab908788c3d4658f1be7dc5811717602ffa2fbcb736e2919699e154093b0d	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:53:21.856+05:30	2026-09-30 13:53:21.857115+05:30
sess_47ec86a537c26c29da13	usr_386a8db5450ed2bf	4c5ac3f5135a6782e50b4a6afbe487469c0b75a7210845effca5990c0aba1029	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:53:50.072+05:30	2026-09-30 13:53:50.077233+05:30
sess_d19813b7e542aa556eac	usr_69f63c6fa32cb0fe	c0e490e2741572ab029cc1f10a3297318d4cc2b8b060f15d409503993de512b0	Mobile App	::ffff:127.0.0.1	f	2026-10-30 13:53:50.207+05:30	2026-09-30 13:53:50.21257+05:30
sess_dd5a46319737a5a5f6e9	usr_771ffc659cac6f5f	4139eaad804292bd9c3f3a0b8513da023bf7cea3971737059f97dd6251b65b2b	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 13:56:04.411+05:30	2026-09-30 13:56:04.413454+05:30
sess_666cbec048bba2936cb0	usr_771ffc659cac6f5f	cee0069386a6c03a8c4712f092a871448e94ed278840e6be56457c671fedcbce	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 15:04:38.72+05:30	2026-09-30 15:04:38.722883+05:30
sess_99e459636390ec850491	usr_771ffc659cac6f5f	078dea58a8edbb263fa6f160bc3fd9248e1afb3a4ca7b0a1b209222eadc9adc6	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 15:34:47.422+05:30	2026-09-30 15:34:47.422617+05:30
sess_335c855586722304bbc6	usr_771ffc659cac6f5f	ee89ad5aea4baa0c335f0533aadb5f1b745b846fd317d6b39a4279ca60d5ecba	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 15:49:50.993+05:30	2026-09-30 15:49:50.994793+05:30
sess_4c5a97cb53e51693a8b1	usr_771ffc659cac6f5f	b25a6d13fdab3e98e4d8572618a08fdd3fd963e918c8a8f61ccc43c8215aad14	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 16:06:31.479+05:30	2026-09-30 16:06:31.479753+05:30
sess_fb3bef373a996b28a1d6	usr_771ffc659cac6f5f	1bbd267992450377058b875109fcb27972ba72255b79af5ac23917dc13289dd9	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 16:31:28.717+05:30	2026-09-30 16:31:28.718839+05:30
sess_e9f14ef65185f1fab660	usr_771ffc659cac6f5f	7d4cc3097bfd90106dbdc5fdf3a5acf8ef7dbaa535609304c3d0c39813b38bb1	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 16:59:12.587+05:30	2026-09-30 16:59:12.588057+05:30
sess_b2219d431c301618e746	usr_771ffc659cac6f5f	770019971a326fb4a050dc1c4214d3617e3e376082db90382a6d23460bf824e7	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-30 17:35:25.354+05:30	2026-09-30 17:35:25.355785+05:30
sess_46c455e0f53050d71baf	usr_2868a49c6aa551f5	68cbefd3ca4457f5f52c6789e069f7dcfb36ac157f89cc3f36400521203ff6ab	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-30 17:47:48.481+05:30	2026-09-30 17:47:48.481385+05:30
sess_bbf14d21502fb3790bf3	usr_771ffc659cac6f5f	73187d73279f38b04039fc5461fab67466961465d8aab3c5e6b8e06a44d052cf	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-30 17:48:46.992+05:30	2026-09-30 17:48:46.993141+05:30
sess_8c90260953f89baf63d1	usr_771ffc659cac6f5f	deb351c1b5305793a0bdaed6b4d8b57a8215d929d4243a6e7e50a0241aae8d88	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 10:51:40.208+05:30	2026-10-01 10:51:40.209275+05:30
sess_d907a542ece44d77b749	usr_771ffc659cac6f5f	967525759a534eebc8cb11667060c1f4a728c6e392178452352b49eacb50a65c	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 11:02:16.872+05:30	2026-10-01 11:02:16.873213+05:30
sess_0c2cada0c0c91c371a1d	usr_771ffc659cac6f5f	cdb23d79b489bd1f0b045a98a632ce1ae30a19b5df105e63725f8f90e1abd40f	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 11:19:20.398+05:30	2026-10-01 11:19:20.39984+05:30
sess_9a18b5d732b140e71e00	usr_e55abb463db8392d	f5ae95584cfd49c05b7f70e3ed998bed83bc263479e38c86fd0ee345d95902ba	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 11:20:31.472+05:30	2026-10-01 11:20:31.473152+05:30
sess_a72b438c3b598fa96ad1	usr_2868a49c6aa551f5	6579022b405e02361b43fb0dedfe676ab005f1077716c02456a83724ce258826	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 11:21:29.253+05:30	2026-10-01 11:21:29.254295+05:30
sess_23609dfce41d7f1d7e63	usr_771ffc659cac6f5f	de6e734c33e640328067f15b52fc4b09525b476c219f5d8cbf5043621f82b0ce	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 11:22:52.941+05:30	2026-10-01 11:22:52.941733+05:30
sess_bbc9a94ca3e190735b33	usr_771ffc659cac6f5f	1608c8a76d48353c2ada0b5067c5243859107957decf908f7294c16610938653	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 11:54:12.536+05:30	2026-10-01 11:54:12.537788+05:30
sess_d38e2cc898619301b677	usr_771ffc659cac6f5f	35e04c54edf0f13e33a03f06e879d4addcfc1b3c6ede6ca5c9bffe8742042917	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 12:12:10.147+05:30	2026-10-01 12:12:10.148265+05:30
sess_9addccaf02f46e179190	usr_771ffc659cac6f5f	7bed1807001080962f782d8ea94e6c8690bbd72754a8a209a0eeb4ad46fcfae8	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 12:35:23.094+05:30	2026-10-01 12:35:23.095645+05:30
sess_edb2f25ecc89394fdf24	usr_771ffc659cac6f5f	b2448a94e6370bbaef0d34def43dd3d846f18b6c768babf16a59a4a95ce1056b	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 12:50:38.97+05:30	2026-10-01 12:50:38.971006+05:30
sess_06eb93de12d338bc80e8	usr_771ffc659cac6f5f	ec62e84c20de655e3f9cf664ad5f51d371f9bf3d4e3946e3416db306cb9807dc	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 13:06:26.379+05:30	2026-10-01 13:06:26.379696+05:30
sess_57058d9d039396cc9ffe	usr_771ffc659cac6f5f	febc3a5b9ade2cdd2596dcf0501cf87c5de8c58c8595cbce2ff0bce2f316a4e0	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 13:25:10.548+05:30	2026-10-01 13:25:10.54914+05:30
sess_4ad8b0b4ca8d05785bca	usr_771ffc659cac6f5f	c5af29108aeeb4c47dd6b21224c816c6fddde6613d3cb6450d3a309f516da439	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 13:43:23.53+05:30	2026-10-01 13:43:23.530563+05:30
sess_dbbb899271a52df14405	usr_771ffc659cac6f5f	bfbedddd0144e2a1eda3168f3935122b7771a96523a61274e2b3fc723d6bd104	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 13:58:34.797+05:30	2026-10-01 13:58:34.798399+05:30
sess_da64253a33acf53e59b0	usr_86b3e6d40335e6f1	4cd8bac3ad90ca83c0d2e745ed5a3af7da35f861e314caf637bf84b766861e85	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.273+05:30	2026-10-01 15:26:29.27532+05:30
sess_73dc5e141a32f27bdf0b	usr_8cf6038983567937	6f8db6ee908d06359727250fce3281a840d63f012b913d6bed0d4d970ec9c837	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.319+05:30	2026-10-01 15:26:29.32148+05:30
sess_63123725bfe0674a9095	usr_73c45d42f9750142	37d1567b7717405fcd9d1af3bd29f153488e1f39b702dc6909097ad6e22be516	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.386+05:30	2026-10-01 15:26:29.38789+05:30
sess_031d679606e5ed749cac	usr_aaba6c37ed2fbd00	6943d7dcd8bd48c30203e0b8e9f70ae2a2f95633b2e43e1cc2edd2bd1f04f69a	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.452+05:30	2026-10-01 15:26:29.453626+05:30
sess_cc3f2645e1fea2089bfb	usr_3956d119b0e3e452	e456a650663ab92132403132f17902bcdcf2bac181cef0ca8a7b1366f9db78f0	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.456+05:30	2026-10-01 15:26:29.45692+05:30
sess_d85cede98fef107fa888	usr_66ac9868bfa6631c	df11c4f4cf850a640bb18870966f65a1d70d8724ba52ccf7b8c91df736e3bc37	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.677+05:30	2026-10-01 15:26:29.678178+05:30
sess_ee94aa1ee65e80e3a1bc	usr_ea7d22375987cbb3	1645da2e6b95eacee8ea6894b90782c15d8467a3e7cebd17afc2aefe4d3b4fd1	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:29.992+05:30	2026-10-01 15:26:29.993099+05:30
sess_cf771adc110e2b5585ce	usr_191f6cef8ff784cc	4c474b546851386400e4389b5513675dbf895c46c93f49b84892a70f6dc3f795	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:30.504+05:30	2026-10-01 15:26:30.504513+05:30
sess_fcbccadee51baf1fcf51	usr_8cb0d6db3214a9bc	5bbdbf2243cd9fd2035f5ca7f19e4586a4dfff1fcadb6635cc0421629c9ccfd8	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:26:31.19+05:30	2026-10-01 15:26:31.191358+05:30
sess_4527f6f4f96ecbb38974	usr_8cb0d6db3214a9bc	b981bc6194051dec509e789eae283c27d35ca865d514ec1d8b32a9297b39e0db	Mobile App	127.0.0.1	t	2026-10-31 15:26:30.648+05:30	2026-10-01 15:26:30.695652+05:30
sess_db3849514e8ee6370b56	usr_8cb0d6db3214a9bc	e991b23185244f0774a5c265b489181fb2f90c9d6ddf91cdef2840139990d2fa	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:26:31.522+05:30	2026-10-01 15:26:31.522756+05:30
sess_b466347bfab60bec7054	usr_8cb0d6db3214a9bc	c998fe2d31528428f91c812b0545df0a719e225de0efdaa4328aaf979da34d40	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:26:31.9+05:30	2026-10-01 15:26:31.901441+05:30
sess_57368ff385896d3c2e94	usr_8cb0d6db3214a9bc	ed55af209c73b6ac56cf652bf7aef94599ee9dcd0805ee9c2dab8f3f47072f51	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:26:33.262+05:30	2026-10-01 15:26:33.263079+05:30
sess_74479d8a484b74b68e98	usr_771ffc659cac6f5f	8f79e2dbd079349c898fc4c10c45774440a4850aa24add8a43a3d3a777414958	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 14:14:12.038+05:30	2026-10-01 14:14:12.039869+05:30
sess_472607a84627c9255040	usr_372a9de0c155953d	02bcd8496faa5a2658d6c39710547441c99a4e5e07af34a47e68b4779fa38a90	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:33:11.616+05:30	2026-10-01 15:33:11.618293+05:30
sess_a4b4ae647d5e4f7c1222	usr_77d1efe4afbc4c7f	f609437c126cc7d519d60df3fee7e07316ba8fe477c0159c418776b92a998a7f	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:33:11.707+05:30	2026-10-01 15:33:11.708425+05:30
sess_6490e2db40f249151cb4	usr_16c2144c0df7f485	cc90301b80e05813e0a202191e4e83c977fffc806f03e147bbfe7d617dbab6da	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:08.911+05:30	2026-10-01 15:39:08.912836+05:30
sess_d4c4aa3fb3504f8ee53f	usr_f16724c6f8d5f94d	21fb25d38c7f952011dcefede1d3bd5de129195f64f036a13d60531a7c5318e6	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:08.995+05:30	2026-10-01 15:39:08.997715+05:30
sess_5ac0292d135d0aa4fcd0	usr_771ffc659cac6f5f	9d5eb3ab4eb50ccd35da34508cbe4724438e181296bc6d88514195fbfe51218d	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 15:28:00.102+05:30	2026-10-01 15:28:00.103092+05:30
sess_bf656dc7cfa129429f57	usr_258e0b7430df83ca	f6a6c2e9408c1f522fb71f0ad1d8f3f2f158659958982e6914857a8f6abfd31c	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:09.006+05:30	2026-10-01 15:39:09.008165+05:30
sess_d3ed2c5fcc2214b80d88	usr_e9919c23c0467ea5	c07c85c87caddfe6d66086fc7e36facbab27e70c3d1cb66e628a1c92063da1a0	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:09.08+05:30	2026-10-01 15:39:09.081778+05:30
sess_ed621979a7d7dab00628	usr_4b2405663fda6e40	45fe3dab369a96f8b86465107733e94e6a5089ab3ddacb4d7048404e23464da6	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:09.137+05:30	2026-10-01 15:39:09.138145+05:30
sess_4b5a7c8a0d5969ee6248	usr_05a01b29ffddd525	61e6a04ccc804854d40d913876b0eab1d548bb4e36db08bd86794850e568cc0d	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:09.295+05:30	2026-10-01 15:39:09.296569+05:30
sess_dff59b1f94c4f38519a5	usr_a0ea1d4f298d4a7e	da372e19bb073404fe904de62f3232266ce96f3ef03a4a8d043c2e1630372f4f	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:09.536+05:30	2026-10-01 15:39:09.536699+05:30
sess_b65376be728892ff0f83	usr_a10542f59057b140	4523218185eb87b39bd55e1bae7081376852c899522b4724365c5105b727c70d	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:09.857+05:30	2026-10-01 15:39:09.857757+05:30
sess_22a9805c583233b0621b	usr_962f5f2641636fae	d616760d41330edd519df3d8c1bfb1a368e71420d76aa299d4709da966471508	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:39:10.282+05:30	2026-10-01 15:39:10.283044+05:30
sess_af7d848649c02b5a83fa	usr_962f5f2641636fae	df8732076aa1d95a784dfc6d9e3c5158171490a24c79ef7420ae09cc928d8bc2	Mobile App	127.0.0.1	t	2026-10-31 15:39:09.796+05:30	2026-10-01 15:39:09.967519+05:30
sess_e82b7613d72aab42f83b	usr_962f5f2641636fae	e12268c5b9e07bdb73b7ce7c8284813c8257f9ab7d148c275a9a386d5ff4667d	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:39:10.561+05:30	2026-10-01 15:39:10.562231+05:30
sess_5e3551ee68cb4d105d11	usr_962f5f2641636fae	b9cfa1208f16d2aa9b85a6ec19967c69d0c0e3963b2188410f7c3c8f7214b962	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:39:10.841+05:30	2026-10-01 15:39:10.841992+05:30
sess_cf197ebab60fcdc87d22	usr_962f5f2641636fae	48c25223dd7380b9dce68abf345221e026098fb79aabcfe4867dc52d40df4215	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:39:11.834+05:30	2026-10-01 15:39:11.835155+05:30
sess_508b6f00851c8a19bcb8	usr_2bad6dc1de996b96	9301d15ea6c72d9f174e1975ed5f06e22501bc9db4cb142c4813d8c5bf5f211d	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.463+05:30	2026-10-01 15:47:11.464836+05:30
sess_0c77ae28ad578a13428b	usr_a1bd125a6a3dd41a	b75689c7e3f5ce7b71773efe2371c433700bd06e951e5410818efd6f842d3c80	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.469+05:30	2026-10-01 15:47:11.470923+05:30
sess_c64c38af29ac3810d683	usr_b2c56e4b881cf6fb	81a3525595497e940c698896e0c8949d7fc1a751e36ffbf1f21b2bc25289df71	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.542+05:30	2026-10-01 15:47:11.54398+05:30
sess_c44c1e880e7864455c28	usr_d012c52d94f984bc	5b3a0bd5c13c87eeebd50cbbf5554cfd05c6b8ea5375a32b73dc0cb7b5e36aad	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.545+05:30	2026-10-01 15:47:11.546288+05:30
sess_ddbc3e425d40cd322643	usr_a7b005600886fb63	85c264c1d18faa40b687d5b03a803285114b03a12cf1b19bc733ac1eb629d44b	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.566+05:30	2026-10-01 15:47:11.56759+05:30
sess_89759cadccda0d6cb6a5	usr_5eb6d029937b3c22	77454f3b3774eec7bfa841d05b703b9ea4d91119d59bf084e1c792c8cadaac71	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.696+05:30	2026-10-01 15:47:11.696914+05:30
sess_f136f7533387d422684a	usr_bd31992cc995573f	e1f657a1c08afa10e1f60844d9e79bb08a7be490c34025b5476a070db7758b8d	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:11.89+05:30	2026-10-01 15:47:11.891126+05:30
sess_ad6636ed4ec45b1c26bb	usr_7a1b921337c5cb3c	648fcbc985bc2de9a4274802d54f3ae242c81bdb8a7bbdc09b267ce16b3dc725	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:12.15+05:30	2026-10-01 15:47:12.151484+05:30
sess_9adbd9f8e07ce28a7d05	usr_87256bb5c03dd033	2a3a90e2e2f33ff26365084fbb0a7e9777c441e59b33731806fbda4793dc838f	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:47:12.549+05:30	2026-10-01 15:47:12.550581+05:30
sess_c99f2e01bb049a360e29	usr_87256bb5c03dd033	74169b15e37a6637446c2c0b945c965310d19f0c7aaa526eac7b051aca875f74	Mobile App	127.0.0.1	t	2026-10-31 15:47:12.265+05:30	2026-10-01 15:47:12.297899+05:30
sess_525579670a9d4ce58ac3	usr_87256bb5c03dd033	8891cb71940269dd0087cf5eb964c387f254b282ba0dfd996a07804bf5e43427	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:47:12.77+05:30	2026-10-01 15:47:12.771253+05:30
sess_775af6860c197b60acc0	usr_87256bb5c03dd033	8a7fec96fbf55153229c81b971b6e5ee9084d99ad2d2777c1f915816fa2c03d0	Mobile App	::ffff:127.0.0.1	t	2026-10-31 15:47:12.998+05:30	2026-10-01 15:47:12.999185+05:30
sess_ea21acd354e4914d1e6a	usr_87256bb5c03dd033	8953d24299fe22902e8ecda13b4f54fcded7badeb86c06f614488919864c42d5	Mobile App	::ffff:127.0.0.1	f	2026-10-31 15:47:13.833+05:30	2026-10-01 15:47:13.83451+05:30
sess_d5b8c714f2b477f24bbe	usr_771ffc659cac6f5f	b82475b9f298390ac49e7fa9c1fbadba5e915e4f86cc249efa39b254715b6012	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 15:54:15.895+05:30	2026-10-01 15:54:15.896777+05:30
sess_9e579cd3c20e609a73dd	usr_771ffc659cac6f5f	d866486260587484da07d19fa9841023ad40ceec02eb62c6c2b3dd614ca5a7ea	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 16:15:42.285+05:30	2026-10-01 16:15:42.286914+05:30
sess_aa2f90e8a774db71b0c2	usr_771ffc659cac6f5f	07a8e7bb1f976fe1115217d7c1378322515522bfc605bdd5cb0db56005bcafae	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 16:30:49.467+05:30	2026-10-01 16:30:49.468261+05:30
sess_7f8fea3bd1b8e3e86673	usr_62068e8f5fc912b3	57ce7795312e218ed7fa54d3a8b0e2ce325df60a1e5b528455f56a1bff5d2fc2	Mobile App	::ffff:127.0.0.1	f	2026-10-31 16:33:10.511+05:30	2026-10-01 16:33:10.512431+05:30
sess_242e4e08da043136da25	usr_771ffc659cac6f5f	b1105a47bf5ba80e367f76d547fd88fb483affba64c91cc4d0c001255db9ba13	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 16:33:24.393+05:30	2026-10-01 16:33:24.397115+05:30
sess_ab51c8213c1873e88b1b	usr_771ffc659cac6f5f	1db25cdca86e2db602f873d069c5d27927071aa125ec27a485c8599fa973a702	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 16:52:38.639+05:30	2026-10-01 16:52:38.646068+05:30
sess_2d28d8afa8d2fc8d6c36	usr_771ffc659cac6f5f	3d08a13794a5272997bddf5037b6886753aed5da415d48e5bf69fe2dbdc2a50d	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-10-31 17:11:02.235+05:30	2026-10-01 17:11:02.236984+05:30
sess_839fd41831529b5bcbe4	usr_771ffc659cac6f5f	5355e014dd485e7d6a8a6bf20e54726c09f8d0ead958c461741c2c55a4f23291	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-10-31 17:17:32.366+05:30	2026-10-01 17:17:32.368114+05:30
sess_dd1dd95906718bc66388	usr_771ffc659cac6f5f	4b034803de9607a7c50311737399a114a4b0ed207e2806121b07f17741b3582b	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-11-02 10:29:20.977+05:30	2026-10-03 10:29:20.978482+05:30
sess_565498edf79e47946970	usr_771ffc659cac6f5f	37af4936327f3800753be5b5394041c9937657d5f315d98009b275195a36b1a8	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-11-02 10:50:03.564+05:30	2026-10-03 10:50:03.565759+05:30
sess_c07872faec4b949b6f04	usr_771ffc659cac6f5f	7edf33e419fdc9f3d568ec746e497de14cef843f2e1a8246af52fd198dc2f956	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-11-02 11:11:47.283+05:30	2026-10-03 11:11:47.284548+05:30
sess_ce6f21ea3227d5c0c6c6	usr_771ffc659cac6f5f	c15e980b30fd6b4f43f53ffc1576b513fedbf55efb989280aa284a72dfffa04c	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-11-02 11:32:19.936+05:30	2026-10-03 11:32:19.9372+05:30
sess_54d8d2eb04b5b81a45df	usr_771ffc659cac6f5f	6e93c76ab802c1f446571b9c2ee2abea25a31a58d85b11bbc30d9370169ad31e	Dart/3.9 (dart:io)	::ffff:127.0.0.1	t	2026-11-02 11:48:34.321+05:30	2026-10-03 11:48:34.322149+05:30
sess_4d14c38bafb15ff960e0	usr_771ffc659cac6f5f	3fc9e3882a0c1c20abf4c91cf5487f9d77ed036b66cae5b62d18c9e3719cc419	Dart/3.9 (dart:io)	::ffff:127.0.0.1	f	2026-11-02 12:08:47.825+05:30	2026-10-03 12:08:47.826646+05:30
\.


--
-- TOC entry 6171 (class 0 OID 17942)
-- Dependencies: 227
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, role_id, name, email, phone, password_hash, status, city, bio, profile_image_url, email_verified, phone_verified, failed_login_count, locked_until, last_login_at, created_at, updated_at, latest_otp, date_of_birth) FROM stdin;
usr_a1bd125a6a3dd41a	3	Workflow Player	wf_player_1790849831155@example.com	+919659733868	$2b$10$kz49W.XeW7w8Y4/bEyVfkuHtRL4kE/9YMMUoZntg76B/wJ1qwu9FG	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:11.462804+05:30	2026-10-01 15:47:11.340322+05:30	2026-10-01 15:47:11.462804+05:30	\N	\N
usr_a7b005600886fb63	2	Workflow Manager	wf_manager_1790849831155@example.com	+919566949244	$2b$10$kz49W.XeW7w8Y4/bEyVfkuHtRL4kE/9YMMUoZntg76B/wJ1qwu9FG	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:11.563956+05:30	2026-10-01 15:47:11.48058+05:30	2026-10-01 15:47:11.563956+05:30	\N	\N
usr_62068e8f5fc912b3	3	Wallet Player	wallet_player_1790852590184@example.com	+919642658996	$2b$10$OAgypqZ6GxKdEukLtM4TB.0GbB3vyIFj5eMC0/nDnYS3LQuiSTU12	SUSPENDED	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 16:33:10.5064+05:30	2026-10-01 16:33:10.325856+05:30	2026-10-01 16:33:11.550259+05:30	\N	\N
usr_a7845baf785372f9	3	Rudra Pandey	rudra12@gmail.com	9865548798	$2b$12$RvSsW8td51ETZdyLA6ey3eW/ZDHsj4jC3O9Wdsc4Cr8wg3udvH0pC	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	\N	2026-09-29 13:52:53.104083+05:30	2026-10-01 15:47:11.244886+05:30	701078	\N
usr_191f6cef8ff784cc	3	CCTV Player	player_cctv_1790848590005@example.com	+919448575609	$2b$12$w1sp0JXr8V8km6o36paz9e4MCuAlwXRM2nXZOnhjNvZKGddU5Gda2	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:30.499464+05:30	2026-10-01 15:26:30.006592+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_73c45d42f9750142	3	Wallet Player	wallet_player_1790848588496@example.com	+919637366299	$2b$10$gD/EB7VbpgMb9sGreIzBqOLdoTgqLacK2ibw9//RQdzw.kMn9d9BK	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:29.377629+05:30	2026-10-01 15:26:28.988086+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_ea7d22375987cbb3	2	Turf Manager	manager_test_1790848588497@example.com	+919567092200	$2b$12$w1sp0JXr8V8km6o36paz9e4MCuAlwXRM2nXZOnhjNvZKGddU5Gda2	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:29.984887+05:30	2026-10-01 15:26:29.487198+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_5eb6d029937b3c22	3	Payment Player 2	pay_p2_1790849831173@example.com	+919725123347	$2b$10$NLO1qh4RgeDf2ucDaV9KQ.ya869CtllDlltEkL7PAyuWdELmtv6TW	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:11.694459+05:30	2026-10-01 15:47:11.55337+05:30	2026-10-01 15:47:11.694459+05:30	\N	\N
usr_7a1b921337c5cb3c	3	CCTV Player	player_cctv_1790849831895@example.com	+919475337244	$2b$12$m3u.cf2zlASUtqw1YJvX3OszndQTNPasb1HMkDzZ54VoARTmIWY6e	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:12.148202+05:30	2026-10-01 15:47:11.89599+05:30	2026-10-01 15:47:12.148202+05:30	\N	\N
usr_d012c52d94f984bc	3	Payment Player 1	pay_p1_1790849831173@example.com	+919839512179	$2b$10$NLO1qh4RgeDf2ucDaV9KQ.ya869CtllDlltEkL7PAyuWdELmtv6TW	ACTIVE	Raipur	\N		f	f	0	\N	2026-10-01 15:47:11.540362+05:30	2026-10-01 15:47:11.359737+05:30	2026-10-01 15:47:12.200164+05:30	\N	\N
usr_bd31992cc995573f	2	Turf Manager	manager_test_1790849831200@example.com	+919566737899	$2b$12$m3u.cf2zlASUtqw1YJvX3OszndQTNPasb1HMkDzZ54VoARTmIWY6e	SUSPENDED	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:11.88576+05:30	2026-10-01 15:47:11.613754+05:30	2026-10-01 15:47:16.288133+05:30	\N	\N
usr_f16724c6f8d5f94d	3	Wallet Player	wallet_player_1790849348137@example.com	+919641985519	$2b$10$moPqSLXst8X4mlkv4aqZ5O8F7VLs1/LjefcL/DfMXheqKYwUFIoNG	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:08.987224+05:30	2026-10-01 15:39:08.716562+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_962f5f2641636fae	3	Test Striker	test_player_1790849348188@example.com	+919841893715	$2b$12$7gd7aRT5iKiy6Z3dToYnF.mRlepiB1gEsMAOFlT0p8I1e06.F.SCe	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:11.833275+05:30	2026-10-01 15:39:09.777615+05:30	2026-10-01 15:47:11.244886+05:30	621751	\N
usr_4b474011146a3a70	3	Yuvraj Sachdev	yuvi23@gmail.com	8899665511	$2b$12$2KIZbT6iZwunzDB5rawbSO6QD0zEmcw2qGg49V9mbaOW/a5DxGmqm	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	\N	2026-09-29 13:28:37.809414+05:30	2026-10-01 15:47:11.244886+05:30	691309	\N
usr_86b3e6d40335e6f1	3	Test Player	player_test_1790848588498@example.com	+919783790462	$2b$10$d.5or.jplpFgyJmLTvLLCeCVSAxPgawCrhm2HYk9K5niVmVvQWDPe	ACTIVE	Raipur	Speedy Winger from Raipur	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:29.26098+05:30	2026-10-01 15:26:28.975522+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_8cb0d6db3214a9bc	3	Test Striker	test_player_1790848588500@example.com	+919886446059	$2b$12$BbchvNdXut/31gS3FStjEOHZZrACy3KocoQe.GvMHVr0olImF68re	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:33.25759+05:30	2026-10-01 15:26:30.633344+05:30	2026-10-01 15:47:11.244886+05:30	498211	\N
usr_05a01b29ffddd525	3	Payment Player 2	pay_p2_1790849348215@example.com	+919716661387	$2b$10$CDNRMCxds/THcZFx0VEAF.shsDUCJj.fZ/GSvRm3om1DPI5f67O56	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:09.293211+05:30	2026-10-01 15:39:09.091211+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_e9919c23c0467ea5	3	Payment Player 1	pay_p1_1790849348215@example.com	+919893581768	$2b$10$CDNRMCxds/THcZFx0VEAF.shsDUCJj.fZ/GSvRm3om1DPI5f67O56	ACTIVE	Raipur	\N		f	f	0	\N	2026-10-01 15:39:09.073854+05:30	2026-10-01 15:39:08.814903+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_2bad6dc1de996b96	3	Test Player	player_test_1790849831152@example.com	+919739804287	$2b$10$kVr43it9yZmHk/l4ui21e.DeMcKVbPzqQHy15B0a19vXeWdvPkdLe	SUSPENDED	Raipur	Speedy Winger from Raipur	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:11.455568+05:30	2026-10-01 15:47:11.327178+05:30	2026-10-01 15:47:11.644452+05:30	\N	\N
usr_87256bb5c03dd033	3	Test Striker	test_player_1790849831152@example.com	+919855730347	$2b$12$WmvBj0LWTlEYzoZEzC.6KeUgkI/lzwbtUfYVhntvYQ1sg7Ahra5X.	SUSPENDED	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:13.832157+05:30	2026-10-01 15:47:12.256235+05:30	2026-10-01 15:47:13.83602+05:30	733026	\N
usr_e55abb463db8392d	1	Aditya Kumar	aadiverma4206@gmail.com	9754313585	$2b$12$JgFjxr9IkY31mN12Z5u8F.hUf00KZjNri6cn.l8IPmv7a36i33i1W	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	t	t	0	\N	2026-10-01 11:20:31.460453+05:30	2026-09-29 15:20:21.207044+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_8cf6038983567937	3	Workflow Player	wf_player_1790848588497@example.com	+919610984495	$2b$10$0kp2tUlKxOcthdynhIU8/.uFNw7ulrj/3NnMddQZZJLeOUfTAPofu	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:29.310256+05:30	2026-10-01 15:26:29.129303+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_3956d119b0e3e452	2	Workflow Manager	wf_manager_1790848588497@example.com	+919587339174	$2b$10$0kp2tUlKxOcthdynhIU8/.uFNw7ulrj/3NnMddQZZJLeOUfTAPofu	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:29.450035+05:30	2026-10-01 15:26:29.332987+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_372a9de0c155953d	3	Workflow Player	wf_player_1790848991248@example.com	+919613076306	$2b$10$9XNKwh1QhnLGu6u7oeuA3e1Z5o43LG/XGTsf2Q6J0vwmgsCLmOmPe	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:33:11.609824+05:30	2026-10-01 15:33:11.470376+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_77d1efe4afbc4c7f	2	Workflow Manager	wf_manager_1790848991248@example.com	+919570031891	$2b$10$9XNKwh1QhnLGu6u7oeuA3e1Z5o43LG/XGTsf2Q6J0vwmgsCLmOmPe	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:33:11.704354+05:30	2026-10-01 15:33:11.625832+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_258e0b7430df83ca	3	Workflow Player	wf_player_1790849348212@example.com	+919664002345	$2b$10$pY75sW9ggarJ1oFXgb2aDuvlrFaVGVhIB69gro0Ilz3alSuQE7unS	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:08.998316+05:30	2026-10-01 15:39:08.819806+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_4b2405663fda6e40	2	Workflow Manager	wf_manager_1790849348212@example.com	+919523226815	$2b$10$pY75sW9ggarJ1oFXgb2aDuvlrFaVGVhIB69gro0Ilz3alSuQE7unS	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:09.13429+05:30	2026-10-01 15:39:09.019558+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_a10542f59057b140	3	CCTV Player	player_cctv_1790849349545@example.com	+919415833250	$2b$12$sEU98KifpnaP0nqyjo2PgeBvhnO6hdHEq7M/QLLnaQXMOTRSNhRlq	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:09.853459+05:30	2026-10-01 15:39:09.545766+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_a0ea1d4f298d4a7e	2	Turf Manager	manager_test_1790849348214@example.com	+919595725145	$2b$12$sEU98KifpnaP0nqyjo2PgeBvhnO6hdHEq7M/QLLnaQXMOTRSNhRlq	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:09.527937+05:30	2026-10-01 15:39:09.096588+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_2868a49c6aa551f5	2	Roshan Jit	roshan12@gmail.com	96633527854	$2b$12$K/0Vo.06/MSlpaFPwq6E2e8M1LDU92uiBlt0odcdUTyzd8b8rbTcK	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 11:21:29.236921+05:30	2026-09-29 15:33:09.732347+05:30	2026-10-01 15:47:11.244886+05:30	494497	\N
usr_66ac9868bfa6631c	3	Payment Player 2	pay_p2_1790848588497@example.com	+919750872371	$2b$10$Bc6IvkEo4TKLzJNkCfrswezE4sFq4lQCI0t/AfFQnFLwtiaDlZmmG	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:26:29.674435+05:30	2026-10-01 15:26:29.465411+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_aaba6c37ed2fbd00	3	Payment Player 1	pay_p1_1790848588497@example.com	+919829499613	$2b$10$Bc6IvkEo4TKLzJNkCfrswezE4sFq4lQCI0t/AfFQnFLwtiaDlZmmG	ACTIVE	Raipur	\N		f	f	0	\N	2026-10-01 15:26:29.443529+05:30	2026-10-01 15:26:29.185564+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_16c2144c0df7f485	3	Test Player	player_test_1790849348155@example.com	+919742426735	$2b$10$/GwGL0VD1ZUg1EI5UW586edRVH4GjIcU9jYWp/K/YyqfaPIpChoqW	ACTIVE	Raipur	Speedy Winger from Raipur	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:39:08.897891+05:30	2026-10-01 15:39:08.692231+05:30	2026-10-01 15:47:11.244886+05:30	\N	\N
usr_b2c56e4b881cf6fb	3	Wallet Player	wallet_player_1790849831168@example.com	+919624607084	$2b$10$eFS5paOQKDqsGJYHGnxCue6IpkhsTsCcIL59vpXx4mHYrv0Br/AG.	SUSPENDED	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 15:47:11.536669+05:30	2026-10-01 15:47:11.336305+05:30	2026-10-01 15:47:12.334451+05:30	\N	\N
usr_771ffc659cac6f5f	3	Player Singh	player@gmail.com	9876544321	$2b$12$H7i2H/Tv14ie4aldlYmAyOAtKIu8biminQrZF6S894/e3Qni8bMzu	ACTIVE	Raipur	\N	/assets/images/avatars/default-avatar.jpg	f	f	0	\N	2026-10-01 17:17:32.333689+05:30	2026-09-29 12:55:42.602639+05:30	2026-10-01 17:17:32.333689+05:30	535082	\N
\.


--
-- TOC entry 6218 (class 0 OID 77311)
-- Dependencies: 274
-- Data for Name: wallet_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id, provider_payment_id, created_at) FROM stdin;
tx_d988f49a5ea66015	usr_771ffc659cac6f5f	DEBIT	100.00	900.00	Entry fee for hosting game "FIFA12"	SUCCESS	\N	\N	2026-10-03 12:10:08.880538+05:30
tx_153d573fa6c89f13	usr_771ffc659cac6f5f	DEBIT	75.00	825.00	Entry fee for hosting game "Fifa"	SUCCESS	\N	\N	2026-10-03 12:14:18.918676+05:30
\.


--
-- TOC entry 6242 (class 0 OID 0)
-- Dependencies: 260
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 27, true);


--
-- TOC entry 6243 (class 0 OID 0)
-- Dependencies: 239
-- Name: game_players_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.game_players_id_seq', 16, true);


--
-- TOC entry 6244 (class 0 OID 0)
-- Dependencies: 241
-- Name: game_waitlist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.game_waitlist_id_seq', 12, true);


--
-- TOC entry 6245 (class 0 OID 0)
-- Dependencies: 243
-- Name: live_score_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.live_score_logs_id_seq', 14, true);


--
-- TOC entry 6246 (class 0 OID 0)
-- Dependencies: 231
-- Name: otp_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.otp_verifications_id_seq', 34, true);


--
-- TOC entry 6247 (class 0 OID 0)
-- Dependencies: 267
-- Name: payment_webhook_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_webhook_events_id_seq', 48, true);


--
-- TOC entry 6248 (class 0 OID 0)
-- Dependencies: 264
-- Name: user_identity_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_identity_history_id_seq', 280, true);


--
-- TOC entry 5757 (class 2606 OID 17995)
-- Name: admin_details admin_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_details
    ADD CONSTRAINT admin_details_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5864 (class 2606 OID 18856)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5894 (class 2606 OID 19882)
-- Name: cctv_cameras cctv_cameras_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_cameras
    ADD CONSTRAINT cctv_cameras_pkey PRIMARY KEY (id);


--
-- TOC entry 5898 (class 2606 OID 19946)
-- Name: cctv_recording_events cctv_recording_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recording_events
    ADD CONSTRAINT cctv_recording_events_pkey PRIMARY KEY (id);


--
-- TOC entry 5896 (class 2606 OID 19910)
-- Name: cctv_recordings cctv_recordings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recordings
    ADD CONSTRAINT cctv_recordings_pkey PRIMARY KEY (id);


--
-- TOC entry 5854 (class 2606 OID 18770)
-- Name: challenge_progress challenge_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.challenge_progress
    ADD CONSTRAINT challenge_progress_pkey PRIMARY KEY (challenge_id, user_id);


--
-- TOC entry 5852 (class 2606 OID 18758)
-- Name: challenges challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.challenges
    ADD CONSTRAINT challenges_pkey PRIMARY KEY (id);


--
-- TOC entry 5780 (class 2606 OID 18167)
-- Name: club_managers club_managers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.club_managers
    ADD CONSTRAINT club_managers_pkey PRIMARY KEY (club_id, user_id);


--
-- TOC entry 5776 (class 2606 OID 18156)
-- Name: clubs clubs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clubs
    ADD CONSTRAINT clubs_pkey PRIMARY KEY (id);


--
-- TOC entry 5838 (class 2606 OID 18630)
-- Name: community_posts community_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_posts
    ADD CONSTRAINT community_posts_pkey PRIMARY KEY (id);


--
-- TOC entry 5788 (class 2606 OID 18247)
-- Name: court_bookings court_bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.court_bookings
    ADD CONSTRAINT court_bookings_pkey PRIMARY KEY (id);


--
-- TOC entry 5782 (class 2606 OID 18210)
-- Name: courts courts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT courts_pkey PRIMARY KEY (id);


--
-- TOC entry 5904 (class 2606 OID 28205)
-- Name: game_activity_logs game_activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_activity_logs
    ADD CONSTRAINT game_activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5800 (class 2606 OID 18345)
-- Name: game_players game_players_game_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_players
    ADD CONSTRAINT game_players_game_id_user_id_key UNIQUE (game_id, user_id);


--
-- TOC entry 5802 (class 2606 OID 18343)
-- Name: game_players game_players_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_players
    ADD CONSTRAINT game_players_pkey PRIMARY KEY (id);


--
-- TOC entry 5900 (class 2606 OID 28179)
-- Name: game_slot_requests game_slot_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_slot_requests
    ADD CONSTRAINT game_slot_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 5871 (class 2606 OID 18912)
-- Name: game_videos game_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_videos
    ADD CONSTRAINT game_videos_pkey PRIMARY KEY (id);


--
-- TOC entry 5807 (class 2606 OID 18379)
-- Name: game_waitlist game_waitlist_game_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist
    ADD CONSTRAINT game_waitlist_game_id_user_id_key UNIQUE (game_id, user_id);


--
-- TOC entry 5809 (class 2606 OID 18381)
-- Name: game_waitlist game_waitlist_game_id_waitlist_order_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist
    ADD CONSTRAINT game_waitlist_game_id_waitlist_order_key UNIQUE (game_id, waitlist_order);


--
-- TOC entry 5811 (class 2606 OID 18377)
-- Name: game_waitlist game_waitlist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist
    ADD CONSTRAINT game_waitlist_pkey PRIMARY KEY (id);


--
-- TOC entry 5795 (class 2606 OID 18308)
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- TOC entry 5815 (class 2606 OID 18414)
-- Name: live_score_logs live_score_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_score_logs
    ADD CONSTRAINT live_score_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5761 (class 2606 OID 18014)
-- Name: manager_details manager_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manager_details
    ADD CONSTRAINT manager_details_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5858 (class 2606 OID 18798)
-- Name: match_disputes match_disputes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_disputes
    ADD CONSTRAINT match_disputes_pkey PRIMARY KEY (id);


--
-- TOC entry 5793 (class 2606 OID 19669)
-- Name: court_bookings no_overlapping_confirmed_bookings; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.court_bookings
    ADD CONSTRAINT no_overlapping_confirmed_bookings EXCLUDE USING gist (court_id WITH =, tsrange((booking_date + start_time), (booking_date + end_time), '[)'::text) WITH &&) WHERE ((status = 'CONFIRMED'::public.booking_status));


--
-- TOC entry 5869 (class 2606 OID 18880)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 5769 (class 2606 OID 18094)
-- Name: otp_verifications otp_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_verifications
    ADD CONSTRAINT otp_verifications_pkey PRIMARY KEY (id);


--
-- TOC entry 5881 (class 2606 OID 19783)
-- Name: payment_orders payment_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT payment_orders_pkey PRIMARY KEY (id);


--
-- TOC entry 5891 (class 2606 OID 19817)
-- Name: payment_webhook_events payment_webhook_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_webhook_events
    ADD CONSTRAINT payment_webhook_events_pkey PRIMARY KEY (id);


--
-- TOC entry 5764 (class 2606 OID 18052)
-- Name: player_details player_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_details
    ADD CONSTRAINT player_details_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5818 (class 2606 OID 18461)
-- Name: player_stats player_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_stats
    ADD CONSTRAINT player_stats_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5848 (class 2606 OID 18706)
-- Name: poll_options poll_options_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (id);


--
-- TOC entry 5850 (class 2606 OID 18720)
-- Name: poll_votes poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (poll_id, user_id);


--
-- TOC entry 5846 (class 2606 OID 18694)
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (id);


--
-- TOC entry 5844 (class 2606 OID 18671)
-- Name: post_comments post_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comments
    ADD CONSTRAINT post_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 5841 (class 2606 OID 18645)
-- Name: post_likes post_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_likes
    ADD CONSTRAINT post_likes_pkey PRIMARY KEY (post_id, user_id);


--
-- TOC entry 5739 (class 2606 OID 17936)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 5741 (class 2606 OID 17938)
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- TOC entry 5862 (class 2606 OID 18828)
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- TOC entry 5829 (class 2606 OID 18559)
-- Name: tournament_bracket_matches tournament_bracket_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_bracket_matches
    ADD CONSTRAINT tournament_bracket_matches_pkey PRIMARY KEY (id);


--
-- TOC entry 5824 (class 2606 OID 18526)
-- Name: tournament_teams tournament_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_pkey PRIMARY KEY (id);


--
-- TOC entry 5826 (class 2606 OID 18528)
-- Name: tournament_teams tournament_teams_tournament_id_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_tournament_id_name_key UNIQUE (tournament_id, name);


--
-- TOC entry 5822 (class 2606 OID 18504)
-- Name: tournaments tournaments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournaments
    ADD CONSTRAINT tournaments_pkey PRIMARY KEY (id);


--
-- TOC entry 5836 (class 2606 OID 18599)
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 5786 (class 2606 OID 18212)
-- Name: courts uq_court_name_per_club; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT uq_court_name_per_club UNIQUE (club_id, name);


--
-- TOC entry 5902 (class 2606 OID 28181)
-- Name: game_slot_requests uq_game_user_slot_request; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_slot_requests
    ADD CONSTRAINT uq_game_user_slot_request UNIQUE (game_id, user_id);


--
-- TOC entry 5883 (class 2606 OID 19787)
-- Name: payment_orders uq_payment_provider_order; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT uq_payment_provider_order UNIQUE (provider, provider_order_id);


--
-- TOC entry 5885 (class 2606 OID 19789)
-- Name: payment_orders uq_payment_provider_payment; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT uq_payment_provider_payment UNIQUE (provider, provider_payment_id);


--
-- TOC entry 5887 (class 2606 OID 19785)
-- Name: payment_orders uq_payment_user_idempotency; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT uq_payment_user_idempotency UNIQUE (user_id, idempotency_key);


--
-- TOC entry 5749 (class 2606 OID 17972)
-- Name: users uq_users_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);


--
-- TOC entry 5751 (class 2606 OID 17974)
-- Name: users uq_users_phone; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uq_users_phone UNIQUE (phone);


--
-- TOC entry 5875 (class 2606 OID 19731)
-- Name: user_identity_history user_identity_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_identity_history
    ADD CONSTRAINT user_identity_history_pkey PRIMARY KEY (id);


--
-- TOC entry 5774 (class 2606 OID 18119)
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 5753 (class 2606 OID 17970)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5906 (class 2606 OID 77327)
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id);


--
-- TOC entry 5865 (class 1259 OID 18863)
-- Name: idx_audit_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_admin ON public.audit_logs USING btree (admin_id);


--
-- TOC entry 5866 (class 1259 OID 18862)
-- Name: idx_audit_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_created ON public.audit_logs USING btree (created_at DESC);


--
-- TOC entry 5789 (class 1259 OID 18266)
-- Name: idx_bookings_court_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_court_date ON public.court_bookings USING btree (court_id, booking_date);


--
-- TOC entry 5790 (class 1259 OID 18267)
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_status ON public.court_bookings USING btree (status);


--
-- TOC entry 5791 (class 1259 OID 18265)
-- Name: idx_bookings_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_user ON public.court_bookings USING btree (user_id);


--
-- TOC entry 5827 (class 1259 OID 18580)
-- Name: idx_bracket_tournament; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bracket_tournament ON public.tournament_bracket_matches USING btree (tournament_id);


--
-- TOC entry 5777 (class 1259 OID 18157)
-- Name: idx_clubs_city; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clubs_city ON public.clubs USING btree (city);


--
-- TOC entry 5778 (class 1259 OID 18158)
-- Name: idx_clubs_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clubs_status ON public.clubs USING btree (status);


--
-- TOC entry 5842 (class 1259 OID 18682)
-- Name: idx_comments_post; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comments_post ON public.post_comments USING btree (post_id, created_at);


--
-- TOC entry 5783 (class 1259 OID 18218)
-- Name: idx_courts_club; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courts_club ON public.courts USING btree (club_id);


--
-- TOC entry 5784 (class 1259 OID 18219)
-- Name: idx_courts_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_courts_status ON public.courts USING btree (status);


--
-- TOC entry 5855 (class 1259 OID 18809)
-- Name: idx_disputes_game; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_disputes_game ON public.match_disputes USING btree (game_id);


--
-- TOC entry 5856 (class 1259 OID 18810)
-- Name: idx_disputes_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_disputes_status ON public.match_disputes USING btree (status);


--
-- TOC entry 5803 (class 1259 OID 18356)
-- Name: idx_game_players_game; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_players_game ON public.game_players USING btree (game_id);


--
-- TOC entry 5804 (class 1259 OID 18357)
-- Name: idx_game_players_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_players_user ON public.game_players USING btree (user_id);


--
-- TOC entry 5796 (class 1259 OID 18326)
-- Name: idx_games_club; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_games_club ON public.games USING btree (club_id);


--
-- TOC entry 5797 (class 1259 OID 18324)
-- Name: idx_games_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_games_date ON public.games USING btree (match_date);


--
-- TOC entry 5798 (class 1259 OID 18325)
-- Name: idx_games_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_games_status ON public.games USING btree (status);


--
-- TOC entry 5873 (class 1259 OID 19750)
-- Name: idx_identity_history_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_identity_history_user ON public.user_identity_history USING btree (user_id);


--
-- TOC entry 5813 (class 1259 OID 18425)
-- Name: idx_live_score_game; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_live_score_game ON public.live_score_logs USING btree (game_id, created_at DESC);


--
-- TOC entry 5759 (class 1259 OID 18025)
-- Name: idx_manager_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_manager_created_by ON public.manager_details USING btree (created_by_admin_id);


--
-- TOC entry 5867 (class 1259 OID 18896)
-- Name: idx_notif_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notif_user ON public.notifications USING btree (user_id, is_read, created_at DESC);


--
-- TOC entry 5765 (class 1259 OID 18102)
-- Name: idx_otp_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_otp_active ON public.otp_verifications USING btree (identifier, purpose) WHERE (is_used = false);


--
-- TOC entry 5766 (class 1259 OID 18100)
-- Name: idx_otp_identifier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_otp_identifier ON public.otp_verifications USING btree (identifier, purpose, created_at DESC);


--
-- TOC entry 5767 (class 1259 OID 18101)
-- Name: idx_otp_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_otp_user ON public.otp_verifications USING btree (user_id);


--
-- TOC entry 5877 (class 1259 OID 19832)
-- Name: idx_payment_orders_expiry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_orders_expiry ON public.payment_orders USING btree (expires_at) WHERE ((status)::text = ANY ((ARRAY['CREATED'::character varying, 'PENDING'::character varying])::text[]));


--
-- TOC entry 5878 (class 1259 OID 19796)
-- Name: idx_payment_orders_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_orders_status ON public.payment_orders USING btree (status);


--
-- TOC entry 5879 (class 1259 OID 19795)
-- Name: idx_payment_orders_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_orders_user ON public.payment_orders USING btree (user_id, created_at DESC);


--
-- TOC entry 5889 (class 1259 OID 19819)
-- Name: idx_payment_webhook_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payment_webhook_order ON public.payment_webhook_events USING btree (payment_order_id);


--
-- TOC entry 5762 (class 1259 OID 18058)
-- Name: idx_player_elo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_player_elo ON public.player_details USING btree (elo_rating DESC);


--
-- TOC entry 5839 (class 1259 OID 18636)
-- Name: idx_posts_city; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_posts_city ON public.community_posts USING btree (city, created_at DESC);


--
-- TOC entry 5770 (class 1259 OID 19751)
-- Name: idx_sessions_expiry; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_expiry ON public.user_sessions USING btree (expires_at) WHERE (is_revoked = false);


--
-- TOC entry 5771 (class 1259 OID 18125)
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_user ON public.user_sessions USING btree (user_id) WHERE (is_revoked = false);


--
-- TOC entry 5772 (class 1259 OID 19749)
-- Name: idx_sessions_user_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_user_active ON public.user_sessions USING btree (user_id) WHERE (is_revoked = false);


--
-- TOC entry 5859 (class 1259 OID 18840)
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_status ON public.support_tickets USING btree (status);


--
-- TOC entry 5860 (class 1259 OID 18839)
-- Name: idx_tickets_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_user ON public.support_tickets USING btree (user_id);


--
-- TOC entry 5819 (class 1259 OID 18510)
-- Name: idx_tournaments_city; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tournaments_city ON public.tournaments USING btree (city);


--
-- TOC entry 5820 (class 1259 OID 18511)
-- Name: idx_tournaments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tournaments_status ON public.tournaments USING btree (status);


--
-- TOC entry 5830 (class 1259 OID 19859)
-- Name: idx_transactions_game_reference; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transactions_game_reference ON public.transactions USING btree (reference_id, type, created_at DESC) WHERE (type = 'PAYMENT'::public.transaction_type);


--
-- TOC entry 5831 (class 1259 OID 19856)
-- Name: idx_transactions_reference_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transactions_reference_id ON public.transactions USING btree (reference_id) WHERE (reference_id IS NOT NULL);


--
-- TOC entry 5832 (class 1259 OID 19858)
-- Name: idx_transactions_user_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_transactions_user_created ON public.transactions USING btree (user_id, created_at DESC);


--
-- TOC entry 5833 (class 1259 OID 18606)
-- Name: idx_tx_reference; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tx_reference ON public.transactions USING btree (reference_id);


--
-- TOC entry 5834 (class 1259 OID 18605)
-- Name: idx_tx_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tx_user ON public.transactions USING btree (user_id, created_at DESC);


--
-- TOC entry 5742 (class 1259 OID 17983)
-- Name: idx_users_city; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_city ON public.users USING btree (city);


--
-- TOC entry 5743 (class 1259 OID 17980)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 5744 (class 1259 OID 19747)
-- Name: idx_users_email_login; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email_login ON public.users USING btree (lower(TRIM(BOTH FROM email)));


--
-- TOC entry 5745 (class 1259 OID 17981)
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- TOC entry 5746 (class 1259 OID 19748)
-- Name: idx_users_phone_login; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone_login ON public.users USING btree (TRIM(BOTH FROM phone));


--
-- TOC entry 5747 (class 1259 OID 17982)
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role_id);


--
-- TOC entry 5872 (class 1259 OID 18933)
-- Name: idx_videos_game; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_videos_game ON public.game_videos USING btree (game_id);


--
-- TOC entry 5812 (class 1259 OID 18392)
-- Name: idx_waitlist_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_waitlist_order ON public.game_waitlist USING btree (game_id, waitlist_order);


--
-- TOC entry 5816 (class 1259 OID 18426)
-- Name: uq_one_final_score_per_game; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_one_final_score_per_game ON public.live_score_logs USING btree (game_id) WHERE (is_final = true);


--
-- TOC entry 5758 (class 1259 OID 18006)
-- Name: uq_single_owner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_single_owner ON public.admin_details USING btree (is_owner) WHERE (is_owner = true);


--
-- TOC entry 5805 (class 1259 OID 19857)
-- Name: ux_game_players_game_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_game_players_game_user ON public.game_players USING btree (game_id, user_id);


--
-- TOC entry 5876 (class 1259 OID 19737)
-- Name: ux_identity_history_type_value; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_identity_history_type_value ON public.user_identity_history USING btree (identity_type, normalized_value);


--
-- TOC entry 5888 (class 1259 OID 19850)
-- Name: ux_payment_orders_user_idempotency; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_payment_orders_user_idempotency ON public.payment_orders USING btree (user_id, idempotency_key);


--
-- TOC entry 5892 (class 1259 OID 19818)
-- Name: ux_payment_webhook_event; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_payment_webhook_event ON public.payment_webhook_events USING btree (provider, event_id);


--
-- TOC entry 5754 (class 1259 OID 19706)
-- Name: ux_users_email_normalized; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_users_email_normalized ON public.users USING btree (lower(TRIM(BOTH FROM email)));


--
-- TOC entry 5755 (class 1259 OID 19707)
-- Name: ux_users_phone_normalized; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ux_users_phone_normalized ON public.users USING btree (TRIM(BOTH FROM phone));


--
-- TOC entry 5999 (class 2620 OID 18272)
-- Name: court_bookings trg_apply_refund_tier; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_apply_refund_tier BEFORE UPDATE ON public.court_bookings FOR EACH ROW EXECUTE FUNCTION public.apply_refund_tier();


--
-- TOC entry 6012 (class 2620 OID 18608)
-- Name: transactions trg_apply_transaction; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_apply_transaction BEFORE INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.apply_transaction_to_wallet();


--
-- TOC entry 6007 (class 2620 OID 18394)
-- Name: game_waitlist trg_assign_waitlist_order; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_assign_waitlist_order BEFORE INSERT ON public.game_waitlist FOR EACH ROW EXECUTE FUNCTION public.assign_waitlist_order();


--
-- TOC entry 6021 (class 2620 OID 18866)
-- Name: audit_logs trg_block_audit_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_block_audit_delete BEFORE DELETE ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION public.block_audit_log_mutation();


--
-- TOC entry 6022 (class 2620 OID 18865)
-- Name: audit_logs trg_block_audit_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_block_audit_update BEFORE UPDATE ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION public.block_audit_log_mutation();


--
-- TOC entry 5979 (class 2620 OID 17941)
-- Name: roles trg_block_roles_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_block_roles_delete BEFORE DELETE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.protect_base_roles();


--
-- TOC entry 5980 (class 2620 OID 17940)
-- Name: roles trg_block_roles_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_block_roles_update BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.protect_base_roles();


--
-- TOC entry 6013 (class 2620 OID 19822)
-- Name: transactions trg_block_transaction_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_block_transaction_delete BEFORE DELETE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.block_transaction_mutation();


--
-- TOC entry 6014 (class 2620 OID 19821)
-- Name: transactions trg_block_transaction_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_block_transaction_update BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.block_transaction_mutation();


--
-- TOC entry 6000 (class 2620 OID 18268)
-- Name: court_bookings trg_bookings_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON public.court_bookings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5981 (class 2620 OID 19738)
-- Name: users trg_capture_user_identity; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_capture_user_identity AFTER INSERT OR UPDATE OF email, phone ON public.users FOR EACH ROW EXECUTE FUNCTION public.capture_user_identity();


--
-- TOC entry 5988 (class 2620 OID 18061)
-- Name: admin_details trg_check_admin_detail; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_admin_detail BEFORE INSERT ON public.admin_details FOR EACH ROW EXECUTE FUNCTION public.enforce_role_detail_match();


--
-- TOC entry 6020 (class 2620 OID 18842)
-- Name: support_tickets trg_check_assigned_staff; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_assigned_staff BEFORE INSERT OR UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION public.check_assigned_staff_is_admin();


--
-- TOC entry 6001 (class 2620 OID 18270)
-- Name: court_bookings trg_check_booking_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_booking_user BEFORE INSERT ON public.court_bookings FOR EACH ROW EXECUTE FUNCTION public.check_booking_user_is_player();


--
-- TOC entry 5990 (class 2620 OID 18062)
-- Name: manager_details trg_check_manager_detail; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_manager_detail BEFORE INSERT ON public.manager_details FOR EACH ROW EXECUTE FUNCTION public.enforce_role_detail_match();


--
-- TOC entry 5997 (class 2620 OID 18179)
-- Name: club_managers trg_check_manager_role; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_manager_role BEFORE INSERT OR UPDATE ON public.club_managers FOR EACH ROW EXECUTE FUNCTION public.check_manager_role();


--
-- TOC entry 5991 (class 2620 OID 18063)
-- Name: player_details trg_check_player_detail; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_player_detail BEFORE INSERT ON public.player_details FOR EACH ROW EXECUTE FUNCTION public.enforce_role_detail_match();


--
-- TOC entry 6017 (class 2620 OID 18737)
-- Name: poll_votes trg_check_poll_option; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_check_poll_option BEFORE INSERT ON public.poll_votes FOR EACH ROW EXECUTE FUNCTION public.check_poll_option_matches_poll();


--
-- TOC entry 5996 (class 2620 OID 18159)
-- Name: clubs trg_clubs_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_clubs_updated_at BEFORE UPDATE ON public.clubs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5998 (class 2620 OID 18220)
-- Name: courts trg_courts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_courts_updated_at BEFORE UPDATE ON public.courts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5992 (class 2620 OID 18469)
-- Name: player_details trg_create_player_stats; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_create_player_stats AFTER INSERT ON public.player_details FOR EACH ROW EXECUTE FUNCTION public.create_player_stats_row();


--
-- TOC entry 6004 (class 2620 OID 18359)
-- Name: game_players trg_enforce_game_player_rules; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_enforce_game_player_rules BEFORE INSERT ON public.game_players FOR EACH ROW EXECUTE FUNCTION public.enforce_game_player_rules();


--
-- TOC entry 6008 (class 2620 OID 18471)
-- Name: live_score_logs trg_finalize_match_result; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_finalize_match_result AFTER INSERT ON public.live_score_logs FOR EACH ROW EXECUTE FUNCTION public.finalize_match_result();


--
-- TOC entry 6002 (class 2620 OID 18327)
-- Name: games trg_games_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_games_updated_at BEFORE UPDATE ON public.games FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5993 (class 2620 OID 18610)
-- Name: player_details trg_grant_welcome_bonus; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_grant_welcome_bonus AFTER INSERT ON public.player_details FOR EACH ROW EXECUTE FUNCTION public.grant_welcome_bonus();


--
-- TOC entry 5995 (class 2620 OID 18104)
-- Name: otp_verifications trg_guard_otp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_guard_otp BEFORE UPDATE ON public.otp_verifications FOR EACH ROW EXECUTE FUNCTION public.guard_otp_update();


--
-- TOC entry 5994 (class 2620 OID 18059)
-- Name: player_details trg_player_details_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_player_details_updated_at BEFORE UPDATE ON public.player_details FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 6009 (class 2620 OID 18467)
-- Name: player_stats trg_player_stats_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_player_stats_updated_at BEFORE UPDATE ON public.player_stats FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 6015 (class 2620 OID 18637)
-- Name: community_posts trg_posts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_posts_updated_at BEFORE UPDATE ON public.community_posts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5982 (class 2620 OID 19740)
-- Name: users trg_prevent_role_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_role_change BEFORE UPDATE OF role_id ON public.users FOR EACH ROW EXECUTE FUNCTION public.prevent_role_change();


--
-- TOC entry 5983 (class 2620 OID 19739)
-- Name: users trg_prevent_user_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_user_delete BEFORE DELETE ON public.users FOR EACH ROW EXECUTE FUNCTION public.prevent_user_delete();


--
-- TOC entry 6005 (class 2620 OID 18396)
-- Name: game_players trg_promote_from_waitlist; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_promote_from_waitlist AFTER DELETE ON public.game_players FOR EACH ROW EXECUTE FUNCTION public.promote_from_waitlist();


--
-- TOC entry 5984 (class 2620 OID 18941)
-- Name: users trg_protect_owner; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_protect_owner BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.protect_owner_account();


--
-- TOC entry 5985 (class 2620 OID 18939)
-- Name: users trg_protect_owner_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_protect_owner_delete BEFORE DELETE ON public.users FOR EACH ROW EXECUTE FUNCTION public.protect_owner_delete();


--
-- TOC entry 5989 (class 2620 OID 18067)
-- Name: admin_details trg_protect_owner_flag; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_protect_owner_flag BEFORE UPDATE ON public.admin_details FOR EACH ROW EXECUTE FUNCTION public.protect_owner_flag();


--
-- TOC entry 5986 (class 2620 OID 18065)
-- Name: users trg_protect_owner_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_protect_owner_users BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.protect_owner_on_users();


--
-- TOC entry 6019 (class 2620 OID 18782)
-- Name: challenge_progress trg_reward_completed_challenge; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_reward_completed_challenge BEFORE INSERT OR UPDATE ON public.challenge_progress FOR EACH ROW EXECUTE FUNCTION public.reward_completed_challenge();


--
-- TOC entry 6003 (class 2620 OID 18329)
-- Name: games trg_snapshot_game_creator_role; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_snapshot_game_creator_role BEFORE INSERT ON public.games FOR EACH ROW EXECUTE FUNCTION public.snapshot_game_creator_role();


--
-- TOC entry 6006 (class 2620 OID 18361)
-- Name: game_players trg_sync_game_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_game_status AFTER INSERT OR DELETE ON public.game_players FOR EACH ROW EXECUTE FUNCTION public.sync_game_status_on_roster_change();


--
-- TOC entry 6018 (class 2620 OID 18739)
-- Name: poll_votes trg_sync_poll_votes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_poll_votes AFTER INSERT OR DELETE ON public.poll_votes FOR EACH ROW EXECUTE FUNCTION public.sync_poll_votes_count();


--
-- TOC entry 6016 (class 2620 OID 18657)
-- Name: post_likes trg_sync_post_likes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_post_likes AFTER INSERT OR DELETE ON public.post_likes FOR EACH ROW EXECUTE FUNCTION public.sync_post_likes_count();


--
-- TOC entry 6011 (class 2620 OID 18545)
-- Name: tournament_teams trg_sync_tournament_team_count; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_sync_tournament_team_count AFTER INSERT OR DELETE ON public.tournament_teams FOR EACH ROW EXECUTE FUNCTION public.sync_tournament_team_count();


--
-- TOC entry 6010 (class 2620 OID 18512)
-- Name: tournaments trg_tournaments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_tournaments_updated_at BEFORE UPDATE ON public.tournaments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5987 (class 2620 OID 19752)
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5908 (class 2606 OID 18001)
-- Name: admin_details admin_details_created_by_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_details
    ADD CONSTRAINT admin_details_created_by_admin_id_fkey FOREIGN KEY (created_by_admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5909 (class 2606 OID 17996)
-- Name: admin_details admin_details_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_details
    ADD CONSTRAINT admin_details_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5955 (class 2606 OID 18857)
-- Name: audit_logs audit_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5966 (class 2606 OID 19883)
-- Name: cctv_cameras cctv_cameras_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_cameras
    ADD CONSTRAINT cctv_cameras_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE;


--
-- TOC entry 5967 (class 2606 OID 19888)
-- Name: cctv_cameras cctv_cameras_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_cameras
    ADD CONSTRAINT cctv_cameras_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE SET NULL;


--
-- TOC entry 5972 (class 2606 OID 19952)
-- Name: cctv_recording_events cctv_recording_events_actor_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recording_events
    ADD CONSTRAINT cctv_recording_events_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5973 (class 2606 OID 19947)
-- Name: cctv_recording_events cctv_recording_events_recording_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recording_events
    ADD CONSTRAINT cctv_recording_events_recording_id_fkey FOREIGN KEY (recording_id) REFERENCES public.cctv_recordings(id) ON DELETE CASCADE;


--
-- TOC entry 5968 (class 2606 OID 19926)
-- Name: cctv_recordings cctv_recordings_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recordings
    ADD CONSTRAINT cctv_recordings_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES public.cctv_cameras(id) ON DELETE SET NULL;


--
-- TOC entry 5969 (class 2606 OID 19916)
-- Name: cctv_recordings cctv_recordings_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recordings
    ADD CONSTRAINT cctv_recordings_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE;


--
-- TOC entry 5970 (class 2606 OID 19921)
-- Name: cctv_recordings cctv_recordings_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recordings
    ADD CONSTRAINT cctv_recordings_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE SET NULL;


--
-- TOC entry 5971 (class 2606 OID 19911)
-- Name: cctv_recordings cctv_recordings_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cctv_recordings
    ADD CONSTRAINT cctv_recordings_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5949 (class 2606 OID 18771)
-- Name: challenge_progress challenge_progress_challenge_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.challenge_progress
    ADD CONSTRAINT challenge_progress_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.challenges(id) ON DELETE CASCADE;


--
-- TOC entry 5950 (class 2606 OID 18776)
-- Name: challenge_progress challenge_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.challenge_progress
    ADD CONSTRAINT challenge_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5915 (class 2606 OID 18168)
-- Name: club_managers club_managers_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.club_managers
    ADD CONSTRAINT club_managers_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE;


--
-- TOC entry 5916 (class 2606 OID 18173)
-- Name: club_managers club_managers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.club_managers
    ADD CONSTRAINT club_managers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5940 (class 2606 OID 18631)
-- Name: community_posts community_posts_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.community_posts
    ADD CONSTRAINT community_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5918 (class 2606 OID 18255)
-- Name: court_bookings court_bookings_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.court_bookings
    ADD CONSTRAINT court_bookings_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE RESTRICT;


--
-- TOC entry 5919 (class 2606 OID 18250)
-- Name: court_bookings court_bookings_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.court_bookings
    ADD CONSTRAINT court_bookings_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE RESTRICT;


--
-- TOC entry 5920 (class 2606 OID 18260)
-- Name: court_bookings court_bookings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.court_bookings
    ADD CONSTRAINT court_bookings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5917 (class 2606 OID 18213)
-- Name: courts courts_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT courts_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE;


--
-- TOC entry 5931 (class 2606 OID 18539)
-- Name: tournaments fk_champion_team; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournaments
    ADD CONSTRAINT fk_champion_team FOREIGN KEY (champion_team_id) REFERENCES public.tournament_teams(id) ON DELETE SET NULL;


--
-- TOC entry 5963 (class 2606 OID 19732)
-- Name: user_identity_history fk_identity_history_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_identity_history
    ADD CONSTRAINT fk_identity_history_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5976 (class 2606 OID 28211)
-- Name: game_activity_logs game_activity_logs_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_activity_logs
    ADD CONSTRAINT game_activity_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5977 (class 2606 OID 28206)
-- Name: game_activity_logs game_activity_logs_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_activity_logs
    ADD CONSTRAINT game_activity_logs_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5924 (class 2606 OID 18346)
-- Name: game_players game_players_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_players
    ADD CONSTRAINT game_players_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5925 (class 2606 OID 18351)
-- Name: game_players game_players_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_players
    ADD CONSTRAINT game_players_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5974 (class 2606 OID 28182)
-- Name: game_slot_requests game_slot_requests_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_slot_requests
    ADD CONSTRAINT game_slot_requests_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5975 (class 2606 OID 28187)
-- Name: game_slot_requests game_slot_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_slot_requests
    ADD CONSTRAINT game_slot_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5959 (class 2606 OID 18918)
-- Name: game_videos game_videos_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_videos
    ADD CONSTRAINT game_videos_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE CASCADE;


--
-- TOC entry 5960 (class 2606 OID 18923)
-- Name: game_videos game_videos_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_videos
    ADD CONSTRAINT game_videos_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE SET NULL;


--
-- TOC entry 5961 (class 2606 OID 18913)
-- Name: game_videos game_videos_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_videos
    ADD CONSTRAINT game_videos_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5962 (class 2606 OID 18928)
-- Name: game_videos game_videos_uploaded_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_videos
    ADD CONSTRAINT game_videos_uploaded_by_id_fkey FOREIGN KEY (uploaded_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5926 (class 2606 OID 18382)
-- Name: game_waitlist game_waitlist_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist
    ADD CONSTRAINT game_waitlist_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5927 (class 2606 OID 18387)
-- Name: game_waitlist game_waitlist_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist
    ADD CONSTRAINT game_waitlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5921 (class 2606 OID 18309)
-- Name: games games_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE SET NULL;


--
-- TOC entry 5922 (class 2606 OID 18314)
-- Name: games games_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE SET NULL;


--
-- TOC entry 5923 (class 2606 OID 18319)
-- Name: games games_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5928 (class 2606 OID 18415)
-- Name: live_score_logs live_score_logs_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_score_logs
    ADD CONSTRAINT live_score_logs_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5929 (class 2606 OID 18420)
-- Name: live_score_logs live_score_logs_updated_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_score_logs
    ADD CONSTRAINT live_score_logs_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5910 (class 2606 OID 18020)
-- Name: manager_details manager_details_created_by_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manager_details
    ADD CONSTRAINT manager_details_created_by_admin_id_fkey FOREIGN KEY (created_by_admin_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5911 (class 2606 OID 18015)
-- Name: manager_details manager_details_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manager_details
    ADD CONSTRAINT manager_details_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5951 (class 2606 OID 18799)
-- Name: match_disputes match_disputes_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_disputes
    ADD CONSTRAINT match_disputes_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- TOC entry 5952 (class 2606 OID 18804)
-- Name: match_disputes match_disputes_reported_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_disputes
    ADD CONSTRAINT match_disputes_reported_by_id_fkey FOREIGN KEY (reported_by_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5956 (class 2606 OID 18886)
-- Name: notifications notifications_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE SET NULL;


--
-- TOC entry 5957 (class 2606 OID 18891)
-- Name: notifications notifications_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE SET NULL;


--
-- TOC entry 5958 (class 2606 OID 18881)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5913 (class 2606 OID 18095)
-- Name: otp_verifications otp_verifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_verifications
    ADD CONSTRAINT otp_verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5964 (class 2606 OID 19790)
-- Name: payment_orders payment_orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT payment_orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5965 (class 2606 OID 19851)
-- Name: payment_webhook_events payment_webhook_events_payment_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_webhook_events
    ADD CONSTRAINT payment_webhook_events_payment_order_id_fkey FOREIGN KEY (payment_order_id) REFERENCES public.payment_orders(id) ON DELETE RESTRICT;


--
-- TOC entry 5912 (class 2606 OID 18053)
-- Name: player_details player_details_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_details
    ADD CONSTRAINT player_details_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5930 (class 2606 OID 18462)
-- Name: player_stats player_stats_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player_stats
    ADD CONSTRAINT player_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.player_details(user_id) ON DELETE CASCADE;


--
-- TOC entry 5945 (class 2606 OID 18707)
-- Name: poll_options poll_options_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- TOC entry 5946 (class 2606 OID 18731)
-- Name: poll_votes poll_votes_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.poll_options(id) ON DELETE CASCADE;


--
-- TOC entry 5947 (class 2606 OID 18721)
-- Name: poll_votes poll_votes_poll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES public.polls(id) ON DELETE CASCADE;


--
-- TOC entry 5948 (class 2606 OID 18726)
-- Name: poll_votes poll_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5943 (class 2606 OID 18677)
-- Name: post_comments post_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comments
    ADD CONSTRAINT post_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5944 (class 2606 OID 18672)
-- Name: post_comments post_comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comments
    ADD CONSTRAINT post_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_posts(id) ON DELETE CASCADE;


--
-- TOC entry 5941 (class 2606 OID 18646)
-- Name: post_likes post_likes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_likes
    ADD CONSTRAINT post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_posts(id) ON DELETE CASCADE;


--
-- TOC entry 5942 (class 2606 OID 18651)
-- Name: post_likes post_likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_likes
    ADD CONSTRAINT post_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5953 (class 2606 OID 18834)
-- Name: support_tickets support_tickets_assigned_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_assigned_staff_id_fkey FOREIGN KEY (assigned_staff_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5954 (class 2606 OID 18829)
-- Name: support_tickets support_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5935 (class 2606 OID 18565)
-- Name: tournament_bracket_matches tournament_bracket_matches_team_a_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_bracket_matches
    ADD CONSTRAINT tournament_bracket_matches_team_a_id_fkey FOREIGN KEY (team_a_id) REFERENCES public.tournament_teams(id) ON DELETE SET NULL;


--
-- TOC entry 5936 (class 2606 OID 18570)
-- Name: tournament_bracket_matches tournament_bracket_matches_team_b_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_bracket_matches
    ADD CONSTRAINT tournament_bracket_matches_team_b_id_fkey FOREIGN KEY (team_b_id) REFERENCES public.tournament_teams(id) ON DELETE SET NULL;


--
-- TOC entry 5937 (class 2606 OID 18560)
-- Name: tournament_bracket_matches tournament_bracket_matches_tournament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_bracket_matches
    ADD CONSTRAINT tournament_bracket_matches_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE;


--
-- TOC entry 5938 (class 2606 OID 18575)
-- Name: tournament_bracket_matches tournament_bracket_matches_winner_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_bracket_matches
    ADD CONSTRAINT tournament_bracket_matches_winner_team_id_fkey FOREIGN KEY (winner_team_id) REFERENCES public.tournament_teams(id) ON DELETE SET NULL;


--
-- TOC entry 5933 (class 2606 OID 18534)
-- Name: tournament_teams tournament_teams_captain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_captain_id_fkey FOREIGN KEY (captain_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5934 (class 2606 OID 18529)
-- Name: tournament_teams tournament_teams_tournament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE;


--
-- TOC entry 5932 (class 2606 OID 18505)
-- Name: tournaments tournaments_club_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tournaments
    ADD CONSTRAINT tournaments_club_id_fkey FOREIGN KEY (club_id) REFERENCES public.clubs(id) ON DELETE RESTRICT;


--
-- TOC entry 5939 (class 2606 OID 18600)
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5914 (class 2606 OID 18120)
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5907 (class 2606 OID 17975)
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE RESTRICT;


--
-- TOC entry 5978 (class 2606 OID 77328)
-- Name: wallet_transactions wallet_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 6227 (class 0 OID 0)
-- Dependencies: 520
-- Name: FUNCTION apply_transaction_to_wallet(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.apply_transaction_to_wallet() FROM PUBLIC;


--
-- TOC entry 6228 (class 0 OID 0)
-- Dependencies: 420
-- Name: FUNCTION create_payment_order(p_user_id character varying, p_provider character varying, p_amount_paise bigint, p_idempotency_key character varying, p_wallet_pin character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.create_payment_order(p_user_id character varying, p_provider character varying, p_amount_paise bigint, p_idempotency_key character varying, p_wallet_pin character varying) FROM PUBLIC;


--
-- TOC entry 6229 (class 0 OID 0)
-- Dependencies: 449
-- Name: FUNCTION expire_stale_payment_orders(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.expire_stale_payment_orders() FROM PUBLIC;


--
-- TOC entry 6230 (class 0 OID 0)
-- Dependencies: 410
-- Name: FUNCTION join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position public.football_position); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position public.football_position) FROM PUBLIC;


--
-- TOC entry 6231 (class 0 OID 0)
-- Dependencies: 554
-- Name: FUNCTION set_wallet_pin(p_user_id character varying, p_pin character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.set_wallet_pin(p_user_id character varying, p_pin character varying) FROM PUBLIC;


--
-- TOC entry 6232 (class 0 OID 0)
-- Dependencies: 499
-- Name: FUNCTION settle_wallet_payment(p_payment_order_id character varying, p_provider_payment_id character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.settle_wallet_payment(p_payment_order_id character varying, p_provider_payment_id character varying) FROM PUBLIC;


--
-- TOC entry 6233 (class 0 OID 0)
-- Dependencies: 531
-- Name: FUNCTION verify_wallet_pin(p_user_id character varying, p_pin character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.verify_wallet_pin(p_user_id character varying, p_pin character varying) FROM PUBLIC;


-- Completed on 2026-10-03 12:17:28

--
-- PostgreSQL database dump complete
--

\unrestrict Y9DoR07p2vb0Y3TtE7OpwIKPi5MpCbDbB7ZLBlMjGJ9eGVgAi5sKkJuCZZpJQg8

