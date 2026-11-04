--
-- PostgreSQL database dump
--

\restrict Ak2c6LRC4Q16edo7R6xthrYeRbtosI2pFtegkgMivojlxQ7NKJ8F3IWPmoDfTTj

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-10-31 16:55:52

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
-- TOC entry 6367 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- TOC entry 5 (class 3079 OID 209659)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 6368 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 3 (class 3079 OID 17641)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 6369 (class 0 OID 0)
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
-- TOC entry 6370 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 1259 (class 1247 OID 17686)
-- Name: admin_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.admin_type AS ENUM (
    'SUPER_ADMIN',
    'OPS_ADMIN',
    'FINANCE_ADMIN'
);


ALTER TYPE public.admin_type OWNER TO postgres;

--
-- TOC entry 1295 (class 1247 OID 17832)
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
-- TOC entry 1310 (class 1247 OID 17882)
-- Name: dispute_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.dispute_status AS ENUM (
    'OPEN',
    'RESOLVED',
    'DISMISSED'
);


ALTER TYPE public.dispute_status OWNER TO postgres;

--
-- TOC entry 1262 (class 1247 OID 17694)
-- Name: foot_preference; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.foot_preference AS ENUM (
    'Right',
    'Left',
    'Both'
);


ALTER TYPE public.foot_preference OWNER TO postgres;

