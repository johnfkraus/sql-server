USE psp3
GO

-- Company Table
CREATE TABLE Company (
    companyid INT CONSTRAINT PK_Company PRIMARY KEY,
    companyname VARCHAR(255) NOT NULL
);

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

-- Staged Data Table (Physical Table)
CREATE TABLE staged_data (
    id INT IDENTITY(1,1) CONSTRAINT PK_staged_data PRIMARY KEY,
    companyid VARCHAR(50) NULL,
    fieldofficeid VARCHAR(50) NULL,
    fiscalyear VARCHAR(50) NULL,
    wtf1 INT NULL,
    wtf2 INT NULL,
    wtf3 INT NULL
);

GO


CREATE TRIGGER trg_CompanyGroup_UpdateModified
ON CompanyGroup
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE cg
    SET Modified = GETDATE(),
        ModifiedBy = SYSTEM_USER
    FROM CompanyGroup cg
    INNER JOIN inserted i ON cg.id = i.id;
END;
GO

CREATE TRIGGER trg_CompanyKeyPartner_UpdateModified
ON CompanyKeyPartner
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ckp
    SET Modified = GETDATE(),
        ModifiedBy = SYSTEM_USER
    FROM CompanyKeyPartner ckp
    INNER JOIN inserted i ON ckp.id = i.id;
END;
GO

CREATE TRIGGER trg_ErrorLog_UpdateModified
ON ErrorLog
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE el
    SET Modified = GETDATE(),
        ModifiedBy = SYSTEM_USER
    FROM ErrorLog el
    INNER JOIN inserted i ON el.id = i.id;
END;
GO


