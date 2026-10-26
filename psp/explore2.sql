USE explore_psp
GO

select @@version
-- Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)  	Jul  7 2026 14:37:25  	Copyright (C) 2022 Microsoft Corporation 	Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS) <X64>


CREATE TABLE CompanyImproved2 (
    companyid INT PRIMARY KEY,
    companyname NVARCHAR(50),
    aorfieldoffice INT NULL,
    dsacfieldoffice INT NULL,
    kpfieldoffices NVARCHAR(MAX) CHECK (ISJSON(kpfieldoffices) = 1),
    annualrevenue INT NULL,
    sectors NVARCHAR(70) NULL
);



-- Insert a JSON array
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(1,'A Co.',51,51,'[51,56]',123,'(1)(5)(8)(12)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(3,'B Co.',52,52,'[52]',NULL,'(3)(7)(14)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(5,'C Co.',53,53,'[53,51]',2221,'(2)(4)(6)(9)(11)(15)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(7,'D Co.',54,55,'[55]',NULL,'(10)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(9,'E Co.',55,55,'[55]',NULL,'(5)(13)(14)(15)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(11,'F, Inc.',56,56,'[56,55]',331,'(1)(2)(3)(4)(5)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(13,'G LLC',57,NULL,'[]',NULL,'(8)(11)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(15,'H Co.',51,NULL,'[51]',NULL,'(6)(7)(9)(10)(12)(14)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(17,'International Co.',52,NULL,'[52]',NULL,'(15)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(19,'Junk Co.',53,NULL,'[51]',NULL,'(2)(6)(8)(10)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(21,'K Co.',54,NULL,'[]',854,'(4)(5)(7)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(23,'Lousy Co.',55,NULL,'[]',NULL,'(1)(9)(11)(13)(14)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(25,'Monkey Co.',56,NULL,'[]',44,'(3)(12)(15)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(27,'NoGoodCo',56,NULL,'[]',NULL,'(7)(8)(9)(10)(11)(12)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(29,'OPEN Co',51,NULL,'[]',199,'(2)(14)')
INSERT INTO CompanyImproved2(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(31,'Platypus Co.',51,NULL,'[]',NULL,'(1)(3)(5)(6)(13)')


SELECT * 
  FROM [explore_psp].[dbo].[CompanyImproved2]

-- OPENJSON: Parse the JSON list into a table format (rows):
SELECT * -- e.companyname, kp.value AS kpfieldoffices
FROM CompanyImproved2 e
CROSS APPLY OPENJSON(e.kpfieldoffices) AS kp;

-- JSON_CONTAINS / Array Checks (SQL Server 2016+): Filter rows where a list contains a specific value:


SELECT *  
FROM CompanyImproved2 c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices));


-- field office 51
SELECT *  
FROM CompanyImproved2 c
WHERE aorfieldoffice = 51 --  IN (SELECT value FROM OPENJSON(kpfieldoffices));
UNION
SELECT *  
FROM CompanyImproved2 c
WHERE dsacfieldoffice = 51 
UNION
SELECT *  
FROM CompanyImproved2 c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices))


ALTER TABLE CompanyImproved2
ADD sectorsjson NVARCHAR(MAX) NULL,
CONSTRAINT CK_companyimproved2_sectorsjson CHECK (sectorsjson IS NULL OR ISJSON(sectorsjson) = 1);

DECLARE @input VARCHAR(100) = '(1)(2)(4)(6)(7)(12)(-11)';

SELECT 
    '[' + STRING_AGG(REPLACE(value, '(', ''), ',') WITHIN GROUP (ORDER BY ordinal) + ']' AS JsonArray
FROM STRING_SPLIT(@input, ')', 1)
WHERE value LIKE '(%';


-- Example for updating existing rows in a table:
UPDATE CompanyImproved2
SET sectorsjson = (
SELECT 
    '[' + STRING_AGG(REPLACE(value, '(', ''), ',') WITHIN GROUP (ORDER BY ordinal) + ']' AS JsonArray
    FROM STRING_SPLIT(sectors, ')', 1)
    WHERE value LIKE '(%'
    -- SELECT JSON_ARRAYAGG(value)
    -- FROM STRING_SPLIT(concatenated_string_column, ',')
)
WHERE sectors IS NOT NULL;

GO


CREATE OR ALTER FUNCTION dbo.fn_GetCompaniesImproved2JSON
(
    @SectorsJSON NVARCHAR(MAX) = NULL,
    @AORsJSON    NVARCHAR(MAX) = NULL
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX);

    -- 1. Get filtered matching companies into a local table variable
    DECLARE @FilteredCompanies TABLE (
        CompanyID INT,
        CompanyName NVARCHAR(100),
        AORFieldOffice INT,
        SectorsJSON NVARCHAR(MAX)
    );

    INSERT INTO @FilteredCompanies
    SELECT 
        c.CompanyID,
        c.CompanyName,
        c.AORFieldOffice,
        c.sectorsjson
    FROM dbo.CompanyTest c
    WHERE 
        -- Optional Sectors Filter
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
        AND
        -- Optional AOR Filter
        (
            @AORsJSON IS NULL 
            OR @AORsJSON = '[]'
            OR ISJSON(@AORsJSON) = 0
            OR EXISTS (
                SELECT 1 
                FROM OPENJSON(@AORsJSON) WITH (aor_id INT '$') AS p_aor
                WHERE p_aor.aor_id = c.AORFieldOffice
            )
        );

    -- 2. Build the combined JSON output object
    SELECT @Result = (
        SELECT 
            -- Array 1: List of matching companies
            (
                SELECT 
                    CompanyID,
                    CompanyName,
                    AORFieldOffice,
                    JSON_QUERY(SectorsJSON) AS sectors
                FROM @FilteredCompanies
                FOR JSON PATH
            ) AS companies,

            -- Array 2: Sector breakdown count for the selected companies
            (
                SELECT 
                    sec.sector_id AS sectorId,
                    COUNT(*) AS companyCount
                FROM @FilteredCompanies fc
                CROSS APPLY OPENJSON(fc.SectorsJSON) WITH (sector_id INT '$') sec
                GROUP BY sec.sector_id
                ORDER BY sec.sector_id
                FOR JSON PATH
            ) AS sectorCounts

        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    RETURN COALESCE(@Result, '{"companies":[],"sectorCounts":[]}');
END;
GO

SELECT * FROM dbo.CompanyTest;
GO


SELECT dbo.fn_GetCompaniesJSON('[2,5]', '[10,12]') AS ResultJSON;