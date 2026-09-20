-- Create base tables
CREATE TABLE dbo.companies (
    company_id INT IDENTITY(1,1) PRIMARY KEY,
    company_name NVARCHAR(100) NOT NULL,
    headquarters NVARCHAR(100) NOT NULL
);

CREATE TABLE dbo.countries (
    country_id INT PRIMARY KEY,
    country_name NVARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL
);

CREATE TABLE dbo.companies_countries (
    company_id INT NOT NULL,
    country_id INT NOT NULL,
    PRIMARY KEY (company_id, country_id),
    FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id),
    FOREIGN KEY (country_id) REFERENCES dbo.countries(country_id)
);

CREATE TABLE dbo.sectors (
    sector_id INT PRIMARY KEY,
    sector_name NVARCHAR(100) NOT NULL
);

CREATE TABLE dbo.companies_sectors (
    company_id INT NOT NULL,
    sector_id INT NOT NULL,
    PRIMARY KEY (company_id, sector_id),
    FOREIGN KEY (company_id) REFERENCES dbo.companies(company_id),
    FOREIGN KEY (sector_id) REFERENCES dbo.sectors(sector_id)
);

-- Seed Sectors & Countries
INSERT INTO dbo.sectors (sector_id, sector_name) VALUES 
(1, 'Technology'), (2, 'Healthcare'), (3, 'Finance'), (4, 'Energy');

INSERT INTO dbo.countries (country_id, country_name, country_code) VALUES 
(1, 'United States', 'US'), (2, 'France', 'FR'), (3, 'Germany', 'DE');

-- Seed Sample Companies
INSERT INTO dbo.companies (company_name, headquarters) VALUES
('Acme Tech', 'San Francisco'),
('BioHealth Labs', 'Paris'),
('Capital Finance', 'Frankfurt'),
('Delta Energy', 'Houston'),
('Echo Software', 'Seattle');

-- Map Companies to Sectors
INSERT INTO dbo.companies_sectors (company_id, sector_id) VALUES
(1, 1), -- Acme Tech -> Tech
(2, 2), -- BioHealth -> Healthcare
(3, 3), -- Capital -> Finance
(4, 4), -- Delta -> Energy
(5, 1); -- Echo -> Tech

-- Map Companies to Countries
INSERT INTO dbo.companies_countries (company_id, country_id) VALUES
(1, 1), (1, 2), (2, 2), (3, 3), (4, 1), (5, 1);



DECLARE @PageNumber INT = 1;
DECLARE @PageSize INT = 2;
DECLARE @SortColumn NVARCHAR(20) = 'company_name'; -- Options: 'company_name', 'headquarters'
DECLARE @SortDirection NVARCHAR(4) = 'ASC';        -- Options: 'ASC', 'DESC'
DECLARE @SectorFilter NVARCHAR(50) = '1,3';        -- Filter by Sector IDs 1 (Tech) and 3 (Finance)

WITH FilteredSectors AS (
    SELECT CAST(value AS INT) AS sector_id 
    FROM STRING_SPLIT(@SectorFilter, ',')
)
SELECT DISTINCT 
    c.company_id,
    c.company_name,
    c.headquarters
FROM dbo.companies c
INNER JOIN dbo.companies_sectors cs ON c.company_id = cs.company_id
INNER JOIN FilteredSectors fs ON cs.sector_id = fs.sector_id
ORDER BY 
    CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'company_name' THEN c.company_name END ASC,
    CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'company_name' THEN c.company_name END DESC,
    CASE WHEN @SortDirection = 'ASC' AND @SortColumn = 'headquarters' THEN c.headquarters END ASC,
    CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'headquarters' THEN c.headquarters END DESC,
    c.company_id ASC -- Tie-breaker for stable pagination
