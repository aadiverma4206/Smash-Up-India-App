-- ==============================================================================
-- SMASH UP INDIA - POSTGRESQL PERFORMANCE OPTIMIZATION MIGRATION
-- Migration Version: 018_performance_indexes_optimization.sql
-- Description: Targeted indexes for Match Discovery, Login/Auth, CCTV Streaming,
--              Financial Transactions Ledger, Notifications, and Unindexed FKs.
-- Safety: Non-destructive, idempotent (IF NOT EXISTS), zero downtime (CONCURRENTLY).
-- Note: Must be executed OUTSIDE an explicit transaction block (BEGIN...COMMIT).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. AUTH & USER NORMALIZED LOOKUPS (10,000+ Users Scaling)
-- ------------------------------------------------------------------------------
-- Accelerates AuthRepository.findUserByIdentifier and checkIdentityExists when
-- users input 10-digit mobile numbers with or without country codes/formatting.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_phone_10digits
  ON public.users (("right"(regexp_replace((phone)::text, '[^0-9]'::text, ''::text, 'g'::text), 10)))
  WHERE phone IS NOT NULL;

-- ------------------------------------------------------------------------------
-- 2. MATCH DISCOVERY & ROSTER WORKLOADS (GamesRepository.getGames)
-- ------------------------------------------------------------------------------
-- Powers open public match discovery filtering by status, approval, match_date,
-- and start_time, avoiding in-memory sort and sequential scan overhead.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_games_discovery_composite
  ON public.games (status, approval_status, match_date ASC, start_time ASC);

-- Foreign key indexes on games table to prevent share-lock contention & speed joins
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_games_creator_id
  ON public.games (creator_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_games_manager_id
  ON public.games (manager_id)
  WHERE manager_id IS NOT NULL;

-- ------------------------------------------------------------------------------
-- 3. GAME WAITLIST & SLOT REQUESTS (Player & Manager Workloads)
-- ------------------------------------------------------------------------------
-- Speeds up PlayerRepository.getMyMatches('WAITLISTED')
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_game_waitlist_user_id
  ON public.game_waitlist (user_id);

-- Speeds up player slot request lookups and manager review queues
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_game_slot_requests_user_status
  ON public.game_slot_requests (user_id, status);

-- ------------------------------------------------------------------------------
-- 4. FINANCIAL LEDGER & WALLET TRANSACTIONS (Wallet & Razorpay Settlement)
-- ------------------------------------------------------------------------------
-- Critical: wallet_transactions previously lacked user_id and reference_id indexes.
-- Powers get_wallet_transaction_history and prevents full table scans on payment settlement.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wallet_transactions_user_created
  ON public.wallet_transactions (user_id, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_wallet_transactions_reference_id
  ON public.wallet_transactions (reference_id)
  WHERE reference_id IS NOT NULL;

-- ------------------------------------------------------------------------------
-- 5. CCTV SURVEILLANCE & MULTI-CAMERA RECORDINGS
-- ------------------------------------------------------------------------------
-- Accelerates background worker polling for recordings needing auto-stop
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_recordings_status_deadline
  ON public.cctv_recordings (status, stop_deadline)
  WHERE status = 'RECORDING';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_recordings_rec_status
  ON public.cctv_recordings (recording_status)
  WHERE recording_status IN ('RECORDING', 'POST_MATCH');

-- Foreign key indexes on cctv_recordings
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_recordings_game_id
  ON public.cctv_recordings (game_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_recordings_camera_id
  ON public.cctv_recordings (camera_id)
  WHERE camera_id IS NOT NULL;

-- Multi-segment playback joining: speeds up segments join by recording & order
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_segments_recording_order
  ON public.cctv_recording_segments (recording_id, segment_order ASC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_segments_game_id
  ON public.cctv_recording_segments (game_id);

-- CCTV audit events ordering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cctv_events_recording
  ON public.cctv_recording_events (recording_id, event_time DESC);

-- ------------------------------------------------------------------------------
-- 6. TOURNAMENTS & BRACKETS
-- ------------------------------------------------------------------------------
-- Speeds up tournament listings by city and chronological start date
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournaments_city_start
  ON public.tournaments (city, start_date ASC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournaments_start
  ON public.tournaments (start_date ASC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tournament_teams_captain
  ON public.tournament_teams (captain_id);

-- ------------------------------------------------------------------------------
-- 7. NOTIFICATIONS & COMMUNITY FEED
-- ------------------------------------------------------------------------------
-- Speeds up paginated notifications list (NotificationService.getUserNotifications)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC);

-- Speeds up cascading deletions and checks when games are modified
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_game_id
  ON public.notifications (game_id)
  WHERE game_id IS NOT NULL;

-- Speeds up community posts by author
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_community_posts_author
  ON public.community_posts (author_id);

-- ------------------------------------------------------------------------------
-- 8. POST-MIGRATION STATISTICS UPDATE
-- ------------------------------------------------------------------------------
ANALYZE public.users;
ANALYZE public.games;
ANALYZE public.game_waitlist;
ANALYZE public.game_slot_requests;
ANALYZE public.wallet_transactions;
ANALYZE public.cctv_recordings;
ANALYZE public.cctv_recording_segments;
ANALYZE public.cctv_recording_events;
ANALYZE public.tournaments;
ANALYZE public.tournament_teams;
ANALYZE public.notifications;
ANALYZE public.community_posts;
