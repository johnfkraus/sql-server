BACKUP DATABASE [psp5]
TO DISK = N'/var/opt/mssql/backup/psp5.bak'
WITH FORMAT,
     MEDIANAME = 'SQLServerBackups',
     NAME = 'Full Backup of psp5';
GO


-- restore

RESTORE FILELISTONLY 
FROM DISK = N'/var/opt/mssql/backup/psp5.bak';
GO


USE [master];
GO

-- Set single user mode to kill any active connections to the existing database
ALTER DATABASE [psp5] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE [psp5]
FROM DISK = N'/var/opt/mssql/backup/psp5.bak'
WITH MOVE N'psp5' TO N'/var/opt/mssql/data/psp5.mdf',
     MOVE N'psp5_log' TO N'/var/opt/mssql/data/psp5_log.ldf',
     REPLACE,
     RECOVERY;
GO

-- Restore multi-user mode
ALTER DATABASE [psp5] SET MULTI_USER;
GO

-- delete a table to see if we can get it back with restore.
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Company]') AND type in (N'U'))
DROP TABLE [dbo].[Company]
GO
