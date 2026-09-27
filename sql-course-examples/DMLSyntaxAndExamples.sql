----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: DML - insert, update and delete data
-- Copywrite: PADS research LTD

----------------------------------------------------
-- 1. Insert

/*




*/


---------------------------------
-- Syntax

-- Insert Into with values
INSERT INTO TableName
VALUES (Value1,Value2,Value3);

-- Insert Into with column names
INSERT INTO TableName ( Col1, 
						Col2, 
						Col3
)
VALUES (Value1, 
		Value2, 
		Value3
);

-- Insert Into with select
INSERT INTO TableA ( Col1, 
					 Col2, 
					 Col3
)
SELECT	Value1,
		Value2,
		Value3
FROM	TableB

-- Bulk Insert
BULK INSERT TableName
FROM 'FileLocation'
WITH ( FORMAT = 'CSV');


---------------------------------
-- Example

--------------------
-- Hospital Insert
INSERT INTO [Covid].[Hospital]([Name])
VALUES 
('London'),
('New York'),
('Sydney')

---------------------------
-- Patient Insert
INSERT INTO [Covid].[Patient] (
		[PK_ID]
		,[FK_Covid_Variant]
		,[Age]
		,[Record_Created_Date]
)
VALUES
(1, 5 ,56, '01/01/2021'),
(2, 100 ,71, '01/01/2021'),
(3, 30000 ,85, '01/01/2021'),
(4, 3452 ,67, '01/01/2021'),
(5, 45 ,95, '01/01/2021'),
(6, 7 ,35, '01/01/2021')

---------------------------
-- Patient_Hospital Insert
INSERT INTO [Covid].[Patient_Hospital](
		[PK_Patient_ID]
		,[PK_Hospital_ID]
		,[Global_Ranking]
		,[Quality_Rating]
		,[Satisfaction]
)
VALUES
(1,1,1,1,3),
(2,2,2,3,3),
(3,3,3,5,4),
(4,3,4,3,5),
(4,2,5,5,3),
(5,2,6,4,1),
(6,1,7,4,2)

BULK INSERT [Covid].[Covid_Variant]
FROM 'C:\Users\Computer\Documents\SQL Tutorials\Covid_Variant.csv'
WITH ( FORMAT = 'CSV');

-- Insert Into 
CREATE TABLE #Temp(
	  [PK_ID] INT
      ,[FK_Covid_Variant] INT
      ,[Age] INT
      ,[Record_Created_Date] DATE
)

INSERT INTO #Temp
SELECT	*
FROM	[Covid].[Patient]

SELECT * FROM #Temp


----------------------------------------------------
-- 2. Update

---------------------------------
-- Syntax

-- every row will be updated with the provided value
UPDATE	TableName
SET		Col1 = 'AValue';


UPDATE	TableName
SET		Col1 = Value1, 
		Col2 = value2
WHERE	Condition;


-- update a table with a value from another table
UPDATE	TableA
SET		TableA.commission = a.Col1 * b.Col2
FROM	TableA a	INNER JOIN 
		TableB b	ON a.FK_ID = b.PK_ID;

---------------------------------
-- Example

SELECT	*
FROM	[Covid].[Covid_Variant]

UPDATE [Covid].[Covid_Variant]
SET	   [Has_Vaccination_Program] = 'no'

SELECT  [PK_ID]
		,[FK_Covid_Variant]
		,[Age]
		,[Record_Created_Date]
FROM	[SQL_Course].[Covid].[Patient]
WHERE	PK_ID = 2

UPDATE  [Covid].[Patient]
SET		Age = 75,
		FK_Covid_Variant = 200
WHERE	PK_ID = 2

UPDATE  p
SET		p.[Record_Created_Date] = cv.[Date]
FROM	[Covid].[Patient] p INNER JOIN
		[Covid].[Covid_Variant] cv ON p.FK_Covid_Variant = cv.[PK_ID]


----------------------------------------------------
-- 3. Delete
/*
DELETE statement removes on record at a time.  Every deleted row is recorded in the transaction log.
TRUNCATE TABLE removes the data by deallocating the data pages used to store the table.
- does not log each deleted row; only records page deallocations in the transaction.


*/


---------------------------------
-- Syntax

DELETE FROM TableName

DELETE FROM TableName WHERE Condition;

TRUNCATE TABLE TableName; 
---------------------------------
-- Example

SELECT *
INTO [Covid].[Covid_Variant_Copy]
FROM [Covid].[Covid_Variant]

SELECT *
FROM [Covid].[Covid_Variant_Copy]

/* Switch on statistics time */
SET STATISTICS TIME ON;

DELETE FROM [Covid].[Covid_Variant_Copy]

/* Switch off statistics time */
SET STATISTICS TIME OFF; 

DROP TABLE [Covid].[Covid_Variant_Copy]

DELETE FROM [Covid].[Covid_Variant_Copy]
WHERE Num_Sequences_Total > 2

/* Switch on statistics time */
SET STATISTICS TIME ON;

TRUNCATE TABLE [Covid].[Covid_Variant_Copy]

/* Switch off statistics time */
SET STATISTICS TIME OFF; 