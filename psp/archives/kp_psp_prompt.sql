old version with error table

Using MS SQL Server 2022
Create the following tables:
a CompanyGroup table with the following columns:
id, int, unique; companyid, int; groupid, int; fieldofficeid, int; Created, CreatedBy, Modified, ModifiedBy
a CompanyKeyPartner table with the following columns:
id, int, unique; companyid, int; fieldofficeid, int; companygroupid, int; fiscalyear, int; wtf1, int, null; wtf2, int, null; wtf3, int, null; Created, CreatedBy, Modified, ModifiedBy
A staged_data table having the following columns:
id, int, unique; companyid; fieldofficeid; fiscalyear, int; wtf1, int, null; wtf2, int, null; wtf3, int, null; 
A Company table with columns: companyid, companyname
Create an error table with columns: id, staged_data_id, error_message (varchar(1000)), Created, CreatedBy, Modified, ModifiedBy
Tables with columns Created, CreatedBy, Modified, ModifiedBy should have default values from GETDATE() and SYSTEM_USER().
Include a trigger to ensure that Modified and ModifiedBy fields are automatically updates.

I want a stored procedure.
I want to pass the procedure the table named staged_data.
The procedure should do the following for each row of the staged_data table:
if any of companyid, fieldofficeid, or fiscalyear are null or empty string or 'not found' in the staged_data table, enter a row in the error table with a suitable
message, the proceed to the next row.
If the value in staged_data.companyid is not found in the Company.companyid column, enter an error message in the error table and skip to the next row, otherwise proceed.
For any row in the CompanyGroup table, if staged_data.companyid = CompanyGroup.companyid AND staged_data.fieldofficeid = CompanyGroup.fieldofficeid 
AND CompanyGroup.groupid = 3, make an entry in the error table and skip to the next row; otherwise proceed.
The following two inserts should be treated as an atomic transaction.  If there is a failure, roll back, and make an entry in the error table.  The error message should reference the row number of the staged_data table that failed to be processed.
Enter a new row with a unique id in the CompanyGroup table.  Generate a unique id for each row.  Set CompanyGroup.companyid = staged_data.companyid, set CompanyGroup.groupid = 3, and set CompanyGroup.fieldofficeid = staged_data.fieldofficeid
Enter a new row with a unique id in the CompanyKeyPartner table.  In the CompanyKeyPartner table, set companyid = staged_data.companyid, set groupid = 3, and
set fieldofficeid = staged_data.fieldofficeid; set WTF1, WTF2, WTF3, and fiscalyear values to match those in the staged_data table.  Set CompanyKeyPartner.companygroupid = CompanyGroup.id.
For each row processed from the staged_data table, print an informative message, including any applicable error message.

