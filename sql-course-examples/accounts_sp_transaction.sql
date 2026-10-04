/*
using ms sql server, I want to create a table named accounts with an accountid as primary key, customerid as a foreign key and a dollar mount up to 10 million. I want a customer account with a customerid primary key, customer name. I want a transactions table with a transactionid as primary key, an acccountid as foreign key, and a dollar amount of the transaction. All tables should have columns for Created, CreatedBy (system user), Modified (date) and ModifiedBy (user) with automatic default values. 
*/

USE accounts
GO

/*
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Accounts]') AND type in (N'U'))
DROP TABLE [dbo].[Accounts]
GO
DROP TABLE Customers;
DROP TABLE Transactions;
*/
-- 1. Create Customers Table
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    
    -- Soft Delete Column
    Deleted BIT NOT NULL DEFAULT 0,
    
    -- Audit / Tracking Columns
    Created DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME(),
    Modified DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ModifiedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME()
);

-- 2. Create Accounts Table
CREATE TABLE Accounts (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    
    -- DECIMAL(9, 2) supports up to $9,999,999.99 with a CHECK constraint capping at $10,000,000.00
    Balance DECIMAL(9, 2) NOT NULL 
        CONSTRAINT CHK_Accounts_MaxAmount CHECK (Balance <= 10000000.00 AND Balance >= 0.00),
    
    -- Soft Delete Column
    Deleted BIT NOT NULL DEFAULT 0,
    
    -- Foreign Key Constraint
    CONSTRAINT FK_Accounts_Customers FOREIGN KEY (CustomerID) 
        REFERENCES Customers(CustomerID),
        
    -- Audit / Tracking Columns
    Created DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME(),
    Modified DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ModifiedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME()
);

-- 3. Create Transactions Table
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    Amount DECIMAL(18, 2) NOT NULL,
    
    -- Foreign Key Constraint
    CONSTRAINT FK_Transactions_Accounts FOREIGN KEY (AccountID) 
        REFERENCES Accounts(AccountID),
        
    -- Audit / Tracking Columns
    Created DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME(),
    Modified DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    ModifiedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME()
);


-- Declare variables
DECLARE @JoeCustomerID INT;
DECLARE @SallyCustomerID INT;

-- 1. Insert Joe and capture his generated CustomerID
INSERT INTO Customers (CustomerName)
VALUES ('Joe');

SET @JoeCustomerID = SCOPE_IDENTITY();

-- Insert Joe's Account
INSERT INTO Accounts (CustomerID, Balance)
VALUES (@JoeCustomerID, 500.00);


-- 2. Insert Sally and capture her generated CustomerID
INSERT INTO Customers (CustomerName)
VALUES ('Sally');

SET @SallyCustomerID = SCOPE_IDENTITY();

-- Insert Sally's Account
INSERT INTO Accounts (CustomerID, Balance)
VALUES (@SallyCustomerID, 1000.00);



CREATE TABLE FailedTransactions (
    FailedTransactionID INT IDENTITY(1,1) PRIMARY KEY,
    SourceAccountID INT NULL,
    DestinationAccountID INT NULL,
    Amount DECIMAL(18,2) NULL,
    FailureReason NVARCHAR(500) NOT NULL,
    
    -- Audit / Tracking Columns
    Created DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SUSER_SNAME()
);
GO

