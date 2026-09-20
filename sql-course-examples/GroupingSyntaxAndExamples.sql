----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Calculations, functions and logic
-- Copywrite: PADS research LTD


--------------------------------------------------------------
-- 1. Aggregate functions and Grouping
-------------------------------
-- Syntax

-- Grouping 
SELECT		[Column Name 1], 
			[Column Name 1] 
			SUM(Any_Column) 
FROM		[Schema].[Table_Name] 
GROUP BY	[Column Name 1], 
			[Column Name 2]


-- Having
SELECT		[Column Name 1], 
			[Column Name 1] 
			SUM(Any_column) 
FROM		[Schema].[Table_Name]  
GROUP BY	[Column Name 1], 
			[Column Name 2]
HAVING		SUM(Any_column) > 100


-- Element Order
SELECT		[Column Name 1], 
			[Column Name 1] 
			SUM(Any_column) 
FROM		[Schema].[Table_Name] 
WHERE		[Condition]
GROUP BY	[Column Name 1], [Column Name 2]
HAVING		SUM(Any_column) > 100
ORDER BY	[Column Name 1]
 

-------------------------------
-- Examples

SELECT		[TerritoryID]
			,[SalesPersonID]
			,SUM([TotalDue]) AS [SUM]
			,MAX([TotalDue]) AS [MAX]
			,MIN([TotalDue]) AS [MIN]
			,AVG([TotalDue])  AS [AVG]
			,COUNT(*) AS [COUNT]
FROM		[Sales].[SalesOrderHeader]
WHERE		[ShipDate] >= '01/01/2013' AND [ShipDate] <= '01/01/2014' AND 
			[SalesPersonID] IS NOT NULL
GROUP BY	[TerritoryID], [SalesPersonID]
HAVING		COUNT(*) > 10 AND AVG([TotalDue]) > 20000
ORDER BY	[TerritoryID], [SalesPersonID]
			

--------------------------------------------------------------
-- 2. Windows functions

-------------------------------
-- Syntax

SELECT	Column1
		,Column2 
		,Window_Function(Parameter) OVER (PARTITION BY Column_Name ORDER BY Column_Name) 
FROM	[Schema] [Table_Name]
 

-------------------------------
-- Examples
 SELECT		[SalesPersonID]
			,[SalesOrderID] 
			,[TotalDue]
			,COUNT(*) OVER() AS [Whole table count]
			,SUM([TotalDue]) OVER (PARTITION BY [SalesPersonID]) AS [Sum]
			,SUM([TotalDue]) OVER (PARTITION BY [SalesPersonID] ORDER BY [SalesOrderID]) AS [Running Total]
			,AVG( [TotalDue]) OVER (PARTITION BY [SalesPersonID]) AS [AVG]
			,MAX( [TotalDue]) OVER (PARTITION BY [SalesPersonID]) AS [MAX] 
			,MIN([TotalDue]) OVER (PARTITION BY [SalesPersonID]) AS [MIN] 
FROM		[Sales].[SalesOrderHeader]
WHERE		[SalesPersonID] IS NOT NULL
ORDER BY	[SalesPersonID], SalesOrderID


-- Rank Functions 
SELECT		[SalesPersonID]
			,[OrderDate] 
			,ROW_NUMBER() OVER(PARTITION BY [SalesPersonID] ORDER BY [OrderDate] ASC) AS [Row Number]
			,RANK() OVER(PARTITION BY [SalesPersonID] ORDER BY [OrderDate] ASC) AS [Rank] 
			,DENSE_RANK() OVER(PARTITION BY [SalesPersonID] ORDER BY [OrderDate] ASC) AS [Dense Rank]
FROM		[Sales].[SalesOrderHeader] 
WHERE		[SalesPersonID] IS NOT NULL
ORDER BY	[SalesPersonID],[OrderDate] ASC

-- Value Functions 
SELECT	[OrderDate]
		,[Total Sales] AS [Todays Total Sales]
		,LAG([Total Sales], 1) OVER(ORDER BY [OrderDate]) AS [Yesterday's Total Sales] 
		,LEAD([Total Sales], 1) OVER (ORDER BY [OrderDate]) AS [Tomorrow’s Total Sales]
		,[Total Sales] - ISNULL(LAG([Total Sales], 1) OVER (ORDER BY [OrderDate]),0) AS [Day on day]
FROM
(
		SELECT [OrderDate]
			    ,SUM(TotalDue) AS [Total Sales] 
		FROM [Sales]. [SalesOrderHeader]
		GROUP BY [OrderDate] 
) AS [Total_sales] 
ORDER BY (OrderDate)


--------------------------------------------------------------
-- 3. Subqueries

-------------------------------
-- Syntax

-- Filtering with subqueries 
SELECT	Column_1
		,Column_2
FROM	Table_A a
WHERE	Column_1 IN (SELECT Column_1 FROM Lookup_Table)
 
 -- Calculated and joined subqueries 
SELECT	Column_1
		,Column_2
		,(
			SELECT COUNT(*) FROM Table_B b
			WHERE b.ID = a.ID
		)
FROM	Table_A a

-- Subqueries as a table
SELECT	Column_1
		,Column_2
FROM	(
			SELECT Column_1, Column_2 FROM Table_B
		) a
 
 -- Aggregate subqueries 
SELECT	 MAX(AVG_Value)
FROM	(
			SELECT	  AVG(Value) AS AVG_Value
			FROM	  Table_B
			GROUP BY  Column_1
					  ,Column_2
		) a

SELECT MAX(AVG(Value))

-------------------------------
-- Examples

SELECT	[BusinessEntityID]
		,[PersonID]
		,[ContactTypeID]
		,[rowguid]
		,[ModifiedDate]
FROM	[Person].[BusinessEntityContact]
WHERE	[ContactTypeID] IN (	SELECT	[ContactTypeID] 
								FROM	[Person].[ContactType]
								WHERE	[Name] LIKE 'A%'
							)

SELECT	[ProductID]
		,[Name]
		,(
			SELECT	COUNT(*)
			FROM	[Production].[WorkOrder] wo
			WHERE	wo.[ProductID] = p.[ProductID]
		) AS Work_Order_Count
FROM	[Production].[Product] p


SELECT	*
FROM	
(
	SELECT	[LocationID]
			,[Name]
			,[CostRate]
			,[Availability]
			,[ModifiedDate]
	FROM	[Production].[Location]
	WHERE	[Name] LIKE '%PAINT%'
) t


SELECT MAX(AverageDue) AS [HighestAverage]
FROM 
(
	SELECT		[TerritoryID]
				,AVG([TotalDue]) as AverageDue
	FROM		[Sales].[SalesOrderHeader]
	GROUP BY	[TerritoryID]
) t




