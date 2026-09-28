----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Advanced database features
-- Copywrite: PADS research LTD


--------------------------------------------------
-- 1. Views
/*
A view is virtual table.
A view contains data from one or more tables.
- does not contain data itself
- can control security and access to a view as with a table
- use a view for complex table joins that need to be reused.
- use views to control access to data 
- add calculated fields or rename them

*/



---------------------------------
-- Syntax
CREATE VIEW ViewName 
AS  

-- SQL statement  
SELECT	*  
FROM	TableA a INNER JOIN
		TableB b ON a.ID = b.ID 


ALTER VIEW ViewName 
AS  

-- SQL statement    
SELECT	*  
FROM	TableA a INNER JOIN
		TableB b ON a.ID = b.ID 


---------------------------------
-- Example

DROP TABLE Covid.Covid_Variant_Copy

CREATE VIEW [Covid].[Covid_Patient]
AS

	SELECT	p.[PK_ID]
			,p.[FK_Covid_Variant]
			,p.[Age] + 10 AS [Adjusted_Age]
			,p.[Record_Created_Date]
			,cv.Variant
	FROM	[Covid].[Patient] p INNER JOIN
			[Covid].[Covid_Variant] cv ON p.[FK_Covid_Variant] = cv.PK_ID

ALTER VIEW [Covid].[Covid_Patient]
AS
SELECT	p.[PK_ID]
		,p.[FK_Covid_Variant]
		,p.[Age] + 10 AS [Adjusted_Age]
		,p.[Record_Created_Date]
		,cv.Variant
		,cv.[Location]
FROM	[Covid].[Patient] p INNER JOIN
		[Covid].[Covid_Variant] cv ON p.[FK_Covid_Variant] = cv.PK_ID

SELECT	*
FROM	[Covid].[Covid_Patient] 


--------------------------------------------------
-- 2. Stored procedures and parameters
/*
- A set of operations that make a complete procedure.
- Could exercise an entire business operation.
- more powerful than a view
- works similar to a function
	- wider scope than function as it can execute an entire operation
- execution plan is stored for faster run times on subsequent operations

*/


---------------------------------
-- Syntax

CREATE PROCEDURE dbo.uspStoredProcName
    @Param1 INT,
    @Param2 VARCHAR(50)
AS

    SET NOCOUNT ON;  -- don't return number of rows affected; speeds things up

    SELECT	Col1, Col2
    FROM	dbo.TableName
    WHERE	Col1 = @Param1 AND Col2 = @Param2;
GO

IF OBJECT_ID ( 'dbo.uspStoredProcName', 'P' ) IS NOT NULL
    DROP PROCEDURE dbo.uspStoredProcName;
GO

EXECUTE dbo.uspStoredProcName @Param1 = N'Value1', @Param2 = N'Value2';

-- jk examples

CREATE PROCEDURE Covid.usp_get_covid_patient
AS
BEGIN
	SELECT *
	FROM [Covid].[Patient]
END


EXEC COVID.usp_get_covid_patient


CREATE PROCEDURE Covid.usp_get_specific_covid_patient
	@PK_ID INT,
	@Age INT
AS
BEGIN
	SELECT *
	FROM [Covid].[Patient] p
	WHERE p.PK_ID = @PK_ID AND p.Age = @Age
END

EXEC Covid.usp_get_specific_covid_patient 1,56

IF OBJECT_ID('[Covid].[usp_get_specific_covid_patient]', 'p') IS NOT NULL
DROP PROCEDURE Covid.usp_get_specific_covid_patient

IF OBJECT_ID('[Covid].[usp_get_covid_patient]', 'p') IS NOT NULL
DROP PROCEDURE Covid.usp_get_Covid_patient


---------------------------------
-- Example

-------------------------
CREATE PROCEDURE Covid.usp_get_covid_patient 
AS
BEGIN
	SELECT	*
	FROM	[Covid].[Patient] p
END

EXEC Covid.usp_get_covid_patient

-------------------------
CREATE PROCEDURE Covid.usp_get_specific_covid_patient
	@PK_ID INT,
	@Age INT
AS
BEGIN
	SELECT	*
	FROM	[Covid].[Patient] p
	WHERE   p.PK_ID = @PK_ID AND p.Age = @Age 
END

EXEC Covid.usp_get_specific_covid_patient 1, 56


