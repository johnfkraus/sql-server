-- sql server course

CREATE TABLE Example_Schema.CovidVariant(
    [PK_ID] INT,
    [Location] VARCHAR(50),
    [Date] DATE,
    [Num_Sequence] INT
)

SELECT TOP(3)
    [AddressTypeID],
    [Name]
INTO [SQL_Course].[dbo].[Filtered_AddressType]
FROM [AdventureWorks2019].[Person].[AddressType]

SELECT TOP (1000) [AddressTypeID]
      ,[Name]
  FROM [SQL_Course].[dbo].[Filtered_AddressType]

  SELECT TOP(3)
    [AddressTypeID],
    [Name]
INTO #Filtered_AddressType
FROM [AdventureWorks2019].[Person].[AddressType]

SELECT TOP (1000) [AddressTypeID]
      ,[Name]
  FROM #Filtered_AddressType


  SELECT TOP(3)
    [AddressTypeID],
    [Name]
INTO ##Filtered_AddressType
FROM [AdventureWorks2019].[Person].[AddressType]

SELECT TOP (1000) [AddressTypeID]
      ,[Name]
  FROM ##Filtered_AddressType


DROP TABLE IF EXISTS [dbo].[Filtered_AddressType]

USE psp
GO

CREATE SCHEMA Covid

CREATE TABLE Covid.Covid_Variant(
    [PK_ID] INT,
    [Location] VARCHAR(50),
    [Date] DATE,
    [Num_Sequence] INT
)

ALTER TABLE Covid.Covid_Variant
ADD Variant VARCHAR(50),
    Num_Sequences_Total DECIMAL(18,0),
    Has_Vaccination_Program CHAR(3),
    Impact INT

ALTER TABLE Covid.Covid_Variant
DROP COLUMN Impact

ALTER TABLE Covid.Covid_Variant
ALTER COLUMN Variant VARCHAR(200)

ALTER TABLE Covid.Covid_Variant
ALTER COLUMN Num_Sequences_Total DECIMAL(18,2)
