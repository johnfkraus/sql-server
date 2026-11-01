# backup-scripts-windows

Using MS SQL Server 2022 and SQL Server Manager, I want a SQL script that when executed once will:  
1. backup databases specified in a list on a specified production database server;
2. copy the same list of databases from the pre-production database server to the production database server.


The script is ready above — `copy_databases_preprod_to_prod.sql`. Run it once in SSMS **connected to the production server**, as sysadmin.

## How It Works

The script runs three phases in order and logs every step to a `#RunLog` temp table printed at the end:

1. **Safety backups on production** — full `BACKUP DATABASE ... WITH COMPRESSION, CHECKSUM, INIT` to a local folder, one timestamped `.bak` per database, so you can roll back.
2. **Backups on pre-production** — a linked server (created automatically if missing) runs `BACKUP DATABASE` on the pre-prod instance via `sp_executesql`, writing the files to a UNC share both servers can reach.
3. **Restore onto production** — reads each backup's file list with `RESTORE FILELISTONLY` (the 22-column on-prem result set per Microsoft docs), builds `MOVE` clauses dynamically for every data/log/FILESTREAM file, kicks users out with `SINGLE_USER WITH ROLLBACK IMMEDIATE`, then restores `WITH REPLACE, RECOVERY, CHECKSUM` — the standard copy-with-MOVE pattern from the RESTORE reference. [learn.microsoft](https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-ver16)

## Edit Before Running

- The config block at the top: pre-prod server name, linked server name, prod backup folder, **shared UNC folder**, prod data/log/filestream directories.
- The database list (`#Databases` insert).
- The safety gate: the script aborts unless `@ConfirmOverwrite = 'YES-PROD-OVERWRITE'`, since phase 3 destroys the listed prod databases.

## Prerequisites And Caveats

- **Share permissions**: the pre-prod service account needs Modify on the share; the prod service account needs Read ([backup device requirements](https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/back-up-and-restore-of-system-databases)).
- **Linked server login**: default self-mapping means your Windows login must be valid on pre-prod with backup rights; a commented `sp_addlinkedsrvlogin` example is included for a dedicated account.
- A database whose safety backup or pre-prod backup fails is skipped (never half-restored); if a restore fails, the script attempts to return the database to `MULTI_USER` and records the error. Set `@StopOnError = 1` to halt everything on the first failure.
- If any listed database is an availability-group replica or participates in replication/log shipping, restoring over it will break that topology — remove those from the list and handle separately.
- Plan for disk space on prod: safety backups plus the incoming restored files coexist.



