----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Introduction to the basics of SQL
-- Copywrite: PADS research LTD

--------------------------------------------------------------
-- 1. Select data from a table

-------------------------------
-- Syntax

-- Basic select statement
SELECT	[Column name 1]
		,[Column name 2]
FROM	[Table name];

-- Wild card select
SELECT	*
FROM	[Table name];

-------------------------------
-- Examples
SELECT	[ProductID]
		,[Name]
FROM	[Production].[Product]

SELECT	*
FROM	[Production].[Product]



--------------------------------------------------------------
-- 2.Sort selected data

-------------------------------
-- Syntax
SELECT   [column name 1]
        ,[column name 2]
FROM     [table name]
ORDER BY [column name 1] ASC
        ,[column name 2] DESC;

-------------------------------
--Examples 

-- Ascending example
SELECT		[CustomerID]
			,[PersonID]
			,[StoreID]
			,[TerritoryID]
			,[AccountNumber]
			,[rowguid]
			,[ModifiedDate]
FROM		[Sales].[Customer]
ORDER BY	[TerritoryID] ASC

-- Descending example
SELECT		[CustomerID]
			,[PersonID]
			,[StoreID]
			,[TerritoryID]
			,[AccountNumber]
			,[rowguid]
			,[ModifiedDate]
FROM		[Sales].[Customer]
ORDER BY	[TerritoryID] DESC

-- Multiple column sort
SELECT		[CustomerID]
			,[PersonID]
			,[StoreID]
			,[TerritoryID]
			,[AccountNumber]
			,[rowguid]
			,[ModifiedDate]
FROM		[Sales].[Customer]
ORDER BY	[TerritoryID]
			,[AccountNumber]

-- Sort by column position
SELECT		[CustomerID]
			,[PersonID]
			,[StoreID]
			,[TerritoryID]
			,[AccountNumber]
			,[rowguid]
			,[ModifiedDate]
FROM		[Sales].[Customer]
ORDER BY	4,5


--------------------------------------------------------------
-- 3.WHERE clause with comparison operators

-------------------------------
-- Syntax
SELECT		[column 1]
			,[column 2]
FROM		[schema].[table name]
WHERE		[condition is true]
ORDER BY	[column 1];

-------------------------------
--Example
SELECT	[SickLeaveHours]
		,[BusinessEntityID]
		,[NationalIDNumber]
		,[LoginID]
		,[OrganizationNode]
		,[OrganizationLevel]
		,[JobTitle]
		,[BirthDate]
		,[MaritalStatus]
		,[Gender]
		,[HireDate]
		,[SalariedFlag]
		,[VacationHours]
		,[CurrentFlag]
		,[rowguid]
		,[ModifiedDate]
FROM	[HumanResources].[Employee]
WHERE	[SickLeaveHours] = 42
		--[SickLeaveHours] > 42
		--[SickLeaveHours] < 42
		--[SickLeaveHours] >= 42
		--[SickLeaveHours] <= 42
		--[SickLeaveHours] <> 42
		--[JobTitle] = 'Marketing Specialist'
		--[BirthDate] = '29/01/1969'

--------------------------------------------------------------
-- 5.Logical operators and NULL values

-------------------------------
-- Syntax

-- OR
SELECT  [column 1]
        ,[column 2]
FROM	[schema].[table]
WHERE	[Boolean condition 1] OR     
        [Boolean condition 2];
-- AND
SELECT  [column 1]
        ,[column 2]
FROM	[schema].[table]
WHERE	[Boolean condition 1] AND  
        [Boolean condition 2];
-- NOT
SELECT  [column 1]
        ,[column 2]
FROM	[schema].[table]
WHERE	NOT [Boolean condition 1];

-- IS NULL
SELECT  [column 1]
        ,[column 2]
FROM	[schema].[table]
WHERE	[column 1] IS NULL;

-- IS NOT NULL
SELECT  [column 1]
        ,[column 2]
FROM	[schema].[table]
WHERE	[column 1] IS NOT NULL;

--------------------------------------------------------------
-- 6.Logical operators and NULL values - example

-------------------------------
--Examples 

-- AND Example 
SELECT	[BusinessEntityID]
		,[TerritoryID]
		,[SalesQuota]
		,[Bonus]
		,[CommissionPct]
		,[SalesYTD]
		,[SalesLastYear]
		,[rowguid]
		,[ModifiedDate]
FROM	[AdventureWorks2019].[Sales].[SalesPerson]
WHERE	[Bonus] > 2000 AND [CommissionPct] <= 0.01

-- OR Example
SELECT	[BusinessEntityID]
		,[TerritoryID]
		,[SalesQuota]
		,[Bonus]
		,[CommissionPct]
		,[SalesYTD]
		,[SalesLastYear]
		,[rowguid]
		,[ModifiedDate]
FROM	[AdventureWorks2019].[Sales].[SalesPerson]
WHERE	[Bonus] > 2000 OR [Bonus] = 0
		
-- NOT Example
SELECT	[BusinessEntityID]
		,[TerritoryID]
		,[SalesQuota]
		,[Bonus]
		,[CommissionPct]
		,[SalesYTD]
		,[SalesLastYear]
		,[rowguid]
		,[ModifiedDate]
FROM	[AdventureWorks2019].[Sales].[SalesPerson]
WHERE	NOT [Bonus] > 2000

