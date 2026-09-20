SELECT
    (SELECT COUNT(*) FROM [dbo].[last_year]) AS CountLastYear,
    (SELECT COUNT(*) FROM [dbo].[this_year]) AS CountThisYear;

-- Rows in TableA that are not in TableB (missing or different)
SELECT * FROM [dbo].[last_year]
EXCEPT
SELECT * FROM [dbo].[this_year];

-- Rows in TableB that are not in TableA
SELECT * FROM [dbo].[this_year]
EXCEPT
SELECT * FROM [dbo].[last_year];