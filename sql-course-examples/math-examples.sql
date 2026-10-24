
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
FROM [Sales].[SalesOrderDetail]

