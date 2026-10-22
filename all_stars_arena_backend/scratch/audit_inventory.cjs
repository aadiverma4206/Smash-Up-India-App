const pg = require('pg');

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres:system@127.0.0.1:5432/all_stars_arena',
});

async function runAudit() {
  const client = await pool.connect();
  try {
    console.log('--- DATABASE INFO ---');
    const dbInfo = await client.query(`
      SELECT current_database() as db_name, version() as pg_version, current_schema() as current_schema;
    `);
    console.log(JSON.stringify(dbInfo.rows, null, 2));

    console.log('\n--- EXTENSIONS ---');
    const extInfo = await client.query(`
      SELECT extname, extversion FROM pg_extension ORDER BY extname;
    `);
    console.log(JSON.stringify(extInfo.rows, null, 2));

    console.log('\n--- TABLES & SIZES & STATS ---');
    const tableStats = await client.query(`
      SELECT
        c.relname AS table_name,
        c.reltuples::bigint AS est_row_count,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
        pg_relation_size(c.oid) AS table_bytes,
        pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
        pg_indexes_size(c.oid) AS indexes_bytes,
        pg_size_pretty(pg_indexes_size(c.oid)) AS indexes_size,
        COALESCE(stat.n_dead_tup, 0) AS dead_tuples,
        COALESCE(stat.n_live_tup, 0) AS live_tuples,
        stat.last_vacuum,
        stat.last_autovacuum,
        stat.last_analyze,
        stat.last_autoanalyze
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_stat_user_tables stat ON stat.relid = c.oid
      WHERE n.nspname = 'public' AND c.relkind = 'r'
      ORDER BY pg_total_relation_size(c.oid) DESC;
    `);
    console.log(JSON.stringify(tableStats.rows, null, 2));

    console.log('\n--- COMPLETE INDEX INVENTORY ---');
    const indexInventory = await client.query(`
      SELECT
        t.relname AS table_name,
        i.relname AS index_name,
        am.amname AS index_type,
        ix.indisunique AS is_unique,
        ix.indisprimary AS is_primary,
        pg_get_indexdef(ix.indexrelid) AS index_definition,
        pg_relation_size(i.oid) AS index_bytes,
        pg_size_pretty(pg_relation_size(i.oid)) AS index_size,
        COALESCE(s.idx_scan, 0) AS idx_scan,
        COALESCE(s.idx_tup_read, 0) AS idx_tup_read,
        COALESCE(s.idx_tup_fetch, 0) AS idx_tup_fetch
      FROM pg_index ix
      JOIN pg_class t ON t.oid = ix.indrelid
      JOIN pg_class i ON i.oid = ix.indexrelid
      JOIN pg_am am ON am.oid = i.relam
      JOIN pg_namespace n ON n.oid = t.relnamespace
      LEFT JOIN pg_stat_user_indexes s ON s.indexrelid = ix.indexrelid
      WHERE n.nspname = 'public'
      ORDER BY t.relname, ix.indisprimary DESC, ix.indisunique DESC, i.relname;
    `);
    console.log(JSON.stringify(indexInventory.rows, null, 2));

    console.log('\n--- FOREIGN KEYS AND INDEX COVERAGE ---');
    const fkInfo = await client.query(`
      SELECT
        c.conname AS fk_name,
        tbl.relname AS table_name,
        ARRAY_TO_STRING(ARRAY_AGG(att.attname ORDER BY u.attposition), ', ') AS fk_columns,
        ref_tbl.relname AS referenced_table,
        ARRAY_TO_STRING(ARRAY_AGG(ref_att.attname ORDER BY u.attposition), ', ') AS referenced_columns,
        (
          SELECT string_agg(idx.relname, '; ')
          FROM pg_index i
          JOIN pg_class idx ON idx.oid = i.indexrelid
          WHERE i.indrelid = c.conrelid
            AND (i.indkey::smallint[])[0:cardinality(c.conkey)-1] = c.conkey
        ) AS covering_indexes
      FROM pg_constraint c
      JOIN pg_class tbl ON tbl.oid = c.conrelid
      JOIN pg_class ref_tbl ON ref_tbl.oid = c.confrelid
      JOIN pg_namespace n ON n.oid = tbl.relnamespace
      CROSS JOIN LATERAL UNNEST(c.conkey) WITH ORDINALITY AS u(attnum, attposition)
      JOIN pg_attribute att ON att.attrelid = c.conrelid AND att.attnum = u.attnum
      JOIN LATERAL (
        SELECT confkey[u.attposition] AS ref_attnum
        FROM pg_constraint
        WHERE oid = c.oid
      ) ref_pos ON true
      JOIN pg_attribute ref_att ON ref_att.attrelid = c.confrelid AND ref_att.attnum = ref_pos.ref_attnum
      WHERE c.contype = 'f' AND n.nspname = 'public'
      GROUP BY c.conname, tbl.relname, ref_tbl.relname, c.conrelid, c.conkey
      ORDER BY tbl.relname, c.conname;
    `);
    console.log(JSON.stringify(fkInfo.rows, null, 2));

  } catch (err) {
    console.error('Audit query error:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

runAudit();
