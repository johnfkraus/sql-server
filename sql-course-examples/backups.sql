-- see backup notes in google drive docs

EXEC sp_helpfile


CREATE DATABASE MyDatabase_Snapshot_PreUpdate
ON 
( 
    NAME = MyDatabase_Data, -- Logical name of your primary database file
    FILENAME = 'C:\SQLData\MyDatabase_Snapshot.ss' -- Path for the sparse file
)
AS SNAPSHOT OF MyDatabase;


BACKUP DATABASE AdventureWorks2019
TO DISK = '/var/opt/mssql/backups/AdventureWorks0919.bak'
WITH COPY_ONLY, CHECKSUM, INIT;


