
SELECT 
    TerritoryID
    ,SalesPersonID
    ,SUM(TotalDue) AS Sum
    ,MAX(TotalDue) AS Max
    ,MIN(TotalDue) AS Min
    ,AVG(TotalDue) AS Avg
    ,COUNT(*) AS Count
  FROM [Sales].[SalesOrderHeader]
  WHERE ShipDate >= '01/01/2013' AND ShipDate < '01/01/2014' AND
  SalesPersonID IS NOT NULL
GROUP BY TerritoryID, SalesPersonID
HAVING COUNT(*) > 10 AND AVG(TotalDue) > 20000
ORDER BY TerritoryID, SalesPersonID
GO
