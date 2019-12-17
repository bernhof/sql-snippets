/*
    Source: https://github.com/bernhof/sql-util/

    Locates objects in SQL Server whose definitions contain the specified search term.
    Supports wild cards.
    If wild cards are used the procedure will not be able to count occurrences.
*/
CREATE proc [dbo].[Find] @lookFor varchar(max), @databaseName nvarchar(128) = null as
begin

    set nocount on
    set xact_abort on

    --declare @databaseName nvarchar(128) = null --if null, searches all databases
    --declare @lookFor varchar(max)
    --set @lookFor = 'akt'

    PRINT 'Locating ''' + @lookFor + ''' in object definitions...'

    create table #types (
        TypeId nvarchar(100),
        TypeDescription nvarchar(100))

    insert #types
    select 'AF', 'Aggregate function (CLR)' UNION ALL
    select 'C' , 'CHECK constraint' UNION ALL
    select 'D' , 'DEFAULT (constraint or stand-alone)' UNION ALL
    select 'F' , 'FOREIGN KEY constraint' UNION ALL
    select 'FN', 'SQL scalar function' UNION ALL
    select 'FS', 'Assembly (CLR) scalar-function' UNION ALL
    select 'FT', 'Assembly (CLR) table-valued function' UNION ALL
    select 'IF', 'SQL inline table-valued function' UNION ALL
    select 'IT', 'Internal table' UNION ALL
    select 'P' , 'SQL Stored Procedure' UNION ALL
    select 'PC', 'Assembly (CLR) stored-procedure' UNION ALL
    select 'PG', 'Plan guide' UNION ALL
    select 'PK', 'PRIMARY KEY constraint' UNION ALL
    select 'R' , 'Rule (old-style, stand-alone)' UNION ALL
    select 'RF', 'Replication-filter-procedure' UNION ALL
    select 'S' , 'System base table' UNION ALL
    select 'SN', 'Synonym' UNION ALL
    select 'SO', 'Sequence object' UNION ALL
    select 'SQ', 'Service queue' UNION ALL
    select 'TA', 'Assembly (CLR) DML trigger' UNION ALL
    select 'TF', 'SQL table-valued-function' UNION ALL
    select 'TR', 'SQL DML trigger' UNION ALL
    select 'TT', 'Table type' UNION ALL
    select 'U' , 'Table (user-defined)' UNION ALL
    select 'UQ', 'UNIQUE constraint' UNION ALL
    select 'V' , 'View' UNION ALL
    select 'X' , 'Extended stored procedure'


    create table #result (
        DatabaseName nvarchar(128),
        ObjectId nvarchar(max), 
        SchemaName nvarchar(128), 
        ObjectName nvarchar(128),
        ObjectDefinition nvarchar(max),
        ObjectType nvarchar(100))

    declare @databases table (
        Name nvarchar(128))

    begin try
        if (@databaseName is not null)
            insert @databases select @databaseName
        else
            insert @databases select name from sys.databases where name not in ('master', 'model', 'msdb', 'SSISDB', 'tempdb')
    end try
    begin catch
        print 'Cannot enumerate databases: ' + ERROR_MESSAGE() + '. Searching current DB instead.'
        insert @databases select DB_NAME()
    end catch

    declare @currentDatabaseName nvarchar(128)
    select @currentDatabaseName = MIN(Name) from @databases
    while @currentDatabaseName is not null
    begin
        PRINT N'Searching database ' + @currentDatabaseName + '...'

        declare @tablesSql nvarchar(max) = N'
            insert #result
            select *
            from (
                select
                    DatabaseName = ' + QUOTENAME(@currentDatabaseName, '''') + ',
                    ObjectId = cast(object_id as varchar(max)),
                    SchemaName = schema_name(schema_id),
                    ObjectName = Name,
                    ObjectDefinition = OBJECT_DEFINITION(object_id),
                    ObjectType = t.TypeDescription
                from
                    ' + QUOTENAME(@currentDatabaseName) + '.sys.objects o
                join
                    #types t on t.TypeId COLLATE Latin1_General_CI_AS_KS_WS = o.type COLLATE Latin1_General_CI_AS_KS_WS
                ) o
            where ObjectDefinition LIKE ''%'' + @lookForInner + ''%'''

        begin try
            exec sp_executesql @tablesSql, N'@lookForInner varchar(max)', @lookForInner = @lookFor
        end try
        begin catch
            PRINT 'Cannot search database ''' + @currentDatabaseName + ''': ' + ERROR_MESSAGE()
            insert #result (DatabaseName, ObjectName) values (@currentDatabaseName, '(Error: see messages)')
        end catch

        select @currentDatabaseName = MIN(Name) from @databases where Name > @currentDatabaseName
    end
 
    if @databaseName is null or @databaseName = 'MSDB'
    begin
        begin try
            insert #result 
            select
                'MSDB',
                cast(j.job_id as varchar(max)),
                null, -- schema
                j.name + ' (Step ' + cast(s.step_id as varchar(max)) + ': ' + s.step_name + ')',
                s.command,
                'Job'
            from
                msdb.dbo.sysjobsteps s
            join
                msdb.dbo.sysjobs j
                on s.job_id = j.job_id
        end try
        begin catch
            PRINT 'Could not search job definitions in MSDB: ' + ERROR_MESSAGE()
            insert #result (DatabaseName, ObjectName) values ('MSDB', '(Error: see messages)')
        end catch
    end

    -- Final result set:
    select
        DatabaseName,
        ObjectId,
        SchemaName,
        ObjectName,
        ObjectType,
        Occurrences = (DATALENGTH(ObjectDefinition)
                      -DATALENGTH(REPLACE(ObjectDefinition,@lookFor,'')))
                      / DATALENGTH(@lookFor) / 2 -- div by 2 because nvarchar counts double in data
    from #result
    order by ObjectName
    --order by Occurrences desc

    drop table #types
    drop table #result
end
