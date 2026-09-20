----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: DDL - create, alter and drop - databases, schemas and tables
-- Copywrite: PADS research LTD

--------------------------------------------------
-- 1. Databases - create and drop

---------------------------------
-- Syntax

-- Create 
CREATE DATABASE The_Database_Name;

-- DROP
DROP DATABASE The_Database_Name;

-- Declare variable
DECLARE @Variable_Name Datatype
SET		@Variable_Name = 'A value'

-- If statement
IF Logical_Condition
BEGIN
	-- Conditional Code to execute 
END 

---------------------------------
-- Example
DECLARE @DB_Name VARCHAR(50)
SET		@DB_Name = 'SQL_Course' 

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = @DB_Name)
BEGIN 
	CREATE DATABASE SQL_Course
END

DROP DATABASE SQL_Course



--------------------------------------------------
-- 2. Schemas - create and drop

---------------------------------
-- Syntax

-- USE 
USE Database_Name

-- Go seperates query batches
GO

-- CREATE
CREATE SCHEMA My_Schema

-- DROP
DROP SCHEMA My_Schema

-- Execute a dynamic query
EXEC('A Dynamic Query');


---------------------------------
-- Example 
USE SQL_Course

-- Go seperates quary batches
GO 

DECLARE @DB_Schema VARCHAR(50)
SET		@DB_Schema = 'Example_Schema' 


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = @DB_Schema)
BEGIN
	EXEC('CREATE SCHEMA ' + @DB_Schema);
END

SELECT * FROM sys.schemas 

DROP SCHEMA Example_Schema



--------------------------------------------------
-- 3. Tables -  create and drop   

---------------------------------
-- Syntax

-- Create table 
CREATE TABLE Table_Name (
	Col1 datatype,
	Col2 datatype,
    Col3 datatype
)

-- Local Temp table
CREATE TABLE #TempTable (
	Col1 datatype,
	Col2 datatype,
    Col3 datatype
);

-- Global Temp table
CREATE TABLE ##TempTable (
	Col1 datatype,
	Col2 datatype,
    Col3 datatype
);

-- Create table with into
SELECT	Col1,
		Col2,
		Col3
INTO	[New_Table]
FROM	[Existing_Table]

--  Drop table 
DROP TABLE Table_Name


---------------------------------
-- Example

-- Create table
CREATE TABLE [dbo].[Covid_Variant] (
    [PK_ID] INT,
	[Location] VARCHAR(100),
    [Date] DATE,
	[Num_Sequences] int
);

-- Create table
CREATE TABLE [Example_Schema].[Covid_Variant] (
    [PK_ID] INT,
	[Location] VARCHAR(100),
    [Date] DATE,
	[Num_Sequences] int
);

-- Temp table
CREATE TABLE ##Covid_Variant (
    [PK_ID] INT,
	[Location] VARCHAR(100),
    [Date] DATE,
	[Num_Sequences] int,
);

-- Temp table
CREATE TABLE ##Glob_Covid_Variant (
    [PK_ID] INT,
	[Location] VARCHAR(100),
    [Date] DATE,
	[Num_Sequences] int,
);

SELECT	* 
FROM	sys.schemas 

SELECT	*
FROM	#Covid_Variant

-- Create into from another table
SELECT	Top(3) [AddressTypeID]
		,[Name]
INTO	[SQL_Course].[dbo].[Filtered_AddressType]
FROM	[AdventureWorks2019].[Person].[AddressType]


-- Create into temp table from another table
SELECT	Top(3) [AddressTypeID]
		,[Name]
INTO	#Filtered_AddressType
FROM	[AdventureWorks2019].[Person].[AddressType]

DROP TABLE [dbo].[Covid_Variant];
DROP TABLE [dbo].[Filtered_AddressType];
DROP TABLE [Example_Schema].[Covid_Variant];

DROP TABLE IF EXISTS [dbo].[Covid_Variant];


--------------------------------------------------
-- 4 Columns - add, alter, and drop

---------------------------------
-- Syntax

-- Add table columns 
ALTER TABLE Table_Name
ADD Column_Name datatype;

-- Drop table column
ALTER TABLE Table_Name
DROP COLUMN Column_Name;

-- Alter table column
ALTER TABLE table_name
ALTER COLUMN Column_Name datatype;


---------------------------------
-- Examples

GO
CREATE SCHEMA Covid;
GO

CREATE TABLE [Covid].[Covid_Variant] (
    [PK_ID] INT,
	[Location] VARCHAR(50),
    [Date] DATE,
	[Num_Sequence] int
);


ALTER TABLE [Covid].[Covid_Variant]
ADD [Variant] VARCHAR(50),
	[Num_Sequences_Total] DECIMAL(18,0),
	[Has_Vaccination_Program] CHAR(3),
	[Impact] INT


