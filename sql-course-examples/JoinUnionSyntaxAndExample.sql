----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Table joins and unions
-- Copywrite: PADS research LTD


--------------------------------------------------------------
-- 1. Inner Join


-------------------------------
-- Syntax
SELECT	a.col1,
		a.col2,
		b.col1,
		b.col2
FROM	table_a a INNER JOIN
		table_b b ON a.pk = b.fk


-------------------------------
-- Example

SELECT	[ProductID]
		,[ProductNumber]
		,[MakeFlag]
		,[FinishedGoodsFlag]
		,[Color]
		,[SafetyStockLevel]
		,[ReorderPoint]
		,[StandardCost]
		,[ListPrice]
		,[Size]
		,[SizeUnitMeasureCode]
		,[WeightUnitMeasureCode]
		,[Weight]
		,[DaysToManufacture]
		,[ProductLine]
		,[Class]
		,[Style]
		,p.[ProductSubcategoryID]
		,p.[ProductModelID]
		,[SellStartDate]
		,[SellEndDate]
		,[DiscontinuedDate]
		,psc.[Name] As [sub name]
FROM	[Production].[Product] p INNER JOIN	
		[Production].[ProductModel]			pm	ON	p.ProductModelID = pm.ProductModelID AND
													pm.Name like 'R%' INNER JOIN 
		[Production].[ProductSubcategory]	psc	ON	p.ProductSubcategoryID = psc.ProductSubcategoryID


--------------------------------------------------------------
-- 2. Left and Right outer joins


-------------------------------
-- Syntax
SELECT	a.col1,
		b.col2,
		c.col1
FROM	table_a a LEFT OUTER JOIN
		table_b b ON a.col_1 = b.col_1 RIGHT OUTER JOIN
		table_b c ON b.col_2 = c.col_2


-------------------------------
-- Example
SELECT	[ProductID]
		,p.[Name]
		,[ProductNumber]
		,[MakeFlag]
		,[FinishedGoodsFlag]
		,[Color]
		,[SafetyStockLevel]
		,[ReorderPoint]
		,[StandardCost]
		,[ListPrice]
		,[Size]
		,[SizeUnitMeasureCode]
		,[WeightUnitMeasureCode]
		,[Weight]
		,[DaysToManufacture]
		,[ProductLine]
		,[Class]
		,[Style]
		,[ProductSubcategoryID]
		,p.[ProductModelID]
		,[SellStartDate]
		,[SellEndDate]
		,[DiscontinuedDate]
FROM	[Production].[Product] p LEFT OUTER JOIN -- RIGHT OUTER JOIN
		[Production].[ProductModel] pm ON p.ProductModelID = pm.ProductModelID 



--------------------------------------------------------------
-- 3. Full and Cross Joins


-------------------------------
-- Syntax
SELECT	a.col1,
		b.col2
FROM	table_a a FULL OUTER JOIN
		table_b b ON a.col_1 = b.col_1 

SELECT	a.col1,
		b.col2
FROM	table_a a CROSS JOIN
		table_b b

-------------------------------
-- Example

-- FULL OUTER JOIN
SELECT	[ProductID]
		,[ProductNumber]
		,[MakeFlag]
		,[FinishedGoodsFlag]
		,[Color]
		,[SafetyStockLevel]
		,[ReorderPoint]
		,[StandardCost]
		,[ListPrice]
		,[Size]
		,[SizeUnitMeasureCode]
		,[WeightUnitMeasureCode]
		,[Weight]
		,[DaysToManufacture]
		,[ProductLine]
		,[Class]
		,[Style]
		,[ProductSubcategoryID]
		,p.[ProductModelID]
		,[SellStartDate]
		,[SellEndDate]
		,[DiscontinuedDate]
		,p.[Name]
FROM	[Production].[Product] p FULL OUTER JOIN
		[Production].[ProductModel] pm ON p.ProductModelID = pm.ProductModelID 

-- CROSS JOIN 
SELECT	dpt.[NAME]
		,emp.JobTitle
FROM
(
	SELECT  TOP(3)
			[Name]
	FROM	[HumanResources].[Department]
) dpt CROSS JOIN
(
	SELECT  TOP(3)
			[JobTitle]
	FROM	[HumanResources].[Employee]
) emp


--------------------------------------------------------------
-- 4. 5.6 Union and Union All


-------------------------------
-- Example
--------------------------------------------
-- UNION Example
SELECT	TOP 10 [CustomerID]
		,'Customer' AS Key_Type
FROM	[Sales].[Customer]

UNION

SELECT	TOP 10 [BusinessEntityID]
		,'BusinessEntityContact' AS Key_Type
FROM	[Person].[BusinessEntityContact]

--------------------------------------------
-- UNION ALL Example
SELECT *
FROM
(
	SELECT	'Ms.' AS [Title]	
			,'Gail'	AS [FirstName]
			,'A' AS [MiddleName] 	
			,'Erickson' AS [LastName]
	UNION ALL
	SELECT TOP 10
			[Title]
			,[FirstName]
			,[MiddleName]
			,[LastName]
	FROM	[Person].[Person]
) s
WHERE	 [LastName] <> 'Erickson'
ORDER BY [LastName]


