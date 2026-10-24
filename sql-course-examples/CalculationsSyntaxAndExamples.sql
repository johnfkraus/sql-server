----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Calculations, functions and logic
-- Copywrite: PADS research LTD


--------------------------------------------------------------
-- 1. Text concatenation and maths operators

-------------------------------
-- Syntax

-------------------------------
-- Examples

USE AdventureWorks2019
GO

SELECT * FROM Sales.SalesOrderDetail
WHERE UnitPriceDiscount <> 0

SELECT	[UnitPrice] + [UnitPriceDiscount] AS [Add]
		,[UnitPrice] - [UnitPriceDiscount] AS [Subtract]
		,[UnitPrice] * 4 AS [Multiply]
		,[UnitPrice] / 2 AS [Divide]
		,21 % 5 AS [Mod]
		,'Tracking number is: ' + [CarrierTrackingNumber] AS [Tracking Number]
FROM	[Sales].[SalesOrderDetail]

--------------------------------------------------------------
-- 2. String functions

-------------------------------
-- Syntax
CHARINDEX ( expressionToFind , expressionToSearch , start_location  )
CONCAT ( string_value1, string_value2, string_valueN)
CONCAT_WS ( separator, argument1, argument2, argumentN... )
FORMAT( value, format, culture )  
LEFT ( character_expression , integer_expression )  
RIGHT ( character_expression , integer_expression )  
LEN ( string_expression )  
LOWER ( character_expression )
UPPER ( character_expression )
LTRIM ( character_expression )  
RTRIM ( character_expression )
SUBSTRING ( expression ,start , length )  
REPLACE ( string_expression , string_pattern , string_replacement )
REVERSE ( string_expression )  


--------------------------------------------------------------
-- 3. String function - examples

-------------------------------
-- Examples

SELECT	CHARINDEX('@', [EmailAddress]) AS [AtPosition]
		,[EmailAddress]
		,RIGHT([EmailAddress], 19) AS [Right]
		,LEFT([EmailAddress], CHARINDEX('@', [EmailAddress]) - 1) AS [Left]
		,LEN([EmailAddress]) AS [Length]
		,SUBSTRING( [EmailAddress],
					CHARINDEX('@', [EmailAddress]) + 1,
					CHARINDEX('.', [EmailAddress]) - CHARINDEX('@', [EmailAddress]) - 1
		) AS [Domain]
		,REPLACE(EmailAddress, '.com', '.co.uk') [EmailRename]
		,REVERSE('abcdefg') AS [Reverse]
FROM	[Person].[EmailAddress]


SELECT	CONCAT([AddressLine1], [AddressLine2], [City], [PostalCode]) AS [ConcatinatedAddress]
		,CONCAT_WS(', ', [AddressLine1], [AddressLine2], [City], [PostalCode]) AS [ConcatinatedAddressWithSeperator]
		,LOWER([AddressLine1]) AS [Lower]
		,UPPER([AddressLine1]) AS [Upper]
		,RTRIM(' abcd  ') AS [RTrim]
		,LTRIM(' abcd  ') AS [LTrim]
		,TRIM(' abcd  ') AS [Trim]
FROM	[Person].[Address]



--------------------------------------------------------------
-- 4. Date functions

-------------------------------
-- Syntax
CURRENT_TIMESTAMP
DATEADD (datepart , number , date ) 
DATEDIFF ( datepart , startdate , enddate ) 
DATEPART ( datepart , date )  
DAY ( date ) 
MONTH ( date )
YEAR ( date )  
EOMONTH ( start_date, month_to_add ])  
GETDATE()
ISDATE ( expression )


