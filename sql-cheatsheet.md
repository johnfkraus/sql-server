# SQL Cheatsheet

## Decimal data type

In MS SQL Server, the DECIMAL and NUMERIC data types are functionally identical synonyms used to store exact, fixed-precision numeric values. They are critical for applications requiring absolute accuracy, such as financial and monetary data. [1] (<https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17>), [2] (<https://www.geeksforgeeks.org/sql-server/sql-server-decimal-data-type/>)

Syntax

```sql
DECIMAL (precision [, scale])
```

Use code with caution.
• precision (p): The maximum total number of digits that can be stored (including digits on both sides of the decimal point). It ranges from 1 to 38 (default is 18). [1] (<https://www.sqlshack.com/understanding-sql-decimal-data-type/>)
• scale (s): The maximum number of digits stored to the right of the decimal point. This value must be between 0 and the specified precision (default is 0). Scale can only be specified if precision is defined. [1] (<https://www.dofactory.com/sql/decimal>), [2] (<https://www.promotic.eu/en/pmdoc/Subsystems/Db/MsSQL/DataTypes.htm>), [3] (<https://www.sqlshack.com/understanding-sql-decimal-data-type/>)

Direct Behavior & Storage Impact

The physical storage requirements vary dynamically depending on the declared precision: [1] (<https://www.dofactory.com/sql/decimal>)

Precision - Storage Bytes
1 – 9, 5 bytes
10 – 19, 9 bytes
20 – 28, 13 bytes
29 – 38, 17 bytes

Practical Verification Example

Consider how SQL Server allocates digits based on your configuration:

• DECIMAL(5,2) can hold a maximum of 5 digits total, with exactly 2 to the right of the decimal point (e.g., -999.99 to 999.99).

• Trying to insert 1234.56 into a DECIMAL(5,2) column will trigger an arithmetic overflow error because it requires 4 digits before the decimal and 2 after, totaling 6 digits. [1] (<https://www.geeksforgeeks.org/sql-server/sql-server-decimal-data-type/>), [2] (<https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17>)

• If you insert a value with more decimal places than the defined scale (e.g., inserting 123.456 into a DECIMAL(5,2) column), SQL Server will automatically round the value to 123.46. [1] (<https://www.sqlservercentral.com/forums/topic/understanding-the-numeric-and-decimal-data-types>), [2] (<https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17>)

Important Considerations

• Different Data Types: SQL Server treats every unique combination of precision and scale as a distinct data type. For example, DECIMAL(10,2) and DECIMAL(10,4) are considered completely separate types during operations. [1] (<https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17>)
• Default Behavior: If you write DECIMAL without parameters, it evaluates to DECIMAL(18,0). [1] (<https://www.sqlshack.com/understanding-sql-decimal-data-type/>)
If you are setting up a database schema, let me know:
• What kind of data are you looking to store? (e.g., currency, precise scientific metrics, percentages)
• Do you need help calculating the ideal precision and scale for your specific range of values?

## Using ms sql server, how does the money data type differ from other numeric types that might be used to represent monetary amounts?

In SQL Server, the `MONEY` (and `SMALLMONEY`) data type differs from alternative numeric types—specifically `DECIMAL`/`NUMERIC` and `FLOAT`—in storage implementation, precision behavior, performance, and formatting.

## Core Comparison Matrix

| Feature / Behavior | `MONEY` | `DECIMAL(p, s)` / `NUMERIC(p, s)` | `FLOAT` / `REAL` |
| --- | --- | --- | --- |
| **Internal Storage** | 8-byte integer (scaled by 10,000) | 5 to 17 bytes (depends on precision $p$) | 4 or 8 bytes (binary floating-point) |
| **Fixed Scale** | Fixed strictly at **4 decimal places** | Variable (user-defined $0$ to $38$) | Dynamic / Approximate |
| **Data Nature** | Exact integer scale | Exact decimal scale | Approximate representation |
| **Rounding Risks** | **High** during intermediate calculations | Controlled precision | High due to floating-point representation |

---

## Key Technical Differences

### 1. Calculation Rounding Errors (The Biggest Drawback)

Because `MONEY` is implemented internally as an integer scaled by 10,000, intermediate calculations involving division or multiplication can suffer from truncation and precision loss before the final result is evaluated.

```sql
-- MONEY division rounding example
DECLARE @m1 MONEY = 10.00, @m2 MONEY = 3.00;
SELECT (@m1 / @m2) * @m2; 
-- Result: 9.9999 (Precision loss due to intermediate 4-decimal truncation)

-- DECIMAL precision safety
DECLARE @d1 DECIMAL(19,4) = 10.00, @d2 DECIMAL(19,4) = 3.00;
SELECT (@d1 / @d2) * @d2; 
-- Result: 10.00000000

```

### 2. Fixed vs. Customizable Scale

* **`MONEY`**: Fixed at 4 decimal digits after the decimal point. If your application needs sub-cent rates (e.g., micro-transactions, currency exchange rates with 6 digits, or fuel pricing), `MONEY` cannot store those values directly without rounding.
* **`DECIMAL(p, s)`**: Allows you to explicitly define total digits ($p$) and decimal scale ($s$). For financial systems, `DECIMAL(19,4)` or `DECIMAL(18,2)` is standard practice.

### 3. Currency Symbols & Implicit Conversions

SQL Server allows literals prefixed with currency symbols (e.g., `$100.50`, `£50.00`) to implicitly convert to `MONEY`. However, `MONEY` does **not** store locale or currency code metadata (e.g., USD vs. EUR); it stores only the numeric quantity.

### 4. Storage & Performance Characteristics

Because `MONEY` uses an 8-byte integer under the hood, basic arithmetic operations (addition/subtraction) can be slightly faster than CPU operations on variable-length `DECIMAL` types. However, on modern hardware, this micro-optimization rarely outweighs the risk of calculation precision errors.

---

## Best Practices Recommendation

* **Avoid `MONEY` for complex calculations:** Most SQL database administrators and financial software developers avoid `MONEY` because of its tendency to produce silent rounding errors in intermediate steps (such as applying tax rates or discounts).
* **Use `DECIMAL(p, s)`:** Use `DECIMAL(19,4)` for general financial data to maintain accuracy across multi-step calculations, or `DECIMAL(18,2)` when strict two-decimal currency precision is required.

## Introducing Relational Integrity

I have a database with a lot of tables.  How can I identify what changes I might need to make to enforce relational integrity?

Here's a practical way to approach it: treat it as a metadata-driven audit that produces a prioritized change list, rather than reviewing tables one by one.

## Workflow

**1. Inventory the rules you already have.** Query the system catalog for tables, columns, primary keys, unique constraints, foreign keys, and nullability — and note which constraints are actually enforced versus just declared. This shows where coverage is thin, but it won't reveal relationships that were never declared.

**2. Infer intended relationships.** Look for columns with matching names and compatible types (`customer_id` in an orders table pointing at a customers table, for example), then confirm against application queries or documentation. Name similarity is a strong hint, not proof — this is the step that needs your judgment, since profiling can find violations of a proposed rule but can't tell you which business relationships should exist.

**3. Profile the data for each candidate rule.** For every table and relationship, check:

* Missing or unsuitable primary keys (no key at all, or a key that isn't actually unique)

* Duplicate candidate/business keys, including duplicates where NULLs participate (`GROUP BY` identity columns with `HAVING COUNT(*) > 1`)
* Orphaned child rows — references with no matching parent (a two-way `EXCEPT` between the child's key values and the parent's key)
* NULLs in columns a relationship would require to be NOT NULL
* Composite and tenant-scoped keys, not just single-column IDs
* Type or collation mismatches between related columns

**4. Produce a change report.** For each finding, record the table/columns, the proposed constraint, the count of violating rows, and sample records — and separate confirmed findings from relationships needing your confirmation. This gives you a preview before any destructive cleanup, which fits how you like to work.

**5. Remediate in dependency order.** Resolve parent-key duplicates first, then invalid child references (fix, quarantine, or delete), then establish parent uniqueness, and only then add foreign keys and NOT NULL constraints — a constraint added before its violations are cleaned up will simply fail to create.

## Key decisions to make along the way

* What to do with orphans and duplicates — repair, quarantine, or delete (repair or quarantine is usually safer)
* Whether to use cascading deletes on foreign keys — this is a business decision, not a technical one, and I'd avoid defaulting to it
* Which key is the real business identity for each table — your preference for a stable business key rather than a surrogate applies here too

Which database engine is this — SQL Server, Postgres, DuckDB, or something else? I can help build a read-only audit script that generates this report across all your tables.

What are declared relationships?

Declared relationships are the ones formally encoded in the database itself as constraints — most commonly foreign keys, plus primary and unique constraints that define what each table's key is. For example, `FOREIGN KEY (customer_id) REFERENCES customers(id)` is a declared relationship: the database engine knows it, enforces it on every insert and update, and rejects any row that would break it.

The contrast is with *undeclared* relationships — ones that exist only by convention. If your `orders` table has a `customer_id` column that matches `customers.id`, but no foreign key constraint was ever created, the relationship is real in practice but invisible to the database. Nothing stops an order from pointing at a customer who doesn't exist. This is extremely common in schemas that grew organically or were built by ORMs that don't create constraints.

That's why step 1 of the audit matters: the catalog tells you what's declared, but the real relationship map is usually bigger. The undeclared ones are exactly where you'll find most of the integrity gaps — orphaned rows, duplicate "keys," and columns that look like they reference something but don't.

## Add audit columns

### Prompt: I want to add to all the existing tables columns identifying when the row was created or modified and by who.  How?

Adding audit columns to every table is a three-part job: add the columns, backfill existing rows, and set up automatic maintenance going forward. The column set is standard:

* `created_at` / `created_by` — set once at insert
* `modified_at` / `modified_by` — updated on every change

## Step 1: Generate the DDL for all tables

Don't hand-write ALTERs — generate them from the catalog. The pattern in SQL Server:

```sql
SELECT 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) +
       ' ADD created_at DATETIME2 NOT NULL CONSTRAINT ' +
       QUOTENAME(t.name + '_created_at_df') + ' DEFAULT SYSUTCDATETIME(), ' +
       'created_by NVARCHAR(100) NULL, ' +
       'modified_at DATETIME2 NOT NULL CONSTRAINT ' +
       QUOTENAME(t.name + '_modified_at_df') + ' DEFAULT SYSUTCDATETIME(), ' +
       'modified_by NVARCHAR(100) NULL;'
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0;
```

In Postgres it's the same idea against `information_schema.tables` or `pg_catalog`. Generated statements give you a reviewable preview of exactly what will run before you run it — same discipline as previewing data changes.

## Step 2: Backfill existing rows

The `DEFAULT` on the added columns timestamps every existing row as "now," which is fine for `created_at` if you accept it (the true creation time is unknowable retroactively). For `created_by`, existing rows have no known author — either leave it NULL or set a marker like `'system'`:

```sql
UPDATE your_table SET created_by = 'system' WHERE created_by IS NULL;
```

If you want real history for the future, that's a different feature — change tracking (SQL Server) or an audit/event table — since these columns only capture current state.

## Step 3: Keep them maintained automatically

Defaults only cover inserts. Updates need a trigger, because the application won't reliably set `modified_at`/`modified_by`:

```sql
CREATE TRIGGER trg_yourtable_audit ON your_table
AFTER UPDATE AS
BEGIN
  UPDATE t SET modified_at = SYSUTCDATETIME(), modified_by = SUSER_SNAME()
  FROM your_table t
  JOIN inserted i ON t.id = i.id;
END
```

In Postgres, a single trigger function handles all tables:

```sql
CREATE OR REPLACE FUNCTION set_audit_columns() RETURNS trigger AS $$
BEGIN
  NEW.modified_at := now();
  NEW.modified_by := current_user;
  RETURN NEW;
END $$ LANGUAGE plpgsql;
```

Then attach it with `BEFORE INSERT OR UPDATE` to each table — those attachments can also be generated from the catalog, and the trigger function can set `created_at`/`created_by` on insert too.

## Two decisions worth making up front

* **Who "by" means:** the database login (`SUSER_SNAME()` / `current_user`) is easy but usually useless if the app connects as one service account. If you need the real application user, the trigger needs to receive it — typically via `SESSION_CONTEXT` (SQL Server) or a custom GUC like `SET LOCAL app.user_id = '...'` (Postgres), with the app setting it per request.
* **UTC vs local:** store timestamps as UTC (`SYSUTCDATETIME()`, or `timestamptz` in Postgres) and convert for display — avoids ambiguity across DST transitions.

Which engine is this? I can write the full catalog-driven script (generation, backfill, and triggers) for it.

### Using MS SQL Server, I want to add to all the existing tables columns identifying when the row was created or modified and by who. How?

I've written a complete, catalog-driven script for you: [add-audit-columns.sql](add-audit-columns.sql). It's a preview-first generator — every step produces reviewable DDL before anything executes — and it requires SQL Server 2017+ (`STRING_AGG`, `CREATE OR ALTER TRIGGER`).

## How it works

**Step 0 — Inventory.** Lists every table with a status: OK, no primary key (trigger skipped), already has some audit columns (review by hand), or special types that need separate handling — system-versioned temporal tables, memory-optimized tables, FileTables, external tables.

**Step 1 — Approved target list.** Builds a `#audit_targets` temp table of ordinary tables that have none of the four columns. Every later step reads from this list, so flagged tables can't be touched accidentally. Constraint names embed the table's `object_id` to avoid name collisions.

**Steps 2–3 — Add columns and backfill.** Each table gets `created_at`/`modified_at` as `DATETIME2(3) NOT NULL` with `SYSUTCDATETIME()` defaults, plus nullable `created_by`/`modified_by`. Existing rows get deployment-time timestamps and `created_by = 'legacy:unknown'` — the true original author is unknowable, so the marker is explicit rather than pretending.

**Step 4 — One trigger per table.** Fires on INSERT and UPDATE, joined through each table's primary key (composite keys supported). Key behaviors:

* `created_*` are immutable — an UPDATE that tries to rewrite them gets reverted from the pre-update row
* On insert, `modified_at` equals `created_at` exactly and `modified_by` gets the acting user; on update only `modified_*` change
* A recursion guard stops the trigger from re-firing itself without blocking legitimate trigger nesting

**"Who" resolution.** The trigger prefers `SESSION_CONTEXT(N'app_user_id')` — your app sets it once per request via `sp_set_session_context` (works with connection pooling) — and falls back to `SUSER_SNAME()` for the database login.

## Caveats worth knowing

* The script has been carefully reviewed but not executed against a live server here — run it against a dev copy first, using the nine behavioral tests at the bottom (including the "UPDATE that tries to change history" case).
* Rows inserted between the ALTER and the trigger creation get the legacy marker — run in a maintenance window or correct them after.
* Tables with no primary key get columns but no trigger; your relational-integrity audit from earlier is the natural place to fix that.
* These columns capture last-change state only. If you later want true history, that's system-versioned temporal tables or a CDC/audit table.

If you tell me roughly how many tables you're dealing with and whether the app connects as a single service account, I can help you plan the deployment window and the session-context wiring on the application side.

## Users, Permissions

A React 19 web application has a [dot.net](http://dot.net) backend with a MS SQL Server database with three separate databases.  All three databases are queried when application users engage with the web site.  Application users are defined and controlled in one of the database tables.  There is a front-end developer, a back-end developer and a database administrator/data engineer.  The application exists in the following environments: development, pre-production and production.  The application is deployed in an internal network without exposure to the public internet.
The database is used directly by the developers and data engineer and also by the application.  How should database users and developers be defined?  How many database users should there be?  Who should own the databases?  What database permissions should the database users and the application have?  How should database users/owners and permissions be organized?

Verified and corrected. Here is the complete design.

## First, Separate the Three Identity Layers

The website users defined in your application table are **business identities** — SQL Server never needs to know about them. The React frontend should never connect to SQL Server or hold database credentials; only the .NET backend does. That gives you three distinct layers:

1. **Application users** — authenticated by the backend, authorized by application code against your users table.
2. **SQL Server principals** — a **login** authenticates to the instance, a **database user** maps that login into one specific database, and **roles** collect permissions. A single login can be mapped as a user into each of your three databases, with different permissions in each. [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/principals-database-engine?view=sql-server-ver17)
3. **Ownership** — a separate concept from administration, covered below.

Because the backend connects with a shared service identity, SQL Server audit trails show the backend service, not the website user. Your application must therefore log its own user identity for audit purposes; direct human SQL access remains attributable through named accounts.

## How Many Database Users

Never create SQL accounts per website user. Assuming one backend workload legitimately needs all three databases in each environment, start with **three runtime identities — one per environment — and nine mapped database users, one in each database copy**. The exact number of server logins depends on how your databases are distributed across instances.

Beyond that baseline, count separately:

| Identity | Purpose | Count |
| --- | --- | --- |
| App runtime login | Backend data access, one per environment | 3 logins → 9 database users |
| Deployment login | CI/CD migrations, one per environment | 3 logins → 9 database users |
| Owner login(s) | Holds database ownership, disabled | 1+ per environment |
| Human access | AD groups mapped to database roles | ~3–5 groups per environment |
| ETL login (optional) | If the data engineer runs scheduled jobs | 1 per environment |

If Windows-integrated authentication with an organizational directory is available (likely on an internal network, but not guaranteed), use it — managed service accounts for the backend and AD groups for humans, per Microsoft's security best practices and Secure your SQL Server guidance. Grant permissions to the groups/roles, never to individual accounts. [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/security/sql-server-security-best-practices?view=sql-server-ver17)

## Who Owns the Databases

Not a developer, not the application account, and not anyone's personal login. Ownership is a security trust decision, not an administrative convenience: the owner maps to the database's built-in `dbo` user, which is distinct from the `db_owner` role and confers substantial authority. [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/principals-database-engine?view=sql-server-ver17)

The recommended pattern is a **dedicated, disabled, non-personal SQL login with no additional server privileges** as the owner — it exists solely to hold ownership and cannot authenticate. Microsoft's guidance adds: have distinct owners for databases, minimize owners per database, and confer trust selectively. [andreas-wolter](https://andreas-wolter.com/en/sql-server-database-ownership-survey-results-recommendations/)

For your three databases: default to **distinct owner principals per database and per environment**. Sharing one owner across the three should be an explicit decision that they form one trust boundary — "the app queries all three" alone doesn't establish that. Your DBA can fully administer the databases without owning them.

## Permissions Matrix

The application should **never** receive `sysadmin`, `db_owner`, or `db_ddladmin`. Prefer a custom database role with the specific schema-scoped permissions the backend actually uses — `db_datareader`/`db_datawriter` grant database-wide access to every table, which is broader than least privilege. Sensitive tables — especially the application-user/credential table — deserve restricted access so that unrelated reporting or human accounts can't read authentication data; how the backend itself accesses it depends on your stack (direct grants or procedures are both legitimate). [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-ver17)

| Principal | Development | Pre-production | Production |
| --- | --- | --- | --- |
| **App runtime** | Custom role, data + EXECUTE | Same as prod (test it there) | Custom role, data + EXECUTE |
| **Deployment/CI** | `db_ddladmin` + data | `db_ddladmin` + data | `db_ddladmin` + data, migrations only |
| **Frontend dev** | No DB access | None | None |
| **Backend dev** | DDL + data as needed; full ownership-level access only in an isolated dev sandbox | Read-oriented; approved writes for testing if the team's process supports it | No standing access |
| **Data engineer** | Broad data access | Scoped data access | Scoped to actual duties |
| **DBA** | Instance admin | Instance admin | Routine named access + separately controlled elevated path |

This matrix is a recommended baseline to adapt to your team's process — not fixed rules. Schema migrations run under the deployment identity, never the runtime identity, and development permissions must not silently carry into production (which is also a reason to consider masking dev copies of production data).

## Cross-Database and Trust Decisions

Map the app login into each of the three databases and grant permissions separately in each. Ordinary cross-database queries work fine with proper per-database grants. Avoid two tempting shortcuts:

* **`TRUSTWORTHY ON`** — opens broad privilege-escalation paths; leave it OFF. [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/security/trustworthy-database-property?view=sql-server-ver17)
* **Cross-database ownership chaining** — keep it OFF unless all databases are deployed as a single unit and you understand the implications. [learn.microsoft](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/cross-db-ownership-chaining-server-configuration-option?view=sql-server-ver17)

If a stored procedure ever needs controlled permissions beyond its caller's (e.g., cross-database access with dynamic SQL), use **certificate module signing** rather than either shortcut. [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-signing-stored-procedures-with-a-certificate?view=sql-server-ver17)

## How to Organize It

* **Environments on separate SQL Server instances** where feasible. If environments share an instance, acknowledge the boundary honestly: whoever administers that instance is trusted with all environments — separate logins per environment do not change that.
* **Grant to groups and roles, not people**: AD group → database user → custom database role → schema-scoped permissions. Use schemas to scope permissions within each database. [learn.microsoft](https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/ownership-and-user-schema-separation?view=sql-server-ver17)
* **Deployment identity** held by CI/CD, not by individuals, for schema changes.
* **DBA elevation in production**: routine named access for daily work, plus a separate, auditable elevation path (separate group or approval workflow) for exceptional actions — not just break-glass.

A minimal example of the model for one production database:

```sql
-- Server level (run in master)
CREATE LOGIN [APP_MyApp_Prod] FROM WINDOWS;   -- or gMSA/SQL login
CREATE LOGIN [svc_MyApp_Deploy_Prod] FROM WINDOWS;
CREATE LOGIN [usr_MyApp_Owner] WITH PASSWORD = '...';  -- owner only
ALTER LOGIN [usr_MyApp_Owner] DISABLE;

-- Per database (repeat in each of the three)
USE [AppDb1];
CREATE USER [APP_MyApp_Prod] FOR LOGIN [APP_MyApp_Prod];
CREATE ROLE [app_runtime];
ALTER ROLE [app_runtime] ADD MEMBER [APP_MyApp_Prod];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO [app_runtime];
GRANT EXECUTE ON SCHEMA::dbo TO [app_runtime];
-- Deny access to the credentials table to everyone but the login path
DENY SELECT ON dbo.AppUsers TO [app_runtime]; -- then grant via proc/signature if needed

ALTER AUTHORIZATION ON DATABASE::[AppDb1] TO [usr_MyApp_Owner];
```

The core idea throughout: **one narrow runtime identity per environment, one deployment identity for schema changes, humans through groups mapped to custom roles, ownership held by a dedicated disabled login, and no broad shortcuts for cross-database access.**

## Log deleted rows

Using ms sql server, can I use a trigger to log info on a row that has been deleted?

Yes — SQL Server makes this easy with the `deleted` virtual table inside an `AFTER DELETE` trigger. Every row affected by the delete is visible there, so you can copy whatever you want into a log table.

```sql
-- One-time setup: a log table
CREATE TABLE dbo.Employee_AuditLog (
    AuditID     INT IDENTITY PRIMARY KEY,
    EmployeeID  INT           NOT NULL,
    FirstName   NVARCHAR(50),
    LastName    NVARCHAR(50),
    DeletedAt   DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
    DeletedBy   NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME()
);
GO

CREATE TRIGGER trg_Employee_Delete
ON dbo.Employee
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Employee_AuditLog (EmployeeID, FirstName, LastName)
    SELECT EmployeeID, FirstName, LastName
    FROM deleted;
END
```

A few things worth knowing:

* **`deleted` is a virtual table** holding the *pre-delete* row images for everything the statement touched — full column values, not just the primary key. Handle it as a set; never assume one row.
* **The trigger fires once per statement**, not per row — so a single `DELETE` that removes 10,000 rows produces one trigger execution with 10,000 rows in `deleted`.
* **For UPDATE triggers**, the same trick works: `deleted` holds the before-image and `inserted` holds the after-image.
* **If you might want to recover rows**, consider a "soft delete" (`INSTEAD OF DELETE` trigger that flips an `IsDeleted` bit and copies to the audit table) — that's often more practical than restoring from the log.
* Keep the trigger lean — it runs inside the same transaction as the delete, so anything slow (writing to a remote table, sending email) will slow down or block the delete itself.

If you want, I can put together a runnable example with a test table, a few deletes, and the audit output so you can see it end-to-end.

## SESSION_CONTEXT

In ms sql server, what is SESSION_CONTEXT?

`SESSION_CONTEXT` is a per-connection key-value store built into SQL Server (2016+). It's the modern replacement for the old `CONTEXT_INFO`, which was limited to a single 128-byte binary blob.

The essentials:

* **Setting values:** `EXEC sys.sp_set_session_context @key = N'app_user_id', @value = 'jane@yourco.com';` — keys are `sysname`, values are `sql_variant` (effectively nvarchar/varbinary up to 7,500 bytes, 256 KB total).
* **Reading values:** `SELECT SESSION_CONTEXT(N'app_user_id');` — from any query, trigger, or stored procedure in that session. It returns `sql_variant`, so you typically cast it: `CAST(SESSION_CONTEXT(N'app_user_id') AS NVARCHAR(128))`. Reading an unset key returns NULL.
* **Scope:** the values live for the life of the session and are invisible to other connections. There's also a `@read_only = 1` flag that locks a value for the rest of the logical session.
* **Connection pooling gotcha:** when a pooled connection is reused, SQL Server's reset (sp_reset_connection) clears session context. So the application must set it after checking a connection out of the pool — per request, not once per connection. That's exactly how the audit trigger uses it: the app sets `app_user_id` at the start of each request, and the trigger reads it with a `COALESCE` fallback to `SUSER_SNAME()` when nothing was set.

Full details in the [Microsoft docs on sp_set_session_context](https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql) and [SESSION_CONTEXT](https://learn.microsoft.com/sql/t-sql/functions/session-context-transact-sql).

If you tell me what your application connects with (Node.js, Python, .NET, etc.), I can show you exactly where to set it in your connection-handling code.

How can I read all the values in SESSION_CONTEXT?

You can't enumerate it directly — `SESSION_CONTEXT(N'key')` reads exactly one key at a time, and there's no DMV that exposes the contents. `sys.dm_exec_sessions` shows the legacy `CONTEXT_INFO` in its `context_info` column, but not the modern key-value store ([Microsoft docs](https://learn.microsoft.com/sql/relational-databases/system-dynamic-management-objects/sys-dm-exec-sessions-transact-sql), and forum testing confirms session context doesn't appear there). So the key list has to come from you. [sqlservercentral](https://www.sqlservercentral.com/forums/topic/session-context-in-sql-jobs)

Two practical patterns:

**1. Iterate over a known key list.** Keep the manifest somewhere — a config table, or just hard-coded in a debug proc:

```sql
CREATE OR ALTER PROCEDURE dbo.show_session_context
AS
BEGIN
    SELECT k.key_name,
           SESSION_CONTEXT(k.key_name) AS value
    FROM (VALUES (N'app_user_id'),
                 (N'client_correlation_id'),
                 (N'tenant_id')) AS k(key_name);
END
```

**2. Store one JSON blob under a single key.** Self-describing, no manifest to maintain:

```sql
EXEC sys.sp_set_session_context
     @key = N'app_context',
     @value = N'{"user_id": "jane@yourco.com", "tenant": "acme", "request_id": "abc-123"}';

SELECT JSON_VALUE(SESSION_CONTEXT(N'app_context'), '$.user_id');
-- or dump the whole thing:
SELECT CAST(SESSION_CONTEXT(N'app_context') AS NVARCHAR(MAX));
```

The JSON approach trades a tiny parse cost for always being able to read everything with one key. If you only have a handful of fixed keys (like the `app_user_id` the audit trigger uses), the key-list approach is simpler and keeps values individually castable.

For a one-off diagnostic right now, a quick-and-dirty version: `SELECT SESSION_CONTEXT(N'app_user_id') AS app_user_id, SESSION_CONTEXT(N'client_correlation_id') AS corr_id;` — since you know which keys your code sets.

## Materialized views / Indexed views

SQL Server: Does not use the phrase "materialized view." Instead, it uses Indexed Views, which automatically synchronize data changes at the cost of additional write overhead on the base tables.

According to r/SQL commenters, a view is a dynamic query executed each time it's accessed, while a materialized view stores the result of a query on disk. In Microsoft SQL Server, a standard view is a virtual table that stores only a query definition, whereas a materialized view (known in SQL Server exclusively as an Indexed View) is a physical copy of the query results stored on disk. [1] (<https://www.reddit.com/r/SQL/comments/158498q/materialized_views_vs_views/>), [2] (<https://www.youtube.com/watch?v=4nOXwEJD8Y0>), [3] (<https://stackoverflow.com/questions/52326565/difference-between-view-and-indexed-view-or-materialized-view>), [4] (<https://www.mysqlui.com/blog/42-views-vs-materialized-views-in-sql>)

While other database engines use the term "materialized view," SQL Server achieves the exact same functionality by allowing you to create a unique clustered index on a view. [1] (<https://www.mysqlui.com/blog/42-views-vs-materialized-views-in-sql>), [2] (<https://www.youtube.com/watch?v=4nOXwEJD8Y0>)

Core Differences

Feature Standard View - Indexed View (Materialized View)

Storage Virtual (Consumes zero disk space; stores only the SELECT text). Physical (Stores actual rows of data on disk like a standard table).

Execution Runs the underlying query every time the view is called. Fetches precomputed data instantly without running the underlying query.

Performance No performance gain; acts purely as a logical shortcut. Massively speeds up heavy aggregations and multi-table joins.

Data Freshness Always 100% real-time (reads directly from the base tables). Always 100% real-time in SQL Server (automatically maintained by the database engine).

Write Overhead None. High overhead; any INSERT, UPDATE, or DELETE on base tables forces the index to update immediately.

Key SQL Server Distinctions

1. Real-Time Maintenance (No Manual Refresh)

In many data warehouses (like Oracle or Snowflake), materialized views can become stale and require manual or scheduled refreshes. SQL Server handles this differently. As discussed on StackOverflow, because an Indexed View is materialized and stored precomputed, it is maintained by SQL Server's transaction log, though this introduces significant limitations, potential maintenance, and blocking issues. [1] (<https://www.youtube.com/watch?v=sOEVAXskgno&t=1>), [2] (<https://www.sqlnoir.com/blog/view-vs-materialized-view>), [3] (<https://tacnode.io/post/view-vs-materialized-view>), [4] (<https://stackoverflow.com/questions/52326565/difference-between-view-and-indexed-view-or-materialized-view>)

1. Strict Technical Restrictions

To turn a standard view into a materialized indexed view in SQL Server, you must meet several rigid requirements: [1] (<https://stackoverflow.com/questions/52326565/difference-between-view-and-indexed-view-or-materialized-view>)

• WITH SCHEMABINDING: The view must be locked to the underlying database schema so base tables cannot be altered or dropped accidentally. [1] (<https://www.youtube.com/watch?v=4nOXwEJD8Y0>)

• Determinism: The view cannot use non-deterministic functions (like GETDATE()).

• Aggregate Restrictions: If you use SUM(), you must also include COUNT_BIG(*). You cannot use MAX(), MIN(), DISTINCT, or outer joins.

1. Enterprise Edition vs. Standard Edition Query Tuning

In SQL Server Enterprise Edition, the query optimizer features automatic query rewrite. If a user writes a query directly against the base tables, the optimizer is smart enough to realize an indexed view already has that data precomputed and will seamlessly route the query to the view instead to save CPU. In Standard Edition, you must explicitly query the view and add the WITH (NOEXPAND) hint to force SQL Server to read the materialized disk data rather than expanding it back into the base query. [1] (<https://learn.microsoft.com/en-us/azure/synapse-analytics/sql/develop-materialized-view-performance-tuning>)

Summary Guidelines: When to use which?

• Use a Standard View if: You need to abstract complex code for clean development, enforce column-level or row-level security boundaries, or if your underlying tables are highly volatile with non-stop write operations. [1] (<https://www.youtube.com/watch?v=sOEVAXskgno&t=1>), [2] (<https://www.youtube.com/watch?v=4nOXwEJD8Y0>)

• Use an Indexed (Materialized) View if: You are querying millions of rows for business intelligence, calculating heavy aggregations (GROUP BY), joining massive static tables, and your database environment is primarily read-heavy (OLAP) rather than transactional (OLTP). [1] (<https://www.youtube.com/watch?v=4nOXwEJD8Y0>)

If you are planning to build an indexed view for a specific query, let me know:

• What aggregations or joins are you trying to optimize?

• How frequently is data written to the underlying tables?

I can help you structure the T-SQL code to ensure it meets SQL Server's schema-binding criteria!



## sysname

In SQL Server 2022 (using SQL Server Management Studio / SSMS), you can retrieve the server's network name or instance name using the built-in `@@SERVERNAME` system function or `SERVERPROPERTY()`.

### Querying the Server Name

Open a **New Query** window in SSMS and execute:

```sql
-- Returns the server (and instance) name as registered in sys.servers
SELECT @@SERVERNAME AS [ServerName];

-- Returns the actual machine name (useful if renamed after installation)
SELECT SERVERPROPERTY('ServerName') AS [ServerProperty_ServerName],
       SERVERPROPERTY('MachineName') AS [MachineName],
       SERVERPROPERTY('InstanceName') AS [InstanceName];

```

---

### Key Differences & Troubleshooting

| Function / Property | What It Returns | Notes |
| --- | --- | --- |
| `@@SERVERNAME` | `SERVER\INSTANCE` | Returns the local server name stored in `sys.servers`. Can become outdated if the host OS was renamed after SQL Server installation. |
| `SERVERPROPERTY('MachineName')` | `SERVER` | The actual physical or virtual Windows host name. |
| `SERVERPROPERTY('ServerName')` | `SERVER\INSTANCE` | The current effective server and instance name. |

> **Note on Data Type:** In SQL Server, `sysname` is also a built-in system data type (an alias for `nvarchar(128)` used for database object names). If you meant the `sysname` data type definition, you can query it via `SELECT * FROM sys.types WHERE name = 'sysname';`.

---


## N'string'?

These are results for using ms sql server, why are strings written like String' with N?
Search instead for using ms sql server, why are strings writtein like N'string' with N?
AI Overview
In MS SQL Server, prefixing a string literal with N declares the string as a Unicode (specifically UTF-16) data type (NVARCHAR or NCHAR). 

Stack Overflow
 +1
According to contributors on sqlservercentral.com, the letter N stands for "National" (or National Language character set), which stems from the SQL-92 standard. 

SQLServerCentral
 +1
Why You Need It
Prevents Data Loss and Corruption: Without the N prefix, SQL Server treats the literal as a non-Unicode string (VARCHAR or CHAR). As discussed by developers on stackoverflow.com, it forces the string to pass through the database's default code page. If your string contains characters outside that specific code page (like Chinese characters, emojis, or specialized symbols), those characters will turn into unreadable question marks (???). 

Level Up Coding
 +4
Guarantees Multilingual Support: According to users on mindstick.com, using N ensures that SQL Server evaluates the string properly, allowing it to natively support characters from virtually any written language. 

Level Up Coding
 +1
Quick Example
sql
-- ❌ Without N: The characters might be corrupted depending on your database collation
SELECT 'Hello, 世界' AS Greeting; 
-- Output could be: Hello, ??

--  With N: Tells SQL Server to explicitly preserve the Unicode data
SELECT N'Hello, 世界' AS Greeting; 
-- Output will be: Hello, 世界
Use code with caution.
⚠️ A Common Pitfall
Simply inserting a string into an NVARCHAR column is not enough to save it from corruption. 
sql
-- Even if Username is an NVARCHAR column, the data is corrupted BEFORE the insert happens
INSERT INTO Users (Username) VALUES ('世界'); 

-- Correct way to preserve the characters
INSERT INTO Users (Username) VALUES (N'世界'); 
Use code with caution.
If you omit the N during an insert, SQL Server converts the literal to non-Unicode first, breaks any characters it doesn't recognize, and then saves those broken characters into your Unicode column. 

YouTube
·Erik Darling (Erik Darling Data)
 +1
If you are interested, we can look into how this affects query performance (implicit conversions) or how to handle strings safely when using dynamic SQL. Which direction would you like to explore next? 

YouTube
·Erik Darling (Erik Darling Data)


