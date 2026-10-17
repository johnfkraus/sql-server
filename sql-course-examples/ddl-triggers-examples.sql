CREATE TABLE Covid.DDL_Audit(
    PK_ID INT IDENTITY(1,1) PRIMARY KEY,
    [Event] XML NOT Null, -- in brackets because it is a reserved word!
    Audit_Date DATETIME NOT NULL,
    Changed_By NVARCHAR(128) NOT NULL    
)
GO

CREATE TRIGGER Tr_DDL_Audit
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_VIEW, ALTER_VIEW, DROP_VIEW

AS
BEGIN
    SET NOCOUNT ON;
    PRINT 'DDL Table / View trigger has run'

    INSERT INTO Covid.DDL_Audit(
        [Event],
        Audit_Date,
        Changed_By   
    )
    VALUES(
        EVENTDATA(),
        GETDATE(),
        USER
    );
END;

GO

CREATE VIEW Covid.TriggerTest
AS 
    SELECT 1 AS col1
GO

DROP VIEW Covid.TriggerTest



SELECT TOP (1000) [PK_ID]
      ,[Event]
      ,[Audit_Date]
      ,[Changed_By]
  FROM [SQL_Course].[Covid].[DDL_Audit]


  SELECT * 
  FROM sys.trigger_events AS TE INNER JOIN
    sys.triggers as T on T.object_id = TE.object_id;

DROP TRIGGER Tr_DDL_Audit ON DATABASE