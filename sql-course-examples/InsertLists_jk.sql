---------------------------------------------
-- Hospital Insert
INSERT INTO [Covid].[Hospital](Name)
VALUES
('London'),
('New York'),
('Sydney')

-- BULK INSERT
-- columns in the csv file must match the fields in the table
BULK INSERT [Covid].[Covid_Variant]
FROM '/Users/blauerbock/workspaces/sql-server/sql-course-examples/Covid_Variant.csv'
WITH (FORMAT = 'CSV')

-- doesn't work with ms sql server in docker in container; instead:


-- docker cp /Users/blauerbock/workspaces/sql-server/sql-course-examples/Covid_Variant.csv e08865bda7d66ef0da15b7a2844929fd8c5202b70136cef7ce84ebaa22a49cfa:/var/opt/mssql/data/

BULK INSERT [Covid].[Covid_Variant]
FROM '/var/opt/mssql/data/Covid_Variant.csv'
WITH (
    FIRSTROW = 0,
    FORMAT = 'CSV' --,  FIRSTROW = 2  -- Skip header row if present
);

INSERT INTO [Covid].[Covid_Variant] (
[PK_ID]
      ,[Location]
      ,[Date]
      ,[Num_Sequences]
      ,[Variant]
      ,[Num_Sequences_Total]
      ,[Has_Vacinaiton_Program]
) VALUES
(1,Angola,06/07/2020,0,Alpha,3,yes)

-- Now SQL Server correctly parses DD/MM/YYYY
SELECT CAST('25/12/2026' AS DATETIME) AS UkDate;

SET DATEFORMAT dmy;

2:53:16 PM
Started executing query at  Line 20
Msg 4863, Level 16, State 1, Line 20
Bulk load data conversion error (truncation) for row 1, column 7 (Has_Vacinaiton_Program).
Msg 4863, Level 16, State 1, Line 20
Bulk load data conversion error (truncation) for row 2, column 7 (Has_Vacinaiton_Program).
Msg 4863, Level 16, State 1, Line 20
Bulk load data conversion error (truncation) for row 3, column 7 (Has_Vacinaiton_Program).
Msg 4863, Level 16, State 1, Line 20
Bulk load data conversion error (truncation) for row 4, column 7 (Has_Vacinaiton_Program).
Msg 4863, Level 16, State 1, Line 20
Bulk load data conversion error (truncation) for row 5, column 7 (Has_Vacinaiton_Program).
Msg 4863, Level 16, State 1, Line 20


BULK INSERT [Covid].[Covid_Variant]
FROM '/var/opt/mssql/data/Covid_Variant.csv'
WITH (
    FORMAT = 'CSV',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW=2
);

Msg 4863, Level 16, State 1, Line 44
Bulk load data conversion error (truncation) for row 1, column 7 (Has_Vacinaiton_Program).
Msg 4863, Level 16, State 1, Line 44


Msg 4865, Level 16, State 1, Line 44
Cannot bulk load because the maximum number of errors (10) was exceeded.
Msg 7399, Level 16, State 1, Line 44
The OLE DB provider "BULK" for linked server "(null)" reported an error. The provider did not give any information about the error.
Msg 7330, Level 16, State 2, Line 44
Cannot fetch a row from OLE DB provider "BULK" for linked server "(null)".

-- THIS FIXED IT:
ALTER TABLE [Covid].[Covid_Variant]
ALTER COLUMN Has_Vacinaiton_Program VARCHAR(10) NULL;


---------------------------------------------
-- Patient Insert; FAILS until Covid_Variant table has data
INSERT INTO [Covid].[Patient] (
    [PK_ID]
      ,[FK_Covid_Variant]
      ,[Age]
      ,[Record_Created_Date]
) VALUES
(1, 5 ,56, '01/01/2021'),
(2, 100 ,71, '01/01/2021'),
(3, 30000 ,85, '01/01/2021'),
(4, 3452 ,67, '01/01/2021'),
(5, 45 ,95, '01/01/2021'),
(6, 7 ,35, '01/01/2021')

---------------------------------------------
-- Patient_Hospital Insert
INSERT INTO [Covid].[Patient_Hospital](
    [PK_Patient_ID]
    ,[PK_Hospital_ID]
    ,[Global_Ranking]
    ,[Quality_Rating]
    ,[Satisfaction]
) VALUES
(1,1,1,1,3),
(2,2,2,3,3),
(3,3,3,4,4),
(4,3,4,3,5),
(4,2,5,4,3),
(5,2,6,4,1),
(6,1,7,4,2)


-- create a temporary table
CREATE TABLE #Temp (
    [PK_ID] INT
      ,[FK_Covid_Variant] INT
      ,[Age] INT
      ,[Record_Created_Date] DATE
)

INSERT INTO #Temp
SELECT *
FROM [Covid].[Patient]

SELECT * FROM #Temp