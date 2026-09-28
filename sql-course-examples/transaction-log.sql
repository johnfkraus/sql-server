To view the transaction log in MS SQL Server, the method depends on whether you want to view active log contents, inspect Virtual Log Files (VLFs), or view transaction log backups.

---

## 1. Inspect Active Log Contents (`fn_dblog`)

SQL Server includes an undocumented system function, `sys.fn_dblog`, which allows you to read active log records directly from the online transaction log.

```sql
USE YourDatabaseName;
GO

SELECT 
    [Current LSN],
    [Operation],
    [Context],
    [Transaction ID],
    [AllocUnitName],
    [Page ID],
    [Slot ID],
    [Begin Time],
    [Transaction Name],
    [Transaction SID]
FROM sys.fn_dblog(NULL, NULL);

```

* **Filter by Operation:** To look for specific events like row deletions (`LOP_DELETE_ROWS`) or inserts (`LOP_INSERT_ROWS`), filter using the `Operation` column:
```sql
SELECT * 
FROM sys.fn_dblog(NULL, NULL)
WHERE [Operation] = 'LOP_DELETE_ROWS';

```



> **Note:** `sys.fn_dblog` reads from memory and active log files. It can cause temporary performance overhead on large, high-throughput databases.

---

## 2. Inspect Virtual Log Files (`DBCC LOGINFO`)

To check the physical structure and status of your Virtual Log Files (VLFs) within the `.ldf` file:

```sql
USE YourDatabaseName;
GO

DBCC LOGINFO;

```

* **`Status = 2`**: Indicates active VLFs that cannot be truncated or reused yet.
* **`Status = 0`**: Indicates inactive VLFs ready for truncation during a log backup or checkpoint.

---

## 3. Read Transaction Log Backups (`fn_dump_dblog`)

If you need to inspect an archived `.trn` log backup file rather than the live transaction log, use `sys.fn_dump_dblog`:

```sql
SELECT 
    [Current LSN],
    [Operation],
    [Context],
    [Transaction ID],
    [AllocUnitName],
    [Begin Time]
FROM sys.fn_dump_dblog(
    NULL, NULL, 'DISK', 1,
    'C:\BackupPath\YourDatabase_LogBackup.trn',
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
    DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
);

```

---

## 4. Third-Party & GUI Alternatives

For detailed auditing or point-in-time forensic analysis (such as reading exact updated payload values):

* **Third-Party Log Readers:** Tools like ApexSQL Log, Redgate SQL Log Rescue, or Devart Transaction Log Reader parse log records into human-readable SQL statements (e.g., generating undo/redo scripts).
* **SSMS Transaction Log Reports:** In SQL Server Management Studio (SSMS), right-click your database **Reports** $\rightarrow$ **Standard Reports** $\rightarrow$ **Transaction Log Shipping Status** or **Disk Usage** to monitor log space utilization visually.