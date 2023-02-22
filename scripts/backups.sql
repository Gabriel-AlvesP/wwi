USE master
ALTER DATABASE WWIGlobal SET RECOVERY FULL;
GO
-- Back up the WWIGlobal database to new media set (backup set 1).
BACKUP DATABASE WWIGlobal
  TO DISK = 'C:\SQLServerBackups\WWIGlobalFullRM.bak'
  WITH FORMAT;
GO
-- Create a routine log backup (backup set 2).
BACKUP LOG WWIGlobal TO DISK = 'C:\SQLServerBackups\WWIGlobalFullRM.bak';
GO

---------------------------------------------
-- Recover to the point of failure
Use master; 
BACKUP LOG WWIGlobal
TO DISK = 'C:\SQLServerBackups\WWIGlobalFullRM.bak'
   WITH NORECOVERY;
GO
--Restore the full database backup (from backup set 1).
RESTORE DATABASE WWIGlobal
  FROM DISK = 'C:\SQLServerBackups\WWIGlobalFullRM.bak'
  WITH FILE=1,
    NORECOVERY;

--Restore the regular log backup (from backup set 2).
RESTORE LOG WWIGlobal
  FROM DISK = 'C:\SQLServerBackups\WWIGlobalFullRM.bak'
  WITH FILE=2,
    NORECOVERY;

--Restore the tail-log backup (from backup set 3).
RESTORE LOG WWIGlobal
  FROM DISK = 'C:\SQLServerBackups\WWIGlobalFullRM.bak'
  WITH FILE=3,
    NORECOVERY;
GO
--recover the database:
RESTORE DATABASE WWIGlobal WITH RECOVERY;
GO;