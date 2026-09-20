
SELECT 
    company_id AS [id],
    company_name AS [name],
    headquarters AS [location.city] -- Creates a nested object: "location": { "city": "..." }
FROM dbo.companies
FOR JSON PATH;

-- companies with sectors, countries as JSON

SELECT 
    c.company_id,
    c.company_name,
    c.headquarters,

    -- Nested JSON Array of Sectors
    JSON_QUERY(
        ISNULL(
            (
                SELECT 
                    s.sector_id,
                    s.sector_name
                FROM dbo.companies_sectors cs
                INNER JOIN dbo.sectors s ON cs.sector_id = s.sector_id
                WHERE cs.company_id = c.company_id
                FOR JSON PATH
            ), 
            '[]'
        )
    ) AS sectors,

    -- Nested JSON Array of Countries
    JSON_QUERY(
        ISNULL(
            (
                SELECT 
                    cnt.country_id,
                    cnt.country_name,
                    cnt.country_code
                FROM dbo.companies_countries cc
                INNER JOIN dbo.countries cnt ON cc.country_id = cnt.country_id
                WHERE cc.company_id = c.company_id
                FOR JSON PATH
            ), 
            '[]'
        )
    ) AS countries

FROM dbo.companies c
ORDER BY c.company_name
FOR JSON PATH;