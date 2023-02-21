use WWIGlobal
GO

-- TODO: CHECK ENCRYPTION
CREATE OR ALTER PROCEDURE sp_generate_action
	@tableName varchar(100) = 'wwi_user',
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
    @sql             nvarchar(max) = '', 
    @sql_params      nvarchar(max) = '',
    @sql_body        nvarchar(max) = '',
    @sql_validations nvarchar(max) = '',
    @sql_where       nvarchar(max) = '',
    @first_run       bit
        
    -- INITIALIZATION
    select @schema = s.name from sys.schemas s inner join sys.tables t on s.schema_id = t.schema_id where LOWER(t.name) = @tableName

    ----------------------------
    ---- Insert 
    ----------------------------

    IF @action = 'insert' or @action = 'all'
    BEGIN
        set @sql = 'CREATE OR ALTER PROCEDURE '+ CONCAT_WS('_', 'sp', @tableName,'insert') + ' '
        set @sql_validations = ' AS BEGIN '
        set @sql_body = N' INSERT INTO ' + @schema + '.' + @tableName + ' VALUES ('
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
                set @sql_params += ' = null'
            END

            -- Validations
            IF @col_type in ( 'tinyint', 'smallint', 'int')
            BEGIN
                set @sql_validations += CONCAT('exec sp_validate_fk ', @tableName, ', ', @col_name, ', @', @col_name, char(13)) 
            END

            -- Body
            set @sql_body += CONCAT('@', @col_name)

	        FETCH NEXT FROM gen_cur INTO @col_id, @col_name, @col_type, @col_len, @col_precision, @col_null
        END

        CLOSE gen_cur
        DEALLOCATE gen_cur

        SET @sql += concat_ws(' ', @sql_params, @sql_validations, @sql_body, ') end')
        print @sql
        exec sp_executesql @sql
    END

    ----------------------------
    ---- Update 
    ----------------------------

    IF @action = 'update' or @action = 'all'
    BEGIN
        set @sql = N'CREATE OR ALTER PROCEDURE '+ CONCAT_WS('_', 'sp', @tableName,'update') + ' '
        set @sql_params = ''
        set @sql_validations = ' AS BEGIN '
        set @sql_body = N' UPDATE ' + @schema + '.' + @tableName + ' SET '
        set @sql_where = N' WHERE '
        set @first_run = 1

        declare @first_body bit = 1, @first_where bit = 1

	    DECLARE gen_cur CURSOR FOR 
	    SELECT c.column_id, c.name, TYPE_NAME(c.user_type_id), c.max_length, c.[precision], c.is_nullable
	    FROM sys.tables o
	    INNER JOIN sys.columns c on c.object_id = o.object_id
	    WHERE LOWER(o.name) = @tableName

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
                set @sql_params += ' = null'
            END

            IF NOT EXISTS (select all_pk.tableName from all_pk_cols all_pk where all_pk.tableName = @tableName and all_pk.columnName = @col_name)
            BEGIN
	            -- Validations
	            IF @col_type in ( 'tinyint', 'smallint', 'int')
	            BEGIN
	                set @sql_validations += CONCAT('exec sp_validate_fk ', @tableName, ', ', @col_name, ', @', @col_name, char(13)) 
	            END

                if @first_body = 1
                BEGIN 
                    set @first_body = 0
                END
                ELSE
                BEGIN 
                    set @sql_body += ', '
                END

                -- Body (to update)
                set @sql_body += concat(@col_name, ' = @', @col_name )
            END
            ELSE
            BEGIN
                -- Validations
                set @sql_validations += CONCAT('exec sp_validate_pk ', @tableName, ', ', @col_name, ', @', @col_name, char(13)) 

                IF @first_where = 1
                BEGIN 
                    set @first_where = 0
                END
                ELSE
                BEGIN 
                    set @sql_where += ' AND '
                END

                -- Where
                set @sql_where += CONCAT(@col_name, ' = @',@col_name)
            END

	        FETCH NEXT FROM gen_cur INTO @col_id, @col_name, @col_type, @col_len, @col_precision, @col_null
        END
    
        CLOSE gen_cur
        DEALLOCATE gen_cur

        SET @sql += concat_ws(' ', @sql_params, @sql_validations, @sql_body, @sql_where, ' end')
        print @sql
        exec sp_executesql @sql
    END

    ----------------------------
    ---- Delete 
    ----------------------------

    IF @action = 'delete' or @action = 'all'
    BEGIN
        -- sp name     
        set @sql = 'CREATE OR ALTER PROCEDURE '+ CONCAT_WS('_', 'sp', @tableName,'delete') + ' '
        set @sql_params = ''
        set @sql_validations = ' AS BEGIN '
        set @sql_body = N' DELETE FROM ' + @schema + '.' + @tableName + ' WHERE '
        set @first_run = 1


	    DECLARE gen_cur CURSOR FOR 
	    SELECT c.column_id, c.name, TYPE_NAME(c.user_type_id), c.max_length, c.[precision], c.is_nullable
	    FROM sys.tables o
	    INNER JOIN sys.columns as c on c.object_id = o.object_id
	    WHERE LOWER(o.name) = @tableName and exists (select columnName from all_pk_cols pk where @tableName = pk.tableName  and pk.columnName = c.name )

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
               set @sql_body += ' and '
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
                set @sql_params += ' = null'
            END

            -- Validations
            set @sql_validations += CONCAT('exec sp_validate_pk ', @tableName, ', ', @col_name, ', @', @col_name, char(13)) 

            -- Body
            set @sql_body += CONCAT(@col_name, ' = @',@col_name)

	        FETCH NEXT FROM gen_cur INTO @col_id, @col_name, @col_type, @col_len, @col_precision, @col_null
        END
        
        CLOSE gen_cur
        DEALLOCATE gen_cur

        SET @sql += concat_ws(' ', @sql_params, @sql_validations, @sql_body, ' end')
        print @sql
        exec sp_executesql @sql
    END

END
GO

--exec sp_generate_action 'systemuser', 'all'; --:)
--go
--exec sp_systemuser_insert  1, 'client@client.com', 'password'
--go
--select * from Authentication.SystemUser where Email = 'client@client.com'
--Go
--exec sp_systemuser_update 1,  'godclient@client.com', 'passwd'
--GO
--select * from Authentication.SystemUser 
--Go
--exec sp_systemuser_delete 1
--GO
--select * from Authentication.SystemUser 
--Go