create view [dbo].[nagiosstatus] as
with
jobProperties as (
	select 
		/* ENTER PROPERTIES HERE */

		  job_name = 'NAME OF JOB'
		, max_minutes_between_runs = 28 * 60 --28 hours
		, nagios_title = 'TITLE TO DISPLAY IN CHECK MK'

		/* WHAT FOLLOWS SHOULD NOT VARY BETWEEN USAGES */
)
select
	nagiosstatus = case
		when scheduled_execution_delayed = 1 and successful = 1 then 1 --warning
		when executed_at_least_once = 0 then 1 --warning (never executed)
		when successful = 0 then 2 --error (job failed)
		else 0 end --success
	, nagiostext = case
		when successful = 0 then isnull(message + ' ', '')
		when scheduled_execution_delayed = 1 then 'Job has not run recently. '
		else '' end
		+ isnull('Last run was: ' + run_date_text + '. Duration: ' + run_duration_text, 'Job has never run.')
	, nagiostitle = nagios_title
from (
	select top 1
		scheduled_execution_delayed = iif(datediff(minute, run_date_time, sysdatetime()) > max_minutes_between_runs, 1, 0)
		, executed_at_least_once = iif(run_date_time is not null, 1, 0)
		, run_date_text = convert(nvarchar, run_date_time, 120)
		, run_duration_text
		, successful = iif(run_status = 1, 1, 0)
		, message
		, nagios_title
	from (
		select
			instance_id
			, step_id
			, run_status
			, message
			-- NOTE: We can't use msdb.dbo.agent_datetime to convert date/time due to restrictive permissions.
			-- Avoiding it allows us to read data about jobs with only the db_datareader role membership.
			, run_date_time = DATEADD(second,
				cast(left(run_time_text, 2) as int) * 60 * 60
				+ cast(substring(run_time_text, 3, 2) as int) * 60
				+ cast(right(run_time_text, 2) as int)
				, run_date2)
			, run_duration_text = left(run_duration_text, 2) + ':' + substring(run_duration_text, 3, 2) + ':' + right(run_duration_text, 2)
			, previous_instance_id = lag(instance_id, 1, 0) over (order by instance_id)
			, p.nagios_title
			, p.max_minutes_between_runs
		from msdb.dbo.sysjobs j
		cross apply (select * from jobProperties) p
		join (	
			select *
				, run_date2 = cast(cast(cast(run_date as varchar) as date) as datetime2)
				, run_time_text = replace(str(run_time, 6), ' ', '0')
				, run_duration_text = replace(str(run_duration, 6), ' ', '0')
			from msdb.dbo.sysjobhistory
		) latest_run on j.job_id = latest_run.job_id
		where 
			j.name = p.job_name
			and step_id = 0 --outcome
	) x
	order by run_date_time desc
) x
