USE explore_psp
GO

-- 1. Create the Company table
IF OBJECT_ID('dbo.CompanyTest', 'U') IS NOT NULL 
    DROP TABLE dbo.CompanyTest;
GO

CREATE TABLE dbo.CompanyTest
(
    CompanyID      INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName    NVARCHAR(100) NOT NULL,
    AORFieldOffice INT NOT NULL,
    sectorsjson    NVARCHAR(MAX) NOT NULL
);
GO

-- 2. Insert sample records
INSERT INTO dbo.CompanyTest (CompanyName, AORFieldOffice, sectorsjson)
VALUES 
    ('Acme Technologies',   10, '[2, 5]'),
    ('Beta Logistics',      12, '[5, 8]'),
    ('Gamma Energy',        10, '[2, 8, 11]'),
    ('Delta Healthcare',    15, '[1, 3]'),
    ('Epsilon Financial',   12, '[2]'),
    ('Zeta Retail',         10, '[5]'),
    ('Eta Defense',         18, '[8, 11, 14]');
GO

-- 3. Verify inserted data
SELECT * FROM dbo.CompanyTest;
GO


CREATE OR ALTER FUNCTION dbo.fn_GetCompaniesJSON
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