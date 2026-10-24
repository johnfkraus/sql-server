----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Working with JSON data
-- Copywrite: PADS research LTD

--------------------------------------------------
-- 1. JSON structure and JSON path
/*
JSON stores semi-structured data.
- JSON is called "semi-structured" because it sits between two extremes: fully structured data (like a relational table with a fixed schema) and unstructured data (like free text or raw images).

The two extremes

1. Structured data — a PostgreSQL or SQL Server table — enforces its shape up front. Every row has the same columns, each with a declared type, and constraints (NOT NULL, UNIQUE, foreign keys) guarantee the data conforms before it's ever stored. The schema is a contract the data can't violate.

2. Unstructured data — an email body, a photo, a log line of prose — has no machine-enforceable structure at all. You can store it, but a program must interpret it heuristically to extract meaning.

Where JSON lands

JSON gives you structure — named fields, nesting, arrays — but ***does not enforce it***:

No fixed schema required.  Two records in the same "collection" of JSON can have completely different fields. Nothing stops {"name": "Alice"} and {"age": 42} from living side by side.

Types are implicit and permissive. A field called price can hold a number in one object and a string "12.50" in another, and both are valid JSON.

Structure is discovered, not declared. With a table, you know the shape before reading any rows. With JSON, you learn the shape by inspecting the data itself — field names, nesting depth, and whether items is an array or an object can vary record to record.

Why the distinction matters in practice

This maps directly onto work you've done with dlt and layered ingestion pipelines. Semi-structured data typically gets handled in stages:

Land it raw — preserve the original JSON exactly as received, since there's no schema to reconstruct it from later.

Infer or impose a schema — tools like dlt (or DuckDB's JSON reader, or Pydantic models) examine actual records and derive column types, nested child tables, and a business_id-style structure you can then enforce.

Validate at a gate — because the source won't reject bad records, you quarantine anything that doesn't match expectations (as in your SQL Server ETL quarantine framework) before publishing to a properly structured table.

So the short version: JSON describes structure but doesn't enforce it. The schema is a convention inside the data rather than a rule imposed on it — which is why it's the natural interchange format for APIs (flexible to produce) and why downstream pipelines exist to turn it into genuinely structured, constraint-backed tables (reliable to query).


JSON is derived from JavaScript.

JSON is used to transfer data between applications.

JSON is used as a data format for some NOSQL document databases such as MongoDB or CosmosDB.

Within SQL Server JSON enables the combination of structured tables with semi-structured NOSQL data concepts.

JSON Data Types

- string
- number
- object
- array
- boolean
- null

*/




---------------------------------
-- Syntax

-- Name Value pairs 
{"name":"value"}

{"age":25}

{"name":"Abbey", "age":22}



-- Object
{
	"item1":{
		"id":1,
		"name":"milk",
		"type":"food"
	},
	"item2":null
}

-- Array 
["Tesla", "BMW", "Fiat"]


-- Complete example
{ "car": 
  {
	  "id": "1",
	  "price": "40000", 
	  "feature": 
	  {
		"list": 
		[
		  {"noDoors": 5, "colour": "red"},
		  {"noDoors": "3", "colour": "blue"},
		  {"noDoors": "5", "colour": "green"}
		]
      }
  }
}

-- JSON path 
$	

$.car

$.car.price

$.car.feature.list[0].colour



--------------------------------------------------
-- 2. JSON functions (there are four)

/*
JSON is stored as plain text typically as VARCHAR or NVARCHAR.

ISJSON checks to see if the stored text is a valid JSON object, array, number, string, or one of the three literal values (false, true, null).

- Returns 1 for true, 0 for false.

JSON_VALUE function extracts a single scalar value of type nvarchar(4000).

- Accepts two parameters: an expression containing the JSON script and the JSON path specifying the property to extract.

- Lax and strict modes.  Lax mode returns null; strict mode returns error.

JSON_QUERY function extracts an object or array, not a scalar, from a JSON string.

JSON_MODIFY(expression, path, new_value) - Update an existing value, insert a new key/value pair, or delete a key.

- Lax (default) or strict mode change how JSON_MODIFY works.  Use lax mode to insert new k/v pairs.
- set a value to null to delete it.

*/


---------------------------------
-- Syntax
SELECT	ISJSON(JSONCol)
FROM	TableName 
WHERE	ISJSON(JSONCol) > 0

SELECT	JSON_VALUE(JSONExpression, 'JSONPath')
FROM	TableName 

SELECT	JSON_QUERY(JSONExpression, 'JSONPath')
FROM	TableName 

SELECT	JSON_MODIFY(JSONExpression, 'JSONPath', 'New Value')
FROM	TableName 



--------------------------------------------------
-- 3. JSON function and path example

---------------------------------
-- Example


CREATE TABLE Covid.JSONExample (
	Cars NVARCHAR(1000)
)

INSERT INTO Covid.JSONExample(
	Cars
)
VALUES( ' { "car": 
			  {
				  "id": "1",
				  "price": "40000", 
				  "feature": 
				  {
					"list": 
					[
					  {"noDoors": 5, "colour": "red"},
					  {"noDoors": 3, "colour": "blue"},
					  {"noDoors": 5, "colour": "green"}
					]
				  }
			  }
			}'
)

