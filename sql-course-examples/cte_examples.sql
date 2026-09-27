WITH AvgOrders(AvgOrders, Subcategory, ProductSubcategoryID) AS (
    SELECT AVG(s.OrderQty) AS AvgOrders
        ,ps.Name AS Subcategory
        ,ps.ProductSubcategoryID
    FROM [Sales].[SalesOrderDetail] s INNER JOIN
        [Production].[Product] p ON s.ProductID = p.ProductID
        INNER JOIN 
        [Production].[ProductSubcategory] ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    GROUP BY ps.Name, ps.ProductSubcategoryID        
)

SELECT p.Name AS ProductName 
    ,ps.Name AS Subcategory
    ,s.OrderQty 
    ,ao.AvgOrders
    FROM [Sales].[SalesOrderDetail] s INNER JOIN
        [Production].[Product] p ON s.ProductID = p.ProductID
        INNER JOIN 
        [Production].[ProductSubcategory] ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
        INNER JOIN 
        AvgOrders ao ON ps.ProductSubcategoryID = ao.ProductSubcategoryID

