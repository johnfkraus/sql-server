/* =====================================================================
   add-audit-columns.sql  --  SQL Server 2017+
   =====================================================================
   Adds four audit columns to every ordinary user table in the current
   database, backfills existing rows, and creates one maintenance
   trigger per table.

     created_at   DATETIME2(3)  NOT NULL  (default SYSUTCDATETIME())
     created_by   NVARCHAR(128) NULL
     modified_at  DATETIME2(3)  NOT NULL  (default SYSUTCDATETIME())
     modified_by  NVARCHAR(128) NULL

   Semantics
   ---------
   - "Who" is resolved as:
       1. SESSION_CONTEXT(N'app_user_id')  -- set by the application (preferred)
       2. SUSER_SNAME()                    -- database login (fallback)
   - created_* are treated as immutable: on UPDATE the trigger restores
     them from the pre-update row (deleted), so an attempt to rewrite
     history is reverted. On INSERT the trigger fills them only when
     absent (COALESCE against inserted values and the DEFAULT).
   - On INSERT, modified_at is set equal to created_at and modified_by
     to the acting user; on UPDATE only modified_* change.
   - Legacy rows existing before deployment have no knowable creation
     time or author. Timestamps reflect deployment time; created_by is
     marked 'legacy:unknown'. These are rollout-time values, not
     historical facts.
   - These columns capture last-change state only - not an audit
     trail. For history, use system-versioned temporal tables or an
     audit table.

   HOW TO RUN (preview-first, one session)
   ---------------------------------------
   1. Run STEP 0 (inventory) and review the statuses.
   2. Run STEP 1 to build #audit_targets - the approved table list
      every later step uses. Temp tables live for the session, so run
      all steps in the same query window.
   3. Run each GENERATOR, REVIEW the statements it produces, then copy
      the result column into a new query window and execute (each
      generated statement ends with a GO batch separator).
   4. Run the VERIFICATION queries and the BEHAVIORAL TESTS on a dev
      copy of the database first.

   IMPORTANT LIMITATIONS
   ---------------------
   - This is a reviewed, PREVIEW-ONLY generator for ordinary supported
     tables. It has NOT been executed against a live server in this
     session - test on a dev copy before deploying.
   - Excluded from #audit_targets and flagged in STEP 0: system tables,
     system-versioned temporal tables and their history tables,
     memory-optimized tables (AFTER triggers not supported there;
     they need natively compiled triggers), FileTables, external
     tables, and tables that already have some-but-not-all of the four
     audit columns (review those by hand).
   - Rows inserted between the ALTER (STEP 2 output) and the trigger
     creation (STEP 4 output) get created_by backfilled to
     'legacy:unknown'. Run the steps in a maintenance window, or accept
     and correct those rows afterwards.
   - Updating a primary key value itself is an edge case: the
     insert/update detector (deleted.created_at IS NULL) treats it as
     an insert, so modified_at is set from created_at rather than now.
     PK updates are rare and generally discouraged.

   Reference documentation:
   - ALTER TABLE:            https://learn.microsoft.com/sql/t-sql/statements/alter-table-transact-sql
   - CREATE TRIGGER:         https://learn.microsoft.com/sql/t-sql/statements/create-trigger-transact-sql
   - sp_set_session_context: https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql
   - SESSION_CONTEXT:        https://learn.microsoft.com/sql/t-sql/functions/session-context-transact-sql
   - TRIGGER_NESTLEVEL:      https://learn.microsoft.com/sql/t-sql/functions/trigger-nestlevel-transact-sql
   ===================================================================== */

USE YourDatabase;  -- <<< change me
GO

/* =====================================================================
   STEP 0 - Inventory: what will be touched, and what needs attention?
   ===================================================================== */
