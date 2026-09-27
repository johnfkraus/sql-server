CREATE TABLE kphistory (
    companyid INT,
    fyear INT,
    foid INT
)

CREATE TABLE dbo.kpactive (
    companyid INT,
    fyear INT,
    foid INT
)


BULK INSERT dbo.kpactive
FROM '/var/opt/mssql/data/kpactive.txt'
WITH (
    ROWTERMINATOR = '\n',
    FIRSTROW=2
);

BULK INSERT dbo.kphistory
FROM '/var/opt/mssql/data/kphistory.txt'
WITH (
    ROWTERMINATOR = '\n',
    FIRSTROW=2
);

WITH (
    FORMAT = 'TXT',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW=2
);


WITH RankedData AS (
    SELECT 
        companyid,
        foid,
        fyear,
        -- Subtract row number from fyear to identify contiguous blocks
        fyear - ROW_NUMBER() OVER (
            PARTITION BY companyid, foid 
            ORDER BY fyear
        ) AS grp_offset
    FROM dbo.kphistory
)
SELECT 
    companyid,
    foid,
    fyear,
    -- Generate a clean group ID per continuous block
    DENSE_RANK() OVER (
        PARTITION BY companyid, foid 
        ORDER BY grp_offset
    ) AS group_id
FROM RankedData
ORDER BY companyid, foid, fyear;


WITH GroupedData AS (
    SELECT 
        companyid,
        foid,
        fyear,
        -- Group identifier per (companyid, foid) combination
        fyear - ROW_NUMBER() OVER (
            PARTITION BY companyid, foid 
            ORDER BY fyear
        ) AS grp_offset
    FROM dbo.kphistory
)
SELECT 
    companyid,
    foid,
    fyear,
    -- Generates a unique integer ID across the entire table
    DENSE_RANK() OVER (
        ORDER BY companyid, foid, grp_offset
    ) AS GroupID
FROM GroupedData
ORDER BY GroupID, fyear;


ALTER TABLE dbo.kphistory
ADD deleted BIT NOT NULL DEFAULT 0;


ALTER TABLE dbo.kphistory
ADD active BIT NOT NULL DEFAULT 0;


UPDATE h
SET h.active = 1
FROM dbo.kphistory h 
INNER JOIN 
dbo.kpactive a ON a.companyid = h.companyid 
AND a.foid = h.foid
AND a.fyear = h.fyear

SELECT * FROM dbo.kphistory
WHERE active = 1


-- update preview
WITH GroupedData AS (
    SELECT 
        *,
        fyear - ROW_NUMBER() OVER (
            PARTITION BY companyid, foid 
            ORDER BY fyear
        ) AS grp_offset
    FROM dbo.kphistory
),
RankedInGroup AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY companyid, foid, grp_offset 
            ORDER BY fyear DESC
        ) AS rn
    FROM GroupedData
)
SELECT companyid, foid, fyear, active, deleted
FROM RankedInGroup
WHERE rn = 1 
  AND active = 0;




WITH GroupedData AS (
    SELECT 
        companyid,
        foid,
        fyear,
        active,
        deleted,
        -- Identify continuous gaps and islands
        fyear - ROW_NUMBER() OVER (
            PARTITION BY companyid, foid 
            ORDER BY fyear
        ) AS grp_offset
    FROM dbo.kphistory
),
RankedInGroup AS (
    SELECT 
        companyid,
        foid,
        fyear,
        active,
        deleted,
        -- Identify the row with the maximum fyear in each group
        ROW_NUMBER() OVER (
            PARTITION BY companyid, foid, grp_offset 
            ORDER BY fyear DESC
        ) AS rn
    FROM GroupedData
)
UPDATE RankedInGroup
SET deleted = 1
WHERE rn = 1           -- Row with maximum fyear in the group
  AND active = 0;      -- Condition: active value is 0


-- how many groups have only one row?
WITH GroupedData AS (
    SELECT 
        companyid,
        foid,
        fyear,
        fyear - ROW_NUMBER() OVER (
            PARTITION BY companyid, foid 
            ORDER BY fyear
        ) AS grp_offset
    FROM dbo.kphistory
)
SELECT 
    DENSE_RANK() OVER (ORDER BY companyid, foid, grp_offset) AS GroupID,
    companyid,
    foid,
    MAX(fyear) AS fyear,
    COUNT(*) AS total_rows
FROM GroupedData
GROUP BY companyid, foid, grp_offset
HAVING COUNT(*) = 1
ORDER BY GroupID;


WITH GroupedData AS (
    SELECT 
        companyid,
        foid,
        fyear,
        -- Group identifier per (companyid, foid) continuous sequence
        fyear - ROW_NUMBER() OVER (
            PARTITION BY companyid, foid 
            ORDER BY fyear
        ) AS grp_offset
    FROM dbo.kphistory
),
GroupCounts AS (
    SELECT 
        companyid,
        foid,
        grp_offset,
        COUNT(*) AS group_size,
        DENSE_RANK() OVER (ORDER BY companyid, foid, grp_offset) AS GroupID
    FROM GroupedData
    GROUP BY companyid, foid, grp_offset
    HAVING COUNT(*) = 1
)
SELECT 
    g.companyid,
    g.foid,
    g.fyear,
    gc.GroupID
FROM GroupedData g
JOIN GroupCounts gc 
    ON g.companyid = gc.companyid 
   AND g.grp_offset = gc.grp_offset
ORDER BY gc.GroupID;