-------------------------------
-- Examples
SELECT	[OrderDate]
		,[DueDate]
		,[ShipDate]
		,DATEADD (WEEK, 1, ShipDate )  AS [Date + 1 Week]
		,DATEADD (DAY, -1, ShipDate) AS [Date - 1 Day]
		,DATEDIFF(DAY, [ShipDate], [DueDate]) AS [Shipping and due diff]
		,DATEPART(Year, [OrderDate]) AS [Year Datepart]
		,DAY([OrderDate]) AS [Day]
		,MONTH([OrderDate]) AS [Month]
		,YEAR([OrderDate]) AS [Year]
		,EOMONTH([OrderDate]) AS [Last day of month]
		,GETDATE() AS [TodaysDate]
		,ISDATE([OrderDate]) AS [Is a date]
		,ISDATE('133/10/2021') AS [Is a date 2]
FROM	[Sales].[SalesOrderHeader]



--------------------------------------------------------------
-- 5. Trig functions

Subtended is a verb form (from subtend, meaning "to stretch under" in Latin) most commonly used in geometry to describe how a line segment, chord, or arc "forms" or "delimits" an angle at a given point.

Basic definition: An object (like a line segment or an arc) subtends an angle when two rays travel from a vertex point to each of the two endpoints of that object, creating an angle in between.

 A Vertex (geometry) is a corner or point where lines, line segments, curves, or the edges of a polygon or polyhedron meet.

 2pi radians = 360 degrees (a whole circle)

pi radians = 180 degrees (a half circle)

pi/2 radians = 90 degrees

3/2pi radians = 180 degrees

Trigonomic functions:

You must use radians, not degrees, in SQL Server trigonometric functions.

𝜃 = angle in radians (type: float)

sin(𝜃)
cos(𝜃)
tan(𝜃)

sin^-1(𝜃) = ASIN
cos^-1(𝜃) = ACOS
tan^-1(𝜃) = ATAN

cot(𝜃) = 1/tan(𝜃) = cos(𝜃)/sin(𝜃)

ATN2 = positive angle between a line specified by x and y and the x axis; given a point
- ATBN2(float, float)

Convert between radians and degrees:

rad -> degrees: rad X 180/pi.  (or use sql server function DEGREES(rad))

degrees -> radians: degrees X pi/180. (or use sql server function RADIANS(degrees))

(𝜃)
(𝜃)
(𝜃)

-------------------------------
-- Syntax
ACOS ( float_expression )  
ASIN ( float_expression ) 
ATAN ( float_expression )  
COS ( float_expression )  
SIN ( float_expression ) 
TAN ( float_expression ) 
COT ( float_expression )  
ATN2 (x , y) 


--------------------------------------------------------------
-- 6. Trig function - examples

-------------------------------
-- Examples

SELECT	DEGREES(PI()/2) AS [90]
		,DEGREES(PI()) AS [180]
		,DEGREES((3 * PI())/2) AS [270] 
		,DEGREES(2 * PI()) AS [360]
		,RADIANS(90.00) AS [pi/2]
		,RADIANS(180.00) AS [pi]
		,RADIANS(270.00) AS [3 * pi/2]
		,RADIANS(360.00) AS [2 * pi]
		,PI() AS [PI]
		,COS(PI()) AS [Cos] 
		,SIN(PI()/2) AS  [Sin]
		,TAN(0) AS  [Tan]
		,DEGREES(ATN2(2,2)) AS [Line] 



--------------------------------------------------------------
-- 7. General maths functions

-------------------------------
-- Syntax
ABS ( numeric_expression )
CEILING ( numeric_expression ) 
FLOOR ( numeric_expression ) 
EXP ( float_expression )   
POWER ( float_expression , y )
LOG ( float_expression , base )
LOG10 ( float_expression )  
RAND ( [ seed ] )  
ROUND ( numeric_expression , length  ,function )  
SIGN ( numeric_expression ) 
SQRT ( float_expression )  
SQUARE ( float_expression ) 



--------------------------------------------------------------
-- 8. General maths function - examples

-------------------------------
-- Examples

