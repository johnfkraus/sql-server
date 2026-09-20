CREATE OR ALTER PROCEDURE dbo.GetCompaniesPaged
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
            CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('company_name', 'both') THEN company_name END ASC,
            CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('company_name', 'both') THEN company_name END DESC,
            CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('headquarters', 'both') THEN headquarters END ASC,
            CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('headquarters', 'both') THEN headquarters END DESC,
            company_id ASC -- Deterministic tie-breaker
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
    )

    -- 5. Aggregate All Sectors and Countries using Correlated Subqueries (Avoids Cartesian Product & Syntax Conflicts)
    SELECT 
        pc.company_id,
        pc.company_name,
        pc.headquarters,
        pc.TotalRecords,
        CEILING(CAST(pc.TotalRecords AS FLOAT) / @PageSize) AS TotalPages,

        -- Aggregated Sectors
        ISNULL(
            (
                SELECT STRING_AGG(s.sector_name, ', ')
                FROM dbo.companies_sectors cs
                INNER JOIN dbo.sectors s ON cs.sector_id = s.sector_id
                WHERE cs.company_id = pc.company_id
            ), 
            ''
        ) AS sectors_list,

        -- Aggregated Countries
        ISNULL(
            (
                SELECT STRING_AGG(cnt.country_name, ', ')
                FROM dbo.companies_countries cc
                INNER JOIN dbo.countries cnt ON cc.country_id = cnt.country_id
                WHERE cc.company_id = pc.company_id
            ), 
            ''
        ) AS countries_list

    FROM PagedCompanies pc
    ORDER BY 
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('company_name', 'both') THEN pc.company_name END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('company_name', 'both') THEN pc.company_name END DESC,
        CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('headquarters', 'both') THEN pc.headquarters END ASC,
        CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('headquarters', 'both') THEN pc.headquarters END DESC,
        pc.company_id ASC;
END;
GO


EXEC dbo.GetCompaniesPaged
    @PageNumber = 1,
    @PageSize = 10,
    @SortColumn = 'both',
    @SortDirection = 'ASC',
    @SectorIds = '1,3',
    @CountryIds = '2';


EXEC dbo.GetCompaniesPaged
    @PageNumber = 1,
    @PageSize = 25,
    @SortColumn = 'headquarters',
    @SortDirection = 'DESC',
    @SectorIds = NULL,
    @CountryIds = NULL;