OFFSET (@PageNumber - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY;



CREATE OR ALTER PROCEDURE dbo.GetCompaniesPaged
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'company_name', -- Options: 'company_name', 'headquarters'
    @SortDirection NVARCHAR(4) = 'ASC',        -- Options: 'ASC', 'DESC'
    @SectorIds NVARCHAR(MAX) = NULL            -- Comma-separated sector IDs (e.g., '1,3,5') or NULL for all
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize inputs
    SET @PageNumber = ISNULL(@PageNumber, 1);
    SET @PageSize = ISNULL(@PageSize, 10);
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;

    -- Parse sector IDs into a CTE if provided
    WITH TargetSectors AS (
        SELECT CAST(value AS INT) AS sector_id
        FROM STRING_SPLIT(@SectorIds, ',')
        WHERE @SectorIds IS NOT NULL AND LTRIM(RTRIM(@SectorIds)) <> ''
    ),
    FilteredCompanies AS (
        SELECT DISTINCT 
            c.company_id,
            c.company_name,
            c.headquarters
        FROM dbo.companies c
        LEFT JOIN dbo.companies_sectors cs ON c.company_id = cs.company_id
        WHERE 
            -- If @SectorIds is NULL/empty, include all companies. Otherwise, match selected sectors.
            @SectorIds IS NULL 
            OR LTRIM(RTRIM(@SectorIds)) = '' 
            OR cs.sector_id IN (SELECT sector_id FROM TargetSectors)
    ),
    ResultWithCount AS (
        SELECT 
            company_id,
            company_name,
            headquarters,
            COUNT(*) OVER() AS TotalRecords
        FROM FilteredCompanies
    )
    SELECT 
        company_id,
        company_name,
        headquarters,
        TotalRecords,
        CEILING(CAST(TotalRecords AS FLOAT) / @PageSize) AS TotalPages
    FROM ResultWithCount
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn = 'company_name'  THEN company_name END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'company_name'  THEN company_name END DESC,
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn = 'headquarters'  THEN headquarters END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'headquarters'  THEN headquarters END DESC,
        company_id ASC -- Deterministic tie-breaker
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO


EXEC dbo.GetCompaniesPaged
    @PageNumber = 1,
    @PageSize = 2,
    @SortColumn = 'company_name',
    @SortDirection = 'ASC',
    @SectorIds = '1,3';


EXEC dbo.GetCompaniesPaged
    @PageNumber = 1,
    @PageSize = 3,
    @SortColumn = 'headquarters',
    @SortDirection = 'DESC',
    @SectorIds = NULL;



CREATE OR ALTER PROCEDURE dbo.GetCompaniesPaged2
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'company_name', -- Options: 'company_name', 'headquarters'
    @SortDirection NVARCHAR(4) = 'ASC',        -- Options: 'ASC', 'DESC'
    @SectorIds NVARCHAR(MAX) = NULL,           -- Comma-separated sector IDs (e.g., '1,3') or NULL
    @CountryIds NVARCHAR(MAX) = NULL           -- Comma-separated country IDs (e.g., '1,2') or NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Input sanitization
    SET @PageNumber = ISNULL(@PageNumber, 1);
    SET @PageSize = ISNULL(@PageSize, 10);
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;

    -- Parse filter lists into distinct tables
    WITH TargetSectors AS (
        SELECT CAST(value AS INT) AS sector_id
        FROM STRING_SPLIT(@SectorIds, ',')
        WHERE @SectorIds IS NOT NULL AND LTRIM(RTRIM(@SectorIds)) <> ''
    ),
    TargetCountries AS (
        SELECT CAST(value AS INT) AS country_id
        FROM STRING_SPLIT(@CountryIds, ',')
        WHERE @CountryIds IS NOT NULL AND LTRIM(RTRIM(@CountryIds)) <> ''
    ),
    FilteredCompanies AS (
        SELECT 
            c.company_id,
            c.company_name,
            c.headquarters
        FROM dbo.companies c
        WHERE 
            -- Sector Filter (Matches if company operates in ANY specified sector)
            (
                @SectorIds IS NULL 
                OR LTRIM(RTRIM(@SectorIds)) = '' 
                OR EXISTS (
                    SELECT 1 
                    FROM dbo.companies_sectors cs
                    INNER JOIN TargetSectors ts ON cs.sector_id = ts.sector_id
                    WHERE cs.company_id = c.company_id
                )
            )
            AND
            -- Country Filter (Matches if company operates in ANY specified country)
            (
                @CountryIds IS NULL 
                OR LTRIM(RTRIM(@CountryIds)) = '' 
                OR EXISTS (
                    SELECT 1 
                    FROM dbo.companies_countries cc
                    INNER JOIN TargetCountries tc ON cc.country_id = tc.country_id
                    WHERE cc.company_id = c.company_id
                )
            )
    ),
    ResultWithCount AS (
        SELECT 
            company_id,
            company_name,
            headquarters,
            COUNT(*) OVER() AS TotalRecords
        FROM FilteredCompanies
    )
    SELECT 
        company_id,
        company_name,
        headquarters,
        TotalRecords,
        CEILING(CAST(TotalRecords AS FLOAT) / @PageSize) AS TotalPages
    FROM ResultWithCount
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn = 'company_name'  THEN company_name END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'company_name'  THEN company_name END DESC,
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn = 'headquarters'  THEN headquarters END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn = 'headquarters'  THEN headquarters END DESC,
        company_id ASC -- Tie-breaker for stable pagination
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO

EXEC dbo.GetCompaniesPaged2
    @PageNumber = 1,
    @PageSize = 10,
    @SortColumn = 'company_name',
    @SortDirection = 'ASC',
    @SectorIds = '1',
    @CountryIds = '2';


EXEC dbo.GetCompaniesPaged2
    @PageNumber = 1,
    @PageSize = 5,
    @SectorIds = NULL,
    @CountryIds = '1,3'; -- US and Germany




CREATE OR ALTER PROCEDURE dbo.GetCompaniesPaged3
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @SortColumn NVARCHAR(50) = 'company_name', -- Options: 'company_name', 'headquarters', 'both'
    @SortDirection NVARCHAR(4) = 'ASC',        -- Options: 'ASC', 'DESC'
    @SectorIds NVARCHAR(MAX) = NULL,           -- Comma-separated sector IDs (e.g., '1,3') or NULL
    @CountryIds NVARCHAR(MAX) = NULL           -- Comma-separated country IDs (e.g., '1,2') or NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Input Sanitization
    SET @PageNumber = ISNULL(@PageNumber, 1);
    SET @PageSize = ISNULL(@PageSize, 10);
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;

    -- 2. Parse Delimited Filter Inputs into CTEs
    WITH TargetSectors AS (
        SELECT CAST(value AS INT) AS sector_id
        FROM STRING_SPLIT(@SectorIds, ',')
        WHERE @SectorIds IS NOT NULL AND LTRIM(RTRIM(@SectorIds)) <> ''
    ),
    TargetCountries AS (
        SELECT CAST(value AS INT) AS country_id
        FROM STRING_SPLIT(@CountryIds, ',')
        WHERE @CountryIds IS NOT NULL AND LTRIM(RTRIM(@CountryIds)) <> ''
    ),

    -- 3. Apply Selective Filtering (Sectors, Countries, Both, or Neither)
    FilteredCompanies AS (
        SELECT 
            c.company_id,
            c.company_name,
            c.headquarters
        FROM dbo.companies c
        WHERE 
            -- Sector Filter (Bypassed if NULL or empty)
            (
                @SectorIds IS NULL 
                OR LTRIM(RTRIM(@SectorIds)) = '' 
                OR EXISTS (
                    SELECT 1 
                    FROM dbo.companies_sectors cs
                    INNER JOIN TargetSectors ts ON cs.sector_id = ts.sector_id
                    WHERE cs.company_id = c.company_id
                )
            )
            AND
            -- Country Filter (Bypassed if NULL or empty)
            (
                @CountryIds IS NULL 
                OR LTRIM(RTRIM(@CountryIds)) = '' 
                OR EXISTS (
                    SELECT 1 
                    FROM dbo.companies_countries cc
                    INNER JOIN TargetCountries tc ON cc.country_id = tc.country_id
                    WHERE cc.company_id = c.company_id
                )
            )
    ),

    -- 4. Calculate Windowed Record Count & Sort Paged Core Dataset
    PagedCompanies AS (
        SELECT 
            company_id,
            company_name,
            headquarters,
            COUNT(*) OVER() AS TotalRecords
        FROM FilteredCompanies
        ORDER BY 
            -- Sort by Company Name primary
            CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('company_name', 'both') THEN company_name END ASC,
            CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('company_name', 'both') THEN company_name END DESC,
            -- Sort by Headquarters primary or secondary
            CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('headquarters', 'both') THEN headquarters END ASC,
            CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('headquarters', 'both') THEN headquarters END DESC,
            company_id ASC -- Deterministic tie-breaker
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
    )

    -- 5. Aggregate All Sectors and Countries for Paged Results
    SELECT 
        pc.company_id,
        pc.company_name,
        pc.headquarters,
        pc.TotalRecords,
        CEILING(CAST(pc.TotalRecords AS FLOAT) / @PageSize) AS TotalPages,

        -- Aggregated Sectors
        ISNULL(
            STRING_AGG(CAST(s.sector_name AS NVARCHAR(MAX)), ', ') 
            WITH GROUP (ORDER BY s.sector_name), 
            ''
        ) AS sectors_list,

        -- Aggregated Countries
        ISNULL(
            STRING_AGG(CAST(cnt.country_name AS NVARCHAR(MAX)), ', ') 
            WITH GROUP (ORDER BY cnt.country_name), 
            ''
        ) AS countries_list

    FROM PagedCompanies pc
    LEFT JOIN dbo.companies_sectors cs ON pc.company_id = cs.company_id
    LEFT JOIN dbo.sectors s ON cs.sector_id = s.sector_id
    LEFT JOIN dbo.companies_countries cc ON pc.company_id = cc.company_id
    LEFT JOIN dbo.countries cnt ON cc.country_id = cnt.country_id
    GROUP BY 
        pc.company_id,
        pc.company_name,
        pc.headquarters,
        pc.TotalRecords
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('company_name', 'both') THEN pc.company_name END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('company_name', 'both') THEN pc.company_name END DESC,
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('headquarters', 'both') THEN pc.headquarters END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('headquarters', 'both') THEN pc.headquarters END DESC,
        pc.company_id ASC;
END;
GO