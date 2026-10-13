-- 014_game_videos_cctv_id.sql
-- Add cctv_id to public.game_videos for multi-camera CCTV footage cataloging

ALTER TABLE public.game_videos 
ADD COLUMN IF NOT EXISTS cctv_id VARCHAR(64) REFERENCES public.cctv_cameras(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_game_videos_cctv_id ON public.game_videos(cctv_id);
CREATE INDEX IF NOT EXISTS idx_game_videos_game_cctv ON public.game_videos(game_id, cctv_id);

-- Ensure canonical cameras exist for court_1 and court_2
INSERT INTO public.cctv_cameras (id, club_id, court_id, name, camera_type, connection_type, rtsp_url_encrypted, is_enabled, status, health_status)
VALUES 
  ('cam_court_1_c1', 'all_stars_arena_club', 'court_1', 'Camera 1 (Main Dome)', 'RTSP_DOME', 'RTSP', 'a85be7a5d2c5ab215dc2c4fe5a4abdb0:090aef5f', true, 'ONLINE', 'ONLINE'),
  ('cam_court_1_c2', 'all_stars_arena_club', 'court_1', 'Camera 2 (Sideline HD)', 'RTSP_DOME', 'RTSP', '7cd81c89947568ffe8fd52db19b6ee0a:741aa07c', true, 'ONLINE', 'ONLINE'),
  ('cam_court_2_c1', 'all_stars_arena_club', 'court_2', 'Camera 1 (Main Dome)', 'RTSP_DOME', 'RTSP', '49f33db91e4007a53c608048539d974c:15158b0', true, 'ONLINE', 'ONLINE'),
  ('cam_court_2_c2', 'all_stars_arena_club', 'court_2', 'Camera 2 (Goalpost HD)', 'RTSP_DOME', 'RTSP', '4e66febba6293e86a1c041d990cea66d:bb3018eb', true, 'ONLINE', 'ONLINE')
ON CONFLICT (id) DO UPDATE SET 
  club_id = EXCLUDED.club_id,
  court_id = EXCLUDED.court_id,
  name = EXCLUDED.name,
  status = 'ONLINE',
  health_status = 'ONLINE';

-- Backfill cctv_id in existing game_videos from cctv_recordings where available
UPDATE public.game_videos gv
SET cctv_id = rec.camera_id
FROM public.cctv_recordings rec
WHERE gv.game_id = rec.game_id AND gv.cctv_id IS NULL AND rec.camera_id IS NOT NULL;

-- Backfill remaining game_videos without cctv_id to court camera 1
UPDATE public.game_videos gv
SET cctv_id = CASE 
  WHEN gv.court_id = 'court_2' THEN 'cam_court_2_c1'
  ELSE 'cam_court_1_c1'
END
WHERE gv.cctv_id IS NULL;
