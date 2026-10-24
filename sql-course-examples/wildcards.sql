
SELECT	[ProductID]
		,[Name]
		,[ProductNumber]
FROM	[AdventureWorks2019].[Production].[Product]
WHERE	-- [Name] LIKE '%LOCK%'
		-- [Name] LIKE 'Internal Lock Washer _'
		-- [Name] LIKE '[a-c]%'
		-- [Name] LIKE '[ft]%'
		-- [Name] NOT LIKE '%[1-9]%'
		-- Name LIKE '[^WB]%'
		Name LIKE '[^WB][^DELH][^owua][^kedh][^ths-][^o ]%[^d.L]'
