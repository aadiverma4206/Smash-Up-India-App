-- 008_cctv_recordings.sql
CREATE TABLE IF NOT EXISTS public.cctv_recordings (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('rec_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    club_id VARCHAR(64) NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    court_id VARCHAR(64) REFERENCES public.courts(id) ON DELETE SET NULL,
    camera_id VARCHAR(64) REFERENCES public.cctv_cameras(id) ON DELETE SET NULL,
    recording_status VARCHAR(32) DEFAULT 'STARTING' NOT NULL, -- IDLE, STARTING, RECORDING, POST_MATCH, STOPPING, COMPLETED, FAILED, STOPPED_MANUALLY
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    scheduled_match_end_at TIMESTAMP WITH TIME ZONE NOT NULL,
    post_match_stop_at TIMESTAMP WITH TIME ZONE NOT NULL, -- scheduled_match_end_at + 15m
    actual_stopped_at TIMESTAMP WITH TIME ZONE,
    manual_stop BOOLEAN DEFAULT false NOT NULL,
    storage_provider VARCHAR(32) DEFAULT 'S3' NOT NULL,
    storage_bucket VARCHAR(128) NOT NULL,
    storage_object_key VARCHAR(512) NOT NULL,
    duration_seconds INT DEFAULT 0 NOT NULL,
    playback_status VARCHAR(32) DEFAULT 'PROCESSING' NOT NULL, -- PROCESSING, READY, FAILED
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cctv_recordings_game ON public.cctv_recordings(game_id);
CREATE INDEX IF NOT EXISTS idx_cctv_recordings_club ON public.cctv_recordings(club_id);
CREATE INDEX IF NOT EXISTS idx_cctv_recordings_status ON public.cctv_recordings(recording_status);
