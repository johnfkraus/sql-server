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
-- 5. Column constraints - create. 
-- https://www.udemy.com/course/a-complete-course-in-sql-with-sql-server/learn/lecture/33797612#overview
/**

Control the quality of data in a column.
Help transactional datbases maintan integrity and valid data.
Often not available in big data or NOSQL databases.
Helps implement business rules.

Column constraints include:
- Null
- unique
- check - lets you create a custom check on one or more columns; Example: make sure a patient's age is between 0 and 120.
- default - Example: automatically insert the current date.

Constraints can be:
- unnamed; inline
	- NOT NULL, UNIQUE, CHECK (Col3>=0), DEFAULT GETDATE(), DEFAULT 'Default_Value'

- named; uses the keyword CONSTRAINT
	- Col1 INT CONSTRAINT Constraint_Name UNIQUE
	- Col2 INT CONSTRAINT Constraint_Name2 CHECK (Col2>=0)

- table-wide; involve several columns
	- Put constraints at the end, after specifying the columns.

**/


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
-- 'WITH VALUES', only applies if we supply a value for this field.
-- will not automatically apply this default to any pre-existing rows
---------------------
-- Add column and constraint
ALTER TABLE Table_Name WITH NOCHECK
ADD Col3 VARCHAR(50) NOT NULL CONSTRAINT Constraint_Name UNIQUE;
/*
WITH NOCHECK has no effect here. 

Per the Microsoft documentation:

"The WITH NOCHECK option has no effect when you add PRIMARY KEY or UNIQUE constraints." 

WITH NOCHECK (and WITH CHECK) only apply to CHECK and FOREIGN KEY constraints.  For UNIQUE and PRIMARY KEY constraints, SQL Server always validates existing data — the statement will fail if duplicates are found, regardless of whether you include WITH NOCHECK. 

So in your statement, the WITH NOCHECK is simply ignored. The unique index is created and all existing rows in Col3 are checked for uniqueness. You can safely remove it without changing behavior:

ALTER TABLE Table_Name
ADD Col3 VARCHAR(50) NOT NULL CONSTRAINT Constraint_Name UNIQUE;
*/

ALTER TABLE Table_Name WITH NOCHECK
ADD Col3 VARCHAR(50) NOT NULL CONSTRAINT Constraint_Name CHECK (Col3>=0);
/*
WITH NOCHECK tells SQL Server to skip validating existing rows against the new CHECK constraint.  The constraint is still created and enforced on all future INSERTs/UPDATEs, but any existing data is not checked — so if existing rows violate Col3 >= 0, the ALTER TABLE will still succeed.

Two important side effects:

The constraint is flagged as not trusted (is_not_trusted = 1 in sys.check_constraints), meaning the query optimizer will ignore it when generating execution plans. 
To make it trusted later (after cleaning up any violating data), run:
ALTER TABLE Table_Name WITH CHECK CHECK CONSTRAINT Constraint_Name;

Without WITH NOCHECK, the default for a newly added constraint is WITH CHECK, which would validate all existing rows and fail the entire ALTER TABLE if any violate the constraint. 
*/


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

/*
MS SQL SERVER ALTER table nocheck

In **Microsoft SQL Server**, the `ALTER TABLE ... NOCHECK CONSTRAINT` statement is used to **disable** one or more **CHECK** or **FOREIGN KEY** constraints on a table. When disabled, the constraint is not enforced, allowing future **INSERT** or **UPDATE** operations that would otherwise violate the constraint rules.

### Key Syntax and Usage

*   **Disable a single constraint:**
    ```sql
    ALTER TABLE table_name NOCHECK CONSTRAINT constraint_name;
    ```
*   **Disable all constraints on a table:**
    ```sql
    ALTER TABLE table_name NOCHECK CONSTRAINT ALL;
    ```

### Important Distinctions

*   **`NOCHECK` vs. `WITH NOCHECK`:**
    *   `ALTER TABLE ... NOCHECK CONSTRAINT` **disables** the constraint.
    *   `ALTER TABLE ... WITH NOCHECK ADD CONSTRAINT` **creates** a new constraint but does not validate existing data against it. The constraint remains **enabled** (trusted) for new data unless explicitly disabled afterward.
*   **Re-enabling Constraints:**
    *   To re-enable a disabled constraint without checking existing data:
        ```sql
        ALTER TABLE table_name CHECK CONSTRAINT constraint_name;
        ```
    *   To re-enable and **validate** existing data (fails if invalid data exists):
        ```sql
        ALTER TABLE table_name WITH CHECK CHECK CONSTRAINT constraint_name;
        ```

### Metadata Check
You can verify the status of constraints using the `sys.check_constraints` and `sys.foreign_keys` system views:
*   `is_disabled`: `1` if disabled, `0` if enabled.
*   `is_not_trusted`: `1` if the constraint was added or re-enabled with `WITH NOCHECK` or if invalid data exists.
*/

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

/*
A primary key uniquely identifies a row within a table.
A primary key signifies that you can set up a relationship between it and a row in another table.
A FK relationship constraint guarantees that the relationship between a primary key and a foreign key is enforced.  
A foreign key may prevent you from deleting a row if it links to a row in another table.
Constraints prevent orphaned records.
 
*/

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
/*
A foreign key is a key in a secondary table that you can join a primary key to.
A foreign key constraint guarantees that the relationship between a primary key and a foreign key are enforced.
A foreign key may prevent you from deleting a row if it links to a row in another table.
Constraints prevent orphaned records.

*/



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