CREATE TYPE StagedDataType AS TABLE (
    id INT,
    companyid VARCHAR(50),
    fieldofficeid VARCHAR(50),
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

    -- Local row variables
    DECLARE @id INT,
            @companyid_raw VARCHAR(50),
            @fieldofficeid_raw VARCHAR(50),
            @fiscalyear_raw VARCHAR(50),
            @wtf1 INT,
            @wtf2 INT,
            @wtf3 INT;

    -- Parsed integer values
    DECLARE @companyid INT,
            @fieldofficeid INT,
            @fiscalyear INT;

    -- Execution context variables
    DECLARE @error_msg VARCHAR(1000);
    DECLARE @new_companygroup_id INT;

    -- Cursor to iterate through staged data
    DECLARE stage_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id, companyid, fieldofficeid, fiscalyear, wtf1, wtf2, wtf3
    FROM @staged_data;

    OPEN stage_cursor;

    FETCH NEXT FROM stage_cursor INTO 
        @id, @companyid_raw, @fieldofficeid_raw, @fiscalyear_raw, @wtf1, @wtf2, @wtf3;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @error_msg = NULL;

        ------------------------------------------------------------------
        -- Rule 1: Validate Required Fields (NULL, Empty, 'not found')
        ------------------------------------------------------------------
        IF @companyid_raw IS NULL OR LTRIM(RTRIM(LOWER(@companyid_raw))) IN ('', 'not found')
           OR @fieldofficeid_raw IS NULL OR LTRIM(RTRIM(LOWER(@fieldofficeid_raw))) IN ('', 'not found')
           OR @fiscalyear_raw IS NULL OR LTRIM(RTRIM(LOWER(@fiscalyear_raw))) IN ('', 'not found')
        BEGIN
            SET @error_msg = CONCAT('Row ID ', @id, ' failed validation: companyid, fieldofficeid, or fiscalyear is NULL, empty, or ''not found''.');
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT @error_msg;
            GOTO NextRow;
        END

        -- Safely cast strings to integer
        SET @companyid = TRY_CAST(@companyid_raw AS INT);
        SET @fieldofficeid = TRY_CAST(@fieldofficeid_raw AS INT);
        SET @fiscalyear = TRY_CAST(@fiscalyear_raw AS INT);

        IF @companyid IS NULL OR @fieldofficeid IS NULL OR @fiscalyear IS NULL
        BEGIN
            SET @error_msg = CONCAT('Row ID ', @id, ' failed validation: companyid, fieldofficeid, or fiscalyear could not be converted to integer values.');
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT @error_msg;
            GOTO NextRow;
        END

        ------------------------------------------------------------------
        -- Rule 2: Check existence in Company table
        ------------------------------------------------------------------
        IF NOT EXISTS (SELECT 1 FROM Company WHERE companyid = @companyid)
        BEGIN
            SET @error_msg = CONCAT('Row ID ', @id, ' failed validation: companyid (', @companyid, ') was not found in Company table.');
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT @error_msg;
            GOTO NextRow;
        END

        ------------------------------------------------------------------
        -- Rule 3: Check for existing CompanyGroup match with groupid = 3
        ------------------------------------------------------------------
        IF EXISTS (
            SELECT 1 
            FROM CompanyGroup 
            WHERE companyid = @companyid 
              AND fieldofficeid = @fieldofficeid 
              AND groupid = 3
        )
        BEGIN
            SET @error_msg = CONCAT('Row ID ', @id, ' failed validation: Existing record found in CompanyGroup with companyid=', @companyid, ', fieldofficeid=', @fieldofficeid, ', and groupid=3.');
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT @error_msg;
            GOTO NextRow;
        END

        ------------------------------------------------------------------
        -- Rule 4: Atomic Insert Transaction
        ------------------------------------------------------------------
        BEGIN TRANSACTION;
        BEGIN TRY
            -- Insert into CompanyGroup
            INSERT INTO CompanyGroup (companyid, groupid, fieldofficeid)
            VALUES (@companyid, 3, @fieldofficeid);

            -- Capture generated unique ID for CompanyGroup
            SET @new_companygroup_id = SCOPE_IDENTITY();

            -- Insert into CompanyKeyPartner linked via companygroupid
            INSERT INTO CompanyKeyPartner (companyid, fieldofficeid, companygroupid, fiscalyear, wtf1, wtf2, wtf3)
            VALUES (@companyid, @fieldofficeid, @new_companygroup_id, @fiscalyear, @wtf1, @wtf2, @wtf3);

            COMMIT TRANSACTION;

            PRINT CONCAT('Row ID ', @id, ' processed successfully. Created CompanyGroup ID: ', @new_companygroup_id, ' and linked CompanyKeyPartner record.');
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @error_msg = CONCAT('Row ID ', @id, ' failed during insert transaction: ', ERROR_MESSAGE());
            INSERT INTO ErrorLog (staged_data_id, error_message) VALUES (@id, @error_msg);
            PRINT @error_msg;
        END CATCH

        NextRow:
        FETCH NEXT FROM stage_cursor INTO 
            @id, @companyid_raw, @fieldofficeid_raw, @fiscalyear_raw, @wtf1, @wtf2, @wtf3;
    END

    CLOSE stage_cursor;
    DEALLOCATE stage_cursor;
END;
GO



-- 1. Setup reference data
INSERT INTO Company (companyid, companyname) 
VALUES (1001, 'Acme Corp'), (1002, 'Stark Industries');

-- 2. Populate a table variable matching StagedDataType
DECLARE @StagedInput StagedDataType;

INSERT INTO @StagedInput (id, companyid, fieldofficeid, fiscalyear, wtf1, wtf2, wtf3)
VALUES 
    (1, '1001', '10', '2024', 100, 200, 300),          -- Success
    (2, 'not found', '10', '2024', 50, 50, 50),         -- Fails: 'not found'
    (3, '9999', '10', '2024', 10, 20, 30),              -- Fails: Company not in Company table
    (4, '1001', '10', '2024', 100, 200, 300);           -- Fails: Duplicate match for groupid=3

-- 3. Execute procedure
EXEC sp_ProcessStagedData @staged_data = @StagedInput;

-- 4. Check results
SELECT * FROM CompanyGroup;
SELECT * FROM CompanyKeyPartner;
SELECT * FROM ErrorLog;


