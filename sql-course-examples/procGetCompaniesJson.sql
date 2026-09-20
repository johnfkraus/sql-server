CREATE OR ALTER PROCEDURE dbo.GetCompaniesPagedJson
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

    -- 3. Apply Selective Filtering
    FilteredCompanies AS (
        SELECT 
            c.company_id,
            c.company_name,
            c.headquarters
        FROM dbo.companies c
        WHERE 
            -- Sector Filter
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
            -- Country Filter
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

    -- 4. Dynamic Pagination & Total Count Calculation
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
            company_id ASC
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
    ),

    -- 5. Construct Structured Rows with Embedded Sub-JSON Arrays
    CompanyRows AS (
        SELECT 
            pc.company_id,
            pc.company_name,
            pc.headquarters,
            pc.TotalRecords,
            
            -- Nested JSON Array for Sectors
            ISNULL(
                (
                    SELECT s.sector_id, s.sector_name
                    FROM dbo.companies_sectors cs
                    INNER JOIN dbo.sectors s ON cs.sector_id = s.sector_id
                    WHERE cs.company_id = pc.company_id
                    FOR JSON PATH
                ), 
                '[]'
            ) AS sectors_json,

            -- Nested JSON Array for Countries
            ISNULL(
                (
                    SELECT cnt.country_id, cnt.country_name, cnt.country_code
                    FROM dbo.companies_countries cc
                    INNER JOIN dbo.countries cnt ON cc.country_id = cnt.country_id
                    WHERE cc.company_id = pc.company_id
                    FOR JSON PATH
                ), 
                '[]'
            ) AS countries_json
        FROM PagedCompanies pc
    )

    -- 6. Combine Metadata and Rows into a Single Root JSON Object
    SELECT 
        @PageNumber AS [pagination.currentPage],
        @PageSize AS [pagination.pageSize],
        ISNULL((SELECT TOP 1 TotalRecords FROM CompanyRows), 0) AS [pagination.totalRecords],
        CEILING(CAST(ISNULL((SELECT TOP 1 TotalRecords FROM CompanyRows), 0) AS FLOAT) / @PageSize) AS [pagination.totalPages],
        
        -- Serialize Companies Array with Clean JSON Parsing
        (
            SELECT 
                company_id,
                company_name,
                headquarters,
                JSON_QUERY(sectors_json) AS sectors,
                JSON_QUERY(countries_json) AS countries
            FROM CompanyRows
            ORDER BY 
                CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('company_name', 'both') THEN company_name END ASC,
                CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('company_name', 'both') THEN company_name END DESC,
                CASE WHEN @SortDirection = 'ASC'  AND @SortColumn IN ('headquarters', 'both') THEN headquarters END ASC,
                CASE WHEN @SortDirection = 'DESC' AND @SortColumn IN ('headquarters', 'both') THEN headquarters END DESC,
                company_id ASC
            FOR JSON PATH
        ) AS [data]
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO


EXEC dbo.GetCompaniesPagedJson
    @PageNumber = 1,
    @PageSize = 2,
    @SortColumn = 'company_name',
    @SortDirection = 'ASC',
    @SectorIds = '1,3',
    @CountryIds = '1,2';