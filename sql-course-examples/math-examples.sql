
-- SELECT 
--     EXP(1) AS [exp 1]

SELECT  [OrderQty]
        ,[UnitPrice]
        ,[LineTotal]
        ,ABS(-20) AS ABS
        ,CEILING(UnitPrice) AS CEILING
        ,FLOOR(UnitPrice) AS FLOOR
        ,EXP(1) AS EXP
        ,POWER(10, 2) AS POWER
        ,POWER(EXP(1),1) AS [POWER(EXP)]
        ,LOG(100,10) AS [10 to what power = 100?]
        ,LOG10(100) AS [log10(100)]
        ,LOG(2.718281828459045, EXP(1)) AS LN
        ,RAND() AS [Rand 0-1 no seed]
        ,RAND(2) AS [Rand 0-1 w/seed]
        ,RAND(LineTotal) AS [Rand 0-1 w/varying seed]
        ,ROUND(UnitPrice, 2) AS Round
        ,SIGN(-156) AS SIGN
        ,SQRT(2) AS SQRT
FROM [Sales].[SalesOrderDetail]


SELECT 
    MIN(LineTotal) AS MinLineTotal
    ,MIN(RAND(LineTotal)) AS [MIN Rand LineTotal]
    ,RAND(MIN(LineTotal)) AS [Rand 0-1 MIN LineTotal]
    ,MAX(LineTotal) AS MaxLineTotal
    ,MAX(RAND(LineTotal)) AS [MAX Rand 0-1 w/varying seed]
    ,RAND(MAX(LineTotal)) AS [RAND MAX LineTotal]
FROM [Sales].[SalesOrderDetail]


[SalesOrderID]  
        ,[OrderQty]
        ,[UnitPrice]
        ,[LineTotal]
        ,ABS(-20) AS ABS
        ,CEILING(UnitPrice) AS CEILING
        ,FLOOR(UnitPrice) AS FLOOR
        ,EXP(1) AS EXP
        ,POWER(10, 2) AS POWER
        ,POWER(EXP(1),1) AS [POWER(EXP)]
        ,LOG(100,10) AS [10 to what power = 100?]
        ,LOG10(100) AS [log10(100)]
        ,LOG(2.718281828459045, EXP(1)) AS LN
        ,RAND() AS [Rand 0-1 no seed]
        ,RAND(2) AS [Rand 0-1 w/seed]
        ,RAND(LineTotal) AS [Rand 0-1 w/varying seed]
FROM [Sales].[SalesOrderDetail]


