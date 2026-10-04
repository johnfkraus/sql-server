-- triggers-examples.sql
USE SQL_Course
GO

CREATE TABLE Covid.PatientAudit (
    AUDIT_PK_ID INT IDENTITY(1,1) NOT NULL,
    PATIENT_PK_ID INT NOT NULL,
    FK_Covid_Variant INT NULL,
    Age INT NULL,
    Record_Created_Date DATE NULL,
    Audit_Date DATETIME DEFAULT GETDATE() NOT NULL,
    [User] VARCHAR(200) DEFAULT SUSER_NAME() NOT NULL
) 
GO


CREATE TRIGGER Covid.Tr_Patient_Audit ON Covid.Patient
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    PRINT 'Patient data has been inserted or updated'

    INSERT INTO Covid.PatientAudit (
        PATIENT_PK_ID,
        FK_Covid_Variant,
        Age,
        Record_Created_Date
    )
    SELECT
        [PK_ID],
        [FK_Covid_Variant],
        [Age],
        [Record_Created_Date]
    FROM INSERTED

END

INSERT INTO [Covid].[Patient] (
    [PK_ID],
    [FK_Covid_Variant],
    [Age],
    [Record_Created_Date]
) 
VALUES (
    100,
    20,
    78, 
    GETDATE()
)
GO

UPDATE [Covid].[Patient]
SET FK_Covid_Variant = 42,
    Age = 54
WHERE PK_ID = 100;
GO


-- PRINT WHAT WAS INSERTED

ALTER TRIGGER Covid.Tr_Patient_Audit ON Covid.Patient
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    PRINT 'Patient data has been inserted or updated'

    INSERT INTO Covid.PatientAudit (
        PATIENT_PK_ID,
        FK_Covid_Variant,
        Age,
        Record_Created_Date
    )
    SELECT
        [PK_ID],
        [FK_Covid_Variant],
        [Age],
        [Record_Created_Date]
    FROM INSERTED

    -- Concatenate inserted rows into a single string to use with PRINT
    DECLARE @msg NVARCHAR(MAX);
    
    SELECT @msg = STRING_AGG(
        CONCAT('PK_ID: ', PK_ID, ', FK_Covid_Variant: ', FK_Covid_Variant, ', Age: ', Age,  
        ', Record_Created_Date: ', Record_Created_Date), CHAR(50)
    )
    FROM INSERTED;

    PRINT '--- INSERTED ROWS ---';
    PRINT @msg;


END

