# SQL Cheatsheet

## Decimal data type

In MS SQL Server, the DECIMAL and NUMERIC data types are functionally identical synonyms used to store exact, fixed-precision numeric values. They are critical for applications requiring absolute accuracy, such as financial and monetary data. [1] (https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17), [2] (https://www.geeksforgeeks.org/sql-server/sql-server-decimal-data-type/)

Syntax

```sql
DECIMAL (precision [, scale])
```
Use code with caution.
• precision (p): The maximum total number of digits that can be stored (including digits on both sides of the decimal point). It ranges from 1 to 38 (default is 18). [1] (https://www.sqlshack.com/understanding-sql-decimal-data-type/)
• scale (s): The maximum number of digits stored to the right of the decimal point. This value must be between 0 and the specified precision (default is 0). Scale can only be specified if precision is defined. [1] (https://www.dofactory.com/sql/decimal), [2] (https://www.promotic.eu/en/pmdoc/Subsystems/Db/MsSQL/DataTypes.htm), [3] (https://www.sqlshack.com/understanding-sql-decimal-data-type/)

Direct Behavior & Storage Impact

The physical storage requirements vary dynamically depending on the declared precision: [1] (https://www.dofactory.com/sql/decimal)

Precision	Storage Bytes
1 – 9	5 bytes
10 – 19	9 bytes
20 – 28	13 bytes
29 – 38	17 bytes


Practical Verification Example

Consider how SQL Server allocates digits based on your configuration:

• DECIMAL(5,2) can hold a maximum of 5 digits total, with exactly 2 to the right of the decimal point (e.g., -999.99 to 999.99).

• Trying to insert 1234.56 into a DECIMAL(5,2) column will trigger an arithmetic overflow error because it requires 4 digits before the decimal and 2 after, totaling 6 digits. [1] (https://www.geeksforgeeks.org/sql-server/sql-server-decimal-data-type/), [2] (https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17)

• If you insert a value with more decimal places than the defined scale (e.g., inserting 123.456 into a DECIMAL(5,2) column), SQL Server will automatically round the value to 123.46. [1] (https://www.sqlservercentral.com/forums/topic/understanding-the-numeric-and-decimal-data-types), [2] (https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17)

Important Considerations

• Different Data Types: SQL Server treats every unique combination of precision and scale as a distinct data type. For example, DECIMAL(10,2) and DECIMAL(10,4) are considered completely separate types during operations. [1] (https://learn.microsoft.com/en-us/sql/t-sql/data-types/decimal-and-numeric-transact-sql?view=sql-server-ver17)
• Default Behavior: If you write DECIMAL without parameters, it evaluates to DECIMAL(18,0). [1] (https://www.sqlshack.com/understanding-sql-decimal-data-type/)
If you are setting up a database schema, let me know:
• What kind of data are you looking to store? (e.g., currency, precise scientific metrics, percentages)
• Do you need help calculating the ideal precision and scale for your specific range of values?




## Using ms sql server, how does the money data type differ from other numeric types that might be used to represent monetary amounts?

In SQL Server, the `MONEY` (and `SMALLMONEY`) data type differs from alternative numeric types—specifically `DECIMAL`/`NUMERIC` and `FLOAT`—in storage implementation, precision behavior, performance, and formatting.

## Core Comparison Matrix

| Feature / Behavior | `MONEY` | `DECIMAL(p, s)` / `NUMERIC(p, s)` | `FLOAT` / `REAL` |
| --- | --- | --- | --- |
| **Internal Storage** | 8-byte integer (scaled by 10,000) | 5 to 17 bytes (depends on precision $p$) | 4 or 8 bytes (binary floating-point) |
| **Fixed Scale** | Fixed strictly at **4 decimal places** | Variable (user-defined $0$ to $38$) | Dynamic / Approximate |
| **Data Nature** | Exact integer scale | Exact decimal scale | Approximate representation |
| **Rounding Risks** | **High** during intermediate calculations | Controlled precision | High due to floating-point representation |

---

## Key Technical Differences

### 1. Calculation Rounding Errors (The Biggest Drawback)

Because `MONEY` is implemented internally as an integer scaled by 10,000, intermediate calculations involving division or multiplication can suffer from truncation and precision loss before the final result is evaluated.

```sql
-- MONEY division rounding example
DECLARE @m1 MONEY = 10.00, @m2 MONEY = 3.00;
SELECT (@m1 / @m2) * @m2; 
-- Result: 9.9999 (Precision loss due to intermediate 4-decimal truncation)

-- DECIMAL precision safety
DECLARE @d1 DECIMAL(19,4) = 10.00, @d2 DECIMAL(19,4) = 3.00;
SELECT (@d1 / @d2) * @d2; 
-- Result: 10.00000000

```

### 2. Fixed vs. Customizable Scale

* **`MONEY`**: Fixed at 4 decimal digits after the decimal point. If your application needs sub-cent rates (e.g., micro-transactions, currency exchange rates with 6 digits, or fuel pricing), `MONEY` cannot store those values directly without rounding.
* **`DECIMAL(p, s)`**: Allows you to explicitly define total digits ($p$) and decimal scale ($s$). For financial systems, `DECIMAL(19,4)` or `DECIMAL(18,2)` is standard practice.

### 3. Currency Symbols & Implicit Conversions

SQL Server allows literals prefixed with currency symbols (e.g., `$100.50`, `£50.00`) to implicitly convert to `MONEY`. However, `MONEY` does **not** store locale or currency code metadata (e.g., USD vs. EUR); it stores only the numeric quantity.

### 4. Storage & Performance Characteristics

Because `MONEY` uses an 8-byte integer under the hood, basic arithmetic operations (addition/subtraction) can be slightly faster than CPU operations on variable-length `DECIMAL` types. However, on modern hardware, this micro-optimization rarely outweighs the risk of calculation precision errors.

---

## Best Practices Recommendation

* **Avoid `MONEY` for complex calculations:** Most SQL database administrators and financial software developers avoid `MONEY` because of its tendency to produce silent rounding errors in intermediate steps (such as applying tax rates or discounts).
* **Use `DECIMAL(p, s)`:** Use `DECIMAL(19,4)` for general financial data to maintain accuracy across multi-step calculations, or `DECIMAL(18,2)` when strict two-decimal currency precision is required.