-------------------------
IF OBJECT_ID ('Covid.usp_get_covid_patient', 'P' ) IS NOT NULL
	DROP PROCEDURE Covid.usp_get_covid_patient 
GO

DROP PROCEDURE Covid.usp_get_specific_covid_patient 


--------------------------------------------------
-- 3. Stored procedures with return values

---------------------------------
-- Syntax

-- Output params
CREATE PROCEDURE dbo.uspStoredProcName
    @Param1 INT = 500,
	@Output_Param1 VARCHAR(50) OUTPUT,
	@Output_Param2 VARCHAR(50) OUTPUT
AS

    SET NOCOUNT ON;

    SELECT	Col1
    FROM	dbo.TableName
    WHERE	Col1 = @Param1

	SET @Output_Param1 = 'Value1'; 
	SET @Output_Param2 = 'Value2'; 
GO


-------------------------
DECLARE @Output_Param1 VARCHAR(50)
DECLARE @Output_Param2 VARCHAR(50)
 
EXECUTE dbo.uspStoredProcName	600, 
								@Output_Param1 OUTPUT, 
								@Output_Param2 OUTPUT
 
SELECT @Output_Param1, @Output_Param2

-------------------------
CREATE PROCEDURE dbo.uspStoredProcName
    @Param1 INT
AS
    SET NOCOUNT ON;

    SELECT	Col1
    FROM	dbo.TableName
    WHERE	Col1 = @Param1

	RETURN (2)
GO

-------------------------
DECLARE @Ret_Code INT
EXECUTE @Ret_Code = dbo.uspStoredProcName @Param1 = 70  
SELECT @Ret_Code


---------------------------------
-- Example

-------------------------
CREATE PROCEDURE Covid.usp_insert_patient
	@Covid_Variant_Name VARCHAR(50) = 'Alpha',
	@Covid_Variant_Country VARCHAR(50),
	@Age INT,
	@Inserted_Patient_ID INT OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

	-- Get Covid Variant ID
	DECLARE @Covid_Variant_PK_ID AS INT

	SELECT  TOP 1 @Covid_Variant_PK_ID = [PK_ID]
	FROM	[Covid].[Covid_Variant]
	WHERE	[Variant] = @Covid_Variant_Name AND [Location] = @Covid_Variant_Country
	ORDER BY [DATE] DESC

	-- Get next patient ID
	DECLARE @Patient_Next_PK INT;

	SELECT		TOP 1 @Patient_Next_PK = [PK_ID] + 1 
	FROM		[Covid].[Patient]
	ORDER BY	[PK_ID] DESC
	
	-- Insert new patient record
	INSERT INTO [Covid].[Patient] (
		[PK_ID],
		[FK_Covid_Variant],
		[Age],
		[Record_Created_Date] 
	)VALUES(
		@Patient_Next_PK,
		@Covid_Variant_PK_ID, 
		@Age,
		GETDATE()
	)

	-- Output inserted hospital ID
	SET @Inserted_Patient_ID = @Patient_Next_PK

	-- For ingremental integers use:
	-- SET @Inserted_Patient_ID = @@IDENTITY

	RETURN(1)
END


-------------------------
DECLARE @Returned_Patient_ID INT
DECLARE @Status INT

EXECUTE @Status = Covid.usp_insert_patient	@Covid_Variant_Name = 'Beta',
										@Covid_Variant_Country = 'New Zealand',
										@Age = 75,
										@Inserted_Patient_ID = @Returned_Patient_ID  OUTPUT

PRINT @Returned_Patient_ID
PRINT @Status


--------------------------------------------------
-- 4. Functions - scaler

---------------------------------
-- Syntax
CREATE FUNCTION dbo.udfFunctionName (@Parm1 DATETIME, @Param2 INT)
RETURNS INT AS
BEGIN
	DECLARE @Variable_To_Return INT;

    -- SQL statements

    RETURN @Variable_To_Return
END;

-- Drop function
DROP FUNCTION Covid.UDF_Is_Even 

SELECT	UDF_Function_Name (Table_Name.Coulmn1)
FROM	Table_Name
WHERE	UDF_Function_Name (Table_Name.Coulmn1) = A_Value


---------------------------------
-- Example

-- Scaler example 
CREATE FUNCTION Covid.UDF_Is_Even 
(
	@number INT
)
RETURNS BIT
AS
BEGIN
	-- Declare the return variable
	DECLARE @result AS BIT

	IF @number % 2 = 0
		SET @result = 1
	ELSE 
		SET @result = 0

	-- Return the result of the function
	RETURN @result
