-- =========================================================================
-- Migration: 025_enforce_court_time_slot_overlap_integrity.sql
-- Description: Enforce 100% strict court time slot non-overlapping rule:
--   - Same court cannot have overlapping bookings/matches on the same date.
--   - Back-to-back bookings (e.g., 2:00-3:00 and 3:00-4:00) ARE permitted.
--   - Different courts (e.g., Court 1 and Court 2) CAN be booked at the exact same time.
--   - Both public.games and public.court_bookings are synchronized and mutually protected.
-- =========================================================================

-- 1. Helper function to normalize court ID strictly to 'court_1' or 'court_2'
CREATE OR REPLACE FUNCTION public.normalize_court_id(p_court VARCHAR)
RETURNS VARCHAR AS $$
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
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. Trigger function to prevent overlapping games / matches
CREATE OR REPLACE FUNCTION public.prevent_court_games_overlap()
RETURNS TRIGGER AS $$
DECLARE
    v_conflict_title VARCHAR;
    v_conflict_start TIME;
    v_conflict_end TIME;
    v_normalized_court VARCHAR;
BEGIN
    -- Normalize court ID
    NEW.court_id := public.normalize_court_id(NEW.court_id);
    v_normalized_court := NEW.court_id;

    -- If the game is cancelled or rejected, it does not occupy the court slot
    IF NEW.status = 'CANCELLED' OR NEW.approval_status = 'REJECTED' THEN
        RETURN NEW;
    END IF;

    -- Basic sanity check: start_time < end_time
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

    -- Check overlap with existing active games on the SAME court and match_date
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

    -- Check overlap with confirmed court bookings on the SAME court and date
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
$$ LANGUAGE plpgsql;

-- 3. Trigger function to prevent overlapping court bookings
CREATE OR REPLACE FUNCTION public.prevent_court_bookings_overlap()
RETURNS TRIGGER AS $$
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

    -- Check overlap with other confirmed court bookings on the SAME court and date
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

    -- Check overlap with existing active games on the SAME court and date
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
$$ LANGUAGE plpgsql;

-- 4. Attach triggers safely
DROP TRIGGER IF EXISTS trg_prevent_court_games_overlap ON public.games;
CREATE TRIGGER trg_prevent_court_games_overlap
    BEFORE INSERT OR UPDATE OF court_id, match_date, start_time, end_time, status, approval_status
    ON public.games
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_court_games_overlap();

DROP TRIGGER IF EXISTS trg_prevent_court_bookings_overlap ON public.court_bookings;
CREATE TRIGGER trg_prevent_court_bookings_overlap
    BEFORE INSERT OR UPDATE OF court_id, booking_date, start_time, end_time, status
    ON public.court_bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_court_bookings_overlap();

-- 5. Safe Covering Indexes for Ultra-Fast Overlap Lookups
CREATE INDEX IF NOT EXISTS idx_games_court_slot_overlap 
    ON public.games(court_id, match_date, start_time, end_time) 
    WHERE status <> 'CANCELLED';

CREATE INDEX IF NOT EXISTS idx_court_bookings_slot_overlap 
    ON public.court_bookings(court_id, booking_date, start_time, end_time) 
    WHERE status = 'CONFIRMED';
