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

        (51003, N'Table `%s` does not exist. Check the database table for more info.')
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