USE msdb;
GO

-- 1. Create the Job
EXEC dbo.sp_add_job 
    @job_name = N'Test_Read_Only_Job',
    @enabled = 1,
    @description = N'Safe test job that only reads system time and waits 5 seconds.';

-- 2. Add a Safe Read-Only Step
EXEC dbo.sp_add_jobstep 
    @job_name = N'Test_Read_Only_Job', 
    @step_name = N'Safe Read Query', 
    @subsystem = N'TSQL', 
    @command = N'
        -- Pure read-only operation
        SELECT GETDATE() AS CurrentExecutionTime, @@SERVERNAME AS ServerName;
        
        -- Optional: Simulate 5 seconds of work
        WAITFOR DELAY ''00:00:05'';
    ', 
    @database_name = N'master';

-- 3. Create a Schedule (Runs every 1 minute for testing)
EXEC dbo.sp_add_schedule 
    @schedule_name = N'Every1MinuteSchedule', 
    @freq_type = 4,           -- Daily
    @freq_interval = 1,       -- Every 1 day
    @freq_subday_type = 4,    -- Minutes
    @freq_subday_interval = 1; -- Every 1 minute

-- 4. Attach Schedule to Job
EXEC dbo.sp_attach_schedule 
    @job_name = N'Test_Read_Only_Job', 
    @schedule_name = N'Every1MinuteSchedule';

-- 5. Target the Local Server
EXEC dbo.sp_add_jobserver 
    @job_name = N'Test_Read_Only_Job';
GO