SELECT [Cars]
	  ,JSON_VALUE(Cars, '$.car.id') AS ID
	  ,JSON_QUERY(Cars, '$.car.feature.list') AS List
	  ,ISJSON(Cars) AS IS_Valid_JSON
	  ,JSON_MODIFY(Cars, '$.car.price', '50000') AS Modify_Value
	  ,JSON_MODIFY(Cars, 'lax $.car.sold', 'true') AS Insert_Key_Value
	  ,JSON_MODIFY(Cars, 'lax $.car.id', null) AS Delete_ID
FROM  Covid.JSONExample
WHERE ISJSON(Cars) = 1 



--------------------------------------------------
-- 4. Convert a table to JSON

---------------------------------
-- Syntax

----------------
SELECT  Col1,
		Col2
FROM	tableName
FOR JSON AUTO;


----------------
SELECT	t1.[Col1] AS [t1.Col1]
		,t1.[Col2] AS [t1.Col2]
		,t2.[Col3] AS [t2.Col3]
		,t2.[Col4] AS [t2.Col4]
FROM	table1 t1 INNER JOIN
		table2 t2  ON t1.PK_ID = t2.FK_ID
FOR JSON PATH, ROOT ('Root_Name'), INCLUDE_NULL_VALUES


---------------------------------
-- Example
SELECT  *
FROM	[SQL_Course].[Covid].[Covid_Variant]
FOR JSON AUTO;

SELECT  cv.[PK_ID] 
		,cv.[Location] 
		,cv.[Date] 
		,cv.[Num_Sequence] 
		,cv.[Variant] 
		,cv.[Num_Sequences_Total] 
		,cv.[Has_Vaccination_Program] 
		,p.[PK_ID] 
		,p.[FK_Covid_Variant] 
		,p.[Age] 
		,p.[Record_Created_Date] [Variant]
FROM	[SQL_Course].[Covid].[Covid_Variant] cv INNER JOIN
		[Covid].[Patient] p  ON cv.PK_ID = p.FK_Covid_Variant
FOR JSON AUTO


----------------
SELECT	cv.[PK_ID] AS [Variant.PK_ID]
		,cv.[Location] AS [Variant.Location]
		,cv.[Date] AS [Variant.Date]
		,cv.[Num_Sequence] AS [Variant.Num_Sequence]
		,cv.[Variant] AS [Variant.Variant]
		,cv.[Num_Sequences_Total] AS [Variant.Num_Sequences_Total]
		,cv.[Has_Vaccination_Program] AS [Variant.Has_Vaccination_Program]
		,p.[PK_ID] AS [Patient.PK_ID]
		,p.[FK_Covid_Variant] AS [Patient.FK_Covid_Variant] 
		,p.[Age] AS [Patient.Age]
		,p.[Record_Created_Date] AS [Patient.Record_Created_Date]
FROM	[SQL_Course].[Covid].[Covid_Variant] cv INNER JOIN
		[Covid].[Patient] p  ON cv.PK_ID = p.FK_Covid_Variant
FOR JSON PATH, ROOT ('Root_Name'), INCLUDE_NULL_VALUES


--------------------------------------------------
-- 5. Convert JSON to a table
/*
OPENJSON(): a table-valued FUNCTION
- we can treat it as if we are reading data from a table.
 - parses JSON and returns rows and columns.
- Use OPENJSON in the from clause of a Transact-SQL statement.  T-SQL (Transact-SQL) is Microsoft's proprietary procedural extension of SQL designed specifically for use with Microsoft SQL Server and Azure SQL Database.

OPENJSON accepts two parameters:
- a JSON expression; and
- (optional) A path to specify what part of the JSON to be extracted.
- The WITH clause controls the columns / schema that should be returned.


*/
---------------------------------
-- Syntax
SELECT	*
FROM	OPENJSON(@json);

SELECT	*
FROM	OPENJSON(jsonExpression, path)


SELECT	*
FROM	OPENJSON(@json)
WITH (	Col1 INT '$.name1.name2',
		Col2 NVARCHAR(50) '$name1.name3',
		Col3 NVARCHAR(50) '$name1.name4'
);

---------------------------------
-- Example

DECLARE @json NVARCHAR(1000)

SET @json = '{ "car": 
			  {
				  "id": "12",
				  "price": "40000", 
				  "feature": 
				  {
					"list": 
					[
					  {"noDoors": 5, "colour": "red"},
					  {"noDoors": 3, "colour": "blue"},
					  {"noDoors": 5, "colour": "green"}
					]
				  }
			  }
			}'

SELECT	*
FROM	OPENJSON(@json)
WITH (	id INT '$.car.id',
		-- price NVARCHAR(50) '$.car.price',
		price INT '$.car.price',
		Option_1_Colour NVARCHAR(50) '$.car.feature.list[0].colour',
		Option_2_Colour NVARCHAR(50) '$.car.feature.list[1].colour',
		Option_3_Colour NVARCHAR(50) '$.car.feature.list[2].colour'
);