SELECT	[OrderQty]
		,[UnitPrice]
		,[LineTotal]
		,ABS(-20) AS [ABS]
		,CEILING([UnitPrice]) AS [CEILING]
		,FLOOR([UnitPrice]) AS [FLOOR]
		,EXP(2) AS [EXP]   
		,POWER(10, 2) AS [POWER]
		,LOG(100, 10) AS [LOG]
		,LOG10(100) AS [LOG10]
		,LOG(7.38905609893065, EXP(1)) AS [LN]
		,RAND(0.2) AS [RAND] 
		,ROUND([UnitPrice], 2 ) AS [ROUND] 
		,SIGN(-156) AS [SIGN]
		,SQRT(9) AS [SQRT]
		,SQUARE(3) AS [SQUARE]
FROM	[Sales].[SalesOrderDetail]

--------------------------------------------------------------
-- 9. Converting data types

-------------------------------
-- Syntax
CAST (expression AS data_type)  
CONVERT (data_type, expression, style)  

-------------------------------
-- Examples

-- CAST and convert example
SELECT	CAST([ActualCost] AS INT ) AS [Int]
		,CAST([ActualCost] AS DECIMAL(18,2) ) AS [Decimal]
		,CAST([ModifiedDate] AS DATETIME2 ) AS [Date]
		,CAST([ActualCost] AS VARCHAR(20) ) AS [Varchar]
		,CAST([ActualCost] AS NCHAR(20) ) AS [Nchar]

		-- Convert example
		,CONVERT(VARCHAR(10), [ModifiedDate], 103) AS [UK_Date]
		,CONVERT(VARCHAR(10), [ModifiedDate], 101) AS [US_Date]
		,CONVERT(VARCHAR(16), [ActualCost], 1) AS [Money Format]
FROM	[Production].[TransactionHistory]

-------------------------
-- Concatination problem 
SELECT	'This is the product ID ' + [ProductID],
		'This is the product ID ' + CAST([ProductID] AS VARCHAR(10)) AS [Concat],
		CONCAT('This is the product ID ', [ProductID]) AS [Concat Function]
FROM	[Production].[TransactionHistory]

-------------------------
-- Calculation problem 
SELECT	[ProductID] / [ReferenceOrderLineID] AS [Integer Division]
		,CAST(
				CAST([ProductID] AS DECIMAL(18,2)) / CAST([ReferenceOrderLineID] AS DECIMAL(18,2)) AS DECIMAL(18,2)
		)

FROM	[Production].[TransactionHistory]
WHERE	[ReferenceOrderLineID] <> 0

-------------------------
-- Function parameter problem
SELECT	--DATEADD(MONTH, 1, '10/30/2030'),
		CONVERT(	VARCHAR(30),
					CONVERT(DATETIME, '10/30/2030', 101),
					103
		),
		DATEADD(MONTH, 
				1, 
				CONVERT(VARCHAR(30),CONVERT(DATETIME, '10/30/2030', 101),103)
		)
FROM	[Production].[TransactionHistory]
WHERE	[ReferenceOrderLineID] <> 0



--------------------------------------------------------------
-- 10. Decision logic

-------------------------------
-- Syntax
CASE  
     WHEN Boolean_expression THEN result_expression [ ...n ]   
     ELSE else_result_expression
END
IIF(boolean_expression, true_value, false_value )
CHOOSE (index, val_1, val_2 , val_n)  


-------------------------------
-- Examples
SELECT  [OrderDate],
		[SalesOrderID],	
		[TotalDue],
		CASE	
				WHEN TotalDue < 1000 THEN 'Bronze product'
				WHEN TotalDue >= 1000 AND TotalDue < 2000  THEN 'Silver product'
				ELSE 'Gold'
		END AS [Product Type],
		IIF(SalesOrderId < 43665, 'Old product', 'New product') AS [Product age],
		CHOOSE(	MONTH(OrderDate),
				'Winter', 'Winter',
				'Spring','Spring','Spring',
				'Summmer','Summmer','Summmer',
				'Autumn','Autumn','Autumn',
				'Winter'
		) AS [Season]
FROM	[Sales].[SalesOrderHeader]