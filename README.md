# SQL utilities
Functionality, behaviour and attribution (where applicable) is described within each script.

* [Add Business Days](https://github.com/bernhof/sql-util/blob/master/add-business-days.sql) - Adds a number of business days to a date. Assumes business days Mon-Fri. I found many examples of similar functionality, but many didn't handle edge cases or odd input values properly. This scripts represents the best parts and some modifications to ensure simple, predictable behaviour.

* [Create Index For All Foreign Keys](https://github.com/bernhof/sql-util/blob/master/create-index-for-all-foreign-keys.sql) - Basic script that generates CREATE INDEX statements for all missing foreign key indexes.

* [Find](https://github.com/bernhof/sql-util/blob/master/find.sql) - Stored proc for searching for terms within procedures, functions or other objects in SQL Server. Supports wildcards and can search multiple databases if user has sufficient permissions. The script came as a result of working with large, messy databases with tons of tables, functions, SPs etc., where I needed to locate all references to certain objects (even in strings within a function) across many databases.

* [Calendar](https://github.com/bernhof/sql-util/blob/master/get-calendar.sql) table-valued function that generates dates in a certain interval and culture.
