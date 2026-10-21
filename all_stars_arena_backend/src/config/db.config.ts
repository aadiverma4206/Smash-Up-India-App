import pg from "pg";
import { env } from "./env.config.js";
import { logger } from "../utils/logger.js";

const { Pool } = pg;

export const dbPool = new Pool({
  connectionString: env.DATABASE_URL,
  ssl: env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
  options: "-c timezone=Asia/Kolkata",
});

dbPool.on("connect", () => {
  logger.info("Connected to PostgreSQL Database (all_stars_arena)");
});

dbPool.on("error", (err) => {
  logger.error({ err }, "Unexpected error on idle PostgreSQL client");
});

export const initDbTables = async () => {
  try {
    await dbPool.query(`
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS latest_otp VARCHAR(10);
      ALTER TABLE public.users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
      ALTER TABLE public.player_details ADD COLUMN IF NOT EXISTS secondary_position VARCHAR(16);
      ALTER TABLE public.player_details ADD COLUMN IF NOT EXISTS elo_rating INT DEFAULT 1200;
      ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS payment_status VARCHAR(32) DEFAULT 'PAID';
      ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE public.game_players ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      UPDATE public.game_players SET created_at = joined_at WHERE created_at IS NULL AND joined_at IS NOT NULL;
      UPDATE public.game_players SET joined_at = created_at WHERE joined_at IS NULL AND created_at IS NOT NULL;

      ALTER TABLE public.games DROP CONSTRAINT IF EXISTS games_entry_fee_check;
      ALTER TABLE public.games ADD CONSTRAINT games_entry_fee_check CHECK (entry_fee >= 0);

      ALTER TABLE public.games ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT 'APPROVED';
      ALTER TABLE public.games ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
      ALTER TABLE public.games ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
      ALTER TABLE public.games ADD COLUMN IF NOT EXISTS manager_id VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL;
      ALTER TABLE public.games DROP CONSTRAINT IF EXISTS games_approval_status_check;
      ALTER TABLE public.games ADD CONSTRAINT games_approval_status_check CHECK (approval_status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED'));

      CREATE TABLE IF NOT EXISTS public.user_device_tokens (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('dev_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          device_token TEXT NOT NULL,
          device_type VARCHAR(32) DEFAULT 'ANDROID' NOT NULL,
          is_active BOOLEAN DEFAULT true NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_user_device_token UNIQUE (user_id, device_token)
      );

      CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.user_device_tokens(user_id);

      CREATE TABLE IF NOT EXISTS public.notifications (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('notif_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          title VARCHAR(255) NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          message TEXT NOT NULL DEFAULT '',
          type VARCHAR(64) NOT NULL DEFAULT 'SYSTEM',
          data JSONB DEFAULT '{}'::jsonb,
          link_url VARCHAR(512),
          club_id VARCHAR(64) REFERENCES public.clubs(id) ON DELETE SET NULL,
          game_id VARCHAR(64) REFERENCES public.games(id) ON DELETE SET NULL,
          is_read BOOLEAN NOT NULL DEFAULT false,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS body TEXT;
      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS message TEXT;
      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS type VARCHAR(64) DEFAULT 'SYSTEM';
      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb;
      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS link_url VARCHAR(512);
      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;
      ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

      CREATE TABLE IF NOT EXISTS public.cctv_cameras (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('cam_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          club_id VARCHAR(64) NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
          court_id VARCHAR(64) REFERENCES public.courts(id) ON DELETE SET NULL,
          name VARCHAR(150) NOT NULL,
          camera_type VARCHAR(32) DEFAULT 'RTSP_DOME' NOT NULL,
          connection_type VARCHAR(32) DEFAULT 'RTSP' NOT NULL,
          rtsp_url_encrypted TEXT NOT NULL,
          stream_reference VARCHAR(255),
          ip_address VARCHAR(64),
          port INTEGER DEFAULT 554,
          is_enabled BOOLEAN DEFAULT true NOT NULL,
          status VARCHAR(32) DEFAULT 'ONLINE' NOT NULL,
          health_status VARCHAR(32) DEFAULT 'ONLINE' NOT NULL,
          last_seen_at TIMESTAMP WITH TIME ZONE,
          created_by VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS encrypted_connection_reference TEXT;
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS health_status VARCHAR(32) DEFAULT 'ONLINE';
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS camera_type VARCHAR(32) DEFAULT 'RTSP_DOME';
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS connection_type VARCHAR(32) DEFAULT 'RTSP';
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS stream_reference VARCHAR(255);
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS created_by VARCHAR(64);

      CREATE TABLE IF NOT EXISTS public.cctv_recordings (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('rec_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
          club_id VARCHAR(64) NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
          court_id VARCHAR(64) REFERENCES public.courts(id) ON DELETE SET NULL,
          camera_id VARCHAR(64) REFERENCES public.cctv_cameras(id) ON DELETE SET NULL,
          status VARCHAR(32) DEFAULT 'RECORDING' NOT NULL,
          recording_status VARCHAR(32) DEFAULT 'RECORDING' NOT NULL,
          started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
          start_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
          scheduled_match_end TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '90 minutes') NOT NULL,
          scheduled_match_end_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '90 minutes') NOT NULL,
          stop_deadline TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '105 minutes') NOT NULL,
          post_match_stop_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '105 minutes') NOT NULL,
          actual_stop_time TIMESTAMP WITH TIME ZONE,
          actual_stopped_at TIMESTAMP WITH TIME ZONE,
          manual_stop BOOLEAN DEFAULT false NOT NULL,
          storage_provider VARCHAR(32) DEFAULT 'S3' NOT NULL,
          storage_bucket VARCHAR(128) DEFAULT 'all-stars-arena-recordings' NOT NULL,
          storage_object_key VARCHAR(512) DEFAULT 'recordings/default.mp4' NOT NULL,
          s3_object_key VARCHAR(512) DEFAULT 'recordings/default.mp4' NOT NULL,
          duration_seconds INT DEFAULT 0 NOT NULL,
          playback_status VARCHAR(32) DEFAULT 'READY' NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS recording_status VARCHAR(32) DEFAULT 'RECORDING';
      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS post_match_stop_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS scheduled_match_end_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS storage_object_key VARCHAR(512);
      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS actual_stopped_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE public.cctv_recordings ADD COLUMN IF NOT EXISTS duration_seconds INTEGER DEFAULT 5400;
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

      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS serial_number VARCHAR(128);
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS protocol VARCHAR(32) DEFAULT 'rtsp';
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS last_error TEXT;
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS last_connection_at TIMESTAMP WITH TIME ZONE;
      ALTER TABLE public.cctv_cameras ADD COLUMN IF NOT EXISTS last_successful_connection TIMESTAMP WITH TIME ZONE;

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
          status VARCHAR(32) DEFAULT 'QUEUED' NOT NULL,
          error_message TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
      );

      CREATE TABLE IF NOT EXISTS public.cctv_recording_events (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('ev_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          recording_id VARCHAR(64) NOT NULL REFERENCES public.cctv_recordings(id) ON DELETE CASCADE,
          event_type VARCHAR(64) NOT NULL,
          actor_user_id VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL,
          event_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
          metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE public.games ADD COLUMN IF NOT EXISTS video_playback_url VARCHAR(512);
      UPDATE public.games
      SET video_playback_url = NULL
      WHERE video_playback_url ILIKE '%commondatastorage.googleapis.com%' OR video_playback_url ILIKE '%BigBuckBunny%';

      DO $$
      BEGIN
        INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
        SELECT seeded.game_id, seeded.user_id, seeded.team, seeded.position, 'PAID'
        FROM (
          SELECT g.id as game_id, u.id as user_id,
                 (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY g.id ORDER BY u.id)) % 2 = 1 THEN 'TEAM_A' ELSE 'TEAM_B' END)::public.team_side as team,
                 (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY g.id ORDER BY u.id)) % 3 = 0 THEN 'ST' WHEN (ROW_NUMBER() OVER (PARTITION BY g.id ORDER BY u.id)) % 3 = 1 THEN 'MID' ELSE 'DEF' END)::public.football_position as position,
                 ROW_NUMBER() OVER (PARTITION BY g.id ORDER BY u.id) as rn,
                 COALESCE(g.max_players, 10) as max_p
          FROM public.games g
          CROSS JOIN public.users u
          WHERE u.role_id = 3
          AND NOT EXISTS (SELECT 1 FROM public.game_players gp WHERE gp.game_id = g.id)
        ) seeded
        WHERE seeded.rn <= seeded.max_p
        ON CONFLICT DO NOTHING;
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END $$;

      CREATE TABLE IF NOT EXISTS public.game_slot_requests (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('req_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
          user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          position VARCHAR(16) DEFAULT 'MID' NOT NULL,
          status VARCHAR(32) DEFAULT 'PENDING' NOT NULL,
          rejection_reason TEXT,
          payment_status VARCHAR(32) DEFAULT 'PAID' NOT NULL,
          entry_fee NUMERIC(10,2) DEFAULT 0.00 NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_game_user_slot_request UNIQUE (game_id, user_id)
      );

      CREATE TABLE IF NOT EXISTS public.game_activity_logs (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('act_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          game_id VARCHAR(64) NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
          actor_id VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL,
          actor_name VARCHAR(150),
          actor_role_name VARCHAR(32) DEFAULT 'PLAYER' NOT NULL,
          action_type VARCHAR(64) NOT NULL,
          details TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS public.payment_orders (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('ord_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          provider VARCHAR(32) DEFAULT 'RAZORPAY' NOT NULL,
          provider_order_id VARCHAR(128),
          provider_payment_id VARCHAR(128),
          amount_paise INT NOT NULL,
          idempotency_key VARCHAR(128),
          status VARCHAR(32) DEFAULT 'PENDING' NOT NULL,
          metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_payment_orders_user_idempotency UNIQUE (user_id, idempotency_key)
      );

      CREATE TABLE IF NOT EXISTS public.wallet_transactions (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('tx_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          user_id VARCHAR(64) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
          transaction_type VARCHAR(32) NOT NULL,
          amount NUMERIC(10,2) NOT NULL,
          balance_after NUMERIC(10,2) NOT NULL,
          description TEXT NOT NULL,
          status VARCHAR(32) DEFAULT 'SUCCESS' NOT NULL,
          reference_id VARCHAR(64),
          provider_payment_id VARCHAR(128),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS public.payment_webhook_events (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('whe_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          provider VARCHAR(32) NOT NULL,
          event_id VARCHAR(128) NOT NULL,
          event_type VARCHAR(128) NOT NULL,
          payment_order_id VARCHAR(64),
          signature_verified BOOLEAN DEFAULT false NOT NULL,
          payload JSONB DEFAULT '{}'::jsonb NOT NULL,
          processing_status VARCHAR(32) DEFAULT 'RECEIVED' NOT NULL,
          processed_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT uq_payment_webhook_events_provider_event UNIQUE (provider, event_id)
      );

      DROP FUNCTION IF EXISTS public.create_payment_order(VARCHAR, VARCHAR, INT, VARCHAR, VARCHAR);
      DROP FUNCTION IF EXISTS public.create_payment_order(VARCHAR, VARCHAR, INT, VARCHAR);
      DROP FUNCTION IF EXISTS public.create_payment_order(VARCHAR, VARCHAR, INT, VARCHAR, VARCHAR, VARCHAR);

      CREATE OR REPLACE FUNCTION public.create_payment_order(
          p_user_id VARCHAR(64),
          p_provider VARCHAR(32),
          p_amount_paise INT,
          p_idempotency_key VARCHAR(128),
          p_wallet_pin VARCHAR(16) DEFAULT NULL
      ) RETURNS VARCHAR(64) LANGUAGE plpgsql AS $$
      DECLARE
          v_order_id VARCHAR(64);
      BEGIN
          -- Top-up payment orders via Razorpay do NOT require PIN verification.
          INSERT INTO public.payment_orders (
              user_id,
              provider,
              amount_paise,
              idempotency_key,
              status,
              created_at,
              updated_at
          ) VALUES (
              p_user_id,
              p_provider,
              p_amount_paise,
              p_idempotency_key,
              'PENDING',
              CURRENT_TIMESTAMP,
              CURRENT_TIMESTAMP
          )
          ON CONFLICT (user_id, idempotency_key) DO UPDATE
          SET updated_at = CURRENT_TIMESTAMP
          RETURNING id INTO v_order_id;

          RETURN v_order_id;
      END;
      $$;

      CREATE OR REPLACE FUNCTION public.settle_wallet_payment(
          p_payment_order_id VARCHAR(64),
          p_provider_payment_id VARCHAR(128)
      ) RETURNS VARCHAR(64) LANGUAGE plpgsql AS $$
      DECLARE
          v_user_id VARCHAR(64);
          v_amount_paise BIGINT;
          v_amount_rupees NUMERIC(10,2);
          v_order_status VARCHAR(32);
          v_purpose VARCHAR(32);
          v_tx_id VARCHAR(64);
          v_new_balance NUMERIC(10,2);
      BEGIN
          -- 1. Fetch payment order with row lock
          SELECT user_id, amount_paise, status, purpose INTO v_user_id, v_amount_paise, v_order_status, v_purpose
          FROM public.payment_orders
          WHERE id = p_payment_order_id FOR UPDATE;

          IF NOT FOUND THEN
              RAISE EXCEPTION 'Payment order % not found', p_payment_order_id;
          END IF;

          -- Enforce that ONLY WALLET_TOPUP orders can ever be settled as a wallet credit
          IF v_purpose <> 'WALLET_TOPUP' THEN
              RAISE EXCEPTION 'Payment order % is not a WALLET_TOPUP order (purpose: %)', p_payment_order_id, v_purpose;
          END IF;

          -- 2. Idempotency: If already settled as PAID, return existing transaction ID
          IF v_order_status = 'PAID' THEN
              SELECT id INTO v_tx_id FROM public.transactions
              WHERE reference_id = p_payment_order_id LIMIT 1;
              IF v_tx_id IS NOT NULL THEN
                  RETURN v_tx_id;
              END IF;

              SELECT id INTO v_tx_id FROM public.wallet_transactions
              WHERE reference_id = p_payment_order_id LIMIT 1;
              IF v_tx_id IS NOT NULL THEN
                  RETURN v_tx_id;
              END IF;

              RETURN 'ALREADY_SETTLED';
          END IF;

          v_amount_rupees := (v_amount_paise::NUMERIC / 100.0);

          -- 3. Record in authoritative transactions ledger
          -- trg_apply_transaction automatically locks player_details FOR UPDATE and credits wallet_balance exactly once
          INSERT INTO public.transactions (
              user_id,
              type,
              amount,
              balance_after,
              status,
              description,
              reference_id
          ) VALUES (
              v_user_id,
              'WALLET_TOPUP',
              v_amount_rupees,
              0,
              'SUCCESS',
              'Wallet Top-Up via Razorpay',
              p_payment_order_id
          ) RETURNING id, balance_after INTO v_tx_id, v_new_balance;

          -- 4. Keep wallet_transactions in sync
          INSERT INTO public.wallet_transactions (
              id,
              user_id,
              transaction_type,
              amount,
              balance_after,
              description,
              status,
              reference_id,
              provider_payment_id
          ) VALUES (
              v_tx_id,
              v_user_id,
              'TOPUP',
              v_amount_rupees,
              v_new_balance,
              'Wallet Top-Up via Razorpay',
              'SUCCESS',
              p_payment_order_id,
              p_provider_payment_id
          ) ON CONFLICT (id) DO UPDATE SET balance_after = EXCLUDED.balance_after;

          -- 5. Mark payment_order as PAID
          UPDATE public.payment_orders
          SET status = 'PAID',
              paid_at = CURRENT_TIMESTAMP,
              provider_payment_id = p_provider_payment_id,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = p_payment_order_id;

          RETURN v_tx_id;
      END;
      $$;

      DROP FUNCTION IF EXISTS public.get_wallet_transaction_history(VARCHAR, INT, INT);
      DROP FUNCTION IF EXISTS public.get_wallet_transaction_history(VARCHAR);

      CREATE OR REPLACE FUNCTION public.get_wallet_transaction_history(
          p_user_id VARCHAR(64),
          p_limit INT DEFAULT 50,
          p_offset INT DEFAULT 0
      ) RETURNS TABLE (
          id VARCHAR(64),
          user_id VARCHAR(64),
          transaction_type VARCHAR(32),
          amount NUMERIC(10,2),
          balance_after NUMERIC(10,2),
          description TEXT,
          status VARCHAR(32),
          reference_id VARCHAR(64),
          provider_payment_id VARCHAR(128),
          created_at TIMESTAMP WITH TIME ZONE
      ) LANGUAGE plpgsql AS $$
      DECLARE
          v_current_wallet_balance NUMERIC(10,2) := 0.00;
      BEGIN
          SELECT COALESCE(wallet_balance, 0.00) INTO v_current_wallet_balance
          FROM public.player_details
          WHERE public.player_details.user_id = p_user_id;

          RETURN QUERY
          WITH combined_ledger AS (
              SELECT
                  t.id::VARCHAR(64) as id,
                  t.user_id::VARCHAR(64) as user_id,
                  CASE
                      WHEN UPPER(t.type::TEXT) LIKE '%REFUND%' OR UPPER(t.description) LIKE '%REFUND%' OR UPPER(t.description) LIKE '%CANCEL%' THEN 'REFUND'::VARCHAR(32)
                      WHEN UPPER(t.type::TEXT) IN ('TOPUP', 'WALLET_TOPUP', 'DEPOSIT', 'CREDIT') THEN 'TOPUP'::VARCHAR(32)
                      WHEN UPPER(t.type::TEXT) IN ('PAYMENT', 'DEBIT', 'WITHDRAWAL', 'MATCH_JOIN') THEN 'DEBIT'::VARCHAR(32)
                      ELSE UPPER(t.type::TEXT)::VARCHAR(32)
                  END as transaction_type,
                  t.amount::NUMERIC(10,2) as amount,
                  COALESCE(NULLIF(t.balance_after, 0), v_current_wallet_balance, 0.00)::NUMERIC(10,2) as balance_after,
                  t.description::TEXT as description,
                  t.status::VARCHAR(32) as status,
                  t.reference_id::VARCHAR(64) as reference_id,
                  wt.provider_payment_id::VARCHAR(128) as provider_payment_id,
                  t.created_at as created_at
              FROM public.transactions t
              LEFT JOIN public.wallet_transactions wt ON (wt.id = t.id OR (t.reference_id IS NOT NULL AND wt.reference_id = t.reference_id))
              WHERE t.user_id = p_user_id

              UNION

              SELECT
                  wt.id::VARCHAR(64) as id,
                  wt.user_id::VARCHAR(64) as user_id,
                  CASE
                      WHEN UPPER(wt.transaction_type::TEXT) LIKE '%REFUND%' OR UPPER(wt.description) LIKE '%REFUND%' OR UPPER(wt.description) LIKE '%CANCEL%' THEN 'REFUND'::VARCHAR(32)
                      WHEN UPPER(wt.transaction_type::TEXT) IN ('TOPUP', 'WALLET_TOPUP', 'DEPOSIT', 'CREDIT') THEN 'TOPUP'::VARCHAR(32)
                      WHEN UPPER(wt.transaction_type::TEXT) IN ('PAYMENT', 'DEBIT', 'WITHDRAWAL', 'MATCH_JOIN') THEN 'DEBIT'::VARCHAR(32)
                      ELSE UPPER(wt.transaction_type::TEXT)::VARCHAR(32)
                  END as transaction_type,
                  wt.amount::NUMERIC(10,2) as amount,
                  COALESCE(NULLIF(wt.balance_after, 0), v_current_wallet_balance, 0.00)::NUMERIC(10,2) as balance_after,
                  wt.description::TEXT as description,
                  wt.status::VARCHAR(32) as status,
                  wt.reference_id::VARCHAR(64) as reference_id,
                  wt.provider_payment_id::VARCHAR(128) as provider_payment_id,
                  wt.created_at as created_at
              FROM public.wallet_transactions wt
              WHERE wt.user_id = p_user_id
                AND NOT EXISTS (
                    SELECT 1 FROM public.transactions t2 WHERE t2.id = wt.id OR (wt.reference_id IS NOT NULL AND t2.reference_id = wt.reference_id)
                )

              UNION

              SELECT
                  po.id::VARCHAR(64) as id,
                  po.user_id::VARCHAR(64) as user_id,
                  'TOPUP'::VARCHAR(32) as transaction_type,
                  (po.amount_paise / 100.0)::NUMERIC(10,2) as amount,
                  v_current_wallet_balance::NUMERIC(10,2) as balance_after,
                  'Wallet Top-up Order' as description,
                  po.status::VARCHAR(32) as status,
                  po.id::VARCHAR(64) as reference_id,
                  po.provider_payment_id::VARCHAR(128) as provider_payment_id,
                  po.created_at as created_at
              FROM public.payment_orders po
              WHERE po.user_id = p_user_id
                AND po.status IN ('PAID', 'SUCCESS', 'SETTLED', 'COMPLETED')
                AND NOT EXISTS (
                    SELECT 1 FROM public.transactions t3 WHERE t3.reference_id = po.id OR t3.id = po.id
                )
                AND NOT EXISTS (
                    SELECT 1 FROM public.wallet_transactions wt3 WHERE wt3.reference_id = po.id OR wt3.id = po.id
                )

              UNION

              SELECT
                  ('mref_' || gp.game_id || '_' || gp.user_id)::VARCHAR(64) as id,
                  gp.user_id::VARCHAR(64) as user_id,
                  'REFUND'::VARCHAR(32) as transaction_type,
                  COALESCE(g.entry_fee, 0.00)::NUMERIC(10,2) as amount,
                  v_current_wallet_balance::NUMERIC(10,2) as balance_after,
                  ('Refund for cancelled match: ' || COALESCE(g.title, 'Football Match'))::TEXT as description,
                  'SUCCESS'::VARCHAR(32) as status,
                  ('MATCH_REFUND:' || gp.game_id || ':' || gp.user_id)::VARCHAR(64) as reference_id,
                  NULL::VARCHAR(128) as provider_payment_id,
                  COALESCE(g.updated_at, g.created_at, CURRENT_TIMESTAMP) as created_at
              FROM public.game_players gp
              JOIN public.games g ON g.id = gp.game_id
              WHERE gp.user_id = p_user_id
                AND (g.status = 'CANCELLED' OR gp.payment_status = 'REFUNDED')
                AND COALESCE(g.entry_fee, 0) > 0
                AND NOT EXISTS (
                    SELECT 1 FROM public.transactions t4
                    WHERE t4.user_id = gp.user_id
                      AND (t4.reference_id = ('MATCH_REFUND:' || gp.game_id || ':' || gp.user_id) OR UPPER(t4.description) LIKE ('%' || UPPER(COALESCE(g.title, 'Match')) || '%'))
                )
                AND NOT EXISTS (
                    SELECT 1 FROM public.wallet_transactions wt4
                    WHERE wt4.user_id = gp.user_id
                      AND (wt4.reference_id = ('MATCH_REFUND:' || gp.game_id || ':' || gp.user_id) OR UPPER(wt4.description) LIKE ('%' || UPPER(COALESCE(g.title, 'Match')) || '%'))
                )
          )
          SELECT * FROM combined_ledger
          ORDER BY created_at DESC
          LIMIT p_limit OFFSET p_offset;
      END;
      $$;

      CREATE OR REPLACE FUNCTION public.set_wallet_pin(
          p_user_id VARCHAR(64),
          p_pin VARCHAR(16)
      ) RETURNS VOID LANGUAGE plpgsql AS $$
      BEGIN
          IF p_pin IS NULL OR p_pin !~ '^[0-9]{6}$' THEN
              RAISE EXCEPTION 'Wallet PIN must be exactly 6 numeric digits';
          END IF;

          UPDATE public.player_details
          SET wallet_pin_hash = crypt(p_pin, gen_salt('bf')),
              wallet_pin_set_at = CURRENT_TIMESTAMP,
              wallet_pin_failed_attempts = 0,
              wallet_pin_locked_until = NULL,
              updated_at = CURRENT_TIMESTAMP
          WHERE user_id = p_user_id;

          IF NOT FOUND THEN
              INSERT INTO public.player_details (
                  user_id,
                  wallet_pin_hash,
                  wallet_pin_set_at,
                  wallet_pin_failed_attempts,
                  wallet_pin_locked_until
              )
              VALUES (
                  p_user_id,
                  crypt(p_pin, gen_salt('bf')),
                  CURRENT_TIMESTAMP,
                  0,
                  NULL
              );
          END IF;
      END;
      $$;

      CREATE OR REPLACE FUNCTION public.verify_wallet_pin(
          p_user_id VARCHAR(64),
          p_pin VARCHAR(16)
      ) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
      DECLARE
          v_hash VARCHAR(255);
          v_failed INT;
          v_locked_until TIMESTAMP WITH TIME ZONE;
      BEGIN
          SELECT wallet_pin_hash, wallet_pin_failed_attempts, wallet_pin_locked_until
          INTO v_hash, v_failed, v_locked_until
          FROM public.player_details
          WHERE user_id = p_user_id
          FOR UPDATE;

          IF NOT FOUND OR v_hash IS NULL THEN
              RETURN FALSE;
          END IF;

          -- Check if currently locked
          IF v_locked_until IS NOT NULL AND v_locked_until > CURRENT_TIMESTAMP THEN
              RAISE EXCEPTION 'WALLET_PIN_LOCKED';
          END IF;

          -- Validate format
          IF p_pin IS NULL OR p_pin !~ '^[0-9]{6}$' THEN
              v_failed := COALESCE(v_failed, 0) + 1;
              IF v_failed >= 5 THEN
                  UPDATE public.player_details
                  SET wallet_pin_failed_attempts = v_failed,
                      wallet_pin_locked_until = CURRENT_TIMESTAMP + INTERVAL '15 minutes',
                      updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = p_user_id;
                  RAISE EXCEPTION 'WALLET_PIN_LOCKED';
              ELSE
                  UPDATE public.player_details
                  SET wallet_pin_failed_attempts = v_failed,
                      updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = p_user_id;
              END IF;
              RETURN FALSE;
          END IF;

          -- Compare hash
          IF v_hash = crypt(p_pin, v_hash) THEN
              -- Success: reset failed attempts
              UPDATE public.player_details
              SET wallet_pin_failed_attempts = 0,
                  wallet_pin_locked_until = NULL,
                  updated_at = CURRENT_TIMESTAMP
              WHERE user_id = p_user_id;
              RETURN TRUE;
          ELSE
              -- Failed: increment attempts and lock after 5
              v_failed := COALESCE(v_failed, 0) + 1;
              IF v_failed >= 5 THEN
                  UPDATE public.player_details
                  SET wallet_pin_failed_attempts = v_failed,
                      wallet_pin_locked_until = CURRENT_TIMESTAMP + INTERVAL '15 minutes',
                      updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = p_user_id;
                  RAISE EXCEPTION 'WALLET_PIN_LOCKED';
              ELSE
                  UPDATE public.player_details
                  SET wallet_pin_failed_attempts = v_failed,
                      updated_at = CURRENT_TIMESTAMP
                  WHERE user_id = p_user_id;
              END IF;
              RETURN FALSE;
          END IF;
      END;
      $$;

      CREATE OR REPLACE FUNCTION public.switch_player_team(
          p_user_id VARCHAR(64),
          p_game_id VARCHAR(64)
      ) RETURNS VARCHAR(16) LANGUAGE plpgsql AS $$
      DECLARE
          v_current_team public.team_side;
          v_new_team public.team_side;
          v_game_status public.match_status;
          v_team_capacity INT;
          v_new_team_count INT;
          v_max_players INT;
      BEGIN
          SELECT status, max_players INTO v_game_status, v_max_players
          FROM public.games WHERE id = p_game_id FOR UPDATE;

          IF NOT FOUND THEN
              RAISE EXCEPTION 'Game not found';
          END IF;

          IF v_game_status NOT IN ('OPEN_FOR_JOINING', 'FULL') THEN
              RAISE EXCEPTION 'Cannot switch team when game status is %', v_game_status;
          END IF;

          SELECT team INTO v_current_team
          FROM public.game_players
          WHERE game_id = p_game_id AND user_id = p_user_id
          FOR UPDATE;

          IF NOT FOUND THEN
              RAISE EXCEPTION 'Player has not joined this game';
          END IF;

          v_new_team := CASE WHEN v_current_team = 'TEAM_A' THEN 'TEAM_B'::public.team_side ELSE 'TEAM_A'::public.team_side END;
          v_team_capacity := v_max_players / 2;

          SELECT COUNT(*) INTO v_new_team_count
          FROM public.game_players
          WHERE game_id = p_game_id AND team = v_new_team;

          IF v_new_team_count >= v_team_capacity THEN
              RAISE EXCEPTION 'Target team % is already full (max % players)', v_new_team, v_team_capacity;
          END IF;

          UPDATE public.game_players
          SET team = v_new_team
          WHERE game_id = p_game_id AND user_id = p_user_id;

          RETURN v_new_team::VARCHAR;
      END;
      $$;

      CREATE OR REPLACE FUNCTION public.join_game_with_wallet(
          p_user_id VARCHAR(64),
          p_game_id VARCHAR(64),
          p_position VARCHAR(16) DEFAULT 'MID'
      ) RETURNS VARCHAR(64) LANGUAGE plpgsql AS $$
      DECLARE
          v_entry_fee NUMERIC(10,2);
          v_max_players INT;
          v_current_count INT;
          v_game_status VARCHAR(32);
          v_wallet_balance NUMERIC(10,2);
          v_team_a_count INT;
          v_team_b_count INT;
          v_assigned_team public.team_side;
          v_roster_id VARCHAR(64);
          v_tx_id VARCHAR(64);
          v_new_balance NUMERIC(10,2);
      BEGIN
          SELECT entry_fee, max_players, status INTO v_entry_fee, v_max_players, v_game_status
          FROM public.games WHERE id = p_game_id FOR UPDATE;

          IF NOT FOUND THEN
              RAISE EXCEPTION 'Match not found';
          END IF;

          IF v_game_status IN ('CANCELLED', 'COMPLETED') THEN
              RAISE EXCEPTION 'Cannot join a match that is %', v_game_status;
          END IF;

          IF EXISTS (SELECT 1 FROM public.game_players WHERE game_id = p_game_id AND user_id = p_user_id) THEN
              RAISE EXCEPTION 'You have already joined this match roster';
          END IF;

          SELECT COUNT(*) INTO v_current_count FROM public.game_players WHERE game_id = p_game_id;
          IF v_current_count >= v_max_players THEN
              RAISE EXCEPTION 'Match is already at full capacity';
          END IF;

          IF v_entry_fee > 0 THEN
              SELECT wallet_balance INTO v_wallet_balance
              FROM public.player_details WHERE user_id = p_user_id FOR UPDATE;

              IF v_wallet_balance IS NULL OR v_wallet_balance < v_entry_fee THEN
                  RAISE EXCEPTION 'INSUFFICIENT_WALLET_BALANCE';
              END IF;

              INSERT INTO public.transactions (user_id, type, amount, balance_after, status, description, reference_id)
              VALUES (p_user_id, 'PAYMENT', v_entry_fee, 0, 'SUCCESS', 'Entry fee for joining match', p_game_id)
              RETURNING id, balance_after INTO v_tx_id, v_new_balance;

              INSERT INTO public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, status, reference_id)
              VALUES (v_tx_id, p_user_id, 'DEBIT', v_entry_fee, v_new_balance, 'Entry fee for joining match', 'SUCCESS', p_game_id)
              ON CONFLICT (id) DO NOTHING;
          END IF;

          SELECT COUNT(*) INTO v_team_a_count FROM public.game_players WHERE game_id = p_game_id AND team = 'TEAM_A';
          SELECT COUNT(*) INTO v_team_b_count FROM public.game_players WHERE game_id = p_game_id AND team = 'TEAM_B';

          IF v_team_a_count <= v_team_b_count THEN
              v_assigned_team := 'TEAM_A'::public.team_side;
          ELSE
              v_assigned_team := 'TEAM_B'::public.team_side;
          END IF;

          INSERT INTO public.game_players (game_id, user_id, team, position, payment_status)
          VALUES (p_game_id, p_user_id, v_assigned_team, UPPER(p_position)::public.football_position, 'PAID')
          RETURNING id INTO v_roster_id;

          IF v_current_count + 1 >= v_max_players THEN
              UPDATE public.games SET status = 'FULL', updated_at = CURRENT_TIMESTAMP WHERE id = p_game_id;
          END IF;

          RETURN v_roster_id;
      END;
      $$;

      -- 1. Ensure canonical club 'all_stars_arena_club' exists
      INSERT INTO public.clubs (id, name, address, city, status)
      VALUES ('all_stars_arena_club', 'All Stars Turf Raipur', 'VIP Road', 'Raipur', 'ACTIVE')
      ON CONFLICT (id) DO UPDATE SET name = 'All Stars Turf Raipur', status = 'ACTIVE';

      -- 2. Ensure canonical courts 'court_1' and 'court_2' exist
      INSERT INTO public.courts (id, club_id, name, environment, surface, base_price, status)
      VALUES
        ('court_1', 'all_stars_arena_club', 'Court 1', 'Outdoor', '3G Turf', 1200.00, 'AVAILABLE'),
        ('court_2', 'all_stars_arena_club', 'Court 2', 'Outdoor', '3G Turf', 1200.00, 'AVAILABLE')
      ON CONFLICT (id) DO UPDATE SET
        club_id = 'all_stars_arena_club',
        name = EXCLUDED.name,
        surface = EXCLUDED.surface,
        status = 'AVAILABLE';

      -- 3. Normalize all games strictly to all_stars_arena_club and court_1 / court_2
      UPDATE public.games
      SET
        club_id = 'all_stars_arena_club',
        court_id = CASE
          WHEN court_id ILIKE '%2%' OR court_id = 'court_2' THEN 'court_2'
          ELSE 'court_1'
        END
      WHERE club_id <> 'all_stars_arena_club' OR court_id NOT IN ('court_1', 'court_2');

      DO $$
      BEGIN
        UPDATE public.court_bookings
        SET court_id = CASE
          WHEN court_id ILIKE '%2%' OR court_id = 'court_2' THEN 'court_2'
          ELSE 'court_1'
        END
        WHERE court_id NOT IN ('court_1', 'court_2');
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END $$;

      -- Clean up any non-canonical courts that are safely unreferenced
      DELETE FROM public.courts WHERE id NOT IN ('court_1', 'court_2')
      AND NOT EXISTS (SELECT 1 FROM public.court_bookings cb WHERE cb.court_id = courts.id)
      AND NOT EXISTS (SELECT 1 FROM public.games g WHERE g.court_id = courts.id);

      -- Multi-camera CCTV cataloging: add cctv_id to game_videos
      ALTER TABLE public.game_videos ADD COLUMN IF NOT EXISTS cctv_id VARCHAR(64) REFERENCES public.cctv_cameras(id) ON DELETE SET NULL;
      CREATE INDEX IF NOT EXISTS idx_game_videos_cctv_id ON public.game_videos(cctv_id);
      CREATE INDEX IF NOT EXISTS idx_game_videos_game_cctv ON public.game_videos(game_id, cctv_id);

      -- Ensure canonical CCTV cameras exist for each court
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

      -- 4. Ensure all managers and admins are linked to all_stars_arena_club
      INSERT INTO public.club_managers (club_id, user_id)
      SELECT 'all_stars_arena_club', id FROM public.users WHERE role_id = 2 OR role_id = 1
      ON CONFLICT DO NOTHING;

      -- 5. Performance Indexes for users search & pagination scaling (10,000+ users)
      CREATE INDEX IF NOT EXISTS idx_users_role_name_asc ON public.users(role_id, name ASC);
      CREATE INDEX IF NOT EXISTS idx_users_name_lower ON public.users(LOWER(name));
      CREATE INDEX IF NOT EXISTS idx_users_email_lower ON public.users(LOWER(email));
      CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);

      DO $$
      BEGIN
        CREATE EXTENSION IF NOT EXISTS pg_trgm;
        CREATE INDEX IF NOT EXISTS idx_users_name_trgm ON public.users USING gin (name gin_trgm_ops);
        CREATE INDEX IF NOT EXISTS idx_users_email_trgm ON public.users USING gin (email gin_trgm_ops);
        CREATE INDEX IF NOT EXISTS idx_users_phone_trgm ON public.users USING gin (phone gin_trgm_ops);
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END $$;

      -- 6. Audit Logs Table Definition & Indexes
      CREATE TABLE IF NOT EXISTS public.audit_logs (
          id VARCHAR(64) PRIMARY KEY DEFAULT ('log_' || SUBSTR(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 16)),
          user_id VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL,
          admin_id VARCHAR(64) REFERENCES public.users(id) ON DELETE SET NULL,
          admin_name VARCHAR(150),
          action VARCHAR(100) NOT NULL,
          target VARCHAR(150),
          details TEXT,
          ip_address VARCHAR(64) DEFAULT '127.0.0.1',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);
      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS admin_id VARCHAR(64);
      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS admin_name VARCHAR(150);
      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS action VARCHAR(100);
      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS target VARCHAR(150);
      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS details TEXT;
      ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS ip_address VARCHAR(64);

      CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
    `);
    logger.info(
      "Database Schema, Indexes & Stored Functions Synchronized Successfully",
    );
  } catch (error) {
    logger.error({ error }, "Database initialization error");
  }
};
