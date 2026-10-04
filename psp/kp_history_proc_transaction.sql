/*
Concept for populating the PSP2 CompanyGroup and CompanyKeyPartner database tables 
with data from PSP1.

Shout out to Google Gemini for helping with this.

PSP1 KP health data shall be provisioned in a staged_data table.  

A stored procedure accepts the staged_data table as a parameter.  The procedure evaluates each row 
of the staged_data table.  If the row is valid, records are entered into both the CompanyGroup table
and the CompanyKeyPartner table in an atomic transaction.

The staged_data table contains one row for every active key partner company and possibly some extra rows for invalid companies found in 1.0.  Health data is included from 1.0 when available.  

The staged data consists of:
A vertical stack of:
1. The 1.0 history data for companies with valid 2.0 ids (completed Friday 9/2); plus
2. The 1.0 history data for companies which lacked valid 2.0 ids; most of these have been 
mapped to 2.0 company ids (completed Friday).
Joined on company ids with 
3. the complete list of active key partner companies (companyid, fieldofficeid, fiscal year); this 
data exists.  

For staging, the above should give us a complete list of active KP companies, with health data where available.

For each row of staged data, a log record is written to an IngestStatus table describing whether processing succeeded or recording any errors.

Prerequisites:

Discard dummy tables created for testing.

Fix fake column names used below.  Make sure the columns referred to in the stored procedure match up with the column names in the real CompanyGroup and CompanyKeyPartner table.

PSP 2.0 has a set of canonical company ids.  Some PSP 1.0 companies are referred to by company ids that don't comply with the 2.0 company ids.  In order for a company in the staged_data table to be added to the PSP2 CompanyGroup and CompanyKeyPartner tables, the following requirements must be met.

- Valid 2.0 company id.  I was able to map all but seven companies in the PSP1 health data to actual companies from the PSP2 Company table.
- Valid field office ids.
- No identical record already exists in the CompanyGroup table.  (I assume we drop all KP records in CompanyGroup)
- A company must be added to BOTH the CompanyGroup and CompanyKeyPartner tables or else the transaction fails.

- The number of rows in the CompanyKeyPartner table must match the number of actual active key partners (400 or so). 
- Companies that can't be mapped to valid 2.0 company ids should not appear in the KP health data page.
- There should be 10 active key partners from Albuquerque.
- All the key partner companies must be in the staged_data table (company id, field office id, 
companygroupid).
- The staged_data table can have more rows than there are key partners, because some of those
rows won't be added to the CompanyKeyPartner table due to invalid company ids or whatever.

Before running the stored procedure:

With backups as deemed necessary:
- Delete all KP companies (GroupID = 3) from the CompanyGroup table.
- Truncate the CompanyKeyPartner table.

-- USE some_demo_database
-- GO

-- Dummy tables for testing only

-- Company Table
CREATE TABLE Company (
    companyid INT NOT NULL CONSTRAINT PK_Company PRIMARY KEY,
    companyname VARCHAR(30) NULL
);

-- FieldOffice Table
CREATE TABLE FieldOffice (
    fieldofficeid INT NOT NULL CONSTRAINT PK_FieldOffice PRIMARY KEY,
    fieldOfficeName VARCHAR(30) NULL
);

-- CompanyGroup Table
CREATE TABLE CompanyGroup (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompanyGroup PRIMARY KEY,
    companyid INT NULL,
    groupid INT NULL,
    fieldofficeid INT NULL,
    Created DATETIME2 NOT NULL CONSTRAINT DF_CompanyGroup_Created DEFAULT GETDATE(),
    CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyGroup_CreatedBy DEFAULT SYSTEM_USER,
    Modified DATETIME2 NOT NULL CONSTRAINT DF_CompanyGroup_Modified DEFAULT GETDATE(),
    ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyGroup_ModifiedBy DEFAULT SYSTEM_USER
);

-- CompanyKeyPartner Table -- no FK
-- CREATE TABLE CompanyKeyPartner (
--     id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompanyKeyPartner PRIMARY KEY,
--     companyid INT NULL,
--     fieldofficeid INT NULL,
--     companygroupid INT NULL,
--     fiscalyear INT NULL,
--     wtf1 INT NULL,
--     wtf2 INT NULL,
--     wtf3 INT NULL,
--     Created DATETIME2 NOT NULL CONSTRAINT DF_CompanyKeyPartner_Created DEFAULT GETDATE(),
--     CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyKeyPartner_CreatedBy DEFAULT SYSTEM_USER,
--     Modified DATETIME2 NOT NULL CONSTRAINT DF_CompanyKeyPartner_Modified DEFAULT GETDATE(),
--     ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyKeyPartner_ModifiedBy DEFAULT SYSTEM_USER
-- );

-- with FK
CREATE TABLE CompanyKeyPartner (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompanyKeyPartner PRIMARY KEY,
    companyid INT NULL,
    fieldofficeid INT NULL,
    companygroupid INT NOT NULL, -- Must match type of CompanyGroup.id
    fiscalyear INT NULL,
    wtf1 INT NULL,
    wtf2 INT NULL,
    wtf3 INT NULL,
    Created DATETIME2 NOT NULL CONSTRAINT DF_CompanyKeyPartner_Created DEFAULT GETDATE(),
    CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyKeyPartner_CreatedBy DEFAULT SYSTEM_USER,
    Modified DATETIME2 NOT NULL CONSTRAINT DF_CompanyKeyPartner_Modified DEFAULT GETDATE(),
    ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_CompanyKeyPartner_ModifiedBy DEFAULT SYSTEM_USER,

    -- Foreign Key Constraint definition
    CONSTRAINT FK_CompanyKeyPartner_CompanyGroup 
        FOREIGN KEY (companygroupid) 
        REFERENCES CompanyGroup(id)
);


-- IngestStatus Table
CREATE TABLE IngestStatus (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_IngestStatus PRIMARY KEY,
    staged_data_id INT NULL,
    company_group_id INT NULL,
    company_key_partner_id INT NULL,
    error BIT NOT NULL CONSTRAINT DF_IngestStatus_Error DEFAULT 0,
    status_message VARCHAR(2000) NULL,
    Created DATETIME2 NOT NULL CONSTRAINT DF_IngestStatus_Created DEFAULT GETDATE(),
    CreatedBy VARCHAR(128) NOT NULL CONSTRAINT DF_IngestStatus_CreatedBy DEFAULT SYSTEM_USER,
    Modified DATETIME2 NOT NULL CONSTRAINT DF_IngestStatus_Modified DEFAULT GETDATE(),
    ModifiedBy VARCHAR(128) NOT NULL CONSTRAINT DF_IngestStatus_ModifiedBy DEFAULT SYSTEM_USER
);

-- Staged Data Table (Physical Table Definition);
-- Some column names are FAKE 
CREATE TABLE staged_data (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_staged_data PRIMARY KEY,
    companyid INT NULL,
    fieldofficeid INT NULL,
    fiscalyear INT NULL,
    wtf1 INT NULL,
    wtf2 INT NULL,
    wtf3 INT NULL
);
GO

-- 2. Triggers for Automatic Audit Column Updates; possibly a best practice, if we like that sort of thing.

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

CREATE TRIGGER trg_IngestStatus_UpdateModified
ON IngestStatus
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ins
    SET Modified = GETDATE(),
        ModifiedBy = SYSTEM_USER
    FROM IngestStatus ins
    INNER JOIN inserted i ON ins.id = i.id;
END;
GO

-- 3. User-Defined Table Type (UDTT)
-- To pass a full table structure into a stored procedure parameter in SQL Server, we define a TVP type. We use VARCHAR(50) for numerical staging fields so the stored procedure can explicitly validate raw input for invalid data types, strings like 'not found', and empty strings.


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

-- stored procedure

CREATE OR ALTER PROCEDURE sp_ProcessStagedData
    @staged_data StagedDataType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    -- Variable declarations for current row extraction
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

    -- Status tracking
    DECLARE @status_id INT,
            @new_companygroup_id INT,
            @new_keypartner_id INT,
            @err_fields VARCHAR(500);

    -- Cursor to iterate through staged data row-by-row
    DECLARE stage_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id, companyid, fieldofficeid, fiscalyear, wtf1, wtf2, wtf3
    FROM @staged_data;

    OPEN stage_cursor;

    FETCH NEXT FROM stage_cursor INTO 
        @id, @companyid_raw, @fieldofficeid_raw, @fiscalyear_raw, @wtf1, @wtf2, @wtf3;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Reset loop context variables
        SET @status_id = NULL;
        SET @new_companygroup_id = NULL;
        SET @new_keypartner_id = NULL;
        SET @companyid = NULL;
        SET @fieldofficeid = NULL;
        SET @fiscalyear = NULL;
        SET @err_fields = '';

        -- Step A: Create initial tracking entry in IngestStatus
        INSERT INTO IngestStatus (staged_data_id, error, status_message)
        VALUES (@id, 0, 'Processing started.');

        SET @status_id = SCOPE_IDENTITY();

        BEGIN TRY
            ------------------------------------------------------------------
            -- Validation 1: Check NULL, empty string, 'not found', or non-INT types
            ------------------------------------------------------------------
            -- Check companyid
            IF @companyid_raw IS NULL OR LTRIM(RTRIM(LOWER(@companyid_raw))) IN ('', 'not found') OR TRY_CAST(@companyid_raw AS INT) IS NULL
                SET @err_fields = CONCAT(@err_fields, 'companyid (', ISNULL(@companyid_raw, 'NULL'), '), ');

            -- Check fieldofficeid
            IF @fieldofficeid_raw IS NULL OR LTRIM(RTRIM(LOWER(@fieldofficeid_raw))) IN ('', 'not found') OR TRY_CAST(@fieldofficeid_raw AS INT) IS NULL
                SET @err_fields = CONCAT(@err_fields, 'fieldofficeid (', ISNULL(@fieldofficeid_raw, 'NULL'), '), ');

            -- Check fiscalyear
            IF @fiscalyear_raw IS NULL OR LTRIM(RTRIM(LOWER(@fiscalyear_raw))) IN ('', 'not found') OR TRY_CAST(@fiscalyear_raw AS INT) IS NULL
                SET @err_fields = CONCAT(@err_fields, 'fiscalyear (', ISNULL(@fiscalyear_raw, 'NULL'), '), ');

            IF LEN(@err_fields) > 0
            BEGIN
                -- Strip trailing comma
                SET @err_fields = LEFT(@err_fields, LEN(@err_fields) - 1);
                
                UPDATE IngestStatus
                SET error = 1,
                    status_message = CONCAT('Error: Invalid field values or non-integer types found in staged_data row ', @id, ' for field(s): ', @err_fields)
                WHERE id = @status_id;

                GOTO NextRow;
            END

            -- Successfully cast values to integer
            SET @companyid = CAST(@companyid_raw AS INT);
            SET @fieldofficeid = CAST(@fieldofficeid_raw AS INT);
            SET @fiscalyear = CAST(@fiscalyear_raw AS INT);

            ------------------------------------------------------------------
            -- Validation 2: Company lookup
            ------------------------------------------------------------------
            IF NOT EXISTS (SELECT 1 FROM Company WHERE companyid = @companyid)
            BEGIN
                UPDATE IngestStatus
                SET error = 1,
                    status_message = CONCAT('Error: companyid ', @companyid, ' from staged_data row ', @id, ' was not found in the Company table.')
                WHERE id = @status_id;

                GOTO NextRow;
            END

            ------------------------------------------------------------------
            -- Validation 3: FieldOffice lookup
            ------------------------------------------------------------------
            IF NOT EXISTS (SELECT 1 FROM FieldOffice WHERE fieldofficeid = @fieldofficeid)
            BEGIN
                UPDATE IngestStatus
                SET error = 1,
                    status_message = CONCAT('Error: fieldofficeid ', @fieldofficeid, ' from staged_data row ', @id, ' was not found in the FieldOffice table.')
                WHERE id = @status_id;

                GOTO NextRow;
            END

            ------------------------------------------------------------------
            -- Validation 4: Duplicate record check (groupid = 3)
            ------------------------------------------------------------------
            IF EXISTS (
                SELECT 1 
                FROM CompanyGroup 
                WHERE companyid = @companyid 
                  AND fieldofficeid = @fieldofficeid 
                  AND groupid = 3
            )
            BEGIN
                UPDATE IngestStatus
                SET error = 1,
                    status_message = CONCAT('Error: A duplicate record already exists in CompanyGroup with companyid ', @companyid, ', fieldofficeid ', @fieldofficeid, ', and groupid = 3 for staged_data row ', @id, '.')
                WHERE id = @status_id;

                GOTO NextRow;
            END

            ------------------------------------------------------------------
            -- Atomic Transaction Inserts
            ------------------------------------------------------------------
            BEGIN TRANSACTION;

                -- Insert 1: CompanyGroup
                INSERT INTO CompanyGroup (companyid, groupid, fieldofficeid)
                VALUES (@companyid, 3, @fieldofficeid);

                SET @new_companygroup_id = SCOPE_IDENTITY();

                -- Insert 2: CompanyKeyPartner
                INSERT INTO CompanyKeyPartner (companyid, fieldofficeid, companygroupid, fiscalyear, wtf1, wtf2, wtf3)
                VALUES (@companyid, @fieldofficeid, @new_companygroup_id, @fiscalyear, @wtf1, @wtf2, @wtf3);

                SET @new_keypartner_id = SCOPE_IDENTITY();

            COMMIT TRANSACTION;

            -- Log success status
            UPDATE IngestStatus
            SET company_group_id = @new_companygroup_id,
                company_key_partner_id = @new_keypartner_id,
                status_message = CONCAT('Successfully processed staged_data row ', @id, '. Created CompanyGroup ID: ', @new_companygroup_id, ' and CompanyKeyPartner ID: ', @new_keypartner_id, '.')
            WHERE id = @status_id;

        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            -- Log unexpected or transaction failures
            UPDATE IngestStatus
            SET error = 1,
                status_message = CONCAT('Error encountered during processing of staged_data row ', @id, ': ', ERROR_MESSAGE())
            WHERE id = @status_id;
        END CATCH

        NextRow:
        FETCH NEXT FROM stage_cursor INTO 
            @id, @companyid_raw, @fieldofficeid_raw, @fiscalyear_raw, @wtf1, @wtf2, @wtf3;
    END

    CLOSE stage_cursor;
    DEALLOCATE stage_cursor;
END;
GO

-- sample data and demo script

-- Clean up test records
-- TRUNCATE TABLE Company;
-- TRUNCATE TABLE FieldOffice;
-- TRUNCATE TABLE CompanyKeyPartner;
-- TRUNCATE TABLE CompanyGroup;
-- TRUNCATE TABLE IngestStatus;


-- Drop Foreign Key
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CompanyKeyPartner_CompanyGroup')
    ALTER TABLE CompanyKeyPartner DROP CONSTRAINT FK_CompanyKeyPartner_CompanyGroup;

-- Truncate all tables
TRUNCATE TABLE CompanyKeyPartner;
TRUNCATE TABLE CompanyGroup;
TRUNCATE TABLE Company;
TRUNCATE TABLE FieldOffice;
TRUNCATE TABLE IngestStatus;

-- Re-create Foreign Key
ALTER TABLE CompanyKeyPartner
ADD CONSTRAINT FK_CompanyKeyPartner_CompanyGroup
FOREIGN KEY (companygroupid) 
REFERENCES CompanyGroup(id);


-- Seed reference data
INSERT INTO Company (companyid, companyname) VALUES (101, 'Acme Corp'), (102, 'Globex Corp');
INSERT INTO FieldOffice (fieldofficeid, fieldOfficeName) VALUES (500, 'North Region'), (501, 'South Region');

-- Seed an existing row in CompanyGroup to trigger the duplicate rule test
-- but this gives us a row in CompanyGroup with no matching row in CompanyKeyPartner
INSERT INTO CompanyGroup (companyid, groupid, fieldofficeid) VALUES (101, 3, 500);
INSERT INTO CompanyKeyPartner (companyid, fieldofficeid, fiscalyear, companygroupid)
VALUES (
    101,
    500,
    2026,
    (SELECT id FROM CompanyGroup 
    WHERE groupid = 3 AND companyid = 101 and fieldofficeid = 500)
);


-- Prepare staged input table variable containing test scenarios
DECLARE @SampleStagedData StagedDataType;

INSERT INTO @SampleStagedData (id, companyid, fieldofficeid, fiscalyear, wtf1, wtf2, wtf3)
VALUES 
    (1, '102', '501', '2025', 10, 20, 30),         -- Success case
    (2, 'not found', '500', '2025', 5, 5, 5),      -- Invalid string value ('not found')
    (3, '102', 'ABC', '2025', 1, 2, 3),            -- Invalid data type ('ABC' non-int fieldofficeid)
    (4, '999', '500', '2025', 1, 1, 1),            -- Company ID 999 does not exist
    (5, '102', '999', '2025', 2, 2, 2),            -- FieldOffice ID 999 does not exist
    (6, '101', '500', '2025', 3, 3, 3);            -- Duplicate entry match in CompanyGroup (groupid=3)

-- Run procedure
EXEC sp_ProcessStagedData @staged_data = @SampleStagedData;

-- Review execution audit results
SELECT 
    -- id AS status_id,
    staged_data_id,
    company_group_id,
    company_key_partner_id,
    error,
    status_message
    -- Created,
    -- CreatedBy
FROM IngestStatus
ORDER BY staged_data_id;
