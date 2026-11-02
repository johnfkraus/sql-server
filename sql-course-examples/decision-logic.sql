USE AdventureWorks2019
GO

SELECT
    [OrderDate]
    ,[SalesOrderID]
    ,[TotalDue]
    ,CASE
        WHEN TotalDue < 1000 THEN 'Bronze product'
        WHEN TotalDue >= 1000 AND TotalDue < 2000 THEN 'Silver product'
        ELSE 'Gold product'
    END AS [Product type]
    ,IIF(SalesOrderId < 43665, 'Old Product', 'New Product') AS [Product age]
    ,MONTH(OrderDate)
    ,CHOOSE(
        MONTH([OrderDate]),
        'Winter', 'Winter',
        'Spring', 'Spring', 'Spring',
        'Summer','Summer','Summer',
        'Autumn', 'Autumn', 'Autumn',
        'Winter'
    )
FROM [Sales].[SalesOrderHeader]