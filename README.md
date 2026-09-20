udemy



Note: AdventureWorks2019.bak file is large and is gitignored
Note: "password" is a fake password.

docker pull mcr.microsoft.com/mssql/server:2022-latest

docker run --platform=linux/amd64 \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=password" \
  -e "MSSQL_PID=Developer" \
  -p 1433:1433 \
  --name sqlserver \
  -d mcr.microsoft.com/mssql/server:2022-latest

container id:

e08865bda7d66ef0da15b7a2844929fd8c5202b70136cef7ce84ebaa22a49cfa


docker cp /path/to/AdventureWorks2019.bak <container_id_or_name>:/var/opt/mssql/data/

docker cp /Users/blauerbock/Downloads/AdventureWorks2019.bak e08865bda7d66ef0da15b7a2844929fd8c5202b70136cef7ce84ebaa22a49cfa:/var/opt/mssql/data/ 

docker exec -it e08865bda7d66ef0da15b7a2844929fd8c5202b70136cef7ce84ebaa22a49cfa bash

ls -la /var/opt/mssql/data/

RESTORE DATABASE AdventureWorks2019
FROM DISK = '/var/opt/mssql/data/AdventureWorks2019.bak'
WITH MOVE 'AdventureWorks2019' TO '/var/opt/mssql/data/AdventureWorks2019.mdf',
     MOVE 'AdventureWorks2019_log' TO '/var/opt/mssql/data/AdventureWorks2019_log.ldf',
     REPLACE;

/opt/mssql-tools18/bin/sqlcmd (or /opt/mssql-tools/bin/sqlcmd in older versions).

use sqlcmd:


/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "password" -C


RESTORE DATABASE AdventureWorks2019
FROM DISK = '/var/opt/mssql/data/AdventureWorks2019.bak'
WITH MOVE 'AdventureWorks2019' TO '/var/opt/mssql/data/AdventureWorks2019.mdf',
     MOVE 'AdventureWorks2019_log' TO '/var/opt/mssql/data/AdventureWorks2019_log.ldf',
     REPLACE;



Brave logo
how to run a sql command in visual studio code with sql server extension


To run a SQL command in Visual Studio Code with the SQL Server extension, first ensure the mssql extension is installed and you have opened a file with the .sql extension or set the language mode to SQL (using Ctrl+K, M).  You must then establish a connection to your database via the Command Palette (Ctrl+Shift+P) by selecting MS SQL: Connect and creating a new connection profile if one does not exist. 

Once connected, you can execute your query using one of the following methods:

Execute Selected/Current Statement: Press Ctrl+Shift+E (Windows/Linux) or Cmd+Shift+E (macOS) to run the query under your cursor or the currently selected text. 
Execute All Queries: Use the Command Palette (F1) and select MS SQL: Execute Query to run the entire contents of the open file. 
Toolbar Button: Click the Run Query icon (play button) located in the top-right corner of the editor window. 
Results will appear in a new window below the editor, and you can save these results as CSV or JSON files from the results pane. 

AI-generated answer. Please verify critical facts.
Elaborate
How do I save query results to a file?
How can I format SQL code in VS Code?
How do I edit my saved connection profiles?


Ask a follow-up question

🌐
Microsoft Learn
learn.microsoft.com › en-us › sql › tools › visual-studio-code-extensions › mssql › mssql-extension-visual-studio-code
Overview - MSSQL Extension for Visual Studio Code | Microsoft Learn
2 weeks ago - Open Visual Studio Code. Select the Extensions icon in the Activity Bar (Cmd+Shift+X on macOS, or Ctrl+Shift+X on Windows and Linux). In the search bar, type mssql. Find SQL Server (mssql) in the results and select it.
🌐
Microsoft Learn
learn.microsoft.com › en-us › sql › tools › visual-studio-code-extensions › mssql › connect-database-visual-studio-code
Quickstart: Run Your First Query - MSSQL Extension for Visual Studio Code | Microsoft Learn
April 23, 2026 - MSSQL extension for Visual Studio Code: In Visual Studio Code, open the Extensions view by selecting the Extensions icon in the Activity Bar on the side of the window. Search for mssql and select Install to add the extension.
Discussions
How to properly execute SQL code on VSCode?

