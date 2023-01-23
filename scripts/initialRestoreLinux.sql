use master;

RESTORE DATABASE wwiOld
FROM DISK = '/var/opt/mssql/backup/WWI_DS.bak'
WITH MOVE 'WWI_DS' TO '/var/opt/mssql/data/wwiOld.mdf',
MOVE 'WWI_DS_Log' TO '/var/opt/mssql/data/wwiOld_log.ldf'
GO

-- Rename database (bc I screw up)
--USE master;
--GO
--ALTER DATABASE WWI_DS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--GO
--ALTER DATABASE WWI_DS MODIFY NAME = wwiOld;
--GO
--ALTER DATABASE wwiOld SET MULTI_USER;
--GO
