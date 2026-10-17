
CREATE TABLE Covid.JSONExample(
    Cars NVARCHAR(1000)
)

INSERT INTO Covid.JSONExample(
	Cars
)
VALUES(
'{ "car":
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
}'
)

SELECT Cars
FROM Covid.JSONExample


SELECT Cars
FROM Covid.JSONExample
WHERE ISJSON(Cars) = 1

SELECT Cars, 
	JSON_QUERY(Cars, '$')
FROM Covid.JSONExample
WHERE ISJSON(Cars) = 1


SELECT Cars, 
	JSON_VALUE(Cars, '$.car.id') AS ID,
	JSON_QUERY(Cars, '$.car.feature.list') AS List,
	ISJSON(Cars) AS Is_Valid_JSON,
	JSON_MODIFY(Cars, '$.car.price', '50000') AS Modify_Value,
	JSON_MODIFY(Cars, 'lax $.car.sold', 'true') AS Insert_Key_Value,
	-- JSON_MODIFY(Cars, 'strict $.car.junk', 'true') AS Insert_Key_Value_strict, fails
	JSON_MODIFY(Cars, 'strict $.car.id', null) AS Delete_ID_strict,
	JSON_MODIFY(Cars, '$.car.id', null) AS Delete_ID_lax
FROM Covid.JSONExample
WHERE ISJSON(Cars) = 1

-- 	JSON_MODIFY(Cars, 'strict $.car.id', null) AS Delete_ID results in "id": null instead of deleting the entire key/value pair.