ALTER TABLE [Covid].[Covid_Variant]
DROP COLUMN [Impact]

ALTER TABLE [Covid].[Covid_Variant]
ALTER COLUMN [Variant] VARCHAR(200)

ALTER TABLE [Covid].[Covid_Variant]
ALTER COLUMN [Num_Sequences_Total] DECIMAL(18,2)



--------------------------------------------------
-- 5. Column constraints - create

---------------------------------
-- Syntax

CREATE TABLE Table_Name (
	Col1 INT NULL,
	Col2 NVARCHAR(50) NOT NULL
)

-- Non named column constraints

CREATE TABLE Table_Name (
	Col1 NVARCHAR(50) NOT NULL,
	Col2 INT UNIQUE,
	Col3 INT CHECK (Col3>=0),
	Col4 DATE DEFAULT GETDATE(),
	Col5 VARCHAR(50) DEFAULT 'Default Value'
)

-- Named constraints 
CREATE	TABLE Table_Name (
		Col1 INT CONSTRAINT Constraint_Name UNIQUE,	
		Col2 INT CONSTRAINT Constraint_Name CHECK (Col2>=0)
)

-- Table wide constraints
CREATE	TABLE Table_Name (
		Col1 INT,
		Col2 INT,
		CONSTRAINT Constraint_Name UNIQUE (Col1,Col2),
		CONSTRAINT Constraint_Name CHECK (Col1>=0 AND Col2=5)
)


---------------------------------
-- Examples 

-- Non Named NOT NULL, UNIQUE, 
-- CHECK and DEFAUT constraint
CREATE TABLE Covid.Patient (
	PK_ID INT UNIQUE NOT NULL,
	Age INT CHECK(Age > 0 AND Age < 120),
	Record_Created_Date DATE DEFAULT GETDATE(),
)

-- Named UNIQUE, CHECK
CREATE TABLE Covid.Patient_Hospital(
		PK_Patient_ID INT NOT NULL, 
		PK_Hospital_ID INT NOT NULL,
		Global_Ranking INT NOT NULL,
		Quality_Rating INT NOT NULL,
		Satisfaction VARCHAR(10),
		CONSTRAINT CS_Patient_Hospital_Un UNIQUE(PK_Patient_ID, PK_Hospital_ID),
		CONSTRAINT CS_Patient_Hospital_Ch CHECK(	Quality_Rating > 0 AND 
													Quality_Rating <= 5
												)
)



--------------------------------------------------
-- 6. Column constraints - alter

---------------------------------
-- Syntax

---------------------
-- Add Unnamed constraint 
ALTER TABLE		Table_Name 
ALTER COLUMN	[Col1] INT NOT NULL

ALTER TABLE Table_Name
ADD UNIQUE (Col1);

ALTER TABLE Table_Name
ADD CHECK (Col1>=8)

---------------------
-- Add named constraint
ALTER TABLE Table_Name
ADD CONSTRAINT Constraint_Name UNIQUE (Col1,Col2);

ALTER TABLE Table_Name
ADD CONSTRAINT Constraint_Name CHECK (Col1>=0 AND Col2='Value');

ALTER TABLE Table_Name
ADD CONSTRAINT Constraint_Name DEFAULT 'Default Value' FOR Col2 WITH VALUES;

---------------------
-- Add column and constraint
ALTER TABLE Table_Name WITH NOCHECK
ADD Col3 VARCHAR(50) NOT NULL CONSTRAINT Constraint_Name UNIQUE;

ALTER TABLE Table_Name WITH NOCHECK
ADD Col3 VARCHAR(50) NOT NULL CONSTRAINT Constraint_Name CHECK (Col3>=0);


---------------------------------
-- Examples 

-- Non Named ALTER NOT NULL columns constraint
ALTER TABLE Covid.Patient
ALTER COLUMN Age INT NOT NULL

ALTER TABLE Covid.Patient
ADD CHECK(Age > 0 AND Age < 100)


-- Named ALTER UNIQUE
ALTER TABLE Covid.Patient_Hospital WITH NOCHECK
ADD CONSTRAINT CS_Global_Ranking_Un UNIQUE(Global_Ranking)

ALTER TABLE Covid.Patient_Hospital WITH NOCHECK
ADD CONSTRAINT CS_Global_Ranking_Def DEFAULT 'Happy' FOR Satisfaction WITH VALUES



--------------------------------------------------
-- 7. Column constraints - drop

---------------------------------
-- Syntax

-- Drop primary key
SELECT	CONSTRAINT_NAME,
		TABLE_SCHEMA,
		TABLE_NAME,
		CONSTRAINT_TYPE
FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE	TABLE_NAME='Table_Name'

ALTER TABLE Table_Name
DROP CONSTRAINT Constraint_Name;

