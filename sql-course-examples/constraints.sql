
USE SQL_Course
GO

CREATE TABLE Covid.Patient (
    PK_ID INT UNIQUE NOT NULL,
    Age INT CHECK(Age > 0 AND Age < 120)
)
