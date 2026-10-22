const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function run() {
  const client = await pool.connect();
  try {
    console.log('Updating database functions to derive max_players from format...');
    await client.query('BEGIN');

    // 1. enforce_game_player_rules
    await client.query(`
      CREATE OR REPLACE FUNCTION public.enforce_game_player_rules()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $function$
      DECLARE
          v_role_id SMALLINT;
          v_max INT;
          v_current_count INT;
      BEGIN
          SELECT role_id INTO v_role_id FROM users WHERE id = NEW.user_id;
          IF v_role_id = 2 THEN
              RAISE EXCEPTION 'Club Managers cannot occupy a player slot in a game';
          END IF;
          IF v_role_id = 1 THEN
              RAISE EXCEPTION 'Admins cannot occupy a player slot in a game';
          END IF;

          SELECT CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END 
          INTO v_max 
          FROM games 
          WHERE id = NEW.game_id;

          SELECT COUNT(*) INTO v_current_count FROM game_players WHERE game_id = NEW.game_id;

          IF v_current_count >= v_max THEN
              RAISE EXCEPTION 'Game roster is already full (max % players)', v_max;
          END IF;

          RETURN NEW;
      END;
      $function$;
    `);
    console.log('Updated enforce_game_player_rules');

    // 2. sync_game_status_on_roster_change
    await client.query(`
      CREATE OR REPLACE FUNCTION public.sync_game_status_on_roster_change()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $function$
      DECLARE
          v_game_id VARCHAR(64);
          v_max INT;
          v_count INT;
          v_status match_status;
      BEGIN
          v_game_id := COALESCE(NEW.game_id, OLD.game_id);
          SELECT CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END, status 
          INTO v_max, v_status 
          FROM games 
          WHERE id = v_game_id;

          SELECT COUNT(*) INTO v_count FROM game_players WHERE game_id = v_game_id;

          IF v_status IN ('OPEN_FOR_JOINING', 'FULL') THEN
              IF v_count >= v_max THEN
                  UPDATE games SET status = 'FULL' WHERE id = v_game_id AND status <> 'FULL';
              ELSE
                  UPDATE games SET status = 'OPEN_FOR_JOINING' WHERE id = v_game_id AND status <> 'OPEN_FOR_JOINING';
              END IF;
          END IF;
          RETURN NULL;
      END;
      $function$;
    `);
    console.log('Updated sync_game_status_on_roster_change');

    // 3. switch_player_team
    await client.query(`
      CREATE OR REPLACE FUNCTION public.switch_player_team(p_user_id character varying, p_game_id character varying)
      RETURNS character varying
      LANGUAGE plpgsql
      AS $function$
      DECLARE
          v_current_team public.team_side;
          v_new_team public.team_side;
          v_game_status public.match_status;
          v_team_capacity INT;
          v_new_team_count INT;
          v_max_players INT;
      BEGIN
          SELECT status, CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END 
          INTO v_game_status, v_max_players
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
      $function$;
    `);
    console.log('Updated switch_player_team');

    // 4. join_game_with_wallet
    await client.query(`
      CREATE OR REPLACE FUNCTION public.join_game_with_wallet(p_user_id character varying, p_game_id character varying, p_position character varying DEFAULT 'MID'::character varying)
      RETURNS character varying
      LANGUAGE plpgsql
      AS $function$
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
          SELECT entry_fee, CASE WHEN format = '5v5' THEN 10 WHEN format = '7v7' THEN 14 ELSE 22 END, status 
          INTO v_entry_fee, v_max_players, v_game_status
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
      $function$;
    `);
    console.log('Updated join_game_with_wallet');

    await client.query('COMMIT');
    console.log('✅ Functions updated successfully!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Update failed:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

run();
