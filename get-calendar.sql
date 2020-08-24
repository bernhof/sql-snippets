create function dbo.GetCalendar (
    @startDate date, 
    @endDate date,
    @culture nvarchar(5) = 'da-DK')
returns table as
return
    with
        t0(i) AS (SELECT 0 UNION ALL SELECT 0), -- 2
        t1(i) AS (SELECT 0 FROM t0 a, t0 b), -- 4
        t2(i) AS (SELECT 0 FROM t1 a, t1 b), -- 16
        t3(i) AS (SELECT 0 FROM t2 a, t2 b), -- 256
        t4(i) AS (SELECT 0 FROM t3 a, t3 b), -- 65.536
        n(i) AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT 0))-1 FROM t4)
    select
        d                             as [Date],
        year(d)                       as [Year],
        month(d)                      as [Month],
        datepart(quarter,d)           as [Quarter],
        day(d)                        as [Day],
        format(d, 'MMMM', @culture)   as [MonthName],
        format(d, 'MMM', @culture)    as [MMM],
        datepart(weekday,d)           as [DayOfWeek],
        format(d, 'dddd', @culture)   as [DayName],
        datepart(iso_week,d)          as [Week]
    from (
        select d = dateadd(day, i, @startDate) from n
        where i between 0 and (datediff(day, @startDate, @endDate))) d
