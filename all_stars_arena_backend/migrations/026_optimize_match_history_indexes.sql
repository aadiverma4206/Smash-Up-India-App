-- Migration 026: Performance optimization indexes for Match History & Match Details
-- Speeds up queries across Player, Manager, and Admin modules.

CREATE INDEX IF NOT EXISTS idx_games_history_date_status
  ON public.games (match_date DESC, start_time DESC, status);

CREATE INDEX IF NOT EXISTS idx_games_player_history_lookup
  ON public.games (creator_id, status, match_date DESC);

CREATE INDEX IF NOT EXISTS idx_games_club_history_lookup
  ON public.games (club_id, status, match_date DESC);

CREATE INDEX IF NOT EXISTS idx_game_players_user_game
  ON public.game_players (user_id, game_id);

CREATE INDEX IF NOT EXISTS idx_game_players_game_payment
  ON public.game_players (game_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_game_videos_game_status
  ON public.game_videos (game_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_court_bookings_user_date
  ON public.court_bookings (user_id, booking_date DESC);

CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_created
  ON public.wallet_transactions (user_id, created_at DESC);
