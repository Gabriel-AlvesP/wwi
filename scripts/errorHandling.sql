use WWIGlobal
GO

CREATE OR ALTER PROCEDURE sp_insert_errorMessages
AS
BEGIN
    IF NOT EXISTS (select * from dbo.Error)
    BEGIN
		INSERT INTO dbo.Error(ErrorId, ErrorMessage) 
		VALUES
        (51001, 'This error is new. Please, report it to the admin.'),

		(51002, 'Action `%s` does not exist.
        Actions available : insert / update / delete / all'),

        (51003, 'Table `%s` does not exist. Check the database table for more info.'),

        (51004, 'FK `%s` does not exist in `%s` table'),

        (51005, 'PK `%s` does not exist in `%s` table'),

        (51006, 'An unexpected error occurred, for more information check the logs'),

        (51007, 'The `%s` value already exists in `%s`.'),


        -- Business Logic
        (52001, 'A sale can only have 1 type of chiller/dry product'),

        (52000, 'Customer `%s` does not exists.'),

        (52101, 'Email cannot be null or empty.'),

        (52102, 'This email `%s` is already in use.'),

        (52103, 'Password must have at least 8 characters.')

    END
END
GO
exec sp_insert_errorMessages
GO

CREATE OR ALTER PROCEDURE sp_throw_error
@errorId int = 1,
@state int = 1,
@param1 varchar(100) = null,
@param2 varchar(100) = null
AS
BEGIN
    IF EXISTS (select errorId from dbo.Error where @errorId = errorId)
    BEGIN
        DECLARE @msg varchar(255) 
        select @msg = errorMessage from dbo.Error where @errorId = errorId
        
        IF @param1 is not null 
        BEGIN 
            if @param2 is not null
            begin
                set @msg = FORMATMESSAGE(@msg,@param1, @param2)
            end
            else
            begin
                set @msg = FORMATMESSAGE(@msg,@param1)
            end
        END
        ELSE
        BEGIN
            set @msg = FORMATMESSAGE(@msg)
        END
         
        INSERT INTO dbo.ErrorLogs(ErrorId, Username) VALUES(@errorId, CURRENT_USER)
        ;THROW @errorId , @msg, @state 
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT errorId FROM dbo.Error)
        BEGIN 
            ;THROW 51000, 'Something went wrong. Try again later.', 1
        END
        ELSE
        BEGIN
            exec sp_throw_error 51001
        END
    END
END
GO

--drop view vw_all_fk_cols
--GO
CREATE VIEW vw_all_fk_cols as 
SELECT 
    t_parent.name AS ParentTableName
    , c_parent.name AS ParentColumnName
    , SCHEMA_NAME(t_child.schema_id) as SchemaName
    , t_child.name AS ReferencedTableName
    , c_child.name AS ReferencedColumnName
FROM sys.foreign_keys fk 
INNER JOIN sys.foreign_key_columns fkc
    ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.tables t_parent
    ON t_parent.object_id = fk.parent_object_id
INNER JOIN sys.columns c_parent
    ON fkc.parent_column_id = c_parent.column_id  
    AND c_parent.object_id = t_parent.object_id 
INNER JOIN sys.tables t_child
    ON t_child.object_id = fk.referenced_object_id
INNER JOIN sys.columns c_child
    ON c_child.object_id = t_child.object_id
    AND fkc.referenced_column_id = c_child.column_id
GO

--drop view vw_all_pk_cols
--GO
CREATE VIEW vw_all_pk_cols 
AS
SELECT s.name as schemaName, t.name as tableName, c.name as columnName --, ic.index_column_id as keyColumnNum
FROM sys.index_columns ic
    inner join sys.columns c on ic.object_id = c.object_id and ic.column_id = c.column_id
    inner join sys.indexes i on ic.object_id = i.object_id and ic.index_id = i.index_id
    inner join sys.tables t on i.object_id = t.object_id
    inner join sys.schemas s on t.schema_id = s.schema_id
    where i.is_primary_key= 1;
GO

--drop VIEW vw_unique_cols
-- Unique constraints
CREATE VIEW vw_unique_cols
as
select cc.TABLE_NAME as tableName, CC.Column_Name as columnName
from information_schema.table_constraints TC
inner join information_schema.constraint_column_usage CC 
on TC.Constraint_Name = CC.Constraint_Name
where TC.constraint_type = 'Unique'
GO

CREATE OR ALTER PROCEDURE sp_validate_fk
    @parent_table varchar(100),
    @parent_col   varchar(100),
    @param_val    int
AS
BEGIN

    IF EXISTS (select ReferencedTableName, ReferencedColumnName 
        from vw_all_fk_cols fk 
        where ParentTableName = @parent_table and ReferencedColumnName = @parent_col
    )
    BEGIN
        declare @ref_schema varchar(100), @ref_table varchar(100), @ref_col varchar(100), @sql nvarchar(255) 

        select top 1 @ref_schema = SchemaName,  @ref_table = ReferencedTableName, @ref_col = ReferencedColumnName
            from vw_all_fk_cols fk 
            where ParentTableName = @parent_table and ReferencedColumnName = @parent_col

        set @sql = concat('declare @count int 
        set @count = (select count(*) from ' , @ref_schema , '.' , @ref_table , ' where ' , @ref_col ,' = ' , @param_val , ') 
            IF @count = 0
            begin
            exec sp_throw_error 51004, 1, ' , @param_val , ', ' , @ref_table , ' end')
        
        exec sp_executesql @sql
    END
END
GO

CREATE OR ALTER PROCEDURE sp_validate_pk
    @table varchar(100),
    @col   varchar(100),
    @param_val    int
AS
BEGIN

    IF EXISTS (select tablename
        from vw_all_pk_cols fk
        where tablename = @table and columnname = @col
    )
    BEGIN
        declare @schema varchar(100),  @sql nvarchar(255) 

        select top 1 @schema = schemaname
            from vw_all_pk_cols pk 
            where tablename = @table and columnname = @col

        set @sql = concat('declare @count int 
        set @count = (select count(*) from ' , @schema , '.' , @table , ' where ' , @col ,' = ' , @param_val , ') 
            IF @count = 0
            begin
            exec sp_throw_error 51005, 1, ' , @param_val , ', ' , @table , ' end')
        
        exec sp_executesql @sql
    END
    
END
GO