-- CREATE SCRIPT TO INDEX ALL FKs
select
    'CREATE INDEX [IX_' + replace(f.name, 'FK_', '') + '] ON [' + object_name(f.parent_object_id) + ']([' + col_name(fc.parent_object_id, fc.parent_column_id) + '])'
from sys.foreign_keys              f
inner join sys.foreign_key_columns fc on f.object_id = fc.constraint_object_id
where not exists (
    select
        *
    from sys.indexes i
    where i.name = 'IX_' + replace(f.name, 'FK_', '')
)

-- VIEW ALL INDEXES:
/*
select
    o.name
  , i.*
from sys.indexes i
join sys.objects o on o.object_id = i.object_id
order by
    o.name
  , i.name
*/