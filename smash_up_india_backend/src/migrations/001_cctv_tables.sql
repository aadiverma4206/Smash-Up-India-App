-- CCTV Cameras Table
CREATE TABLE IF NOT EXISTS public.cctv_cameras (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('cam_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    club_id VARCHAR(64) NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    court_id VARCHAR(64) REFERENCES public.courts(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    rtsp_url_encrypted TEXT NOT NULL,
    ip_address VARCHAR(64),
    port INTEGER DEFAULT 554,
    is_enabled BOOLEAN DEFAULT true NOT NULL,
    status VARCHAR(32) DEFAULT 'ONLINE' NOT NULL,
    last_health_check_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- CCTV Recordings Table
CREATE TABLE IF NOT EXISTS public.cctv_recordings (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('rec_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    club_id VARCHAR(64) NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    court_id VARCHAR(64) REFERENCES public.courts(id) ON DELETE SET NULL,
    camera_id VARCHAR(64) REFERENCES public.cctv_cameras(id) ON DELETE SET NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    scheduled_match_end TIMESTAMP WITH TIME ZONE NOT NULL,
    stop_deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_stop_time TIMESTAMP WITH TIME ZONE,
    s3_object_key VARCHAR(512),
    status VARCHAR(32) DEFAULT 'RECORDING' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cctv_cameras_club ON public.cctv_cameras(club_id);
CREATE INDEX IF NOT EXISTS idx_cctv_cameras_court ON public.cctv_cameras(court_id);
CREATE INDEX IF NOT EXISTS idx_cctv_recordings_game ON public.cctv_recordings(game_id);
