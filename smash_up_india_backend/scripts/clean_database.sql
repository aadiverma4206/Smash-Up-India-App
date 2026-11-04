-- =========================================================================
-- DATABASE CLEANUP SCRIPT: SMASH UP INDIA
-- =========================================================================
-- Keeps:
--   1. roles table (ALL roles: ADMIN, MANAGER, PLAYER)
--   2. courts table (court_1, court_2)
--   3. users table: ONLY 3 login demo users:
--      - Player:  player@gmail.com (Password: Player@123)
--      - Manager: roshan12@gmail.com (Password: Roshan@123)
--      - Admin:   aadiverma4206@gmail.com (Password: Admin@123)
--   4. User profile records (player_details, player_stats, manager_details, admin_details)
--   5. Club 'smash_up_india_club' (required by foreign key on courts) & club_managers
--
-- Clears data from all other tables while preserving full table schemas.
-- =========================================================================

BEGIN;

-- 1. Temporarily bypass mutation-blocking triggers (e.g. audit_logs, transactions, users delete prevention)
SET session_replication_role = 'replica';

-- 2. Clear all activity, transactional, and dynamic tables
DELETE FROM public.audit_logs;
DELETE FROM public.cctv_recording_segments;
DELETE FROM public.cctv_recording_events;
DELETE FROM public.cctv_recordings;
DELETE FROM public.cctv_cameras;
DELETE FROM public.challenge_progress;
DELETE FROM public.challenges;
DELETE FROM public.community_posts;
DELETE FROM public.post_comments;
DELETE FROM public.post_likes;
DELETE FROM public.poll_votes;
DELETE FROM public.poll_options;
DELETE FROM public.polls;
DELETE FROM public.game_activity_logs;
DELETE FROM public.live_score_logs;
DELETE FROM public.match_disputes;
DELETE FROM public.player_match_results;
DELETE FROM public.game_videos;
DELETE FROM public.game_waitlist;
DELETE FROM public.game_slot_requests;
DELETE FROM public.game_players;
DELETE FROM public.games;
DELETE FROM public.court_bookings;
DELETE FROM public.tournament_bracket_matches;
DELETE FROM public.tournament_teams;
DELETE FROM public.tournaments;
DELETE FROM public.payment_webhook_events;
DELETE FROM public.payment_orders;
DELETE FROM public.wallet_transactions;
DELETE FROM public.transactions;
DELETE FROM public.notifications;
DELETE FROM public.otp_verifications;
DELETE FROM public.support_tickets;
DELETE FROM public.user_device_tokens;
DELETE FROM public.user_identity_history;
DELETE FROM public.user_sessions;

-- 3. Delete non-target profiles
DELETE FROM public.player_stats 
WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'player@gmail.com');

DELETE FROM public.player_wallets 
WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'player@gmail.com');

UPDATE public.player_wallets SET wallet_balance = 0.00;

DELETE FROM public.manager_details 
WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'roshan12@gmail.com');

DELETE FROM public.admin_details 
WHERE user_id NOT IN (SELECT id FROM public.users WHERE email = 'aadiverma4206@gmail.com');

-- 4. Clean clubs and club_managers, preserving only 'smash_up_india_club' for courts
DELETE FROM public.club_managers 
WHERE club_id <> 'smash_up_india_club' 
   OR user_id NOT IN (SELECT id FROM public.users WHERE email = 'roshan12@gmail.com');

DELETE FROM public.clubs 
WHERE id <> 'smash_up_india_club';

-- 5. Delete all other users except the 3 login demo users
DELETE FROM public.users 
WHERE email NOT IN (
    'player@gmail.com',
    'roshan12@gmail.com',
    'aadiverma4206@gmail.com'
);

-- 6. Restore normal trigger execution
SET session_replication_role = 'origin';

COMMIT;