🌐r/vscode
3
4
December 18, 2023
postgresql - How to run SQL query in visual Studio Code - Stack Overflow

🌐stackoverflow.com
How do I use SQL database in Visual Studio?

🌐r/learnprogramming
28
31
July 24, 2014
Is there an IDE, or any extensions for Visual Studio Code, that can help me with SQL queries that are written terribly?

🌐r/SQL
36
36
October 24, 2023

Show more

🌐
Visual Studio Code
code.visualstudio.com › docs › languages › tsql
Transact-SQL in Visual Studio Code
November 3, 2021 - Open the Extensions view from VS Code Side Bar (⇧⌘X (Windows, Linux Ctrl+Shift+X)). Type "mssql" in the search bar, click Install, and reload VS Code when prompted. Easily connect to SQL Server running on-premises, in any cloud, Azure SQL ...

🌐
Visual Studio Marketplace
marketplace.visualstudio.com › items
SQL Server (mssql) - Visual Studio Marketplace
5 days ago - Extension for Visual Studio Code - Design and optimize schemas for SQL Server, Azure SQL, and SQL Database in Fabric using a modern, lightweight extension built for developers
🌐
SQL Shack
sqlshack.com › visual-studio-code-vs-code-for-sql-server-development
Visual Studio Code (VS Code) for SQL Server development
July 16, 2020 - Visual Studio Code also supports these features for the SQL Server database. Right-click on the desired table, and you get these options. ... VS code SQL Server extension also supports executing queries in SQLCMD mode.

🌐
GitHub
github.com › microsoft › vscode-mssql › wiki › getting-started › 18d55bdb458a0f94ab2e47e4cb104f39b4731c3b
getting started · microsoft/vscode-mssql Wiki
First, install Visual Studio Code and start it. Then install the mssql extension by pressing cmd+shift+p or F1 to open the command palette in Visual Studio Code, select Install Extenion and choose mssql.

Author: microsoft
🌐
SQLServerCentral
sqlservercentral.com › home › articles › working with sql server in visual studio code
Working with SQL Server in Visual Studio Code – SQLServerCentral
June 17, 2024 - For example, you could create tables, run a select, run system-stored procedures, or run any T-SQL sentence. Disconnect will disconnect Visual Studio code from the database.

🌐
Microsoft Learn
learn.microsoft.com › en-us › azure › azure-sql › database › connect-query-vscode
Use Visual Studio Code to connect and query - Azure SQL Database & SQL Managed Instance | Microsoft Learn
2 weeks ago - Open Visual Studio Code. Open the Extensions pane (or Ctrl + Shift + X). Search for sql and then install the SQL Server (mssql) extension.
🌐
DZone
dzone.com › data engineering › databases › sql with visual studio code
SQL With Visual Studio Code
November 8, 2017 - Let's look at how to get it all set up. Create a new file and set the language type to SQL (press CTRL + K + M). Open the command palette with CTRL + SHIFT + P and type SQL to show the MS SQL commands.

Find elsewhere
Google
Bing
Mojeek
🌐
SQLServerCentral
sqlservercentral.com › home › blog posts › running sql queries with visual studio code
Running SQL Queries with Visual Studio Code – SQLServerCentral
January 5, 2017 - Code works on Windows, Linux and Mac · Once you have downloaded and installed hit CTRL SHIFT and P which will open up the command palette · Once you start typing the results will filter so type ext and then select Extensions : Install Extension

🌐
Dynamics Community
community.dynamics.com › blogs › post
How Do I: Use Visual Studio Code instead of SSMS?
Once you have downloaded and installed VSCode (download it here), you need to add the mssql extension in Visual Studio Code, which you can find here. Then create a new file in VSCode and give it the extension .sql. The mssql extension enables mssql commands and T-SQL IntelliSense in the editor ...
🌐
DEV Community
dev.to › funkysi1701 › sql-with-visual-studio-code-1k3p
SQL with Visual Studio Code - DEV Community
January 27, 2020 - Lets look at how to get it all set up. Create a new file and set the language type to SQL (Press CTRL+K,M ) Open the command palette, *CTRL+SHIFT+P * and type SQL to show the mssql commands.

