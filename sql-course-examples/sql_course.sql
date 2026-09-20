-- DROP DATABASE my_database

SELECT *
FROM sys.databases

DECLARE @DB_NAME VARCHAR(50)
SET @DB_NAME = 'SQL_Course'

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = @DB_Name)
BEGIN
    CREATE DATABASE SQL_Course
END

