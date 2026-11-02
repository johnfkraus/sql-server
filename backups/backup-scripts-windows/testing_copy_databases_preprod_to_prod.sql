/*==============================================================================
  ONE-TIME SCRIPT: Refresh production databases from pre-production
  SQL Server 2022 / SSMS

  What it does (single execution, in this order):
    1. Takes a FULL safety backup of each listed database ON THE PRODUCTION server.
    2. Takes a FULL backup of the same databases ON THE PRE-PRODUCTION server
       (via a linked server), writing them to a network share both servers reach.
    3. Restores those backups OVER the production databases (WITH REPLACE),
       moving data/log files to the configured production paths.

  RUN THIS ON THE PRODUCTION SERVER (SSMS query window), logged in as sysadmin.

  PREREQUISITES
    - A UNC share that BOTH servers can reach:
        * the PRE-PROD SQL Server service account needs MODIFY on it (to write backups)
        * the PROD SQL Server service account needs READ on it (to restore)
    - A linked server to pre-prod (created automatically below if missing).
      Default login self-mapping is used: your Windows login must exist with
      sysadmin (or at least db_backupoperator) on the pre-prod instance.
      For SQL-auth or a dedicated account, see sp_addlinkedsrvlogin example below.
    - Enough disk space on prod for both the safety backups and the restored files.
    - The MSOLEDBSQL (OLE DB Driver for SQL Server) provider installed on prod.

  WARNING: step 3 OVERWRITES the listed production databases with pre-prod data.
  The script aborts unless you set @ConfirmOverwrite below.

  Reference docs:
    - RESTORE FILELISTONLY result set (used to build MOVE clauses):
      https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-filelistonly-transact-sql
    - Copy a database using BACKUP/RESTORE with MOVE:
      https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql
==============================================================================*/
SET NOCOUNT ON;

/*========================= 1. CONFIGURATION - EDIT THESE =====================*/
DECLARE @PreProdServer   sysname       = N'e08865bda7d6';  -- pre-prod network name (server or server\instance)
DECLARE @LinkedServer    sysname       = N'PREPROD_LNK';              -- linked server name (created if missing)
DECLARE @ProdBackupDir   nvarchar(260) = N'D:\SQLBackups\Safety\';    -- prod safety backups (local path on PROD)
DECLARE @ShareBackupDir nvarchar(260) = N'\\fileserver\sqlbackups\';  -- share reachable by BOTH servers (UNC)
DECLARE @ProdDataDir    nvarchar(260) = N'D:\SQLData\';               -- restore target for .mdf/.ndf on PROD
DECLARE @ProdLogDir     nvarchar(260) = N'E:\SQLLogs\';              -- restore target for .ldf on PROD
DECLARE @FilestreamDir  nvarchar(260) = N'D:\SQLData\Filestream\';   -- restore target for FILESTREAM containers (if any)
DECLARE @StopOnError    bit           = 0;                            -- 1 = stop remaining databases after first hard failure
DECLARE @ConfirmOverwrite nvarchar(30) = N'YES-PROD-OVERWRITE';       -- safety gate: must equal this exact value

/*========================= 2. DATABASE LIST - EDIT ============================*/
IF OBJECT_ID('tempdb..#Databases') IS NOT NULL DROP TABLE #Databases;
CREATE TABLE #Databases (DbName sysname NOT NULL PRIMARY KEY);

INSERT INTO #Databases (DbName) VALUES
    (N'AppDb'),
    (N'ReportingDb'),
    (N'CustomerDb');
/*======================== END OF CONFIGURATION ================================*/

/* Safety gate */
IF @ConfirmOverwrite <> N'YES-PROD-OVERWRITE'
BEGIN
    RAISERROR(N'Aborted: @ConfirmOverwrite must be set to ''YES-PROD-OVERWRITE'' to allow overwriting production databases.', 16, 1);
    RETURN;
END

