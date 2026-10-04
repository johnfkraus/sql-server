-- USE some_demo_database
-- GO

-- Company Table
CREATE TABLE Company (
    companyid INT CONSTRAINT PK_Company PRIMARY KEY,
    companyname VARCHAR(255) NOT NULL
);
GO

-- CompanyGroup Table
CREATE TABLE CompanyGroup (
    id INT IDENTITY(1,1) CONSTRAINT PK_CompanyGroup PRIMARY KEY,
    companyid INT NOT NULL,
    groupid INT NOT NULL,
    fieldofficeid INT NOT NULL,
    Created DATETIME2 NOT NULL CONSTRAINT DF_CompanyGroup_Created DEFAULT GETDATE(),
    CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyGroup_CreatedBy DEFAULT SYSTEM_USER,
    Modified DATETIME2 NOT NULL CONSTRAINT DF_CompanyGroup_Modified DEFAULT GETDATE(),
    ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyGroup_ModifiedBy DEFAULT SYSTEM_USER
);
GO

-- CompanyKeyPartner Table
CREATE TABLE CompanyKeyPartner (
    id INT IDENTITY(1,1) CONSTRAINT PK_CompanyKeyPartner PRIMARY KEY,
    companyid INT NOT NULL,
    fieldofficeid INT NOT NULL,
    companygroupid INT NOT NULL,
    fiscalyear INT NOT NULL,
    wtf1 INT NULL,
    wtf2 INT NULL,
    wtf3 INT NULL,
    Created DATETIME2 NOT NULL CONSTRAINT DF_CompanyKeyPartner_Created DEFAULT GETDATE(),
    CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyKeyPartner_CreatedBy DEFAULT SYSTEM_USER,
    Modified DATETIME2 NOT NULL CONSTRAINT DF_CompanyKeyPartner_Modified DEFAULT GETDATE(),
    ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyKeyPartner_ModifiedBy DEFAULT SYSTEM_USER
);
GO

-- Error Table
CREATE TABLE ErrorLog (
    id INT IDENTITY(1,1) CONSTRAINT PK_ErrorLog PRIMARY KEY,
    staged_data_id INT NULL,
    error_message VARCHAR(1000) NOT NULL,
    Created DATETIME2 NOT NULL CONSTRAINT DF_ErrorLog_Created DEFAULT GETDATE(),
    CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_ErrorLog_CreatedBy DEFAULT SYSTEM_USER,
    Modified DATETIME2 NOT NULL CONSTRAINT DF_ErrorLog_Modified DEFAULT GETDATE(),
    ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_ErrorLog_ModifiedBy DEFAULT SYSTEM_USER
);
GO

-- Staged Data Table (Physical Table)
CREATE TABLE staged_data (
    id INT IDENTITY(1,1) CONSTRAINT PK_staged_data PRIMARY KEY,
    companyid VARCHAR(50) NULL,
    fieldofficeid VARCHAR(50) NULL,
    companygroupid INT NULL,
    fiscalyear VARCHAR(50) NULL,
    wtf1 INT NULL,
    wtf2 INT NULL,
    wtf3 INT NULL
);


CREATE TYPE StagedDataType AS TABLE (
    id INT,
    companyid VARCHAR(50),
    fieldofficeid VARCHAR(50),
    companygroupid INT,
    fiscalyear VARCHAR(50),
    wtf1 INT,
    wtf2 INT,
    wtf3 INT
);
GO


