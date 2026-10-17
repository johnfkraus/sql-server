SELECT TOP (1000) [PK_ID]
      ,[Event]
      ,[Audit_Date]
      ,[Changed_By]
  FROM [SQL_Course].[Covid].[DDL_Audit]


  SELECT * 
  FROM sys.trigger_events AS TE INNER JOIN
    sys.triggers as T on T.object_id = TE.object_id;

DROP TRIGGER Tr_DDL_Audit ON DATABASE