/* Normalize trailing backslashes on directories */
SELECT @ProdBackupDir   = IIF(RIGHT(@ProdBackupDir,1)   <> N'\', @ProdBackupDir   + N'\', @ProdBackupDir),
       @ShareBackupDir  = IIF(RIGHT(@ShareBackupDir,1)  <> N'\', @ShareBackupDir  + N'\', @ShareBackupDir),
       @ProdDataDir     = IIF(RIGHT(@ProdDataDir,1)     <> N'\', @ProdDataDir     + N'\', @ProdDataDir),
       @ProdLogDir      = IIF(RIGHT(@ProdLogDir,1)      <> N'\', @ProdLogDir      + N'\', @ProdLogDir),
       @FilestreamDir   = IIF(RIGHT(@FilestreamDir,1)   <> N'\', @FilestreamDir   + N'\', @FilestreamDir);

DECLARE @ts   nvarchar(14) = FORMAT(SYSDATETIME(), N'yyyyMMddHHmmss');
DECLARE @sql  nvarchar(max);
DECLARE @DbName sysname;
DECLARE @BackupFile nvarchar(400);
DECLARE @moves nvarchar(max);
DECLARE @FailureCount int = 0;

/* Run log */
IF OBJECT_ID('tempdb..#RunLog') IS NOT NULL DROP TABLE #RunLog;
CREATE TABLE #RunLog
(
    StepId   int IDENTITY(1,1) NOT NULL,
    DbName   sysname           NOT NULL,
    Phase    nvarchar(20)      NOT NULL,   -- PRODBACKUP / PREPRODBACKUP / RESTORE
    Status   nvarchar(10)      NOT NULL,   -- SUCCESS / FAILED / SKIPPED
    Detail   nvarchar(4000)    NULL,
    RunAt    datetime2(0)      NOT NULL DEFAULT SYSDATETIME()
);

/*========================= 3. LINKED SERVER TO PRE-PROD =======================*/
IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = @LinkedServer)
BEGIN
    EXEC sp_addlinkedserver
         @server     = @LinkedServer,
         @srvproduct = N'',
         @provider   = N'MSOLEDBSQL',          -- OLE DB Driver for SQL Server
         @datasrc    = @PreProdServer;

    /* Default is self-mapping (your login is used on pre-prod). If you need a
       dedicated remote login instead, uncomment and adjust:
    EXEC sp_addlinkedsrvlogin
         @rmtsrvname  = @LinkedServer,
         @useself     = N'False',
         @locallogin  = NULL,                  -- NULL = all local logins
         @rmtuser     = N'preprod_backup_user',
         @rmtpassword = N'********';
    */
END

/* Test connectivity to pre-prod */
BEGIN TRY
    SET @sql = N'EXEC ' + QUOTENAME(@LinkedServer) + N'.master.sys.sp_executesql N''SELECT 1;'';';
    EXEC sp_executesql @sql;
END TRY
BEGIN CATCH
    RAISERROR(N'Aborted: cannot reach pre-production server through linked server %s. Error: %s',
              16, 1, @LinkedServer, ERROR_MESSAGE());
    RETURN;
END CATCH;

/*========================= 4. PHASE 1 - SAFETY BACKUPS ON PROD ================*/
PRINT N'=== Phase 1: safety backups on PRODUCTION ===';

DECLARE dbcur CURSOR LOCAL FAST_FORWARD FOR SELECT DbName FROM #Databases ORDER BY DbName;
OPEN dbcur;
FETCH NEXT FROM dbcur INTO @DbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @BackupFile = @ProdBackupDir + @DbName + N'_' + @ts + N'_prod_safety.bak';
        SET @sql = N'BACKUP DATABASE ' + QUOTENAME(@DbName)
                 + N' TO DISK = N''' + @BackupFile + N''''
                 + N' WITH COMPRESSION, CHECKSUM, INIT, STATS = 5;';
        EXEC sp_executesql @sql;

        INSERT INTO #RunLog (DbName, Phase, Status, Detail)
        VALUES (@DbName, N'PRODBACKUP', N'SUCCESS', N'Safety backup: ' + @BackupFile);
    END TRY
    BEGIN CATCH
        SET @FailureCount += 1;
        INSERT INTO #RunLog (DbName, Phase, Status, Detail)
        VALUES (@DbName, N'PRODBACKUP', N'FAILED', ERROR_MESSAGE());
        IF @StopOnError = 1
        BEGIN
            PRINT N'Aborted after failure in Phase 1 (see log below).';
            GOTO FinalReport;
        END
    END CATCH

    FETCH NEXT FROM dbcur INTO @DbName;
END
CLOSE dbcur; DEALLOCATE dbcur;

/*========================= 5. PHASE 2 - BACKUPS ON PRE-PROD ===================*/
PRINT N'=== Phase 2: backups on PRE-PRODUCTION (written to share) ===';

DECLARE dbcur CURSOR LOCAL FAST_FORWARD FOR SELECT DbName FROM #Databases ORDER BY DbName;
OPEN dbcur;
FETCH NEXT FROM dbcur INTO @DbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        /* Skip databases that could not be safety-backed up */
        IF EXISTS (SELECT 1 FROM #RunLog
                   WHERE DbName = @DbName AND Phase = N'PRODBACKUP' AND Status = N'FAILED')
        BEGIN
            INSERT INTO #RunLog (DbName, Phase, Status, Detail)
            VALUES (@DbName, N'PREPRODBACKUP', N'SKIPPED', N'Skipped: PROD safety backup failed.');
        END
        ELSE
        BEGIN
            SET @BackupFile = @ShareBackupDir + @DbName + N'_' + @ts + N'_from_preprod.bak';

            /* Statement that will run ON the pre-prod server */
            DECLARE @remoteStmt nvarchar(max) =
                N'BACKUP DATABASE ' + QUOTENAME(@DbName)
              + N' TO DISK = N''' + @BackupFile + N''''
              + N' WITH COMPRESSION, CHECKSUM, FORMAT, INIT, STATS = 5;';

            /* Ship it through the linked server (quotes doubled for nesting) */
            SET @sql = N'EXEC ' + QUOTENAME(@LinkedServer) + N'.master.sys.sp_executesql @stmt = N'''
                      + REPLACE(@remoteStmt, N'''', N'''''') + N''';';
            EXEC sp_executesql @sql;

            INSERT INTO #RunLog (DbName, Phase, Status, Detail)
            VALUES (@DbName, N'PREPRODBACKUP', N'SUCCESS', N'Pre-prod backup: ' + @BackupFile);
        END
    END TRY
    BEGIN CATCH
        SET @FailureCount += 1;
        INSERT INTO #RunLog (DbName, Phase, Status, Detail)
        VALUES (@DbName, N'PREPRODBACKUP', N'FAILED', ERROR_MESSAGE());
        IF @StopOnError = 1
        BEGIN
            PRINT N'Aborted after failure in Phase 2 (see log below).';
            GOTO FinalReport;
        END
    END CATCH

    FETCH NEXT FROM dbcur INTO @DbName;
END
CLOSE dbcur; DEALLOCATE dbcur;

/*========================= 6. PHASE 3 - RESTORE ONTO PROD ====================*/
PRINT N'=== Phase 3: restore pre-prod backups over PRODUCTION databases ===';

/* Exact FILELISTONLY result set for SQL Server 2022 (on-prem) */
IF OBJECT_ID('tempdb..#FileList') IS NOT NULL DROP TABLE #FileList;
CREATE TABLE #FileList
(
    LogicalName          nvarchar(128),
    PhysicalName         nvarchar(260),
    Type                 char(1),
    FileGroupName        nvarchar(128) NULL,
    Size                 numeric(20,0),
    MaxSize              numeric(20,0),
    FileID               bigint,
    CreateLSN            numeric(25,0),
    DropLSN              numeric(25,0) NULL,
    UniqueID             uniqueidentifier,
    ReadOnlyLSN          numeric(25,0) NULL,
    ReadWriteLSN         numeric(25,0) NULL,
    BackupSizeInBytes    bigint,
    SourceBlockSize      int,
    FileGroupID          int,
    LogGroupGUID         uniqueidentifier NULL,
    DifferentialBaseLSN  numeric(25,0) NULL,
    DifferentialBaseGUID uniqueidentifier NULL,
    IsReadOnly           bit,
    IsPresent            bit,
    TDEThumbprint        varbinary(32) NULL,
    SnapshotURL          nvarchar(360) NULL
);

DECLARE dbcur CURSOR LOCAL FAST_FORWARD FOR SELECT DbName FROM #Databases ORDER BY DbName;
OPEN dbcur;
FETCH NEXT FROM dbcur INTO @DbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    /* Only restore databases whose pre-prod backup succeeded */
    IF NOT EXISTS (SELECT 1 FROM #RunLog
                   WHERE DbName = @DbName AND Phase = N'PREPRODBACKUP' AND Status = N'SUCCESS')
    BEGIN
        INSERT INTO #RunLog (DbName, Phase, Status, Detail)
        VALUES (@DbName, N'RESTORE', N'SKIPPED', N'Skipped: no successful pre-prod backup.');
        FETCH NEXT FROM dbcur INTO @DbName;
        CONTINUE;
    END

    SET @BackupFile = @ShareBackupDir + @DbName + N'_' + @ts + N'_from_preprod.bak';
    DELETE FROM #FileList;

    BEGIN TRY
        /* Read the file list from the backup to build MOVE clauses */
        INSERT INTO #FileList
        EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFile + '''');

        ;WITH fl AS
        (
            SELECT LogicalName, Type,
                   rn = ROW_NUMBER() OVER (PARTITION BY Type ORDER BY FileID)
            FROM #FileList
            WHERE IsPresent = 1
        )
        SELECT @moves = COALESCE(STRING_AGG(CAST(
            N', MOVE N''' + LogicalName + N''' TO N''' +
            CASE Type
                WHEN 'D' THEN @ProdDataDir + @DbName
                              + IIF(rn > 1, N'_' + CAST(rn AS nvarchar(10)), N'') + N'.mdf'
                WHEN 'L' THEN @ProdLogDir + @DbName + N'_log'
                              + IIF(rn > 1, N'_' + CAST(rn AS nvarchar(10)), N'') + N'.ldf'
                WHEN 'S' THEN @FilestreamDir + @DbName
                              + IIF(rn > 1, N'_' + CAST(rn AS nvarchar(10)), N'')
                ELSE @ProdDataDir + @DbName + N'_misc'   -- full-text catalogs etc.
            END + N''''
            AS nvarchar(max)), N' '), N'')
        FROM fl;

        /* Kick active connections out so the restore can get exclusive access */
        IF DB_ID(@DbName) IS NOT NULL
            EXEC (N'ALTER DATABASE ' + QUOTENAME(@DbName) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;');

        /* Restore over the existing database */
        SET @sql = N'RESTORE DATABASE ' + QUOTENAME(@DbName)
                 + N' FROM DISK = N''' + @BackupFile + N''''
                 + N' WITH REPLACE, RECOVERY, CHECKSUM, STATS = 5'
                 + ISNULL(@moves, N'') + N';';
        EXEC sp_executesql @sql;

        /* Back to normal multi-user access */
        IF DB_ID(@DbName) IS NOT NULL
            EXEC (N'ALTER DATABASE ' + QUOTENAME(@DbName) + N' SET MULTI_USER;');

        INSERT INTO #RunLog (DbName, Phase, Status, Detail)
        VALUES (@DbName, N'RESTORE', N'SUCCESS', N'Restored from: ' + @BackupFile);
    END TRY
    BEGIN CATCH
        SET @FailureCount += 1;

        /* Make sure the database is not left stuck in SINGLE_USER */
        IF DB_ID(@DbName) IS NOT NULL
        BEGIN
            BEGIN TRY
                EXEC (N'ALTER DATABASE ' + QUOTENAME(@DbName) + N' SET MULTI_USER WITH ROLLBACK IMMEDIATE;');
            END TRY
            BEGIN CATCH
                /* Database may be mid-restore / not accessible - leave as is. */
            END CATCH
        END

        INSERT INTO #RunLog (DbName, Phase, Status, Detail)
        VALUES (@DbName, N'RESTORE', N'FAILED', ERROR_MESSAGE());

        IF @StopOnError = 1
        BEGIN
            PRINT N'Aborted after failure in Phase 3 (see log below).';
            GOTO FinalReport;
        END
    END CATCH

    FETCH NEXT FROM dbcur INTO @DbName;
END
CLOSE dbcur; DEALLOCATE dbcur;

/*========================= 7. FINAL REPORT ====================================*/
FinalReport:
IF CURSOR_STATUS('local','dbcur') >= -1
BEGIN
    CLOSE dbcur; DEALLOCATE dbcur;
END

PRINT N'=== Run finished at ' + CONVERT(nvarchar(19), SYSDATETIME(), 120) + N' ===';
SELECT StepId, DbName, Phase, Status, Detail, RunAt
FROM #RunLog
ORDER BY StepId;

IF @FailureCount > 0
    THROW 51000, 'One or more steps FAILED - see the run log above. Databases with FAILED RESTORE rows were NOT successfully refreshed.', 1;

PRINT N'All steps completed.';
