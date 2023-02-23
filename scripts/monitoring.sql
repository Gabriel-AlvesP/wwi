-- Monitoring & Metadata
use WWIGlobal
GO
SET NOCOUNT ON
GO
CREATE OR ALTER PROCEDURE dbo.sp_db_monitoring
AS	
BEGIN
	DECLARE monitoring_cur CURSOR FOR SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, NUMERIC_PRECISION, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS;

	DECLARE @tableName VARCHAR(100), @column_name VARCHAR(100), @data_Type VARCHAR(100),
	@is_nullable CHAR(3), @numeric bigint, @max_length BIGINT, @referenced_column VARCHAR(255),
	@referenced_table VARCHAR(100)

	OPEN monitoring_cur

	FETCH NEXT FROM monitoring_cur INTO @tableName, @column_name, @data_Type, @is_nullable, @numeric, @max_length

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS (
			SELECT OBJECT_NAME(f.parent_object_id) AS 'Table Name',
				COL_NAME(fc.referenced_object_id, fc.referenced_column_id), 
				OBJECT_NAME(f.referenced_object_id) , 
				COL_NAME(fc.parent_object_id,fc.parent_column_id),
				delete_referential_action_desc, update_referential_action_desc, GETDATE()
				FROM sys.foreign_keys AS f
				INNER JOIN sys.foreign_key_columns AS fc ON f.OBJECT_ID = fc.constraint_object_id
				INNER JOIN sys.all_objects ao on f.parent_object_id = ao.object_id
				WHERE COL_NAME(fc.parent_object_id,fc.parent_column_id) = @column_name
			)
			BEGIN
				INSERT INTO dbo.Monitoring (Table_name, Column_name, Data_Type, Is_nullable, Numeric_precision, Character_maximum_length)
				VALUES (@tableName, @column_name, @data_Type, @is_nullable, @numeric, @max_length)
			END
			ELSE 
			BEGIN
				SELECT 	@referenced_column = COL_NAME(fc.referenced_object_id, fc.referenced_column_id), 
							@referenced_table = OBJECT_NAME(f.referenced_object_id)
							FROM sys.foreign_keys AS f
							INNER JOIN sys.foreign_key_columns AS fc ON f.OBJECT_ID = fc.constraint_object_id
							INNER JOIN sys.all_objects ao on f.parent_object_id = ao.object_id
							WHERE COL_NAME(fc.parent_object_id,fc.parent_column_id) = @column_name

				INSERT INTO dbo.Monitoring (Table_name, Column_name, Data_Type, Is_nullable, Numeric_precision, Character_maximum_length, Referenced_column, Referenced_table)
				VALUES (@tableName, @column_name, @data_Type, @is_nullable, @numeric, @max_length, @referenced_column, @referenced_table)
			END

			FETCH NEXT FROM monitoring_cur INTO @tableName, @column_name, @data_Type, @is_nullable, @numeric, @max_length
	END 
	CLOSE monitoring_cur
	DEALLOCATE monitoring_cur
END
GO 

CREATE VIEW dbo.vw_last_monitoring
AS 
	select * from dbo.Monitoring m1
	where format(m1.update_date,'yyyy-MM-dd HH:mm') = (select top 1 format(update_date,'yyyy-MM-dd HH:mm') from dbo.Monitoring) 
GO

CREATE OR ALTER PROCEDURE dbo.sp_data_estimation
AS
BEGIN

	CREATE TABLE #Table_Information(
		name VARCHAR(MAX),
		rows VARCHAR(MAX),
		reserved VARCHAR(MAX),
		data VARCHAR(MAX), 
		index_size VARCHAR(MAX),
		unused VARCHAR(MAX)
	)

	DECLARE information CURSOR FOR SELECT rows, data, reserved FROM #Table_Information
	DECLARE tables CURSOR FOR SELECT TABLE_SCHEMA ,TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
	DECLARE @tableName VARCHAR(MAX)
	DECLARE @schema VARCHAR(MAX)
	DECLARE @space VARCHAR(MAX)
	DECLARE @rows VARCHAR(MAX)
	DECLARE @reserved VARCHAR(MAX)

	OPEN tables
	OPEN information

	FETCH NEXT FROM tables INTO @schema, @tableName
	SET @schema = CONCAT(@schema, '.', @tableName)

	INSERT INTO #Table_Information EXEC sp_spaceused @schema

	FETCH NEXT FROM information INTO @rows, @space, @reserved
	IF @rows <> 0 
	BEGIN
		INSERT INTO dbo.Data_Estimation(Table_name, Entries_number, Reserved_storage, Data_storage, Data_per_registry) 
		VALUES (@schema, @rows, @reserved, @space,CAST(SUBSTRING(@space, 0 ,  CHARINDEX('K',@space)) AS FLOAT) /  CAST(@rows AS FLOAT))
	END
	WHILE @@FETCH_STATUS = 0
	BEGIN
		FETCH NEXT FROM tables INTO @schema, @tableName
		SET @schema = CONCAT(@schema, '.', @tableName)

		INSERT INTO #Table_Information EXEC sp_spaceused @schema

		FETCH NEXT FROM information INTO @rows, @space, @reserved
		
		IF @rows <> 0 
		BEGIN
			INSERT INTO dbo.Data_Estimation(Table_name, Entries_number, Reserved_storage, Data_storage, Data_per_registry) 
			VALUES(@schema, @rows, @reserved, @space,CAST(SUBSTRING(@space, 0 ,  CHARINDEX('K',@space)) AS FLOAT) /  CAST(@rows AS FLOAT))
		END
	END 

	DROP TABLE #Table_Information
	CLOSE tables
	DEALLOCATE tables
	CLOSE information
	DEALLOCATE information
END
GO
exec dbo.sp_db_monitoring
go
exec dbo.sp_data_estimation
go 
set nocount OFF
go
select * from dbo.Monitoring
go 
select * from dbo.Data_Estimation