----------------------------------------------
-- Course: A completed course in SQL with SQL server
-- Section Title: Working with JSON data
-- Copywrite: PADS research LTD

--------------------------------------------------
-- 1. JSON structure and JSON path

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
-- 2. JSON functions

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

SELECT	*
FROM	OPENJSON(@json)
WITH (	id INT '$.car.id',
		price NVARCHAR(50) '$.car.price',
		Option_1_Colour NVARCHAR(50) '$.car.feature.list[0].colour',
		Option_2_Colour NVARCHAR(50) '$.car.feature.list[1].colour',
		Option_3_Colour NVARCHAR(50) '$.car.feature.list[2].colour'
);




