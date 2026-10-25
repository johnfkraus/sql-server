USE explore_psp
GO

select @@version
-- Microsoft SQL Server 2022 (RTM-CU26) (KB5093420) - 16.0.4265.3 (X64)  	Jul  7 2026 14:37:25  	Copyright (C) 2022 Microsoft Corporation 	Developer Edition (64-bit) on Linux (Ubuntu 22.04.5 LTS) <X64>

CREATE TABLE CompanyImproved (
    companyid INT PRIMARY KEY,
    companyname NVARCHAR(50),
    aorfieldoffice INT NULL,
    dsacfieldoffice INT NULL,
    kpfieldoffices NVARCHAR(MAX) CHECK (ISJSON(kpfieldoffices) = 1),
    annualrevenue INT NULL,
    sectors NVARCHAR(70) NULL
);





-- Insert a JSON array
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(1,'A Co.',51,51,'[51,56]',123,'(1)(5)(8)(12)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(3,'B Co.',52,52,'[52]',NULL,'(3)(7)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(5,'C Co.',53,53,'[53,51]',2221,'(2)(4)(6)(9)(11)(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(7,'D Co.',54,55,'[55]',NULL,'(10)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(9,'E Co.',55,55,'[55]',NULL,'(5)(13)(14)(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(11,'F, Inc.',56,56,'[56,55]',331,'(1)(2)(3)(4)(5)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(13,'G LLC',57,NULL,'[]',NULL,'(8)(11)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(15,'H Co.',51,NULL,'[51]',NULL,'(6)(7)(9)(10)(12)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(17,'International Co.',52,NULL,'[52]',NULL,'(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(19,'Junk Co.',53,NULL,'[51]',NULL,'(2)(6)(8)(10)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(21,'K Co.',54,NULL,'[]',854,'(4)(5)(7)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(23,'Lousy Co.',55,NULL,'[]',NULL,'(1)(9)(11)(13)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(25,'Monkey Co.',56,NULL,'[]',44,'(3)(12)(15)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(27,'NoGoodCo',56,NULL,'[]',NULL,'(7)(8)(9)(10)(11)(12)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(29,'OPEN Co',51,NULL,'[]',199,'(2)(14)')
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue, sectors) VALUES(31,'Platypus Co.',51,NULL,'[]',NULL,'(1)(3)(5)(6)(13)')






INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES
(1,'A Co.',51,51,'[51,56]',123)

INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(3,'B Co.',52,52,'[52]',NULL)

INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(5,'C Co.',53,53,'[53,51]',2221)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(7,'D Co.',54,55,'[55]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(9,'E Co.',55,55,'[55]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(11,'F, Inc.',56,56,'[56,55]',331)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(13,'G LLC',57,NULL,'[]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(15,'H Co.',51,NULL,'[51]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(17,'International Co.',52,NULL,'[52]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(19,'Junk Co.',53,NULL,'[51]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(21,'K Co.',54,NULL,'[]',854)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(23,'Lousy Co.',55,NULL,'[]',NULL)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(25,'Monkey Co.',56,NULL,'[]',44)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(27,'NoGoodCo',56,NULL,'[]',NULL)

INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(29,'OPEN Co',51,NULL,'[]',199)
INSERT INTO CompanyImproved(companyid, companyname, aorfieldoffice, dsacfieldoffice, kpfieldoffices, annualrevenue) VALUES(31,'Platypus Co.',51,NULL,'[]',NULL)

SELECT [companyid]
      ,[companyname]
      ,[aorfieldoffice]
      ,[dsacfieldoffice]
      ,[kpfieldoffices]
      ,[annualrevenue]
  FROM [explore_psp].[dbo].[CompanyImproved]

-- OPENJSON: Parse the JSON list into a table format (rows):
SELECT * -- e.companyname, kp.value AS kpfieldoffices
FROM CompanyImproved e
CROSS APPLY OPENJSON(e.kpfieldoffices) AS kp;

-- JSON_CONTAINS / Array Checks (SQL Server 2016+): Filter rows where a list contains a specific value:

SELECT *  
FROM CompanyImproved c
WHERE 56 IN (SELECT value FROM OPENJSON(kpfieldoffices));


SELECT *  
FROM CompanyImproved c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices));


-- field office 51
SELECT *  
FROM CompanyImproved c
WHERE aorfieldoffice = 51 --  IN (SELECT value FROM OPENJSON(kpfieldoffices));
UNION
SELECT *  
FROM CompanyImproved c
WHERE dsacfieldoffice = 51 
UNION
SELECT *  
FROM CompanyImproved c
WHERE 51 IN (SELECT value FROM OPENJSON(kpfieldoffices));




DECLARE @input VARCHAR(100) = '(1)(2)(4)(6)(7)(12)(-11)';

SELECT 
    '[' + STRING_AGG(REPLACE(value, '(', ''), ',') WITHIN GROUP (ORDER BY ordinal) + ']' AS JsonArray
FROM STRING_SPLIT(@input, ')', 1)
WHERE value LIKE '(%';

[
  [1, 5, 8, 12],
  [3, 7, 14],
  [2, 4, 6, 9, 11, 15],
  [10],
  [5, 13, 14, 15],
  [1, 2, 3, 4, 5],
  [8, 11],
  [6, 7, 9, 10, 12, 14],
  [15],
  [2, 6, 8, 10],
  [4, 5, 7],
  [1, 9, 11, 13, 14],
  [3, 12, 15],
  [7, 8, 9, 10, 11, 12],
  [2, 14],
  [1, 3, 5, 6, 13]
]

  [1, 5, 8, 12]
  [3, 7, 14]
  [2, 4, 6, 9, 11, 15]
  [10]
  [5, 13, 14, 15]
  [1, 2, 3, 4, 5]
  [8, 11]
  [6, 7, 9, 10, 12, 14]
  [15]
  [2, 6, 8, 10]
  [4, 5, 7]
  [1, 9, 11, 13, 14]
  [3, 12, 15]
  [7, 8, 9, 10, 11, 12]
  [2, 14]
  [1, 3, 5, 6, 13]

(1)(5)(8)(12)
(3)(7)(14)
(2)(4)(6)(9)(11)(15)
(10)
(5)(13)(14)(15)
(1)(2)(3)(4)(5)
(8)(11)
(6)(7)(9)(10)(12)(14)
(15)
(2)(6)(8)(10)
(4)(5)(7)
(1)(9)(11)(13)(14)
(3)(12)(15)
(7)(8)(9)(10)(11)(12)
(2)(14)
(1)(3)(5)(6)(13)