---------------------------------
-- Example
SELECT	*
FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'Patient'

ALTER TABLE [Covid].[Patient]
DROP CONSTRAINT UQ_Patient_XXXXXXXXX 



----------------------------------------------------
-- 8. Primary key constraints

---------------------------------
-- Syntax

-- Primary Key
CREATE TABLE Table_Name (
    ID int NOT NULL PRIMARY KEY,
    Col1 varchar(50) NOT NULL,
    Col2 varchar(50)
);

-- Primary Key With Identity 
CREATE TABLE Table_Name (
    ID int IDENTITY(1,1) PRIMARY KEY,
    Col1 varchar(50) NOT NULL,
    Col2 varchar(50)
);

-- Compound Primary Keys 
CREATE TABLE Table_Name (
    ID1 int NOT NULL,
    ID2 int NOT NULL,
    Col2 varchar(50),
    CONSTRAINT Compound_Constraint PRIMARY KEY (ID1,ID2)
);

-- Add primary key
ALTER TABLE Table_Name
ADD PRIMARY KEY (ID);

-- Add compound primary key
ALTER TABLE Table_Name
ADD CONSTRAINT Compound_Constraint PRIMARY KEY (ID1,ID2);

-- Drop primary key
SELECT	CONSTRAINT_NAME,
		TABLE_SCHEMA,
		TABLE_NAME,
		CONSTRAINT_TYPE
FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE	TABLE_NAME='Table_Name'

ALTER TABLE Table_Name
DROP CONSTRAINT Compound_Constraint;


---------------------------------
-- Example
CREATE TABLE Covid.Hospital (
	PK_Hospital_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] VARCHAR(50)
)

DROP TABLE Covid.Patient_Hospital

CREATE TABLE Covid.Patient_Hospital(
		PK_Patient_ID INT NOT NULL, 
		PK_Hospital_ID INT NOT NULL,
		Global_Ranking INT NOT NULL,
		Quality_Rating INT NOT NULL,
		Satisfaction VARCHAR(10),
		CONSTRAINT CS_Compound_Key PRIMARY KEY(PK_Patient_ID, PK_Hospital_ID),
		CONSTRAINT CS_Patient_Hospital_Ch CHECK(	Quality_Rating > 0 AND 
													Quality_Rating <= 5
												),
)

ALTER TABLE Covid.Covid_Variant
ALTER COLUMN PK_ID INT NOT NULL;

ALTER TABLE Covid.Covid_Variant 
ADD PRIMARY KEY(PK_ID)



----------------------------------------------------
-- 9. Foreign Key 

---------------------------------
-- Syntax

CREATE TABLE Table_B (
    PK_Table_B_ID int NOT NULL PRIMARY KEY,
);

CREATE TABLE Table_A (
    PK_Table_A_ID int NOT NULL PRIMARY KEY,
    FK_Table_B_ID int FOREIGN KEY REFERENCES Table_B(PK_Table_B_ID)
);

-- Named Constraint and Compound Keys
CREATE TABLE Table_A (
    PK_Table_A_ID int NOT NULL PRIMARY KEY,
    FK_Table_B_ID int NOT NULL,
    CONSTRAINT FK_Table_A_Table_B_Constraint FOREIGN KEY (FK_Table_B_ID)
    REFERENCES Table_B(PK_Table_B_ID)
);

-- Add Foreign Key
ALTER TABLE Table_A
ADD CONSTRAINT FK_Table_A_Table_B_Constraint
FOREIGN KEY (FK_Table_B_ID) REFERENCES Table_B(PK_Table_B_ID);