SELECT s.name AS schema_name,
       t.name AS table_name,
       CASE WHEN t.temporal_type = 2 THEN 'system-versioned temporal - review by hand'
            WHEN t.temporal_type = 1 THEN 'temporal history table (read-only, skipped)'
            WHEN t.is_external = 1 THEN 'external table (skipped)'
            WHEN t.is_memory_optimized = 1 THEN 'memory-optimized - needs natively compiled trigger'
            WHEN t.is_filetable = 1 THEN 'filetable (skipped)'
            WHEN EXISTS (SELECT 1 FROM sys.columns AS c
                         WHERE c.object_id = t.object_id
                           AND c.name IN (N'created_at', N'created_by',
                                          N'modified_at', N'modified_by'))
                 THEN 'partial audit columns already - review by hand'
            WHEN NOT EXISTS (SELECT 1 FROM sys.key_constraints AS kc
                             WHERE kc.parent_object_id = t.object_id
                               AND kc.type = 'PK')
                 THEN 'NO PK - trigger will be skipped, add a key first'
            ELSE 'ok' END AS status
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY CASE WHEN status = 'ok' THEN 1 ELSE 0 END, s.name, t.name;
GO

/* =====================================================================
   STEP 1 - Build the approved target list
   ---------------------------------------------------------------------
   #audit_targets contains ONLY ordinary tables that have none of the
   four audit columns. Every generator and verification below reads
   from this list, so tables flagged in STEP 0 can never be touched
   accidentally by a later step.
   ===================================================================== */
SELECT t.object_id, s.name AS schema_name, t.name AS table_name
INTO #audit_targets
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND t.temporal_type = 0          -- ordinary, non-temporal table
  AND t.is_external = 0
  AND t.is_memory_optimized = 0
  AND t.is_filetable = 0
  AND NOT EXISTS (SELECT 1 FROM sys.columns AS c
                  WHERE c.object_id = t.object_id
                    AND c.name IN (N'created_at', N'created_by',
                                   N'modified_at', N'modified_by'));

SELECT COUNT(*) AS tables_to_modify FROM #audit_targets;
GO

/* =====================================================================
   STEP 2 - GENERATOR: ALTER TABLE ... ADD audit columns
   ---------------------------------------------------------------------
   Constraint names embed the table's object_id (schema-scoped
   uniqueness, no 128-character overflow, no collisions).
   ===================================================================== */
SELECT N'ALTER TABLE ' + QUOTENAME(a.schema_name) + N'.' + QUOTENAME(a.table_name) + N'
    ADD created_at  DATETIME2(3)  NOT NULL
        CONSTRAINT ' + QUOTENAME(N'df_created_at_' + CAST(a.object_id AS nvarchar(20)))  + N' DEFAULT SYSUTCDATETIME(),
        created_by  NVARCHAR(128) NULL,
        modified_at DATETIME2(3)  NOT NULL
        CONSTRAINT ' + QUOTENAME(N'df_modified_at_' + CAST(a.object_id AS nvarchar(20))) + N' DEFAULT SYSUTCDATETIME(),
        modified_by NVARCHAR(128) NULL;
GO'
FROM #audit_targets AS a
ORDER BY a.schema_name, a.table_name;
GO

/* =====================================================================
   STEP 3 - GENERATOR: backfill created_by for legacy rows
   ---------------------------------------------------------------------
   The true original author of pre-existing rows is unknowable, so the
   marker is explicit: 'legacy:unknown'. Timestamps were already set to
   deployment time by the DEFAULT backfill. modified_by is left NULL -
   no modifications have occurred since deployment. Adjust to suit.
   ===================================================================== */
SELECT N'UPDATE ' + QUOTENAME(a.schema_name) + N'.' + QUOTENAME(a.table_name) + N'
    SET created_by = N''legacy:unknown''
    WHERE created_by IS NULL;
GO'
FROM #audit_targets AS a
ORDER BY a.schema_name, a.table_name;
GO

