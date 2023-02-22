use WWIGlobal
GO

-- TODO:  Implemente o código necessário à encriptação, do campo relativo ao token do “traking number” do serviço.
-- TODO: relativo à password dos utilizadores do sistema e dos campos relativos ao preço dos produtos

-- Create Database Master Key
CREATE MASTER KEY ENCRYPTION
BY PASSWORD = 'SuperStrongPasswd1!'
GO

-- Create Encryption Certificate
CREATE CERTIFICATE wwiGlobalCert1
WITH SUBJECT = 'Encrypt stuff'
GO

-- Create Symetric Key
CREATE SYMMETRIC KEY EncryptSomething
WITH ALGORITHM = TRIPLE_DES 
ENCRYPTION BY CERTIFICATE wwiGlobalCert
GO

-- Add column which will hold encrypted data in binary
ALTER TABLE tableName 
ADD col VARBINARY(256)
GO

-- Update binary column with encrypted data created by certificate and key
OPEN SYMMETRIC KEY EncryptSomething DECRYPTION
BY CERTIFICATE wwiGlobalCert1
UPDATE tableName
SET col =
ENCRYPTBYKEY(KEY_GUID('EncryptSomething'), columnWithDataToEncrypt)
GO

-- DROP the original column
--ALTER TABLE tableName
--DROP COLUMN <columnWithDataToEncrypt>
--GO

-- Decrypt a column and convert its data to varchar
--OPEN SYMMETRIC KEY <KeyName> DECRYPTION
--BY CERTIFICATE <databaseNameCert>
--SELECT CONVERT(VARCHAR(50), DECRYPTBYKEY(<columnToDecrypt>)) as Something
--from <tableName>
--GO
--
--CLOSE SYMMETRIC KEY <KeyName>
--GO

-- Hash columns
CREATE OR ALTER FUNCTION fn_hashIt(@col nvarchar(32))
RETURNS varbinary(32)
AS BEGIN
    DECLARE @var nvarchar(32) = convert(nvarchar(32),@col)
    RETURN HASHBYTES ('SHA2_256', @col)
END
GO

CREATE OR ALTER FUNCTION Authentication.fn_authenticateUser
(@email varhar(255), @passwd nvarchar(32))
RETURNS bit
AS
BEGIN
    IF EXISTS (
        select * 
        from Authentication.SystemUser 
        where email = @email 
        and passwd = HASHBYTES('SHA2_256', @passwd)
    )
    BEGIN
        return 1
    END
    return 0
END
