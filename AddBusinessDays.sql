/*
  Adds/subtracts a number of business days to a given date.
  This function assumes that business days are Monday-Friday.

  Examples:
    Adding 1 to a Friday, Saturday or Sunday returns the following Monday.
    Subtracting 1 from a Monday, Sunday or Saturday returns the preceding Friday.
    Adding 0 any date returns the date itself, regardless of whether it is a business day.
    Adding/subtracting a non-zero number to any date *always* returns a business day.
*/
CREATE FUNCTION [dbo].[AddBusinessDays](
      @daysToAdd int
    , @fromDate datetime
)
RETURNS DATETIME AS
BEGIN
    /*
        Determine @@DATEFIRST-independant integer value identifying the weekday.
        1=Monday, 2=Tuesday, ... 7=Sunday
    */
    DECLARE @startWeekday INT
    SET @startWeekday = ((DATEPART(weekday, @FromDate) + @@DATEFIRST + 5) % 7 + 1)

    /*
        Account for @fromDate being a Saturday (when moving forwards) or Sunday (when moving backwards).
        In these cases, add/subtract 1 to move past the following/preceding weekend day.
        This ensures that:
        - Adding 1 to a Saturday, returns the following Monday.
        - Subtracting 1 from a Sunday, returns the preceding Friday.
    */
    DECLARE @weekendModifier int
    SET @weekendModifier = 
        CASE
        WHEN SIGN(@daysToAdd) = -1 AND @startWeekday = 7 THEN -1 --Sunday, backward movement
        WHEN SIGN(@daysToAdd) = 1 AND @startWeekday = 6 THEN 1 --Saturday, forward movement
        ELSE 0 --No movement
        END

    RETURN
        @weekendModifier
        + DATEADD(day, 
            (@daysToAdd % 5)
            + CASE
                WHEN ((@@DATEFIRST + DATEPART(weekday, @fromDate)) % 7 + (@daysToAdd % 5)) > 6 THEN 2
                ELSE 0
                END,
            DATEADD(week, (@daysToAdd / 5), @fromDate))
END
