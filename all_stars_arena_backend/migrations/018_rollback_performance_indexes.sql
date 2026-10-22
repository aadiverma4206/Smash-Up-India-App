-- ==============================================================================
-- ALL STARS ARENA - POSTGRESQL 18 ROLLBACK SCRIPT FOR MIGRATION 018
-- Script: 018_rollback_performance_indexes.sql
-- Description: Safely drops newly created performance indexes without touching
--              any primary keys, unique constraints, foreign keys, tables or data.
-- Safety: Idempotent (IF EXISTS), zero-downtime (CONCURRENTLY).
-- Note: Must be executed OUTSIDE an explicit transaction block (BEGIN...COMMIT).
-- ==============================================================================

-- 1. Rollback Auth & User index
DROP INDEX CONCURRENTLY IF EXISTS public.idx_users_phone_10digits;

-- 2. Rollback Match Discovery & Games FK indexes
DROP INDEX CONCURRENTLY IF EXISTS public.idx_games_discovery_composite;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_games_creator_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_games_manager_id;

-- 3. Rollback Game Waitlist & Slot Requests indexes
DROP INDEX CONCURRENTLY IF EXISTS public.idx_game_waitlist_user_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_game_slot_requests_user_status;

-- 4. Rollback Financial Ledger & Wallet Transactions indexes
DROP INDEX CONCURRENTLY IF EXISTS public.idx_wallet_transactions_user_created;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_wallet_transactions_reference_id;

-- 5. Rollback CCTV Surveillance indexes
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_recordings_status_deadline;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_recordings_rec_status;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_recordings_game_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_recordings_camera_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_segments_recording_order;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_segments_game_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_cctv_events_recording;

-- 6. Rollback Tournaments & Teams indexes
DROP INDEX CONCURRENTLY IF EXISTS public.idx_tournaments_city_start;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_tournaments_start;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_tournament_teams_captain;

-- 7. Rollback Notifications & Community Feed indexes
DROP INDEX CONCURRENTLY IF EXISTS public.idx_notifications_user_created;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_notifications_game_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_community_posts_author;

-- 8. Refresh table statistics
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
