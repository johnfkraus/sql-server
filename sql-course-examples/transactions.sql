BEGIN TRANSACTION
    BEGIN TRY
        DECLARE @TestVar INT
        -- SELECT @TestVar = 'Error'
        SELECT @TestVar = 1
    END TRY
    -- catch errors
    BEGIN CATCH
        IF @@TRANCOUNT > 0  -- ARE ANY transactions open?
        BEGIN
            PRINT 'Number of transactions = ' + CAST(@@TRANCOUNT AS VARCHAR(10))
            ROLLBACK TRANSACTION
            PRINT 'SQL Rolled Back'
        END

    END CATCH
    -- commit transaction
    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        PRINT 'Transaction committed'
    END
