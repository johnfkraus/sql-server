SELECT @@SERVERNAME AS [ServerName];

-- Returns the server (and instance) name as registered in sys.servers
SELECT @@SERVERNAME AS [ServerName];

-- Returns the actual machine name (useful if renamed after installation)
SELECT SERVERPROPERTY('ServerName') AS [ServerProperty_ServerName],
       SERVERPROPERTY('MachineName') AS [MachineName],
       SERVERPROPERTY('InstanceName') AS [InstanceName];