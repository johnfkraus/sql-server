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