--
-- TOC entry 1268 (class 1247 OID 17712)
-- Name: pickle_position; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pickle_position AS ENUM (
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


ALTER TYPE public.pickle_position OWNER TO postgres;

--
-- TOC entry 1283 (class 1247 OID 17786)
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
-- TOC entry 1286 (class 1247 OID 17808)
-- Name: match_privacy; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.match_privacy AS ENUM (
    'PUBLIC',
    'PRIVATE'
);


ALTER TYPE public.match_privacy OWNER TO postgres;

--
-- TOC entry 1289 (class 1247 OID 17814)
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
-- TOC entry 1322 (class 1247 OID 17922)
-- Name: otp_channel; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.otp_channel AS ENUM (
    'SMS',
    'EMAIL',
    'WHATSAPP'
);


ALTER TYPE public.otp_channel OWNER TO postgres;

--
-- TOC entry 1319 (class 1247 OID 17908)
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
-- TOC entry 1280 (class 1247 OID 17780)
-- Name: pitch_environment; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pitch_environment AS ENUM (
    'Indoor',
    'Outdoor'
);


ALTER TYPE public.pitch_environment OWNER TO postgres;

--
-- TOC entry 1274 (class 1247 OID 17762)
-- Name: pitch_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pitch_status AS ENUM (
    'AVAILABLE',
    'BLOCKED',
    'MAINTENANCE'
);


ALTER TYPE public.pitch_status OWNER TO postgres;

--
-- TOC entry 1277 (class 1247 OID 17770)
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
-- TOC entry 1265 (class 1247 OID 17702)
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
-- TOC entry 1292 (class 1247 OID 17826)
-- Name: team_side; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.team_side AS ENUM (
    'TEAM_A',
    'TEAM_B'
);


ALTER TYPE public.team_side OWNER TO postgres;

--
-- TOC entry 1313 (class 1247 OID 17890)
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
-- TOC entry 1316 (class 1247 OID 17900)
-- Name: ticket_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ticket_status AS ENUM (
    'OPEN',
    'ASSIGNED',
    'RESOLVED'
);


ALTER TYPE public.ticket_status OWNER TO postgres;

--
-- TOC entry 1304 (class 1247 OID 17864)
-- Name: tournament_format; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tournament_format AS ENUM (
    'Knockout',
    'Round-Robin'
);


ALTER TYPE public.tournament_format OWNER TO postgres;

--
-- TOC entry 1307 (class 1247 OID 17870)
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
-- TOC entry 1301 (class 1247 OID 17856)
-- Name: transaction_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.transaction_status AS ENUM (
    'PENDING',
    'SUCCESS',
    'FAILED'
);


ALTER TYPE public.transaction_status OWNER TO postgres;

--
-- TOC entry 1298 (class 1247 OID 17844)
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
-- TOC entry 1256 (class 1247 OID 17680)
-- Name: user_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_status AS ENUM (
    'ACTIVE',
    'SUSPENDED'
);


ALTER TYPE public.user_status OWNER TO postgres;

--
-- TOC entry 1271 (class 1247 OID 17752)
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
-- TOC entry 280 (class 1255 OID 18271)
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
-- TOC entry 549 (class 1255 OID 18607)
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


ALTER FUNCTION public.apply_transaction_to_wallet() OWNER TO postgres;

--
-- TOC entry 364 (class 1255 OID 18393)
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
-- TOC entry 606 (class 1255 OID 18864)
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
-- TOC entry 534 (class 1255 OID 19820)
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
-- TOC entry 484 (class 1255 OID 18221)
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
-- TOC entry 306 (class 1255 OID 19704)
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
-- TOC entry 497 (class 1255 OID 18841)
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
-- TOC entry 477 (class 1255 OID 18269)
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
-- TOC entry 512 (class 1255 OID 18178)
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
-- TOC entry 429 (class 1255 OID 18736)
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
-- TOC entry 308 (class 1255 OID 18070)
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
-- TOC entry 362 (class 1255 OID 18069)
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
-- TOC entry 299 (class 1255 OID 213402)
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
-- TOC entry 437 (class 1255 OID 19835)
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
-- TOC entry 602 (class 1255 OID 18468)
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
-- TOC entry 531 (class 1255 OID 18358)
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

          SELECT CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END 
          INTO v_max 
          FROM games 
          WHERE id = NEW.game_id;

          SELECT COUNT(*) INTO v_current_count FROM game_players WHERE game_id = NEW.game_id;

          IF v_current_count >= v_max THEN
              RAISE EXCEPTION 'Game roster is already full (max % players)', v_max;
          END IF;

          RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.enforce_game_player_rules() OWNER TO postgres;

--
-- TOC entry 421 (class 1255 OID 18060)
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
-- TOC entry 471 (class 1255 OID 19834)
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
-- TOC entry 529 (class 1255 OID 18470)
-- Name: finalize_match_result(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.finalize_match_result() RETURNS trigger
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


ALTER FUNCTION public.finalize_match_result() OWNER TO postgres;

--
-- TOC entry 589 (class 1255 OID 19742)
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
-- TOC entry 501 (class 1255 OID 19849)
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
-- TOC entry 342 (class 1255 OID 213403)
-- Name: get_wallet_transaction_history(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_wallet_transaction_history(p_user_id character varying, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0) RETURNS TABLE(id character varying, user_id character varying, transaction_type character varying, amount numeric, balance_after numeric, description text, status character varying, reference_id character varying, provider_payment_id character varying, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
      DECLARE
          v_current_wallet_balance NUMERIC(10,2) := 0.00;
      BEGIN
          SELECT COALESCE(wallet_balance, 0.00) INTO v_current_wallet_balance
          FROM public.player_wallets
          WHERE public.player_wallets.user_id = p_user_id;

          RETURN QUERY
          WITH combined_ledger AS (
              SELECT
                  t.id::VARCHAR(64) as id,
                  t.user_id::VARCHAR(64) as user_id,
                  CASE
                      WHEN UPPER(t.type::TEXT) LIKE '%REFUND%' OR UPPER(t.description) LIKE '%REFUND%' OR UPPER(t.description) LIKE '%CANCEL%' THEN 'REFUND'::VARCHAR(32)
                      WHEN UPPER(t.type::TEXT) IN ('TOPUP', 'WALLET_TOPUP', 'DEPOSIT', 'CREDIT') THEN 'TOPUP'::VARCHAR(32)
                      WHEN UPPER(t.type::TEXT) IN ('PAYMENT', 'DEBIT', 'WITHDRAWAL', 'MATCH_JOIN') THEN 'DEBIT'::VARCHAR(32)
                      ELSE UPPER(t.type::TEXT)::VARCHAR(32)
                  END as transaction_type,
                  t.amount::NUMERIC(10,2) as amount,
                  COALESCE(NULLIF(t.balance_after, 0), v_current_wallet_balance, 0.00)::NUMERIC(10,2) as balance_after,
                  t.description::TEXT as description,
                  t.status::VARCHAR(32) as status,
                  t.reference_id::VARCHAR(128) as reference_id,
                  wt.provider_payment_id::VARCHAR(128) as provider_payment_id,
                  t.created_at as created_at
              FROM public.transactions t
              LEFT JOIN public.wallet_transactions wt ON (wt.id = t.id OR (t.reference_id IS NOT NULL AND wt.reference_id = t.reference_id))
              WHERE t.user_id = p_user_id

              UNION

              SELECT
                  wt.id::VARCHAR(64) as id,
                  wt.user_id::VARCHAR(64) as user_id,
                  CASE
                      WHEN UPPER(wt.transaction_type::TEXT) LIKE '%REFUND%' OR UPPER(wt.description) LIKE '%REFUND%' OR UPPER(wt.description) LIKE '%CANCEL%' THEN 'REFUND'::VARCHAR(32)
                      WHEN UPPER(wt.transaction_type::TEXT) IN ('TOPUP', 'WALLET_TOPUP', 'DEPOSIT', 'CREDIT') THEN 'TOPUP'::VARCHAR(32)
                      WHEN UPPER(wt.transaction_type::TEXT) IN ('PAYMENT', 'DEBIT', 'WITHDRAWAL', 'MATCH_JOIN') THEN 'DEBIT'::VARCHAR(32)
                      ELSE UPPER(wt.transaction_type::TEXT)::VARCHAR(32)
                  END as transaction_type,
                  wt.amount::NUMERIC(10,2) as amount,
                  COALESCE(NULLIF(wt.balance_after, 0), v_current_wallet_balance, 0.00)::NUMERIC(10,2) as balance_after,
                  wt.description::TEXT as description,
                  wt.status::VARCHAR(32) as status,
                  wt.reference_id::VARCHAR(128) as reference_id,
                  wt.provider_payment_id::VARCHAR(128) as provider_payment_id,
                  wt.created_at as created_at
              FROM public.wallet_transactions wt
              WHERE wt.user_id = p_user_id
                AND NOT EXISTS (
                    SELECT 1 FROM public.transactions t2 WHERE t2.id = wt.id OR (wt.reference_id IS NOT NULL AND t2.reference_id = wt.reference_id)
                )

              UNION

              SELECT
                  po.id::VARCHAR(64) as id,
                  po.user_id::VARCHAR(64) as user_id,
                  CASE
                      WHEN po.purpose = 'WALLET_TOPUP' THEN 'TOPUP'::VARCHAR(32)
                      ELSE 'RAZORPAY_BOOKING'::VARCHAR(32)
                  END as transaction_type,
                  (po.amount_paise / 100.0)::NUMERIC(10,2) as amount,
                  v_current_wallet_balance::NUMERIC(10,2) as balance_after,
                  CASE
                      WHEN po.purpose = 'WALLET_TOPUP' THEN 'Wallet Top-Up via Razorpay'
                      ELSE 'Turf Pitch Booking via Razorpay'
                  END as description,
                  po.status::VARCHAR(32) as status,
                  po.id::VARCHAR(128) as reference_id,
                  po.provider_payment_id::VARCHAR(128) as provider_payment_id,
                  po.created_at as created_at
              FROM public.payment_orders po
              WHERE po.user_id = p_user_id
                AND po.status IN ('PAID', 'SUCCESS', 'SETTLED', 'COMPLETED')
                AND NOT EXISTS (
                    SELECT 1 FROM public.transactions t3 WHERE t3.reference_id = po.id OR t3.id = po.id
                )
                AND NOT EXISTS (
                    SELECT 1 FROM public.wallet_transactions wt3 WHERE wt3.reference_id = po.id OR wt3.id = po.id
                )
          )
          SELECT * FROM combined_ledger
          ORDER BY created_at DESC
          LIMIT p_limit OFFSET p_offset;
      END;
      $$;


ALTER FUNCTION public.get_wallet_transaction_history(p_user_id character varying, p_limit integer, p_offset integer) OWNER TO postgres;

--
-- TOC entry 431 (class 1255 OID 18609)
-- Name: grant_welcome_bonus(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.grant_welcome_bonus() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Disabled permanently: No bonus amount to be given to players
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.grant_welcome_bonus() OWNER TO postgres;

--
-- TOC entry 524 (class 1255 OID 18103)
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
-- TOC entry 625 (class 1255 OID 210793)
-- Name: join_game_with_wallet(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position character varying DEFAULT 'MID'::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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
              v_assigned_team := 'TEAM_A'::public.team_side;
          ELSE
              v_assigned_team := 'TEAM_B'::public.team_side;
          END IF;

          INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
          VALUES (p_game_id, p_user_id, v_assigned_team, UPPER(p_position)::public.pickle_position, 'PAID')
          RETURNING id INTO v_roster_id;

          IF v_current_count + 1 >= v_max_players THEN
              UPDATE public.games SET status = 'FULL', updated_at = CURRENT_TIMESTAMP WHERE id = p_game_id;
          END IF;

          RETURN v_roster_id;
      END;
      $$;


ALTER FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position character varying) OWNER TO postgres;

--
-- TOC entry 426 (class 1255 OID 19860)
-- Name: join_game_with_wallet(character varying, character varying, public.pickle_position); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position public.pickle_position) RETURNS bigint
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


ALTER FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position public.pickle_position) OWNER TO postgres;

--
-- TOC entry 575 (class 1255 OID 19746)
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
-- TOC entry 370 (class 1255 OID 19745)
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
-- TOC entry 463 (class 1255 OID 211711)
-- Name: normalize_court_id(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.normalize_court_id(p_court character varying) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      BEGIN
          IF p_court IS NULL OR TRIM(p_court) = '' THEN
              RETURN 'court_1';
          END IF;
          IF LOWER(p_court) ILIKE '%2%' THEN
              RETURN 'court_2';
          ELSE
              RETURN 'court_1';
          END IF;
      END;
      $$;


ALTER FUNCTION public.normalize_court_id(p_court character varying) OWNER TO postgres;

--
-- TOC entry 397 (class 1255 OID 211713)
-- Name: prevent_court_bookings_overlap(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_court_bookings_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
          v_conflict_title VARCHAR;
          v_conflict_start TIME;
          v_conflict_end TIME;
          v_normalized_court VARCHAR;
      BEGIN
          NEW.court_id := public.normalize_court_id(NEW.court_id);
          v_normalized_court := NEW.court_id;

          IF NEW.status <> 'CONFIRMED' THEN
              RETURN NEW;
          END IF;

          IF NEW.end_time <= NEW.start_time THEN
              RAISE EXCEPTION 'Booking end time (%) must be strictly after start time (%)', NEW.end_time, NEW.start_time
                  USING ERRCODE = '22000';
          END IF;

          -- Enforce: cannot book in the past
          IF (TG_OP = 'INSERT' OR NEW.booking_date <> OLD.booking_date OR NEW.start_time <> OLD.start_time) THEN
              IF (NEW.booking_date + NEW.start_time) < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata' - INTERVAL '2 minutes') THEN
                  RAISE EXCEPTION 'Cannot book a court slot in the past. Booking date (%) and start time (%) have already passed. Please select a future date and time.',
                      NEW.booking_date, NEW.start_time
                      USING ERRCODE = '22000';
              END IF;
          END IF;

          SELECT 'Turf Booking', start_time, end_time
          INTO v_conflict_title, v_conflict_start, v_conflict_end
          FROM public.court_bookings
          WHERE court_id = v_normalized_court
            AND booking_date = NEW.booking_date
            AND status = 'CONFIRMED'
            AND (id <> NEW.id OR NEW.id IS NULL)
            AND (start_time < NEW.end_time AND end_time > NEW.start_time)
          LIMIT 1;

          IF FOUND THEN
              RAISE EXCEPTION 'Court % is already booked from % to % on %. Overlapping time slots are not permitted on the same court. Please choose another time or switch to another court.',
                  v_normalized_court, v_conflict_start, v_conflict_end, NEW.booking_date
                  USING ERRCODE = '23505';
          END IF;

          SELECT title, start_time, end_time
          INTO v_conflict_title, v_conflict_start, v_conflict_end
          FROM public.games
          WHERE court_id = v_normalized_court
            AND match_date = NEW.booking_date
            AND status <> 'CANCELLED'
            AND approval_status <> 'REJECTED'
            AND (start_time < NEW.end_time AND end_time > NEW.start_time)
          LIMIT 1;

          IF FOUND THEN
              RAISE EXCEPTION 'Court % is already booked for match "%" from % to % on %. Overlapping time slots are not permitted on the same court. Please choose another time or switch to another court.',
                  v_normalized_court, v_conflict_title, v_conflict_start, v_conflict_end, NEW.booking_date
                  USING ERRCODE = '23505';
          END IF;

          RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.prevent_court_bookings_overlap() OWNER TO postgres;

--
-- TOC entry 516 (class 1255 OID 211712)
-- Name: prevent_court_games_overlap(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_court_games_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
          v_conflict_title VARCHAR;
          v_conflict_start TIME;
          v_conflict_end TIME;
          v_normalized_court VARCHAR;
      BEGIN
          NEW.court_id := public.normalize_court_id(NEW.court_id);
          v_normalized_court := NEW.court_id;

          IF NEW.status = 'CANCELLED' OR NEW.approval_status = 'REJECTED' THEN
              RETURN NEW;
          END IF;

          IF NEW.end_time <= NEW.start_time THEN
              RAISE EXCEPTION 'Match end time (%) must be strictly after start time (%)', NEW.end_time, NEW.start_time
                  USING ERRCODE = '22000';
          END IF;

          -- Enforce: cannot book or reschedule a slot in the past
          IF (TG_OP = 'INSERT' OR NEW.match_date <> OLD.match_date OR NEW.start_time <> OLD.start_time) THEN
              IF (NEW.match_date + NEW.start_time) < (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata' - INTERVAL '2 minutes') THEN
                  RAISE EXCEPTION 'Cannot book a court slot in the past. Match date (%) and start time (%) have already passed. Please select a future date and time.',
                      NEW.match_date, NEW.start_time
                      USING ERRCODE = '22000';
              END IF;
          END IF;

          SELECT title, start_time, end_time
          INTO v_conflict_title, v_conflict_start, v_conflict_end
          FROM public.games
          WHERE court_id = v_normalized_court
            AND match_date = NEW.match_date
            AND status <> 'CANCELLED'
            AND approval_status <> 'REJECTED'
            AND (id <> NEW.id OR NEW.id IS NULL)
            AND (start_time < NEW.end_time AND end_time > NEW.start_time)
          LIMIT 1;

          IF FOUND THEN
              RAISE EXCEPTION 'Court % is already booked for "%" from % to % on %. Overlapping time slots are not permitted on the same court. Please choose another time or switch to another court.',
                  v_normalized_court, v_conflict_title, v_conflict_start, v_conflict_end, NEW.match_date
                  USING ERRCODE = '23505';
          END IF;

          SELECT 'Turf Booking', start_time, end_time
          INTO v_conflict_title, v_conflict_start, v_conflict_end
          FROM public.court_bookings
          WHERE court_id = v_normalized_court
            AND booking_date = NEW.match_date
            AND status = 'CONFIRMED'
            AND (start_time < NEW.end_time AND end_time > NEW.start_time)
          LIMIT 1;

          IF FOUND THEN
              RAISE EXCEPTION 'Court % is already booked from % to % on %. Overlapping time slots are not permitted on the same court. Please choose another time or switch to another court.',
                  v_normalized_court, v_conflict_start, v_conflict_end, NEW.match_date
                  USING ERRCODE = '23505';
          END IF;

          RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.prevent_court_games_overlap() OWNER TO postgres;

--
-- TOC entry 519 (class 1255 OID 18936)
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
-- TOC entry 611 (class 1255 OID 19676)
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
-- TOC entry 500 (class 1255 OID 18395)
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
-- TOC entry 618 (class 1255 OID 17939)
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
-- TOC entry 496 (class 1255 OID 18940)
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
-- TOC entry 384 (class 1255 OID 18938)
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
-- TOC entry 355 (class 1255 OID 18066)
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
-- TOC entry 558 (class 1255 OID 18064)
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
-- TOC entry 378 (class 1255 OID 19744)
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
-- TOC entry 537 (class 1255 OID 19743)
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
-- TOC entry 391 (class 1255 OID 19741)
-- Name: register_player(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.register_player(p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_city character varying DEFAULT 'Raipur'::character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.register_player(p_name character varying, p_email character varying, p_phone character varying, p_password_hash character varying, p_city character varying) OWNER TO postgres;

--
-- TOC entry 533 (class 1255 OID 18781)
-- Name: reward_completed_challenge(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reward_completed_challenge() RETURNS trigger
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


ALTER FUNCTION public.reward_completed_challenge() OWNER TO postgres;

--
-- TOC entry 453 (class 1255 OID 17929)
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
-- TOC entry 587 (class 1255 OID 19828)
-- Name: set_wallet_pin(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_wallet_pin(p_user_id character varying, p_pin character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
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
      $_$;


ALTER FUNCTION public.set_wallet_pin(p_user_id character varying, p_pin character varying) OWNER TO postgres;

--
-- TOC entry 528 (class 1255 OID 19824)
-- Name: settle_wallet_payment(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.settle_wallet_payment(p_payment_order_id character varying, p_provider_payment_id character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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


ALTER FUNCTION public.settle_wallet_payment(p_payment_order_id character varying, p_provider_payment_id character varying) OWNER TO postgres;

--
-- TOC entry 541 (class 1255 OID 18328)
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
-- TOC entry 492 (class 1255 OID 52735)
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
-- TOC entry 583 (class 1255 OID 18360)
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
          SELECT CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END, status 
          INTO v_max, v_status 
          FROM games 
          WHERE id = v_game_id;

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
-- TOC entry 458 (class 1255 OID 18738)
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
-- TOC entry 316 (class 1255 OID 18656)
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
-- TOC entry 585 (class 1255 OID 18544)
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
-- TOC entry 562 (class 1255 OID 19829)
-- Name: verify_wallet_pin(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_wallet_pin(p_user_id character varying, p_pin character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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

          -- Check if currently locked
          IF v_locked_until IS NOT NULL AND v_locked_until > CURRENT_TIMESTAMP THEN
              RAISE EXCEPTION 'WALLET_PIN_LOCKED';
          END IF;

          -- Validate format
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

          -- Compare hash
          IF v_hash = crypt(p_pin, v_hash) THEN
              -- Success: reset failed attempts
              UPDATE public.player_wallets
              SET wallet_pin_failed_attempts = 0,
                  wallet_pin_locked_until = NULL,
                  updated_at = CURRENT_TIMESTAMP
              WHERE user_id = p_user_id;
              RETURN TRUE;
          ELSE
              -- Failed: increment attempts and lock after 5
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
      $_$;


ALTER FUNCTION public.verify_wallet_pin(p_user_id character varying, p_pin character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 229 (class 1259 OID 17985)
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
-- TOC entry 262 (class 1259 OID 18844)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    admin_id character varying(64),
    admin_name character varying(120) NOT NULL,
    action character varying(64) NOT NULL,
    target character varying(150) NOT NULL,
    details text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    user_id character varying(64),
    ip_address character varying(64)
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 18843)
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
-- TOC entry 6378 (class 0 OID 0)
-- Dependencies: 261
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- TOC entry 270 (class 1259 OID 19864)
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
    created_by character varying(64),
    serial_number character varying(128),
    protocol character varying(32) DEFAULT 'rtsp'::character varying,
    last_error text,
    last_connection_at timestamp with time zone,
    last_successful_connection timestamp with time zone
);


ALTER TABLE public.cctv_cameras OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 19931)
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
-- TOC entry 277 (class 1259 OID 175652)
-- Name: cctv_recording_segments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cctv_recording_segments (
    id character varying(64) DEFAULT ('seg_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    recording_id character varying(64) NOT NULL,
    game_id character varying(64) NOT NULL,
    segment_order integer DEFAULT 1 NOT NULL,
    s3_object_key character varying(512),
    local_file_path character varying(512),
    start_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_time timestamp with time zone,
    duration_seconds numeric(10,2) DEFAULT 0 NOT NULL,
    file_size_bytes bigint DEFAULT 0 NOT NULL,
    status character varying(32) DEFAULT 'QUEUED'::character varying NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.cctv_recording_segments OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 19893)
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
    scheduled_match_end_at timestamp with time zone,
    storage_object_key character varying(512),
    started_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    actual_stopped_at timestamp with time zone,
    duration_seconds integer DEFAULT 5400,
    error_code character varying(64),
    error_message text,
    retry_count integer DEFAULT 0,
    ffmpeg_pid integer,
    local_temp_path character varying(512),
    manual_stop boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    playback_status character varying(32) DEFAULT 'PROCESSING'::character varying,
    storage_bucket character varying(128) DEFAULT 'smash-up-india-recordings'::character varying
);


ALTER TABLE public.cctv_recordings OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 18759)
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
-- TOC entry 257 (class 1259 OID 18740)
-- Name: challenges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.challenges (
    id character varying(64) DEFAULT ('ch_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    title character varying(150) NOT NULL,
    description text NOT NULL,
    target_count integer DEFAULT 5 NOT NULL,
    reward_badge character varying(64) NOT NULL,
    reward_wallet_bonus numeric(8,2) DEFAULT 0.00 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT challenges_reward_wallet_bonus_check CHECK (((reward_wallet_bonus >= (0)::numeric) AND (reward_wallet_bonus <= (350)::numeric))),
    CONSTRAINT challenges_target_count_check CHECK ((target_count > 0))
);


ALTER TABLE public.challenges OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 18160)
-- Name: club_managers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.club_managers (
    club_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.club_managers OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 18126)
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
-- TOC entry 251 (class 1259 OID 18611)
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
-- TOC entry 238 (class 1259 OID 18222)
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
-- TOC entry 237 (class 1259 OID 18180)
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
-- TOC entry 274 (class 1259 OID 28192)
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
-- TOC entry 241 (class 1259 OID 18331)
-- Name: game_players; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_players (
    id bigint NOT NULL,
    game_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    team public.team_side NOT NULL,
    "position" public.pickle_position DEFAULT 'MID'::public.pickle_position NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    payment_status character varying(32) DEFAULT 'PAID'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    payment_method character varying(32) DEFAULT 'WALLET'::character varying,
    payment_reference character varying(128),
    refund_status character varying(32) DEFAULT 'NOT_REFUNDED'::character varying,
    refund_reference character varying(128),
    refund_amount numeric(10,2) DEFAULT 0.00,
    refunded_at timestamp with time zone
);


ALTER TABLE public.game_players OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 18330)
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
-- TOC entry 6379 (class 0 OID 0)
-- Dependencies: 240
-- Name: game_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.game_players_id_seq OWNED BY public.game_players.id;


--
-- TOC entry 273 (class 1259 OID 28159)
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
-- TOC entry 264 (class 1259 OID 18897)
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    cctv_id character varying(64)
);


ALTER TABLE public.game_videos OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 18363)
-- Name: game_waitlist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.game_waitlist (
    id bigint NOT NULL,
    game_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    team_preference public.team_side,
    "position" public.pickle_position DEFAULT 'MID'::public.pickle_position NOT NULL,
    waitlist_order integer DEFAULT 1 NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT game_waitlist_waitlist_order_check CHECK ((waitlist_order > 0))
);


ALTER TABLE public.game_waitlist OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 18362)
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
-- TOC entry 6380 (class 0 OID 0)
-- Dependencies: 242
-- Name: game_waitlist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.game_waitlist_id_seq OWNED BY public.game_waitlist.id;


--
-- TOC entry 239 (class 1259 OID 18273)
-- Name: games; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.games (
    id character varying(64) DEFAULT ('gam_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    title character varying(200) NOT NULL,
    court_id character varying(64),
    creator_id character varying(64) NOT NULL,
    creator_role_name character varying(32) NOT NULL,
    created_by_player boolean DEFAULT true NOT NULL,
    format public.match_format DEFAULT '11v11'::public.match_format NOT NULL,
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
    approval_status character varying(32) DEFAULT 'APPROVED'::character varying,
    rejection_reason text,
    manager_id character varying(64),
    cancellation_reason text,
    video_playback_url character varying(512),
    entry_fee numeric(10,2) DEFAULT 200.00 NOT NULL,
    club_id character varying(64) DEFAULT 'smash_up_india_club'::character varying,
    per_player_fee numeric(10,2) DEFAULT 0.00,
    CONSTRAINT chk_game_times CHECK ((end_time > start_time)),
    CONSTRAINT games_approval_status_check CHECK (((approval_status)::text = ANY ((ARRAY['PENDING_APPROVAL'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying])::text[]))),
    CONSTRAINT games_entry_fee_check CHECK ((entry_fee >= (0)::numeric)),
    CONSTRAINT games_team_a_score_check CHECK (((team_a_score IS NULL) OR (team_a_score >= 0))),
    CONSTRAINT games_team_b_score_check CHECK (((team_b_score IS NULL) OR (team_b_score >= 0)))
);


ALTER TABLE public.games OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 18398)
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
-- TOC entry 244 (class 1259 OID 18397)
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
-- TOC entry 6381 (class 0 OID 0)
-- Dependencies: 244
-- Name: live_score_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.live_score_logs_id_seq OWNED BY public.live_score_logs.id;


--
-- TOC entry 230 (class 1259 OID 18007)
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
-- TOC entry 259 (class 1259 OID 18783)
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
-- TOC entry 263 (class 1259 OID 18867)
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    body text,
    type character varying(64) DEFAULT 'SYSTEM'::character varying,
    data jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 18072)
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
-- TOC entry 232 (class 1259 OID 18071)
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
-- TOC entry 6382 (class 0 OID 0)
-- Dependencies: 232
-- Name: otp_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.otp_verifications_id_seq OWNED BY public.otp_verifications.id;


--
-- TOC entry 267 (class 1259 OID 19755)
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
    CONSTRAINT payment_orders_purpose_check CHECK (((purpose)::text = ANY ((ARRAY['WALLET_TOPUP'::character varying, 'MATCH_JOIN'::character varying, 'MATCH_CREATION'::character varying])::text[]))),
    CONSTRAINT payment_orders_status_check CHECK (((status)::text = ANY ((ARRAY['CREATED'::character varying, 'PENDING'::character varying, 'PAID'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying, 'REFUNDED'::character varying, 'EXPIRED'::character varying])::text[])))
);


ALTER TABLE public.payment_orders OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 19798)
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
-- TOC entry 268 (class 1259 OID 19797)
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
-- TOC entry 6383 (class 0 OID 0)
-- Dependencies: 268
-- Name: payment_webhook_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_webhook_events_id_seq OWNED BY public.payment_webhook_events.id;


--
-- TOC entry 231 (class 1259 OID 18026)
-- Name: player_wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_wallets (
    user_id character varying(64) CONSTRAINT player_details_user_id_not_null NOT NULL,
    wallet_balance numeric(12,2) DEFAULT 0.00 CONSTRAINT player_details_wallet_balance_not_null NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    wallet_pin_hash character varying(255),
    wallet_pin_set_at timestamp with time zone,
    wallet_pin_failed_attempts integer DEFAULT 0 CONSTRAINT player_details_wallet_pin_failed_attempts_not_null NOT NULL,
    wallet_pin_locked_until timestamp with time zone,
    CONSTRAINT player_details_wallet_balance_check CHECK (((wallet_balance >= (0)::numeric) AND (wallet_balance <= 200000.00)))
);


ALTER TABLE public.player_wallets OWNER TO postgres;

--
-- TOC entry 6384 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN player_wallets.wallet_pin_hash; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.player_wallets.wallet_pin_hash IS 'bcrypt hash (via pgcrypto crypt/gen_salt) of the player''s 6-digit wallet PIN. NULL until they set one. Never store the raw PIN anywhere.';


--
-- TOC entry 279 (class 1259 OID 211370)
-- Name: player_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.player_details AS
 SELECT user_id,
    wallet_balance,
    created_at,
    updated_at,
    wallet_pin_hash,
    wallet_pin_set_at,
    wallet_pin_failed_attempts,
    wallet_pin_locked_until
   FROM public.player_wallets;


ALTER VIEW public.player_details OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 101896)
-- Name: player_match_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player_match_results (
    id character varying(64) DEFAULT ('pmr_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    game_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    team public.team_side NOT NULL,
    goals_scored integer DEFAULT 0 NOT NULL,
    assists integer DEFAULT 0 NOT NULL,
    rating numeric(3,1) DEFAULT 7.0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.player_match_results OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 18427)
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
-- TOC entry 255 (class 1259 OID 18695)
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
-- TOC entry 256 (class 1259 OID 18712)
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
-- TOC entry 254 (class 1259 OID 18683)
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
-- TOC entry 253 (class 1259 OID 18658)
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
-- TOC entry 252 (class 1259 OID 18638)
-- Name: post_likes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_likes (
    post_id character varying(64) NOT NULL,
    user_id character varying(64) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.post_likes OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 17930)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id smallint NOT NULL,
    role_name character varying(32) NOT NULL,
    description character varying(255)
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 18811)
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
-- TOC entry 249 (class 1259 OID 18546)
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
-- TOC entry 248 (class 1259 OID 18513)
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
-- TOC entry 247 (class 1259 OID 18472)
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
-- TOC entry 250 (class 1259 OID 18581)
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
    reference_id character varying(128),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_topup_max CHECK (((type <> 'WALLET_TOPUP'::public.transaction_type) OR (amount <= 50000.00))),
    CONSTRAINT transactions_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT transactions_balance_after_check CHECK (((balance_after >= (0)::numeric) AND (balance_after <= 200000.00)))
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 209629)
-- Name: user_device_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_device_tokens (
    id character varying(64) DEFAULT ('dev_'::text || substr(md5(((random())::text || (clock_timestamp())::text)), 1, 16)) NOT NULL,
    user_id character varying(64) NOT NULL,
    device_token text NOT NULL,
    device_type character varying(32) DEFAULT 'ANDROID'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_device_tokens OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 19716)
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
-- TOC entry 265 (class 1259 OID 19715)
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
-- TOC entry 6385 (class 0 OID 0)
-- Dependencies: 265
-- Name: user_identity_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_identity_history_id_seq OWNED BY public.user_identity_history.id;


--
-- TOC entry 234 (class 1259 OID 18105)
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
-- TOC entry 228 (class 1259 OID 17942)
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
-- TOC entry 275 (class 1259 OID 77311)
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
    reference_id character varying(128),
    provider_payment_id character varying(128),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.wallet_transactions OWNER TO postgres;

--
-- TOC entry 5692 (class 2604 OID 18847)
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- TOC entry 5617 (class 2604 OID 18334)
-- Name: game_players id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_players ALTER COLUMN id SET DEFAULT nextval('public.game_players_id_seq'::regclass);


--
-- TOC entry 5626 (class 2604 OID 18366)
-- Name: game_waitlist id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_waitlist ALTER COLUMN id SET DEFAULT nextval('public.game_waitlist_id_seq'::regclass);


--
-- TOC entry 5630 (class 2604 OID 18401)
-- Name: live_score_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_score_logs ALTER COLUMN id SET DEFAULT nextval('public.live_score_logs_id_seq'::regclass);


--
-- TOC entry 5572 (class 2604 OID 18075)
-- Name: otp_verifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_verifications ALTER COLUMN id SET DEFAULT nextval('public.otp_verifications_id_seq'::regclass);


--
-- TOC entry 5712 (class 2604 OID 19801)
-- Name: payment_webhook_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_webhook_events ALTER COLUMN id SET DEFAULT nextval('public.payment_webhook_events_id_seq'::regclass);


--
-- TOC entry 5702 (class 2604 OID 19719)
-- Name: user_identity_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_identity_history ALTER COLUMN id SET DEFAULT nextval('public.user_identity_history_id_seq'::regclass);


--
-- TOC entry 6312 (class 0 OID 17985)
-- Dependencies: 229
-- Data for Name: admin_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_details (user_id, admin_type, is_owner, designation, created_by_admin_id, created_at) FROM stdin;
usr_e55abb463db8392d	SUPER_ADMIN	t	Super Admin	\N	2026-09-29 15:20:21.207044+05:30
\.