CREATE OR ALTER PROCEDURE usp_TransferMoney
    @SourceAccountID INT,
    @DestinationAccountID INT,
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AbsoluteAmount DECIMAL(18,2) = ABS(@Amount);
    DECLARE @SourceBalance DECIMAL(9,2);
    DECLARE @SourceExists INT;
    DECLARE @DestExists INT;
    DECLARE @ErrorMessage NVARCHAR(500);

    -- Ensure amount is non-zero
    IF @AbsoluteAmount = 0
    BEGIN
        SET @ErrorMessage = 'Transfer amount must be greater than zero.';
        PRINT 'TRANSACTION FAILED: ' + @ErrorMessage;
        INSERT INTO FailedTransactions (SourceAccountID, DestinationAccountID, Amount, FailureReason)
        VALUES (@SourceAccountID, @DestinationAccountID, @Amount, @ErrorMessage);
        RETURN;
    END

    -- Ensure source and destination are different accounts
    IF @SourceAccountID = @DestinationAccountID
    BEGIN
        SET @ErrorMessage = 'Source and destination accounts must be different.';
        PRINT 'TRANSACTION FAILED: ' + @ErrorMessage;
        INSERT INTO FailedTransactions (SourceAccountID, DestinationAccountID, Amount, FailureReason)
        VALUES (@SourceAccountID, @DestinationAccountID, @Amount, @ErrorMessage);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check existence and lock rows in consistent order to prevent deadlocks
        SELECT @SourceBalance = Balance 
        FROM Accounts WITH (UPDLOCK) 
        WHERE AccountID = @SourceAccountID AND Deleted = 0;

        SELECT @DestExists = COUNT(1) 
        FROM Accounts WITH (UPDLOCK) 
        WHERE AccountID = @DestinationAccountID AND Deleted = 0;

        -- Validate Source Account
        IF @SourceBalance IS NULL
        BEGIN
            SET @ErrorMessage = CONCAT('Source account ID ', @SourceAccountID, ' does not exist or is deleted.');
            RAISERROR(@ErrorMessage, 16, 1);
        END

        -- Validate Destination Account
        IF @DestExists = 0
        BEGIN
            SET @ErrorMessage = CONCAT('Destination account ID ', @DestinationAccountID, ' does not exist or is deleted.');
            RAISERROR(@ErrorMessage, 16, 1);
        END

        -- Validate Balance Sufficiency
        IF @SourceBalance < @AbsoluteAmount
        BEGIN
            SET @ErrorMessage = CONCAT('Insufficient funds in source account ', @SourceAccountID, 
                                       '. Current balance: $', CAST(@SourceBalance AS NVARCHAR(20)), 
                                       ', Requested transfer: $', CAST(@AbsoluteAmount AS NVARCHAR(20)));
            RAISERROR(@ErrorMessage, 16, 1);
        END

        -- Validate Max Account Limit ($10,000,000.00 check for destination)
        IF (SELECT Balance FROM Accounts WHERE AccountID = @DestinationAccountID) + @AbsoluteAmount > 10000000.00
        BEGIN
            SET @ErrorMessage = CONCAT('Destination account ', @DestinationAccountID, ' balance would exceed the $10,000,000.00 limit.');
            RAISERROR(@ErrorMessage, 16, 1);
        END

        -- 1. Deduct from Source Account
        UPDATE Accounts
        SET Balance = Balance - @AbsoluteAmount,
            Modified = SYSDATETIME(),
            ModifiedBy = SUSER_SNAME()
        WHERE AccountID = @SourceAccountID;

        -- 2. Deposit into Destination Account
        UPDATE Accounts
        SET Balance = Balance + @AbsoluteAmount,
            Modified = SYSDATETIME(),
            ModifiedBy = SUSER_SNAME()
        WHERE AccountID = @DestinationAccountID;

        -- 3. Record Transactions (Debit for Source, Credit for Destination)
        INSERT INTO Transactions (AccountID, Amount)
        VALUES (@SourceAccountID, -@AbsoluteAmount);

        INSERT INTO Transactions (AccountID, Amount)
        VALUES (@DestinationAccountID, @AbsoluteAmount);

        -- Commit the transaction
        COMMIT TRANSACTION;

        PRINT CONCAT('TRANSACTION SUCCESSFUL: Transferred $', CAST(@AbsoluteAmount AS NVARCHAR(20)), 
                     ' from Account ', @SourceAccountID, ' to Account ', @DestinationAccountID, '.');

    END TRY
    BEGIN CATCH
        -- Rollback any active transaction
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Get error message details
        IF @ErrorMessage IS NULL
            SET @ErrorMessage = ERROR_MESSAGE();

        PRINT 'TRANSACTION FAILED: ' + @ErrorMessage;

        -- Log failure to FailedTransactions table
        INSERT INTO FailedTransactions (SourceAccountID, DestinationAccountID, Amount, FailureReason)
        VALUES (@SourceAccountID, @DestinationAccountID, @Amount, @ErrorMessage);
    END CATCH
END;
GO

-- 1. Successful Transfer ($100 from Joe [Account 1] to Sally [Account 2])
EXEC usp_TransferMoney @SourceAccountID = 1, @DestinationAccountID = 2, @Amount = 100.00;

-- 2. Failed Transfer (Insufficient Funds: Joe tries to send $1,000 when he has $400 left)
EXEC usp_TransferMoney @SourceAccountID = 1, @DestinationAccountID = 2, @Amount = 1000.00;

-- 3. Failed Transfer (Invalid Account)
EXEC usp_TransferMoney @SourceAccountID = 999, @DestinationAccountID = 2, @Amount = 50.00;

-- Inspect Failed Transactions Log
SELECT * FROM FailedTransactions;
GO

-- 1. Trigger for Customers Table
CREATE OR ALTER TRIGGER trg_Customers_UpdateModified
ON Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Avoid infinite loops if the trigger itself performs an update
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    -- Update Modified and ModifiedBy for updated rows
    UPDATE c
    SET 
        Modified = SYSDATETIME(),
        ModifiedBy = SUSER_SNAME()
    FROM Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
END;
GO

-- 2. Trigger for Accounts Table
CREATE OR ALTER TRIGGER trg_Accounts_UpdateModified
ON Accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Avoid infinite loops if the trigger itself performs an update
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    -- Update Modified and ModifiedBy for updated rows
    UPDATE a
    SET 
        Modified = SYSDATETIME(),
        ModifiedBy = SUSER_SNAME()
    FROM Accounts a
    INNER JOIN inserted i ON a.AccountID = i.AccountID;
END;
GO



-- Set NOCOUNT to keep output clean
SET NOCOUNT ON;

PRINT '==================================================';
PRINT '1. TESTING SINGLE-ROW UPDATE (Customers Table)';
PRINT '==================================================';

-- Display pre-update state for Joe
SELECT CustomerID, CustomerName, Created, Modified, ModifiedBy 
FROM Customers 
WHERE CustomerName = 'Joe';

-- Pause briefly so SYSDATETIME() changes noticeably
WAITFOR DELAY '00:00:02';

-- Execute update on Joe's record
UPDATE Customers
SET CustomerName = 'Joe (Updated)'
WHERE CustomerName = 'Joe';

-- Display post-update state to verify Modified timestamp changed
SELECT CustomerID, CustomerName, Created, Modified, ModifiedBy 
FROM Customers 
WHERE CustomerName LIKE 'Joe%';

PRINT '==================================================';
PRINT '2. TESTING MULTI-ROW / BULK UPDATE (Accounts Table)';
PRINT '==================================================';

-- Display pre-update state for all Accounts
SELECT AccountID, CustomerID, Balance, Created, Modified, ModifiedBy 
FROM Accounts;

-- Pause briefly
WAITFOR DELAY '00:00:02';

-- Execute a bulk update adding $10 to all active accounts
UPDATE Accounts
SET Balance = Balance + 10.00
WHERE Deleted = 0;

-- Display post-update state to verify all updated rows updated their Modified column
SELECT AccountID, CustomerID, Balance, Created, Modified, ModifiedBy 
FROM Accounts;