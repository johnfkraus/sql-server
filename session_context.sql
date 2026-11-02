USE SQL_Course
GO

CREATE OR ALTER PROCEDURE dbo.show_session_context
AS
BEGIN
    SELECT k.key_name,
           SESSION_CONTEXT(k.key_name) AS value
    FROM (VALUES (N'app_user_id'),
                 (N'client_correlation_id'),
                 (N'tenant_id')) AS k(key_name);
END



DECLARE @RC int

-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[show_session_context] 
GO