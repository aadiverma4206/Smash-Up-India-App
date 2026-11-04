-- Migration: 015_game_players_timestamps.sql
-- Ensure game_players has joined_at, created_at, and updated_at columns

ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Backfill existing rows so created_at and joined_at are synchronized
UPDATE public.game_players SET created_at = joined_at WHERE created_at IS NULL AND joined_at IS NOT NULL;
UPDATE public.game_players SET joined_at = created_at WHERE joined_at IS NULL AND created_at IS NOT NULL;