CREATE OR ALTER PROCEDURE sp_ProcessStagedData
    @staged_data StagedDataType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables to hold current row data
    DECLARE @id INT,
            @companyid_str VARCHAR(50),
            @fieldofficeid_str VARCHAR(50),
            @fiscalyear_str VARCHAR(50),
            @companygroupid INT,
            @wtf1 INT,
            @wtf2 INT,
            @wtf3 INT;

    -- Parsed integer values
    DECLARE @companyid INT,
            @fieldofficeid INT,
            @fiscalyear INT;

    -- Helper variables
    DECLARE @error_msg VARCHAR(1000);
    DECLARE @new_companygroupid INT;

    -- Cursor to iterate through each row in staged_data
    DECLARE stage_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id, companyid, fieldofficeid, companygroupid, fiscalyear, wtf1, wtf2, wtf3
    FROM @staged_data;

    OPEN stage_cursor;

    FETCH NEXT FROM stage_cursor INTO 
        @id, @companyid_str, @fieldofficeid_str, @companygroupid, @fiscalyear_str, @wtf1, @wtf2, @wtf3;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @error_msg = NULL;

        ------------------------------------------------------------------
        -- 1. Validate required fields (NULL, empty string, or 'not found')
        ------------------------------------------------------------------
        IF @companyid_str IS NULL OR LTRIM(RTRIM(@companyid_str)) IN ('', 'not found')
           OR @fieldofficeid_str IS NULL OR LTRIM(RTRIM(@fieldofficeid_str)) IN ('', 'not found')
           OR @fiscalyear_str IS NULL OR LTRIM(RTRIM(@fiscalyear_str)) IN ('', 'not found')
        BEGIN
            SET @error_msg = 'Validation Failed: companyid, fieldofficeid, or fiscalyear is NULL, empty, or ''not found''.';
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT 'Row ID ' + CAST(@id AS VARCHAR(10)) + ': ' + @error_msg;
            GOTO NextRow;
        END

        -- Cast/Parse strings to integer
        SET @companyid = TRY_CAST(@companyid_str AS INT);
        SET @fieldofficeid = TRY_CAST(@fieldofficeid_str AS INT);
        SET @fiscalyear = TRY_CAST(@fiscalyear_str AS INT);

        IF @companyid IS NULL OR @fieldofficeid IS NULL OR @fiscalyear IS NULL
        BEGIN
            SET @error_msg = 'Validation Failed: companyid, fieldofficeid, or fiscalyear cannot be converted to INT.';
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT 'Row ID ' + CAST(@id AS VARCHAR(10)) + ': ' + @error_msg;
            GOTO NextRow;
        END

        ------------------------------------------------------------------
        -- 2. Validate existence in Company table
        ------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM Company WHERE companyid = @companyid)
        BEGIN
            SET @error_msg = 'Validation Failed: companyid ' + CAST(@companyid AS VARCHAR(10)) + ' not found in Company table.';
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT 'Row ID ' + CAST(@id AS VARCHAR(10)) + ': ' + @error_msg;
            GOTO NextRow;
        END

        ------------------------------------------------------------------
        -- 3. Check existing CompanyGroup match with groupid = 3
        ------------------------------------------------------------------
        IF EXISTS (
            SELECT 1 
            FROM CompanyGroup 
            WHERE companyid = @companyid 
              AND fieldofficeid = @fieldofficeid 
              AND groupid = 3
        )
        BEGIN
            SET @error_msg = 'Validation Failed: Entry already exists in CompanyGroup for companyid ' 
                             + CAST(@companyid AS VARCHAR(10)) + ', fieldofficeid ' 
                             + CAST(@fieldofficeid AS VARCHAR(10)) + ' with groupid = 3.';
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT 'Row ID ' + CAST(@id AS VARCHAR(10)) + ': ' + @error_msg;
            GOTO NextRow;
        END

        ------------------------------------------------------------------
        -- 4. Atomic Transaction Insert into CompanyGroup & CompanyKeyPartner
        ------------------------------------------------------------------
        BEGIN TRANSACTION;
        BEGIN TRY
            -- Insert into CompanyGroup
            INSERT INTO CompanyGroup (companyid, groupid, fieldofficeid)
            VALUES (@companyid, 3, @fieldofficeid);

            SET @new_companygroupid = SCOPE_IDENTITY();

            -- Insert into CompanyKeyPartner
            INSERT INTO CompanyKeyPartner (companyid, fieldofficeid, companygroupid, fiscalyear, wtf1, wtf2, wtf3)
            VALUES (@companyid, @fieldofficeid, @new_companygroupid, @fiscalyear, @wtf1, @wtf2, @wtf3);

            COMMIT TRANSACTION;

            PRINT 'Row ID ' + CAST(@id AS VARCHAR(10)) + ': Successfully processed and inserted into CompanyGroup (ID: ' 
                  + CAST(@new_companygroupid AS VARCHAR(10)) + ') and CompanyKeyPartner.';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @error_msg = 'Transaction Failed: ' + ERROR_MESSAGE();
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT 'Row ID ' + CAST(@id AS VARCHAR(10)) + ': ' + @error_msg;
        END CATCH

        NextRow:
        FETCH NEXT FROM stage_cursor INTO 
            @id, @companyid_str, @fieldofficeid_str, @companygroupid, @fiscalyear_str, @wtf1, @wtf2, @wtf3;
    END

    CLOSE stage_cursor;
    DEALLOCATE stage_cursor;
END;
GO



-- Populating sample company data
INSERT INTO Company (companyid, companyname) VALUES (101, 'Acme Corp'), (102, 'Globex Corp');

-- Declare and populate table variable
DECLARE @MyStagedData StagedDataType;

INSERT INTO @MyStagedData (id, companyid, fieldofficeid, companygroupid, fiscalyear, wtf1, wtf2, wtf3)
VALUES 
    (1, '101', '10', NULL, '2024', 10, 20, 30),        -- Valid row
    (2, 'not found', '10', NULL, '2024', 5, 5, 5),      -- Invalid: 'not found'
    (3, '999', '10', NULL, '2024', 1, 2, 3),            -- Invalid: company 999 missing
    (4, '101', '10', NULL, '2024', 10, 20, 30);         -- Invalid: duplicate groupid=3 match

-- Execute stored procedure
EXEC sp_ProcessStagedData @staged_data = @MyStagedData;

-- View logged errors
SELECT * FROM ErrorLog;
