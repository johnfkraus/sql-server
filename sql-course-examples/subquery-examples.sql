

SELECT [BusinessEntityID]
      ,[PersonID]
      ,[ContactTypeID]
      ,[rowguid]
      ,[ModifiedDate]
  FROM [AdventureWorks2019].[Person].[BusinessEntityContact]
  WHERE ContactTypeID IN (
    SELECT ContactTypeID FROM Person.ContactType WHERE Name LIKE 'A%'
  )
  
--  SELECT * FROM Person.ContactType

-- count the work orders but only where they are related to the product
-- not the best way to join tables
SELECT ProductId
    ,Name
    ,(
        SELECT COUNT(*)
        FROM Production.WorkOrder wo
        WHERE wo.ProductID = p.ProductID
    ) AS WorkOrderCount

FROM Production.Product p

-- select from a subquery as if it were a table

SELECT * 
FROM (
    SELECT 
        LocationID,
        Name,
        CostRate,
        Availability,
        ModifiedDate
    FROM Production.Location
) t

-- FIND THE Aggregate of an aggregate

SELECT MAX(AverageDue) AS HighestAverageDue
FROM (
    SELECT TerritoryID
        ,AVG(TotalDue) AS AverageDue
    FROM 
        Sales.SalesOrderHeader
    GROUP BY TerritoryID
) t
