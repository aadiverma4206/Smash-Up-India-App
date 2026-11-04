-- 007_cctv_cameras.sql
CREATE TABLE IF NOT EXISTS public.cctv_cameras (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('cam_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
    club_id VARCHAR(64) NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    court_id VARCHAR(64) REFERENCES public.courts(id) ON DELETE SET NULL,
    name VARCHAR(150) NOT NULL,
    camera_type VARCHAR(32) DEFAULT 'RTSP_DOME' NOT NULL,
    connection_type VARCHAR(32) DEFAULT 'RTSP' NOT NULL,
    encrypted_connection_reference TEXT NOT NULL,
    stream_reference VARCHAR(255),
    is_enabled BOOLEAN DEFAULT true NOT NULL,
    health_status VARCHAR(32) DEFAULT 'ONLINE' NOT NULL, -- IDLE, ONLINE, OFFLINE, RECORDING, ERROR
    last_seen_at TIMESTAMP WITH TIME ZONE,
    created_by VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cctv_cameras_club ON public.cctv_cameras(club_id);
CREATE INDEX IF NOT EXISTS idx_cctv_cameras_court ON public.cctv_cameras(court_id);
