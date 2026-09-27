CREATE SCHEMA Covid;

CREATE TABLE Covid.Patient (
	PK_ID INT UNIQUE NOT NULL,
	Age INT CHECK(Age > 0 AND Age < 120),
	Record_Created_Date DATE DEFAULT GETDATE(),
)

CREATE TABLE Covid.Patient_Hospital(
		PK_Patient_ID INT NOT NULL, 
		PK_Hospital_ID INT NOT NULL,
		Global_Ranking INT NOT NULL,
		Quality_Rating INT NOT NULL,
		Satisfaction VARCHAR(10),
		CONSTRAINT CS_Patient_Hospital_Un UNIQUE(PK_Patient_ID, PK_Hospital_ID),
		CONSTRAINT CS_Patient_Hospital_Ch CHECK(	Quality_Rating > 0 AND 
													Quality_Rating <= 5
												)
)

INSERT INTO Covid.Patient (	PK_ID, Age) VALUES (1, 44);
)
INSERT INTO Covid.Patient (	PK_ID, Age) VALUES (1, 44);  -- violates unique

INSERT INTO Covid.Patient (	PK_ID, Age) VALUES (2, -44);  -- fails

INSERT INTO Covid.Patient (	PK_ID, Age) VALUES (2, 45);   -- OK

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(1, 101, 0, 4, 'High' );

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(2, 101, 0, -4, 'High' );  -- no record inserted

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(2, 101, 0, 6, 'High' );  -- no record inserted

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(2, 101, 33, 4, 'High' );  -- no record inserted

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(3, 101, 33, 4, 'Highest rating possible?' );  -- no record inserted; Satisfaction string is too long.

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(4, 101, 33, 4, '0123456789' );  -- OK ; Satisfaction string is not too long.

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating, Satisfaction) VALUES(5, 102, 33, 4, '01234567890' );  -- fails ; Satisfaction string is too long by one character.


ALTER TABLE [Covid].[Patient]
ALTER COLUMN [Age] INT NOT NULL


ALTER TABLE [Covid].[Patient]
ADD CHECK(Age > 0 AND Age < 120)


ALTER TABLE [Covid].[Patient_Hospital] WITH NOCHECK -- EXISTING DATA WON'T BE CHECKED
ADD CONSTRAINT CS_Global_Ranking_Un UNIQUE(Global_Ranking) 

ALTER TABLE [Covid].[Patient_Hospital] WITH NOCHECK
ADD CONSTRAINT CS_Global_Ranking_Def DEFAULT 'Happy' FOR Satisfaction

INSERT INTO Covid.Patient_Hospital(PK_Patient_ID,  PK_Hospital_ID, Global_Ranking, Quality_Rating) VALUES(6, 104, 37, 4 );  -- default value inserted for Satisfaction

ALTER TABLE [Covid].[Patient_Hospital] WITH NOCHECK
ADD CONSTRAINT CS_Global_Ranking_Def DEFAULT 'Happy' FOR Satisfaction WITH VALUES
-- ADDED WITH VALUES: all nulls will get the default value


-- see all constraints

IN MS SQL SERVER, when I run:
SELECT * 
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
What do IS_DEFERRABLE and INITIALLY_DEFFERED mean?

In SQL Server, both columns always return NO — SQL Server does not support deferrable constraints. 

IS_DEFERRABLE: Whether constraint checking can be deferred to the end of a transaction. SQL Server always returns NO because it checks constraints immediately after each statement. 
INITIALLY_DEFERRED: Whether the constraint's initial check time is deferred (as opposed to immediate). SQL Server always returns NO for the same reason. 
These columns exist only for SQL standard compliance (INFORMATION_SCHEMA is a SQL-standard interface); in SQL Server they are effectively placeholders.



CREATE TABLE Covid.Hospital (
	PK_Hospital_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	Name VARCHAR(50)
)

DROP TABLE [Covid].[Patient_Hospital]

CREATE TABLE [Covid].[Patient_Hospital](
	[PK_Patient_ID] [int] NOT NULL,
	[PK_Hospital_ID] [int] NOT NULL,
	[Global_Ranking] [int] NOT NULL,
	[Quality_Rating] [int] NOT NULL,
	[Satisfaction] [varchar](10) NULL,
	CONSTRAINT [CS_Compound_Key] PRIMARY KEY([PK_Patient_ID], [PK_Hospital_ID]),
	CONSTRAINT [CS_Patient_Hospital_Ch] CHECK  ([Quality_Rating]> 0 AND [Quality_Rating]<=5)
)

CREATE TABLE [Covid].[Covid_Variant] (
    [PK_ID] INT,
	[Location] VARCHAR(100),
    [Date] DATE,
	[Num_Sequences] int
);

ALTER TABLE [Covid].[Covid_Variant]
ADD [Variant] VARCHAR(50),
	[Num_Sequences_Total] DECIMAL(18,0),
	[Has_Vaccination_Program] CHAR(3),
	[Impact] INT


ALTER TABLE [Covid].[Covid_Variant]
DROP COLUMN [Impact]

ALTER TABLE [Covid].[Covid_Variant]
ALTER COLUMN [Variant] VARCHAR(200)

ALTER TABLE [Covid].[Covid_Variant]
ALTER COLUMN [Num_Sequences_Total] DECIMAL(18,2)

ALTER TABLE Covid.Covid_Variant
ALTER COLUMN PK_ID INT NOT NULL;

ALTER TABLE Covid.Covid_Variant 
ADD PRIMARY KEY(PK_ID)

DROP TABLE Covid.Patient

CREATE TABLE Covid.Patient(
	PK_ID INT NOT NULL PRIMARY KEY,
 	FK_Covid_Variant INT FOREIGN KEY REFERENCES Covid.Covid_Variant(PK_ID),
	Age INT CHECK (Age > 0 AND Age < 120),
	Record_Created_Date DATE DEFAULT GETDATE()
)

-- alternative fk syntax
CREATE TABLE Covid.Patient(
	PK_ID INT NOT NULL PRIMARY KEY,
 	FK_Covid_Variant INT ,
	Age INT CHECK (Age > 0 AND Age < 120),
	Record_Created_Date DATE DEFAULT GETDATE(),
	CONSTRAINT FK_Patient_Covid_Variant FOREIGN KEY (FK_Covid_Variant ) REFERENCES Covid.Covid_Variant(PK_ID)
)

ALTER TABLE Covid.Patient_Hospital 
ADD CONSTRAINT FK_Patient_Hospital_Hospital 
FOREIGN KEY (PK_Hospital_ID) REFERENCES Covid.Hospital(PK_Hospital_ID)

