On MacOS, With Visual Studio Code, using MS SQL Server running in Podman, I want to back up a database.  How?


To back up a SQL Server database running inside a Podman container on macOS using Visual Studio Code, execute the `BACKUP DATABASE` T-SQL command directly from VS Code and copy the `.bak` file out of the container to your Mac's filesystem.

---

### Step 1: Open VS Code with SQL Server Extension

1. Ensure the **SQL Server (mssql)** extension by Microsoft is installed in VS Code.
2. Open the **SQL Server** panel from the VS Code sidebar and connect to your containerized instance (typically `localhost,1433` using the `sa` account).

---

### Step 2: Create a Container Backup Directory

Run a terminal command to ensure a target folder exists inside the SQL Server container:

```bash
podman/docker exec -it <container_name_or_id> mkdir -p /var/opt/mssql/backup

docker exec -it e08865bda7d66ef0da15b7a2844929fd8c5202b70136cef7ce84ebaa22a49cfa mkdir -p /var/opt/mssql/backup

```

*(Replace `<container_name_or_id>` with your container name, e.g., `sql2022` or `mssql`)*.

---

### Step 3: Run the Backup T-SQL Query in VS Code

1. Open a **New Query** window (`Cmd + N` followed by setting the language mode to SQL, or right-clicking your connection in the MSSQL panel and selecting **New Query**).
2. Execute the following T-SQL command to perform the backup:

```sql
BACKUP DATABASE [YourDatabaseName]
TO DISK = N'/var/opt/mssql/backup/YourDatabaseName.bak'
WITH FORMAT,
     MEDIANAME = 'SQLServerBackups',
     NAME = 'Full Backup of YourDatabaseName';
GO

```

```sql
BACKUP DATABASE [psp5]
TO DISK = N'/var/opt/mssql/backup/psp5.bak'
WITH FORMAT,
     MEDIANAME = 'SQLServerBackups',
     NAME = 'Full Backup of psp5';
GO

```

---

### Step 4: Copy the Backup File to Your Mac

To bring the backup file onto your host macOS file system, open your local terminal (or VS Code's integrated terminal) and run:

```bash
podman cp <container_name_or_id>:/var/opt/mssql/backup/YourDatabaseName.bak ~/Desktop/YourDatabaseName.bak

```

---