-- CASCADE changes
CREATE TABLE Table_A (
    PK_Table_A_ID int NOT NULL, 
	FK_Table_B_ID int NOT NULL,
	CONSTRAINT PK_Constraint PRIMARY KEY (PK_Table_A_ID),
    CONSTRAINT FK_Table_A_Table_B_Constraint FOREIGN KEY (FK_Table_B_ID)
    REFERENCES Table_B(PK_Table_B_ID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


---------------------------------
-- Example

DROP Table Covid.Patient

CREATE TABLE Covid.Patient (
	PK_ID INT NOT NULL PRIMARY KEY,
	FK_Covid_Variant INT FOREIGN KEY REFERENCES Covid.Covid_Variant(PK_ID),
	Age INT CHECK(Age > 0 AND Age < 120),
	Record_Created_Date DATE DEFAULT GETDATE(),
)

CREATE TABLE Covid.Patient (
	PK_ID INT NOT NULL PRIMARY KEY,
	FK_Covid_Variant INT NOT NULL,
	Age INT CHECK(Age > 0 AND Age < 120),
	Record_Created_Date DATE DEFAULT GETDATE(),
	CONSTRAINT FK_Patient_Covid_Variant FOREIGN KEY (FK_Covid_Variant) REFERENCES Covid.Covid_Variant(PK_ID)
)

ALTER TABLE Covid.Patient_Hospital
ADD CONSTRAINT FK_Patient_Hospital_Hospital 
FOREIGN KEY (PK_Hospital_ID)  REFERENCES Covid.Hospital(PK_Hospital_ID)



----------------------------------------------------
-- 10. Indexes

---------------------------------
-- Syntax

-- Create clustered index 
CREATE CLUSTERED INDEX IX_TableName_Col1 ON dbo.TableName (Col1);   

-- Create non-clustered index 
CREATE NONCLUSTERED INDEX IX_TableName_Col1 ON dbo.TableName (Col1);

-- Create index if not exists
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_TableName_Col1' AND object_id = OBJECT_ID('TableName'))
    CREATE CLUSTERED INDEX IX_TableName_Col1 ON TableName(Col1);   

-- Drop Index
DROP INDEX TableName.IndexName;


---------------------------------
-- Example

-- Drop primary key
SELECT	CONSTRAINT_NAME,
		TABLE_SCHEMA,
		TABLE_NAME,
		CONSTRAINT_TYPE
FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE	TABLE_NAME='Patient'

ALTER TABLE Covid.Patient
DROP CONSTRAINT PK__Patient;

SELECT * FROM sys.indexes 
WHERE  object_id = OBJECT_ID('Covid.Patient')

SELECT	Age, Record_Created_Date
FROM	Covid.Patient
WHERE	Age = 35

CREATE CLUSTERED INDEX IX_Clustered_Ex ON Covid.Patient(PK_ID)

SELECT	Age, Record_Created_Date
FROM	Covid.Patient
WHERE	Age = 35

CREATE NONCLUSTERED INDEX IX_Clustered_Age ON Covid.Patient(Age)

SELECT	Age, Record_Created_Date
FROM	Covid.Patient
WHERE	Age = 35

DROP INDEX IX_Clustered_Age ON Covid.Patient

CREATE NONCLUSTERED INDEX IX_Clustered_Age_Inc ON Covid.Patient(Age)
INCLUDE (Record_Created_Date);

SELECT	Age, Record_Created_Date
FROM	Covid.Patient
WHERE	Age = 35


----------------------------------------------------
-- 11. CTE

---------------------------------
-- Syntax

-- Basic CTE
WITH CTE_Name AS (
   -- Define the CTE query. 
   SELECT	Col1,
			Col2
   FROM		[Table_Name]
)

-- SELECT, INSERT, UPDATE, DELETE
SELECT	*
FROM	CTE_Name


-- CTE with named columns
WITH CTE_Name (Col1, Col2)  
AS (  
    SELECT	Col1, 
			Col2 
    FROM	Table_Name
)  

SELECT	Col1, 
		Col2
FROM	CTE_Name 


-- Recursive CTE
WITH EmployeeManager(ManagerID, EmployeeID, EmployeeLevel) AS   
(  
    SELECT	ManagerID, EmployeeID, 0 AS EmployeeLevel  
    FROM	dbo.Employees   
    WHERE	ManagerID IS NULL  

    UNION ALL  

    SELECT  e.ManagerID, e.EmployeeID, EmployeeLevel + 1  
    FROM	dbo.Employees AS e INNER JOIN 
			EmployeeManager AS m ON e.ManagerID = m.EmployeeID   
) 

SELECT		ManagerID, EmployeeID, EmployeeLevel   
FROM		EmployeeManager   
OPTION (MAXRECURSION 5); 



---------------------------------
-- Example

WITH AvgOrders ([AvgOrders], [Subcategory], [ProductSubcategoryID]) AS (
	SELECT		Avg(s.[OrderQty]) AS AvgOrders
				,ps.[Name] AS Subcategory
				,ps.[ProductSubcategoryID]
	FROM		[Sales].[SalesOrderDetail] s INNER JOIN
				[Production].[Product] p ON s.[ProductID] = p.[ProductID] INNER JOIN
				[Production].[ProductSubcategory] ps ON p.[ProductSubcategoryID] = ps.[ProductSubcategoryID]
	GROUP BY	ps.[Name], ps.[ProductSubcategoryID]
)

SELECT		p.[Name] AS ProductName
			,ps.[Name] AS Subcategory
			,s.[OrderQty]
			,ao.[AvgOrders]
FROM		[Sales].[SalesOrderDetail] s INNER JOIN
			[Production].[Product] p ON s.[ProductID] = p.[ProductID] INNER JOIN
			[Production].[ProductSubcategory] ps ON p.[ProductSubcategoryID] = ps.[ProductSubcategoryID] INNER JOIN
			AvgOrders ao ON ps.[ProductSubcategoryID] = ao.[ProductSubcategoryID]