/*
Indexes affect query performance.
Often designed incorrectly.
A key place to look when optimising queries.

By default, rows are stored in the heap.  To find data, you have to scan every item.
An index works like a dictionary index.
Types:
- rowstore
	- organized by rows
	- includes clustered and non-clustered
- columnstore
	- organized by columns
- clustered (b-tree)
	- data is ordered
	- We can only efficiently seek data from one column
	- only one clustered index can exist per table
- non-clustered
	- up to 999 per table
	- since only one clustered index can exist, for other fields we need non-clustered index.
	- need to apply filters and joins on other columns

Index strategy

- Reduce the number of indexes for tables with a high number of updates.
- Increase the use of indexes for tables with a high number of reads.
- Create indexes on primary keys and foreign keys to improve joins.
- You cannot index every data type.  Example, varchar(max) is not indexable.
- Indexes are best used on highly unique columns.  Not if all the tables have the same values. 
- Generally no need to index small tables.
- Match the sort order of the index with the sort order of the queries.

In SQL Server, the decision between a clustered and non-clustered index comes down to **how data is physically stored vs. how it is referenced**.

* A **clustered index** defines the physical order of the rows on disk. The leaf nodes of the B-Tree *are* the data rows themselves. Because physical storage can only be sorted one way, you get **only 1 clustered index per table**.

* A **non-clustered index** creates a separate, lightweight B-Tree structure containing only the indexed key columns and a pointer (the cluster key or row ID) back to the actual data. You can have **up to 999 non-clustered indexes per table**.

---

## When to Use a Clustered Index

Because the table itself is sorted by this key, clustered indexes excel at retrieval patterns that involve sorting, range scans, or sequential key lookup.

* **Primary Keys / Unique Identifiers:** Auto-incrementing integers (`IDENTITY`) or sequential IDs (`BIGINT`) make ideal clustered keys because new rows append cleanly to the end, preventing page splits.
* **Range Scans (`BETWEEN`, `>`, `<`):** Queries filtering ranges (e.g., `WHERE OrderDate BETWEEN '2026-01-01' AND '2026-01-31'`) read contiguous memory pages on disk with minimal I/O overhead.
* **Sorting (`ORDER BY`) & Grouping (`GROUP BY`):** If queries frequently request data sorted by a specific column (e.g., `ORDER BY TransactionDate`), SQL Server skips an expensive explicit sort operation.
* **High-Frequency Point Lookups returning ALL columns:** Queries executing `SELECT * WHERE CustomerID = 1052` fetch all record fields instantly without additional lookups.

---

## When to Use a Non-Clustered Index

Non-clustered indexes provide targeted lookup paths for queries filtering on columns other than your main table sorting key.

* **Foreign Keys & Secondary Search Columns:** Useful when querying on fields distinct from your primary key, such as searching employees by `LastName` or orders by `CustomerID`.
* **Exact Match Point Lookups (`=`):** Queries retrieving specific records based on unique attributes (e.g., `WHERE Email = 'user@example.com'`).
* **Covering Queries (`INCLUDE` clause):** When non-clustered indexes store the key filtering columns and `INCLUDE` additional payload columns, SQL Server satisfies the query entirely within the index tree—avoiding costly Key Lookups back to the clustered table.
* **Frequently Updated Columns:** Modifying non-clustered index key values reorders small index nodes without reordering the entire table on disk.

---

## Structural Comparison

| Characteristic | Clustered Index | Non-Clustered Index |
| --- | --- | --- |
| **Limit per table** | Max **1** | Up to **999** |
| **Physical Storage** | Rearranges actual data rows on disk | Separate index structure with pointers to data |
| **Leaf Node Content** | Complete row data | Index keys + Clustering Key / RID |
| **Best Column Choice** | Monotonic IDs, Dates, Primary Key | Foreign keys, filtering predicates, `JOIN` conditions |
| **Write Impact** | Higher on key update/random insert (causes page splits) | Low-to-moderate per additional index |

Creating a PK may automatically create a clustered index.

*/

---------------------------------
-- Syntax

-- look for our constraints

SELECT *
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'Patient'

-- delete the primary key PK_Patient....  for this exercise

ALTER TABLE Covid.patient
DROP CONSTRAINT PK__Patient__F4A24BC2BFE83DF6

SELECT Age, Record_Created_Date
FROM Covid.Patient
WHERE Age = 35;

-- select the above and click execution plan
-- "scan" means it will scan all the records

CREATE CLUSTERED INDEX IX_Clustered_Ex ON Covid.Patient (PK_ID);   
-- we still have to scan through every record

CREATE NONCLUSTERED INDEX IX_Nonclustered_Age ON Covid.Patient (Age);
-- database decides to ignore our nonclustered index; too much trouble given there is little date here

CREATE NONCLUSTERED INDEX IX_Nonclustered_Age_Inc ON Covid.Patient (Age)
INCLUDE (Record_Created_Date)
-- this is so the db doesn't have to look up Record_Created_Date
-- NOW the db uses Index Seek, not scan every single record.

-- DROP the index that isn't doing anything for us:
DROP INDEX IX_Nonclustered_Age ON Covid.Patient


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
/*
A CTE is a temporary named result set.
CTE is used to group a complex query into a single result set that can be used in a subsequent query.
Can make the code more readable.
Can be used to execute recursive logic in a similar way that a for-loop iterates over a list.

How to use a CTE
- cannot use ORDER BY or INTO statements in a CTE
- a CTE must be immediately followed by a single SELECT, INSERT, UPDATE, DELETE, or MERGE statement.
- Could be used to to take two aggregates for example if you want to take your maximum average value.

*/
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