END

SELECT Covid.UDF_Is_Even (3)

DROP FUNCTION Covid.UDF_Is_Even 


--------------------------------------------------
-- 4. Functions - table valued

---------------------------------
-- Syntax

---------------------------
-- Inline table-valued function
CREATE FUNCTION dbo.UDF_Function_Name (@Param1 int)
RETURNS TABLE
WITH SCHEMABINDING 
AS
RETURN
(
    SELECT *
	FROM Table_Name
	WHERE Col1 = @Param1
);

----------------------------
-- Multi-statement table valued function
CREATE FUNCTION dbo.UDF_Multi_Table_Funciton(
	@Param1 VARCHAR(50)
)

RETURNS @Return_Table TABLE (
        Col1 INT,  
		Col2 INT
    )
	WITH SCHEMABINDING
BEGIN
	
	INSERT INTO @Return_Table
	SELECT  Col1,
			Col2
	FROM [Table_Name]

	INSERT INTO @Return_Table
	SELECT  Col1,
			Col2
	FROM [Table_Name2]

	RETURN
END
---------------------------------
-- Example

-- Inline Table example 
CREATE FUNCTION Covid.UDF_Inline_Covid_Patient
(	
	@Location VARCHAR(100)
)
RETURNS TABLE 
WITH SCHEMABINDING
AS
RETURN 
(
	SELECT	p.Age,  
			p.Record_Created_Date, 
			cv.[Location], 
			cv.Variant
	FROM	[Covid].[Patient] p INNER JOIN
			[Covid].[Covid_Variant] cv ON p.[FK_Covid_Variant] = cv.[PK_ID]
	WHERE [Location] = @Location 
)

SELECT * 
FROM   [Covid].[UDF_Inline_Covid_Patient] ('Angola') 


-- Milti statement Table example
CREATE FUNCTION Covid.UDF_Miltiline_Covid_Patient( 
	@Location VARCHAR(100),
	@Variant VARCHAR(100)
)
    RETURNS @Return_Table TABLE (
        Age INT,  
		Record_Created_Date DATE, 
		[Location] VARCHAR(50), 
		Variant VARCHAR(200),
		Match_Type VARCHAR(20)
    )
	WITH SCHEMABINDING
BEGIN

    INSERT INTO @Return_Table
    SELECT	p.Age,  
			p.Record_Created_Date, 
			cv.[Location], 
			cv.Variant,
			'Location' AS Match_Type
	FROM	[Covid].[Patient] p INNER JOIN
			[Covid].[Covid_Variant] cv ON p.[FK_Covid_Variant] = cv.[PK_ID]
	WHERE   cv.[Location] = @Location 

	INSERT INTO @Return_Table
    SELECT	p.Age,  
			p.Record_Created_Date, 
			cv.[Location], 
			cv.Variant,
			'Variant' AS Match_Type
	FROM	[Covid].[Patient] p INNER JOIN
			[Covid].[Covid_Variant] cv ON p.[FK_Covid_Variant] = cv.[PK_ID]
	WHERE   cv.Variant = @Variant

    RETURN;
END;

SELECT * 
FROM [Covid].[UDF_Miltiline_Covid_Patient] ('Angola','Omicron')


--------------------------------------------------
-- 5. Transactions

---------------------------------
-- Syntax

-- Rollback if transaction fails
BEGIN TRAN
    BEGIN TRY
		-- Run SQL Script
    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRAN;
        END

    END CATCH;

-- Commit Transaction
IF @@TRANCOUNT >0
BEGIN
    COMMIT TRAN;
END

---------------------------------
-- Example

------------------------------
-- Rollback if transaction fails
BEGIN TRAN
    BEGIN TRY

		-- Run SQL Script
		DECLARE @TestVar INT
		SELECT @TestVar = 'Error'

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
			PRINT 'Number of Transactions = ' + CAST(@@TRANCOUNT AS VARCHAR(10));
            
			ROLLBACK TRAN;

			PRINT 'SQL Rolled Back';
        END

    END CATCH;

-- Commit Transaction
IF @@TRANCOUNT >0
BEGIN
    COMMIT TRAN;
	PRINT 'Transaction Committed';
END


--------------------------------------------------
-- 6. Cursors

