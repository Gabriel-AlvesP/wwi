USE master
ALTER DATABASE WWIGlobal SET RECOVERY FULL;
GO

-- TODO: add jobs
-- Back up the WWIGlobal database to new media set (backup set 1).
BACKUP DATABASE WWIGlobal
  TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak'
  WITH FORMAT;
GO
-- Create a routine log backup (backup set 2).
BACKUP LOG WWIGlobal TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak';
GO
---------------------------------------------
-- Recover to the point of failure
Use master; 
--Create tail-log backup.
BACKUP LOG WWIGlobal
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak'
   WITH NORECOVERY;
GO
--Restore the full database backup (from backup set 1).
RESTORE DATABASE WWIGlobal
  FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak'
  WITH FILE=1,
    NORECOVERY;

--Restore the regular log backup (from backup set 2).
RESTORE LOG WWIGlobal
  FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak'
  WITH FILE=2,
    NORECOVERY;

--Restore the tail-log backup (from backup set 3).
RESTORE LOG WWIGlobal
  FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak'
  WITH FILE=3,
    NORECOVERY;
GO
--recover the database:
RESTORE DATABASE WWIGlobal WITH RECOVERY;
GO;