🌐
GitHub
github.com › microsoft › vscode-mssql
GitHub - microsoft/vscode-mssql: Visual Studio Code SQL Server extension. · GitHub
Run queries by selecting MS SQL: Execute Query from the Command Palette (F1), or use the shortcut: ... Customize shortcuts via the command palette or in your settings.json. See customize shortcuts for help.

Author: microsoft
🌐
Reddit
reddit.com › r/vscode › how to properly execute sql code on vscode?
r/vscode on Reddit: How to properly execute SQL code on VSCode?
December 18, 2023 - I have set up the SQL server extension on VSCode, however there is an issue with executing SQL code on it. Current I need to do right-click on existing table and then "select top 1000", which generates a sample code and results. As below I can rerun the SQL, or write/paste my actual SQL code and use the green triangle to run the new query. However, if I use the white triangle or if I save a .sql file and reopening it, I get the "Error Not connected" when I use the white triangle, and there is no green triangle button if I just open the SQL script. What are the proper way to run a .sql on VSCode?
Top answer
1 of 1
2
I know this isnt your question but microsoft make azure data studio. Its a SQL client written in electron ... why would you want to do this in VSCode instead of a dedicated SQL client?
🌐
LaunchCode
education.launchcode.org › data-analysis-curriculum › installations › install-vscode-sql › index.html
Setting Up Visual Studio Code for SQL :: Data Analysis Curriculum
February 12, 2024 - This setup allows us to connect ... Visual Studio Code installed . Open Visual Studio Code and go to the Extensions view by clicking the Extensions icon in the Activity Bar or pressing Ctrl+Shift+X (Windows/Linux) or Cmd+Shift+X (Mac)....
🌐
Microsoft Learn
learn.microsoft.com › en-us › sql › tools › visual-studio-code-extensions › mssql › mssql-extension-visual-studio-code
Overview of the MSSQL Extension for Visual Studio Code - SQL Server | Microsoft Learn
Open Visual Studio Code. Select the Extensions icon in the Activity Bar (Cmd+Shift+X on macOS, or Ctrl+Shift+X on Windows and Linux). In the search bar, type mssql. Find SQL Server (mssql) in the results and select it.
🌐
Windows OS Hub
woshub.com › connect-sql-vscode
Connect to MS SQL Server Database in Visual Studio Code | Windows OS Hub
March 15, 2024 - If you already have VSCode installed on your computer, all you need to do is download and install the mssql extension (https://marketplace.visualstudio.com/items?itemName=ms-mssql.mssql): Go to Extension (Ctrl+Shift+X) and search for mssql; ... ...

🌐
Stack Overflow
stackoverflow.com › questions › 72743136 › how-to-run-sql-query-in-visual-studio-code
postgresql - How to run SQL query in visual Studio Code - Stack Overflow
Top answer
1 of 1
5
You could use an extension that allows you to connect to a local/remote database and execute SQL commands through VSC. I've used Database Client in the past, and was satisfied with the result. It could also format .sql files and allows you to run queries from straight from a file as well.
🌐
SQLServerCentral
sqlservercentral.com › home › articles › how well does the mssql extension in vscode work?
How Well Does the MSSQL Extension in VSCode Work? – SQLServerCentral
September 22, 2025 - I assume this is some default stuff from VS Code and because I have PostgreSQL and SQL Server extensions, the ".sql" type is pulling in both items. If I type a query, things change slightly. Here I'll add a little code for the server info. Notice that I now have a "run" with some optional items (Tab, JSON and Ask AI).

🌐
Dynamics Community
community.dynamics.com › blogs › post
Using Visual Studio Code to Interact with SQL
January 18, 2017 - Simply click on the reload button and VS Code will do this automatically. The window will reload and be blank. So now that we have the SQL extension installed, lets run some scripts! To stat this process you can hit CTRL-SHIFT-P to bring up the command line for VS Code.


how to run a sql command in visual studio code with sql server extension - Brave Search



9/5/26

You can exec into the mssql container in the Docker desktop app.  Select container on the left, then click on the Exec tab.

Click the Files tab to see the file directory tree.

MS SQL Server Management Studio

I have MS SQL Server running in a docker container on my MacBook Pro.  I am trying to complete coursework 
from an online course that uses MS SQL Server Management Studio.  Is MS SQL Server Management Studio 
available for MacOS?  If not, what should I use?


			"MSSQL_SA_PASSWORD=password",
