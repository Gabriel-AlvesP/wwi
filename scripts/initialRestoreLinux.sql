use master;
GO

RESTORE DATABASE WWI_OldData
FROM DISK = '/var/opt/mssql/backup/WWI_DS.bak'
WITH MOVE 'WWI_DS' TO '/var/opt/mssql/data/WWI_OldData.mdf',
MOVE 'WWI_DS_Log' TO '/var/opt/mssql/data/WWI_OldData_log.ldf'
GO

-- Rename database (bc I screw up)
--ALTER DATABASE WWI_DS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--GO
--ALTER DATABASE WWI_DS MODIFY NAME = wwiOld;
--GO
--ALTER DATABASE wwiOld SET MULTI_USER;
--GO
