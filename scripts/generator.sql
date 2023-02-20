use WWIGlobal
GO

CREATE OR ALTER PROCEDURE sp_generate_action
	@table_name varchar(100) = 'systemuser',
	@action     varchar(100) = 'insert'
AS
BEGIN
    set nocount on
    set @table_name = LOWER(@table_name)
	set @action     = LOWER(@action)
    DECLARE @msg varchar(255) = FORMATMESSAGE(51000, @action)

    IF @action <> 'insert' and @action <> 'delete' and @action <> 'update'
    BEGIN
        exec sp_throw_error 51002, 1, @action
    END

    IF NOT EXISTS (
        SELECT o.name as 'TableName'
        FROM sys.all_objects as o
        WHERE LOWER(o.name) = @table_name AND o.type = 'U'
    )
    BEGIN
        exec sp_throw_error 51003, 1, @table_name 
    END

    --DECLARE 
        --@schema varchar(100),

    

    -- table_name to lower
    -- check if table exists
    -- get table schema
    -- action to lower

END
GO

exec sp_generate_action 'adsf', 'insert';
GO