---------------------------------
-- Syntax
DECLARE @Col1 INT, @Col2 INT

DECLARE My_Cursor CURSOR FOR 
SELECT  Col1, Col2  
FROM    TableName    
  
OPEN My_Cursor 
  
FETCH NEXT FROM My_Cursor   
INTO @Col1, @Col2  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
    -- Run SQL  
	SELECT @Col1, @Col2  

	FETCH NEXT FROM My_Cursor  
	INTO @Col1, @Col2  
END   

CLOSE My_Cursor ;  
DEALLOCATE My_Cursor;  

---------------------------------
-- Example

CREATE VIEW Covid.Delete1
AS 
	SELECT 1 AS Col1
GO

CREATE VIEW Covid.Delete2
AS 
	SELECT 1 AS Col1

GO

CREATE VIEW Covid.Delete3
AS 
	SELECT 1 AS Col1

GO

SELECT  OBJECT_SCHEMA_NAME(v.object_id) AS Schema_Name,
		v.Name
FROM	sys.views as v
WHERE	v.name LIKE '%Delete%'

-----------------------------------------
-- Cursor
DECLARE @Schema_Name VARCHAR(50), @Name VARCHAR(50), @DynamicSQL VARCHAR(500)

DECLARE My_Cursor CURSOR FOR 
SELECT  OBJECT_SCHEMA_NAME(v.object_id) AS Schema_Name,
		v.Name
FROM	sys.views as v
WHERE	v.name LIKE '%Delete%'  
  
OPEN My_Cursor 
  
FETCH NEXT FROM My_Cursor   
INTO @Schema_Name, @Name 
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
    -- Run SQL  
	PRINT @Schema_Name
	PRINT @Name

	SET @DynamicSQL = 'DROP VIEW ' + @Schema_Name + '.' + @Name

	PRINT @DynamicSQL
	EXEC (@DynamicSQL)

	FETCH NEXT FROM My_Cursor   
	INTO @Schema_Name, @Name 
END   

CLOSE My_Cursor ;  
DEALLOCATE My_Cursor; 



--------------------------------------------------
-- 7. XML

---------------------------------
-- Syntax

---------------
<root_node>
	<node>Value</node>
	<node attribute="Value"/>
</root_node>


---------------
SELECT [Col1],
	   [Col2]	
FROM   TableName
FOR XML AUTO;

<row Col1="1" Col2="a"/>
<row Col1="2" Col2="b"/>
<row Col1="3" Col2="c"/>
<row Col1="4" Col2="d"/>
<row Col1="5" Col2="e"/>

---------------
SELECT [Col1],
	   [Col2],
	   [Col3]
FROM   TableName
FOR XML PATH

<row>
    <col1>value1</col1>
    <col2>value2</col2>
    <col3>value3</col3>
</row>
<row>
    <col1>value1</col1>
    <col2>value2</col2>
    <col3>value3</col3>
</row>


---------------
SELECT  [Col1],
	    [Col2],
	    [Col3]
FROM   TableName
FOR XML PATH ('RowName')

<RowName>
    <col1>value1</col1>
    <col2>value2</col2>
    <col3>value3</col3>
</RowName>
<RowName>
    <col1>value1</col1>
    <col2>value2</col2>
    <col3>value3</col3>
</RowName>


---------------
SELECT  [Col1],
	    [Col2],
	    [Col3]
FROM    TableName
FOR XML PATH ('RowName'), ROOT('RootName')

<RootName>
    <RowName>
        <col1>value1</col1>
        <col2>value2</col2>
        <col3>value3</col3>
    </RowName>
    <RowName>
        <col1>value1</col1>
        <col2>value2</col2>
        <col3>value3</col3>
    </RowName>
</RootName>

---------------
SELECT  [Col0] AS [@AttributeName],  
		[Col1] AS [ParentNode/Col1],  
		[Col2] AS [ParentNode/Col2],  
		[Col3] AS [ParentNode/Col3],  
		[Col4]
FROM	TableName
FOR XML PATH ('RowName'), ROOT('RootName')

<RootName>
  <RowName AttributeName="1">
    <ParentNode>
      <Col1>value1</Col1>
      <Col2>value2</Col2>
      <Col3>value3</Col3>
    </ParentNode>
    <Col4>value4</Col4>
  </RowName>
</RootName>


---------------------------------
-- Example

