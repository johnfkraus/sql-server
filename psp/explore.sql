USE explore_psp
GO

CREATE TABLE Company (
    companyid INT PRIMARY KEY,
    companyname NVARCHAR(50),
    aorfieldoffice INT NULL,
    dsacfieldoffice INT NULL,
    kpfieldoffices NVARCHAR(MAX) CHECK (ISJSON(kpfieldoffices) = 1),
    annualrevenue INT NULL
);

-- Insert a JSON array
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES
(1,'A Co.',51,51,'[51,56]',123)

INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(3,'B Co.',52,52,'[52]',NULL)

INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(5,'C Co.',53,53,'[53,51]',2221)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(7,'D Co.',54,55,'[55]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(9,'E Co.',55,55,'[55]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(11,'F, Inc.',56,56,'[56,55]',331)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(13,'G LLC',57,NULL,'[]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(15,'H Co.',51,NULL,'[51]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(17,'International Co.',52,NULL,'[52]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(19,'Junk Co.',53,NULL,'[51]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(21,'K Co.',54,NULL,'[]',854)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(23,'Lousy Co.',55,NULL,'[]',NULL)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(25,'Monkey Co.',56,NULL,'[]',44)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(27,'NoGoodCo',56,NULL,'[]',NULL)

INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(29,'OPEN Co',51,NULL,'[]',199)
INSERT INTO Company(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(31,'Platypus Co.',51,NULL,'[]',NULL)

SELECT [companyid]
      ,[companyname]
      ,[aorfieldoffice]
      ,[dsacfieldoffice]
      ,[kpfieldoffices]
      ,[annualrevenue]
  FROM [explore_psp].[dbo].[Company]

-- OPENJSON: Parse the JSON list into a table format (rows):
SELECT * -- e.companyname, kp.value AS kpfieldoffices
FROM Company e
CROSS APPLY OPENJSON(e.kpfieldoffices) AS kp;

-- JSON_CONTAINS / Array Checks (SQL Server 2016+): Filter rows where a list contains a specific value:

SELECT *  
FROM Company c
WHERE 56 IN (SELECT value FROM OPENJSON(kpfieldoffices));


SELECT *  
FROM Company c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices));


-- field office 51
SELECT *  
FROM Company c
WHERE aorfieldoffice = 51 --  IN (SELECT value FROM OPENJSON(kpfieldoffices));
UNION
SELECT *  
FROM Company c
WHERE dsacfieldoffice = 51 
UNION
SELECT *  
FROM Company c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices));




--  IN (SELECT value FROM OPENJSON(kpfieldoffices));
