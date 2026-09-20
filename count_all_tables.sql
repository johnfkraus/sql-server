-- count all row in all tables

USE AdventureWorks2019
GO

SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRowCount
FROM sys.tables t
JOIN sys.schemas s 
    ON t.schema_id = s.schema_id
JOIN sys.partitions p 
    ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1) -- 0 = Heap, 1 = Clustered Index
GROUP BY s.name, t.name
ORDER BY TotalRowCount DESC;