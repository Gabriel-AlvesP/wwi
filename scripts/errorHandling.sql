use WWIGlobal
GO

CREATE OR ALTER PROCEDURE sp_insert_error_messages
AS
BEGIN
    IF NOT EXISTS (select * from dbo.Error)
    BEGIN
		INSERT INTO dbo.Error(ErrorId, ErrorMessage) 
		VALUES
        (51001, N'This error is new. Please, report it to the admin.'),

		(51002, N'Action `%s` does not exist.
        Actions available : insert / update / delete / all'),

        (51003, N'Table `%s` does not exist. Check the database table for more info.'),

        (51004, N'FK `%s` does not exist in `%s` table')
    END
END
GO
exec sp_insert_error_messages
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

--drop view all_fk_cols
--GO
CREATE VIEW all_fk_cols as 
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

CREATE OR ALTER PROCEDURE fk_validation
    @parent_table varchar(100),
    @parent_col   varchar(100),
    @param_val    int
AS
BEGIN

    IF EXISTS (select ReferencedTableName, ReferencedColumnName 
        from all_fk_cols fk 
        where ParentTableName = @parent_table and ReferencedColumnName = @parent_col
    )
    BEGIN
        declare @ref_schema varchar(100), @ref_table varchar(100), @ref_col varchar(100), @sql nvarchar(255) 

        select top 1 @ref_schema = SchemaName,  @ref_table = ReferencedTableName, @ref_col = ReferencedColumnName
            from all_fk_cols fk 
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