USE explore_psp
GO

select @@version
-- Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)  	Jul  7 2026 14:37:25  	Copyright (C) 2022 Microsoft Corporation 	Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS) <X64>

CREATE TABLE CompanyImproved (
    companyid INT PRIMARY KEY,
    companyname NVARCHAR(50),
    aorfieldoffice INT NULL,
    dsacfieldoffice INT NULL,
    kpfieldoffices NVARCHAR(MAX) CHECK (ISJSON(kpfieldoffices) = 1),
    annualrevenue INT NULL,
    sectors NVARCHAR(70) NULL
);





-- Insert a JSON array
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(1,'A Co.',51,51,'[51,56]',123,'(1)(5)(8)(12)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(3,'B Co.',52,52,'[52]',NULL,'(3)(7)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(5,'C Co.',53,53,'[53,51]',2221,'(2)(4)(6)(9)(11)(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(7,'D Co.',54,55,'[55]',NULL,'(10)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(9,'E Co.',55,55,'[55]',NULL,'(5)(13)(14)(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(11,'F, Inc.',56,56,'[56,55]',331,'(1)(2)(3)(4)(5)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(13,'G LLC',57,NULL,'[]',NULL,'(8)(11)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(15,'H Co.',51,NULL,'[51]',NULL,'(6)(7)(9)(10)(12)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(17,'International Co.',52,NULL,'[52]',NULL,'(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(19,'Junk Co.',53,NULL,'[51]',NULL,'(2)(6)(8)(10)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(21,'K Co.',54,NULL,'[]',854,'(4)(5)(7)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(23,'Lousy Co.',55,NULL,'[]',NULL,'(1)(9)(11)(13)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(25,'Monkey Co.',56,NULL,'[]',44,'(3)(12)(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(27,'NoGoodCo',56,NULL,'[]',NULL,'(7)(8)(9)(10)(11)(12)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(29,'OPEN Co',51,NULL,'[]',199,'(2)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(31,'Platypus Co.',51,NULL,'[]',NULL,'(1)(3)(5)(6)(13)')



SELECT * 
  FROM [explore_psp].[dbo].[CompanyImproved]

-- OPENJSON: Parse the JSON list into a table format (rows):
SELECT * -- e.companyname, kp.value AS kpfieldoffices
FROM CompanyImproved e
CROSS APPLY OPENJSON(e.kpfieldoffices) AS kp;

-- JSON_CONTAINS / Array Checks (SQL Server 2016+): Filter rows where a list contains a specific value:

SELECT *  
FROM CompanyImproved c
WHERE 56 IN (SELECT value FROM OPENJSON(kpfieldoffices));


SELECT *  
FROM CompanyImproved c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices));


-- field office 51
SELECT *  
FROM CompanyImproved c
WHERE aorfieldoffice = 51 --  IN (SELECT value FROM OPENJSON(kpfieldoffices));
UNION
SELECT *  
FROM CompanyImproved c
WHERE dsacfieldoffice = 51 
UNION
SELECT *  
FROM CompanyImproved c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices))




ALTER TABLE CompanyImproved
ADD sectorsjson NVARCHAR(MAX) NULL,
CONSTRAINT CK_table_name_sectorsjson CHECK (sectorsjson IS NULL OR ISJSON(sectorsjson) = 1);

DECLARE @input VARCHAR(100) = '(1)(2)(4)(6)(7)(12)(-11)';

SELECT 
    '[' + STRING_AGG(REPLACE(value, '(', ''), ',') WITHIN GROUP (ORDER BY ordinal) + ']' AS JsonArray
FROM STRING_SPLIT(@input, ')', 1)
WHERE value LIKE '(%';


-- Example for updating existing rows in a table:
UPDATE CompanyImproved
SET sectorsjson = (
SELECT 
    '[' + STRING_AGG(REPLACE(value, '(', ''), ',') WITHIN GROUP (ORDER BY ordinal) + ']' AS JsonArray
    FROM STRING_SPLIT(sectors, ')', 1)
    WHERE value LIKE '(%'
    -- SELECT JSON_ARRAYAGG(value)
    -- FROM STRING_SPLIT(concatenated_string_column, ',')
)
WHERE sectors IS NOT NULL;


-- field office 51 and sectors = 2,5
DECLARE @fieldofficeid INT = 51;
-- DECLARE @sectors NVARCHAR(MAX) = '[2]'
DECLARE @TargetSectors NVARCHAR(MAX) = '[2,5]';

SELECT *  
FROM CompanyImproved c
WHERE aorfieldoffice = @fieldofficeid --  IN (SELECT value FROM OPENJSON(kpfieldoffices));
UNION
SELECT *  
FROM CompanyImproved c
WHERE dsacfieldoffice = @fieldofficeid
UNION
SELECT *  
FROM CompanyImproved c
WHERE @fieldofficeid IN (SELECT value FROM OPENJSON(kpfieldoffices))
-- DECLARE @TargetSectors NVARCHAR(MAX) = '[2,5]';
UNION
SELECT *
FROM CompanyImproved c
WHERE EXISTS (
    SELECT 1
    FROM OPENJSON(c.sectorsjson) WITH (sector_id INT '$') AS c_sec
    INNER JOIN OPENJSON(@TargetSectors) WITH (sector_id INT '$') AS t_sec
        ON c_sec.sector_id = t_sec.sector_id
);


-- DECLARE @TargetSectors NVARCHAR(MAX) = '[2,5]';

SELECT c.*
FROM CompanyImproved c
WHERE EXISTS (
    SELECT 1
    FROM OPENJSON(c.sectorsjson) WITH (sector_id INT '$') AS c_sec
    INNER JOIN OPENJSON(@TargetSectors) WITH (sector_id INT '$') AS t_sec
        ON c_sec.sector_id = t_sec.sector_id
);
GO

-- any field office 51 and sectors = 2,5
DECLARE @anyfieldofficeid NVARCHAR(MAX) = '[51,53]';
DECLARE @kpfieldofficeid NVARCHAR(MAX) = @anyfieldofficeid;
DECLARE @dsacfieldofficeid NVARCHAR(MAX) = @anyfieldofficeid; -- '[51,53]';
DECLARE @TargetSectors NVARCHAR(MAX) = '[2,5]';
DECLARE @TargetAORs NVARCHAR(MAX) = @anyfieldofficeid;

SELECT c.*
FROM CompanyImproved c
WHERE c.aorfieldoffice IN (
    SELECT CAST(value AS INT)
    FROM OPENJSON(@TargetAORs)
)
UNION
SELECT c.*
FROM CompanyImproved c
WHERE c.dsacfieldoffice IN (
    SELECT CAST(value AS INT)
    FROM OPENJSON(@dsacfieldofficeid)
)
UNION
SELECT *  
FROM CompanyImproved c
WHERE @kpfieldofficeid IN (SELECT value FROM OPENJSON(kpfieldoffices))
UNION
SELECT *
FROM CompanyImproved c
WHERE EXISTS (
    SELECT 1
    FROM OPENJSON(c.sectorsjson) WITH (sector_id INT '$') AS c_sec
    INNER JOIN OPENJSON(@TargetSectors) WITH (sector_id INT '$') AS t_sec
        ON c_sec.sector_id = t_sec.sector_id
);

/*
USING MS sql server 2022, I have a Company table with a column "sectorsjson" of type NVARCHAR(MAX). The sectorsjson column contains a json array of integers. I want to be able to select rows from the table where the json array in sectorsjson contains integer values specified in an array containing in a string like '[2,5]'. 

USING MS sql server 2022, I have a Company table with a column "aorfieldoffice" of type INT. The  I want to be able to select rows from the table where the aorfieldoffice matches any of the integer values specified in an array containing in a string like '[2,5]'. 

*/

GO

DECLARE @TargetAORs NVARCHAR(MAX) = '[51,53]';

SELECT c.*
FROM CompanyImproved c
WHERE c.aorfieldoffice IN (
    SELECT CAST(value AS INT)
    FROM OPENJSON(@TargetAORs)
);
GO

CREATE OR ALTER FUNCTION dbo.fn_GetCompanies
(
    @anyfieldofficeids NVARCHAR(MAX) = NULL, --  '[51,53]';
    -- @TargetAORs NVARCHAR(MAX) = NULL,
    @kpfieldofficeids NVARCHAR(MAX) = NULL, -- @anyfieldofficeid;
    @dsacfieldofficeids NVARCHAR(MAX) = NULL, -- @anyfieldofficeid; -- '[51,53]';
    @TargetSectors NVARCHAR(MAX) = NULL --  '[2,5]';
)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM CompanyImproved c
    WHERE (@TargetAORs is NULL OR c.aorfieldoffice IN (
        SELECT CAST(value AS INT)
        FROM OPENJSON(@TargetAORs)
    )
      AND (@AORFieldOffice IS NULL OR AORFieldOffice = @AORFieldOffice)
      AND (@MinEmployees IS NULL OR EmployeeCount >= @MinEmployees)
      AND (@MaxEmployees IS NULL OR EmployeeCount <= @MaxEmployees)
);
GO

CREATE OR ALTER FUNCTION dbo.fn_SearchCompanies
(
    @SectorsJSON NVARCHAR(MAX) = NULL,
    @AORsJSON    NVARCHAR(MAX) = NULL,
    @anyfieldofficeids NVARCHAR(MAX) = NULL, --  '[51,53]';
    -- @TargetAORs NVARCHAR(MAX) = NULL,
    @kpfieldofficeids NVARCHAR(MAX) = NULL, -- @anyfieldofficeid;
    @dsacfieldofficeids NVARCHAR(MAX) = NULL, -- @anyfieldofficeid; -- '[51,53]';
    @TargetSectors NVARCHAR(MAX) = NULL --  '[2,5]';
)
RETURNS TABLE
AS
RETURN
(
    SELECT c.*
    FROM dbo.CompanyImproved c
    WHERE 
        -- Condition 2: AOR Filter (Matching against an INT column 'aorfieldoffice')
        (
            @AORsJSON IS NULL 
            OR @AORsJSON = '[]'
            OR ISJSON(@AORsJSON) = 0
            OR EXISTS (
                SELECT 1 
                FROM OPENJSON(@AORsJSON) WITH (aor_id INT '$') AS p_aor
                WHERE p_aor.aor_id = c.aorfieldoffice
            )
        )
        AND
        -- Condition 1: Sector Filter (Matching against a JSON array column 'sectorsjson')
        (
            @SectorsJSON IS NULL 
            OR @SectorsJSON = '[]'
            OR ISJSON(@SectorsJSON) = 0
            OR EXISTS (
                SELECT 1 
                FROM OPENJSON(c.sectorsjson) WITH (sector_id INT '$') AS c_sec
                INNER JOIN OPENJSON(@SectorsJSON) WITH (sector_id INT '$') AS p_sec
                    ON c_sec.sector_id = p_sec.sector_id
            )
        )

);
GO

SELECT * 
FROM dbo.fn_SearchCompanies(
    @SectorsJSON = '[2,5]', 
    @AORsJSON = '[10,12]'
);