
USE SQL_Course
GO

SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS DatabaseCollation;
-- SQL_Latin1_General_CP1_CI_AS


CREATE TABLE my_sort(
    ID INT,
    NAME VARCHAR(100)
)

INSERT INTO my_sort(ID, NAME)
VALUES
(1, 'abc'),
(2, 'Abc'), 
(3, 'acc') 

INSERT INTO my_sort(ID, NAME)
VALUES
(3, 'acc') 


SELECT * FROM my_sort;


SELECT * FROM my_sort 
ORDER BY NAME ASC;


SELECT * 
FROM my_sort
ORDER BY NAME COLLATE Latin1_General_CS_AS;

SELECT * 
FROM my_sort
ORDER BY NAME COLLATE Latin1_General_CI_AS;


SELECT * 
FROM my_sort
ORDER BY NAME COLLATE Latin1_General_100_BIN2;