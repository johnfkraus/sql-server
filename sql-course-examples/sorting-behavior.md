## Sorting Behavior

Gemini:

By default, SQL Server's sorting behavior (whether upper and lower case letters are treated as identical) is determined by the **collation** of the column or database.

If your queries are treating `'A'` and `'a'` differently, you are using a **Case-Sensitive (`_CS`)** collation. You can make sorting case-insensitive using one of two methods:

---

### Method 1: Specify a Case-Insensitive Collation in the `ORDER BY` Clause

You can override the collation directly inside your query without changing table structures. Append `COLLATE` with a **Case-Insensitive (`_CI`)** collation—such as `Latin1_General_CI_AS` or `SQL_Latin1_General_CP1_CI_AS`—to the column in your `ORDER BY` clause.

```sql
SELECT EmployeeName
FROM Employees
ORDER BY EmployeeName COLLATE Latin1_General_CI_AS ASC;

```

---

### Method 2: Use `LOWER()` or `UPPER()` in the `ORDER BY` Clause

If you want a quick fix without referencing specific SQL Server collation names, force all values to lower or upper case before ordering:

```sql
SELECT EmployeeName
FROM Employees
ORDER BY LOWER(EmployeeName) ASC;

```

> **Performance Note:** Applying functions like `LOWER()` or using `COLLATE` in the `ORDER BY` clause prevents SQL Server from using existing indexes on that column for sorting. If case-insensitive sorting is a frequent requirement, consider permanently changing the column's default collation using:
> ```sql
> ALTER TABLE Employees 
> ALTER COLUMN EmployeeName VARCHAR(100) COLLATE Latin1_General_CI_AS;
> 
> ```
> 
>
To perform a case-sensitive sort in MS SQL Server, apply a **case-sensitive collation** directly to the column in your `ORDER BY` clause using the `COLLATE` keyword.

### Syntax

```sql
SELECT Column1, Column2
FROM YourTable
ORDER BY Column1 COLLATE Latin1_General_CS_AS;

```

### How Collation Flags Work

SQL Server collations use specific suffix flags to dictate sorting rules:

* **`CS` (Case-Sensitive):** Forces upper and lower case letters to be treated differently.
* **`AS` (Accent-Sensitive):** Ensures accents are respected (e.g., `e` and `é` are sorted differently).
* **`CI` / `AI`:** Case-Insensitive and Accent-Insensitive (the default in many installations).

### Examples

Assuming a table `Users` with a column `Username` containing `['alpha', 'Alpha', 'BETA', 'beta']`:

#### 1. Standard Case-Sensitive Sort

Most common SQL Server case-sensitive collation:

```sql
SELECT Username
FROM Users
ORDER BY Username COLLATE Latin1_General_CS_AS;

```

#### 2. Binary Collation (Strict ASCII / Code Point Order)

If you want standard ASCII order where **all** uppercase letters come before **all** lowercase letters (e.g., `Alpha`, `BETA`, `alpha`, `beta`):

```sql
SELECT Username
FROM Users
ORDER BY Username COLLATE Latin1_General_100_BIN2;

```

> **Note:** Binary collations (`_BIN2`) sort strictly by numerical code point values, making them the fastest option for sorting performance.

### Checking Your Server's Current Collation

If you want to check what collation your database or column uses by default:

```sql
SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS DatabaseCollation;

```