SELECT  [PK_ID] AS [@Patient_ID],  
		[FK_Covid_Variant] AS [Covid_Variant_ID],  
		[Age] AS [Details/Age],  
		[Record_Created_Date] AS [Details/Record_Created_Date] 
FROM	[Covid].[Patient]
FOR XML PATH ('Row'), ROOT('Root')


--------------------------------------------------
-- 8. Triggers syntax

------------------------
CREATE TRIGGER TriggerNameInsert ON [TableName]
AFTER INSERT 
AS 
	SELECT *
	FROM inserted


CREATE TRIGGER TriggerNameUpdate ON [TableName]
AFTER UPDATE
AS 
	SELECT *
	FROM inserted


CREATE TRIGGER TriggerNameDelete ON [TableName]
AFTER DELETE
AS 
	SELECT *
	FROM deleted

------------------------
CREATE TRIGGER TriggerNameInsert ON [TableName]
AFTER INSERT, UPDATE, DELETE 
AS 
	-- SQL script to run


ALTER TRIGGER TriggerNameInsert ON [TableName]
AFTER INSERT, UPDATE, DELETE 
AS 
	-- SQL script to run

------------------------
DROP TRIGGER TriggerName

------------------------
CREATE TRIGGER [Tr_TriggerName]  
ON DATABASE  
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_VIEW, ALTER_VIEW, DROP_VIEW  
AS  
BEGIN  
  
    Print 'Create table triger has run'  
END  


--------------------------------------------------
-- 9. Triggers DML example

CREATE TABLE [Covid].[Patient_Audit]
(
	[Audit_PK_ID] [int] IDENTITY(1,1) NOT NULL,
	[Patient_PK_ID] [int] NOT NULL,
	[FK_Covid_Variant] [int] NULL,
	[Age] [int] NULL,
	[Record_Created_Date] [date] NULL,
	[Audit_Date] DATETIME DEFAULT GETDATE() NOT NULL,
	[User] VARCHAR(200) DEFAULT SUSER_NAME() NOT NULL
)

CREATE TRIGGER [Covid].[Tr_Patient_Audit] ON [Covid].[Patient]
AFTER INSERT, UPDATE
AS  
BEGIN  

	SET NOCOUNT ON
    PRINT 'Patient Data Inserted / Updated' 
	
	INSERT INTO [Covid].[Patient_Audit](
	   [Patient_PK_ID]
      ,[FK_Covid_Variant]
      ,[Age]
      ,[Record_Created_Date]
	)
	SELECT [PK_ID]
		  ,[FK_Covid_Variant]
		  ,[Age]
		  ,[Record_Created_Date]
	FROM INSERTED 
END  

INSERT INTO [Covid].[Patient](
	[PK_ID]
	,[FK_Covid_Variant]
	,[Age]
	,[Record_Created_Date]
)
VALUES (
	100,
	20,
	78,
	GETDATE()
)

UPDATE	[Covid].[Patient]
SET		[FK_Covid_Variant] = 40
		,[Age] = 55
WHERE	[PK_ID] = 100

--------------------------------------------------
-- 11. Triggers DDL example

CREATE TABLE Covid.DDL_Audit(
   PK_ID int IDENTITY(1,1) PRIMARY KEY,
   [Event] XML NOT NULL,
   Audit_Date DATETIME NOT NULL,
   Changed_By NVARCHAR(128) NOT NULL
);


CREATE TRIGGER [Tr_DDL_Audit]
ON DATABASE
FOR	CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_VIEW, ALTER_VIEW, DROP_VIEW  
AS
BEGIN
    SET NOCOUNT ON;

	PRINT 'DDL table / view triger has run'  

    INSERT INTO Covid.DDL_Audit
    (
       [Event],
       Audit_Date,
       Changed_By
    ) 
	VALUES (
           EVENTDATA(),
           GETDATE(),
           USER
    );
END;

-----------------------------------------------------
-- Test DDL Trigger 
CREATE VIEW Covid.TriggerTest
AS 
	SELECT 1 AS Col1

DROP VIEW Covid.TriggerTest

-----------------------------------------------------
-- View events that course triggers to fire
SELECT	* 
FROM	sys.trigger_events AS TE  INNER JOIN
		sys.triggers AS T ON T.object_id = TE.object_id 

-----------------------------------------------------
-- Drop Trigger
DROP TRIGGER Tr_DDL_Audit ON DATABASE