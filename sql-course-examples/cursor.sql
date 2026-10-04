USE SQL_Course
GO

CREATE VIEW Covid.Delete1
AS 
	SELECT 1 AS Col1
GO

CREATE VIEW Covid.Delete2
AS 
	SELECT 1 AS Col1

GO

CREATE VIEW Covid.Delete3
AS 
	SELECT 1 AS Col1

GO

SELECT 
	OBJECT_SCHEMA_NAME(v.object_id) AS Schema_Name,
	v.name
FROM sys.views AS v
WHERE v.name LIKE '%delete%'

DECLARE @Schema_Name VARCHAR(10), @Name VARCHAR(50), @DynamicSQL VARCHAR(500)

-- declare cursor and populate with a set of view names:
DECLARE My_Cursor CURSOR FOR
SELECT 
	OBJECT_SCHEMA_NAME(v.object_id) AS Schema_Name,
	v.name
FROM sys.views AS v
WHERE v.name LIKE '%delete%'

OPEN My_Cursor

FETCH NEXT FROM My_Cursor
