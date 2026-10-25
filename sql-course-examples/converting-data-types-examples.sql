
https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver17

https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver17#date-and-time-styles

-- CAST (expression AS data_type )
-- CONVERT(data_type, expression, format/style)


-- Examples
SELECT ActualCost
FROM [Production].[TransactionHistory]

-- CAST
SELECT 
    CAST(ActualCost AS INT) AS [int]
    ,CAST(ActualCost AS DECIMAL(18,2)) AS [DEC]
    ,CAST(ModifiedDate AS DATETIME2) AS [datetime2]
    ,CAST(ActualCost AS VARCHAR(20)) AS [varchar20]
    ,CAST(ActualCost AS NCHAR(20)) AS [NCHAR20]
    ,CONVERT(VARCHAR(10), ModifiedDate, 103) AS [UK DATE]
    ,CONVERT(VARCHAR(10), ModifiedDate, 101) AS [US DATE]
    ,CONVERT(VARCHAR(10), ActualCost, 1) AS [comma separated]        
FROM [Production].[TransactionHistory]



-- Concatenation
-- SELECT 'This is the product id' + ProductID
SELECT 
    'This is the product id ' + CAST(ProductID AS VARCHAR(10))
    ,'This is the product id ' + CAST(ProductID AS NCHAR(15))
FROM [Production].[TransactionHistory]


-- Calculation
-- Integer division truncates remainder
SELECT 
    ProductID / ReferenceOrderLineID
    ,ProductID
    ,ReferenceOrderLineID
    ,CAST(ProductID AS DECIMAL(18,2)) / CAST(ReferenceOrderLineID AS DECIMAL(18,2)) AS dec1
    ,CAST
        (
            CAST(ProductID AS DECIMAL(18,2)) / CAST(ReferenceOrderLineID AS DECIMAL(18,2)) AS DECIMAL(18,2)) AS DEC2
FROM [Production].[TransactionHistory]
WHERE ReferenceOrderLineID <> 0


-- Functions
SELECT 
    -- DATEADD(MONTH, 1, '30/10/2030')
    CONVERT(DATETIME, '30/10/2030', 103) AS adate
    ,DATEADD(MONTH, 1, CONVERT(DATETIME, '30/10/2030', 103)) AS [date+1MONTH]

FROM [Production].[TransactionHistory]



-- 
SELECT *
FROM [Production].[TransactionHistory]