/* =====================================================================
   STEP 4 - GENERATOR: one maintenance trigger per table
   ---------------------------------------------------------------------
   - Fires FOR INSERT, UPDATE.
   - Affected rows only: the base table is joined to `inserted` through
     the table's primary key (composite keys supported).
   - created_* are immutable after insert: on UPDATE they are restored
     from `deleted` (the pre-update row). On INSERT they are filled
     only when the application did not supply them.
   - On INSERT, modified_at = created_at (exact match) and modified_by
     = acting user; on UPDATE, modified_at = now, modified_by = acting
     user.
   - TRIGGER_NESTLEVEL(@@PROCID, ...) stops THIS trigger from
     re-firing itself; it does not block legitimate nesting from other
     triggers. Note the maintenance UPDATE can fire other AFTER UPDATE
     triggers on the same table - include that in testing.
   - Skipped for target tables with no PK (no reliable way to identify
     affected rows). A suitable unique NOT NULL key works too if you
     adapt the join condition.
   ===================================================================== */
WITH pk_cols AS (
    SELECT
        kc.parent_object_id AS object_id,
        STRING_AGG(
            CONVERT(nvarchar(max), QUOTENAME(c.name)),
            N', ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS pk_list,
        STRING_AGG(
            CONVERT(nvarchar(max),
                N't.' + QUOTENAME(c.name) + N' = i.' + QUOTENAME(c.name)),
            N' AND ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS join_t_i,
        STRING_AGG(
            CONVERT(nvarchar(max),
                N'd.' + QUOTENAME(c.name) + N' = i.' + QUOTENAME(c.name)),
            N' AND ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS join_d_i
    FROM sys.key_constraints AS kc
    JOIN sys.index_columns AS ic
           ON ic.object_id = kc.parent_object_id
          AND ic.index_id = kc.unique_index_id
    JOIN sys.columns AS c
           ON c.object_id = ic.object_id
          AND c.column_id = ic.column_id
    WHERE kc.type = N'PK'
      AND ic.key_ordinal > 0
    GROUP BY kc.parent_object_id
)
SELECT
    N'CREATE OR ALTER TRIGGER '
    + QUOTENAME(a.schema_name) + N'.'
    + QUOTENAME(LEFT(N'trg_' + a.table_name + N'_'
                      + CAST(a.object_id AS nvarchar(20)) + N'_audit', 128))
    + N'
ON ' + QUOTENAME(a.schema_name) + N'.' + QUOTENAME(a.table_name) + N'
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL(@@PROCID, ''AFTER'', ''DML'') > 1
        RETURN;
    UPDATE t
    SET t.created_at  = COALESCE(d.created_at, i.created_at, SYSUTCDATETIME()),
        t.created_by  = COALESCE(d.created_by, i.created_by,
                                COALESCE(CAST(SESSION_CONTEXT(N''app_user_id'') AS NVARCHAR(128)),
                                         SUSER_SNAME())),
        t.modified_at = CASE WHEN d.created_at IS NULL
                              THEN COALESCE(i.created_at, SYSUTCDATETIME())
                              ELSE SYSUTCDATETIME() END,
        t.modified_by = COALESCE(CAST(SESSION_CONTEXT(N''app_user_id'') AS NVARCHAR(128)),
                                 SUSER_SNAME())
    FROM ' + QUOTENAME(a.schema_name) + N'.' + QUOTENAME(a.table_name) + N' AS t
    INNER JOIN inserted AS i ON ' + pk.join_t_i + N'
    LEFT JOIN deleted AS d ON ' + pk.join_d_i + N';
END
GO'
FROM #audit_targets AS a
JOIN pk_cols AS pk ON pk.object_id = a.object_id
UNION ALL
SELECT N'/* WARNING: ' + QUOTENAME(a.schema_name) + N'.' + QUOTENAME(a.table_name)
     + N' has no primary key - audit trigger skipped. */'
FROM #audit_targets AS a
WHERE NOT EXISTS (SELECT 1 FROM sys.key_constraints AS kc
                  WHERE kc.parent_object_id = a.object_id AND kc.type = 'PK')
ORDER BY 1;
GO

/* =====================================================================
   APPLICATION SIDE - passing the real user through
   ---------------------------------------------------------------------
   If the application connects under a single service account,
   SUSER_SNAME() is useless for "who". Have the app set the acting user
   once per request (works with connection pooling - set it after the
   connection is checked out, not once per connection):

     EXEC sys.sp_set_session_context
          @key = N'app_user_id',
          @value = @current_user,     -- e.g. 'jane@yourco.com'
          @read_only = 0;            -- 1 prevents later changes on this
                                      -- logical connection

   The trigger reads it with SESSION_CONTEXT(N'app_user_id') and falls
   back to SUSER_SNAME() when unset. Swap in ORIGINAL_LOGIN() if you
   want the original connecting login rather than the execution
   context. Note this is application-supplied attribution, not
   independently authenticated identity.
   ===================================================================== */

/* =====================================================================
   VERIFICATION (same session as #audit_targets)
   ===================================================================== */

-- 1. All four columns exist on every target table?
SELECT a.schema_name, a.table_name,
       MAX(CASE WHEN c.name = 'created_at'  THEN 1 ELSE 0 END) AS has_created_at,
       MAX(CASE WHEN c.name = 'created_by'  THEN 1 ELSE 0 END) AS has_created_by,
       MAX(CASE WHEN c.name = 'modified_at' THEN 1 ELSE 0 END) AS has_modified_at,
       MAX(CASE WHEN c.name = 'modified_by' THEN 1 ELSE 0 END) AS has_modified_by
FROM #audit_targets AS a
LEFT JOIN sys.columns AS c ON c.object_id = a.object_id
GROUP BY a.object_id, a.schema_name, a.table_name
HAVING MAX(CASE WHEN c.name = 'created_at'  THEN 1 ELSE 0 END) = 0
    OR MAX(CASE WHEN c.name = 'created_by'  THEN 1 ELSE 0 END) = 0
    OR MAX(CASE WHEN c.name = 'modified_at' THEN 1 ELSE 0 END) = 0
    OR MAX(CASE WHEN c.name = 'modified_by' THEN 1 ELSE 0 END) = 0;
-- Empty result = every target table has all four columns.

-- 2. Audit trigger present, enabled, and firing on BOTH INSERT and
--    UPDATE for every target table with a PK?
SELECT a.schema_name, a.table_name
FROM #audit_targets AS a
WHERE EXISTS (SELECT 1 FROM sys.key_constraints AS kc
              WHERE kc.parent_object_id = a.object_id AND kc.type = 'PK')
  AND 2 <> (SELECT COUNT(DISTINCT te.type_desc)
            FROM sys.triggers AS tr
            JOIN sys.trigger_events AS te ON te.object_id = tr.object_id
            WHERE tr.parent_id = a.object_id
              AND tr.name = LEFT(N'trg_' + a.table_name + N'_'
                                 + CAST(a.object_id AS nvarchar(20)) + N'_audit', 128)
              AND tr.is_disabled = 0
              AND te.type_desc IN ('INSERT', 'UPDATE'));
-- Empty result = every PK target table has an enabled trigger
-- firing on both events.

/* =====================================================================
   BEHAVIORAL TESTS (run on a dev copy before deploying)
   ---------------------------------------------------------------------
   1. Fresh insert with no audit values supplied:
      expect all four stamped; modified_at = created_at exactly;
      modified_by = acting user.
   2. Insert with explicit created_by supplied:
      expect the explicit value preserved; modified_by = acting user.
   3. Single-row and multi-row UPDATE:
      expect only touched rows' modified_* to change; untouched rows
      keep their values; created_* never change.
   4. UPDATE that tries to change created_at / created_by:
      expect the trigger to restore the original values.
   5. A composite-primary-key table: same expectations.
   6. With and without SESSION_CONTEXT set:
      expect app_user_id when set, SUSER_SNAME() when not.
   7. Direct recursion enabled (ALTER DATABASE ... SET
      RECURSIVE_TRIGGERS ON): expect the trigger to return early, no
      infinite loop.
   8. A table that already has an AFTER UPDATE trigger: confirm the
      two triggers coexist. Note the maintenance UPDATE may re-fire
      the other trigger depending on database nesting settings -
      verify the combined behavior is what you expect.
   9. Rows inserted during deployment (between STEP 2 output and
      STEP 4 output): confirm whether any received 'legacy:unknown'
      and correct them if so.
   ===================================================================== */
