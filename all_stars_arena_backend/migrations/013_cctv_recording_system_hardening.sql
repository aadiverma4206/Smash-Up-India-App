-- 013_cctv_recording_system_hardening.sql
-- Production Hardening for CCTV Cameras, Sessions & Video Segments

-- 1. Extend cctv_cameras with device serial, protocol, connection telemetry & diagnostics
ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS serial_number VARCHAR(128);
ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS protocol VARCHAR(32) DEFAULT 'rtsp';
ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS last_error TEXT;
ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS last_connection_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS last_successful_connection TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_cctv_cameras_club_enabled ON public.cctv_cameras(club_id, is_enabled);
CREATE INDEX IF NOT EXISTS idx_cctv_cameras_court ON public.cctv_cameras(court_id);

-- 2. Extend cctv_recordings with execution tracking, process PID, diagnostics & retry counter
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS error_code VARCHAR(64);
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS error_message TEXT;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS retry_count INT DEFAULT 0;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS ffmpeg_pid INT;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS local_temp_path VARCHAR(512);
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS manual_stop BOOLEAN DEFAULT false;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS playback_status VARCHAR(32) DEFAULT 'PROCESSING';
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS actual_stop_time TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS scheduled_match_end TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS stop_deadline TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS s3_object_key VARCHAR(512);

CREATE INDEX IF NOT EXISTS idx_cctv_recordings_game_status ON public.cctv_recordings(game_id, status);
CREATE INDEX IF NOT EXISTS idx_cctv_recordings_active_deadline ON public.cctv_recordings(status, stop_deadline);

-- 3. Create cctv_recording_segments for durable chunked segment management
CREATE TABLE IF NOT EXISTS public.cctv_recording_segments (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('seg_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    recording_id VARCHAR(64) NOT NULL REFERENCES public.cctv_recordings(id) ON DELETE CASCADE,
    game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    segment_order INT NOT NULL DEFAULT 1,
    s3_object_key VARCHAR(512) NOT NULL,
    local_file_path VARCHAR(512),
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds NUMERIC(10,2) DEFAULT 0 NOT NULL,
    file_size_bytes BIGINT DEFAULT 0 NOT NULL,
    status VARCHAR(32) DEFAULT 'QUEUED' NOT NULL, -- QUEUED, RECORDING, UPLOADING, READY, FAILED
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cctv_segments_rec ON public.cctv_recording_segments(recording_id);
CREATE INDEX IF NOT EXISTS idx_cctv_segments_game ON public.cctv_recording_segments(game_id);
CREATE INDEX IF NOT EXISTS idx_cctv_segments_status ON public.cctv_recording_segments(status);

-- 4. Games lifecycle reason audit columns
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
