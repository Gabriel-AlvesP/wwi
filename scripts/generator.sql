use WWIGlobal
GO

CREATE OR ALTER PROCEDURE sp_generate_action
	@tableName varchar(100) = 'systemuser',
	@action     varchar(100) = 'all'
AS
BEGIN
    set nocount on
    set @tableName = LOWER(@tableName)
	set @action     = LOWER(@action)
    DECLARE @msg varchar(255) = FORMATMESSAGE(51000, @action)

    IF @action <> 'insert' and @action <> 'delete' and @action <> 'update' and @action <> 'all'
    BEGIN
        exec sp_throw_error 51002, 1, @action
    END

    IF NOT EXISTS (
        SELECT name 
        FROM sys.Tables 
        WHERE LOWER(name) = @tableName
    )
    BEGIN
        exec sp_throw_error 51003, 1, @tableName 
    END

    -- DECLARATION
    DECLARE @schema     varchar(255),
    @col_id          int,
    @col_name        varchar(100),
    @col_type        varchar(20),
    @col_len         int, 
    @col_precision   int,
    @col_null        bit,
    @col_identity    bit,
    @sql             varchar(max),
    @sql_params      varchar(max),
    @sql_body        varchar(max),
    @first_run       bit
        
    -- INITIALIZATION
    select @schema = s.name from sys.schemas s inner join sys.tables t on s.schema_id = t.schema_id where LOWER(t.name) = @tableName

    ----------------------------
    ---- Insert 
    ----------------------------

    IF @action = 'insert' or @action = 'all'
    BEGIN
        set @sql = 'CREATE OR ALTER PROCEDURE '+ CONCAT_WS('_', @tableName,'insert') 
        set @sql_body += N' AS BEGIN INSERT INTO ' + @tableName + ' VALUES ('
        set @first_run = 1

	    DECLARE gen_cur CURSOR FOR 
	    SELECT c.column_id, c.name, TYPE_NAME(c.user_type_id), c.max_length, c.[precision], c.is_nullable
	    FROM sys.tables o
	    INNER JOIN sys.columns as c on c.object_id = o.object_id
	    WHERE LOWER(o.name) = @tableName and c.is_identity = 0
	
	    OPEN gen_cur
	    FETCH NEXT FROM gen_cur INTO @col_id, @col_name, @col_type, @col_len, @col_precision, @col_null
        

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @first_run = 1
            BEGIN
                set @first_run = 0
            END
            ELSE
            BEGIN
               set @sql_params += ', ' 
               set @sql_body += ', '
            END 
            
            -- Params
            set @sql_params += CONCAT('@', @col_name, ' ', @col_type)

            IF @col_type in ('varchar', 'char')
            BEGIN
                set @sql_params += CONCAT('(', @col_len, ')')
            END

            IF @col_type = 'numeric'
            BEGIN
                set @sql_params += CONCAT('(', @col_precision, ', ', @col_len, ')')
            END

            IF @col_null = 1
            BEGIN
                set @sql += ' = null'
            END

            -- Body
            set @sql_body += CONCAT('@', @col_name)
        END

        CLOSE @gen_cur

        SET @sql += @sql_params + @sql_body + ') end'
        exec @sql
    END

    ----------------------------
    ---- Update 
    ----------------------------

    IF @action = 'update' or @action = 'all'
    BEGIN
        set @sql = 'CREATE OR ALTER PROCEDURE '+ CONCAT_WS('_', @tableName,'update')
        set @first_run = 1

	    DECLARE gen_cur CURSOR FOR 
	    SELECT c.column_id, c.name, TYPE_NAME(c.user_type_id), c.max_length, c.[precision], c.is_nullable
	    FROM sys.tables o
	    INNER JOIN sys.columns c on c.object_id = o.object_id
	    WHERE LOWER(o.name) = @tableName

	    OPEN gen_cur
	    FETCH NEXT FROM gen_cur INTO @col_id, @col_name, @col_type, @col_len, @col_precision, @col_null

    END

    ----------------------------
    ---- Delete 
    ----------------------------

    IF @action = 'delete' or @action = 'all'
    BEGIN
        -- sp name     
        set @sql = 'CREATE OR ALTER PROCEDURE '+ CONCAT_WS('_', @tableName,'delete')

    END
END
GO

exec sp_generate_action 'SalesOrderHeader', 'insert';
exec sp_generate_action 'adsf', 'sert';
GO