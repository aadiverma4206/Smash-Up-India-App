-- Add optional ₹100 CCTV video recording add-on columns to games and court_bookings
ALTER TABLE public.games
  ADD COLUMN IF NOT EXISTS cctv_recording_enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS cctv_recording_fee NUMERIC(10,2) NOT NULL DEFAULT 0.00;

ALTER TABLE public.court_bookings
  ADD COLUMN IF NOT EXISTS cctv_recording_enabled BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS cctv_recording_fee NUMERIC(10,2) NOT NULL DEFAULT 0.00;