-- IS NOT NULL Example
SELECT	[BusinessEntityID]
		,[TerritoryID]
		,[SalesQuota]
		,[Bonus]
		,[CommissionPct]
		,[SalesYTD]
		,[SalesLastYear]
		,[rowguid]
		,[ModifiedDate]
FROM	[AdventureWorks2019].[Sales].[SalesPerson]
WHERE	[SalesQuota] IS NOT NULL

-- IS NULL Example
SELECT	[BusinessEntityID]
		,[TerritoryID]
		,[SalesQuota]
		,[Bonus]
		,[CommissionPct]
		,[SalesYTD]
		,[SalesLastYear]
		,[rowguid]
		,[ModifiedDate]
FROM	[AdventureWorks2019].[Sales].[SalesPerson]
WHERE	[SalesQuota] IS NULL



--------------------------------------------------------------
-- 7.BETWEEN and IN functions

-------------------------------
-- Syntax

-- BETWEEN
SELECT	[column 1]
		,[column 2]
FROM	[schema].[table]
WHERE	[column 1] BETWEEN     
		[value 1] AND [value 2];

-- IN
SELECT	[column 1]
		,[column 2]
FROM	[schema].[table]
WHERE	[column 1] 
		IN('value 1', 'value 2', 'value 3'); 

-- IN with sub query
SELECT	[column 1]
		,[column 2]
FROM	[schema].[table]
WHERE	[column 1] IN	(
							SELECT	[column 1]
							FROM	[schema].[table]
						); 


--------------------------------------------------------------
-- 8.BETWEEN and IN functions - example

-------------------------------
--Examples 

-- BETWEEN Example
SELECT	[Weight]
		,[SellEndDate]
		,[ProductID]
		,[Name]
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
		,[DaysToManufacture]
		,[ProductLine]
		,[Class]
		,[Style]
		,[ProductSubcategoryID]
		,[ProductModelID]
		,[SellStartDate]
		,[DiscontinuedDate]
		,[rowguid]
		,[ModifiedDate]
FROM	[Production].[Product] 
WHERE	[Weight] BETWEEN 400 AND 800
		--[Weight] >= 400 AND [Weight] <= 800
		--[Weight] NOT BETWEEN 400 AND 800
		--[SellEndDate] BETWEEN '29/05/2012' AND '29/05/2012'

-- IN Example
SELECT		[ProductID]
			,[LocationID]
			,[Shelf]
			,[Bin]
			,[Quantity]
			,[rowguid]
			,[ModifiedDate]
FROM		[AdventureWorks2019].[Production].[ProductInventory]
WHERE		[LocationID] IN (50,6)
ORDER BY	[LocationID]	

SELECT	[LocationID]
FROM	[AdventureWorks2019].[Production].[Location]
WHERE	[Availability] = 120

SELECT		[ProductID]
			,[LocationID]
			,[Shelf]
			,[Bin]
			,[Quantity]
			,[rowguid]
			,[ModifiedDate]
FROM		[AdventureWorks2019].[Production].[ProductInventory]
WHERE		[LocationID] IN (
								SELECT	[LocationID]
								FROM	[AdventureWorks2019].[Production].[Location]
								WHERE	[Availability] = 120
							)
ORDER BY	[LocationID]	



--------------------------------------------------------------
-- 9.LIKE function and wildcards
/*
% - Matches any characters or numbers

A% - Match words starting with A.

_ (underscore) - matches any single character

'[abcf]%' (square bracket wildcard) - accept a list of characters in a certain position.

'[f-h]%' - specify a range of characters, f,g,h

^ (carat) operator, means NOT;

'[^a-c]%' - the first letter should not be in the range a-c.



*/


-------------------------------
-- Syntax

SELECT	[character column]
		,[col 2]
FROM	[table name]
WHERE	[character column] LIKE 'pattern'


--------------------------------------------------------------
-- 10.LIKE function and wildcards - example

-------------------------------
--Examples 

SELECT	[ProductID]
		,[Name]
		,[ProductNumber]
FROM	[AdventureWorks2019].[Production].[Product]
WHERE	-- [Name] LIKE '%LOCK%'
		-- [Name] LIKE 'Internal Lock Washer _'
		-- [Name] LIKE '[a-c]%'
		-- [Name] LIKE '[ft]%'
		-- [Name] NOT LIKE '%[1-9]%'
		-- Name LIKE '[^WB]%'
		Name LIKE '[^WB][^DELH][^owua][^kedh]%'


--------------------------------------------------------------
-- 11.Order of precedence
/*
Maths [*/%], [+-]

Comparison operators [=,>,<,>=,<=,<>, etc.]

NOT

AND

[BETWEEN, IN, LIKE, OR] [ANY, ALL, SOME]

If operators in an expression have equal precedence, they are evaluated left to right.

Use brackets to control exexecution order.

Everything in parentheses will be evaluated as a complete statement.


*/



-------------------------------
-- Examples
SELECT	[ProductID]
		,[Name]
		,[ProductNumber]
		,[StandardCost]
FROM	[AdventureWorks2019].[Production].[Product]
WHERE	[StandardCost] * 2 > 200 AND 
		[Color] IS NOT NULL AND 
		([Name] LIKE '%Cranker%' OR [Name] LIKE '%Road%') OR
		[Name] LIKE 'B_a%'