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
WITH SUBJECT = 'Encrypt secrets'
GO

-- Create Symetric Key
CREATE SYMMETRIC KEY EncryptPrices
WITH ALGORITHM = TRIPLE_DES 
ENCRYPTION BY CERTIFICATE wwiGlobalCert1
GO


-- Add column which will hold encrypted data in binary
ALTER TABLE Stock.ProductModel
ADD E_StandardUnitCost VARBINARY(256), 
E_CurrentRetailPrice VARBINARY(256),
E_RecommendedRetailPrice VARBINARY(256)
GO

-- Update binary column with encrypted data created by certificate and key
OPEN SYMMETRIC KEY EncryptPrices DECRYPTION
BY CERTIFICATE wwiGlobalCert1
UPDATE Stock.ProductModel
SET 
    E_StandardUniCost = ENCRYPTBYKEY(KEY_GUID('EncryptPrices'), StandardUnitCost),
    E_CurrentRetailPrice = ENCRYPTBYKEY(KEY_GUID('EncryptPrices'), CurrentRetailPrice),
    E_RecommendedRetailPrice = ENCRYPTBYKEY(KEY_GUID('EncryptPrices'), RecommendedRetailPrice )
GO

-- Drop the original column
ALTER TABLE tableName
DROP COLUMN StandardUniCost,
CurrentRetailPrice,
RecommendedRetail
GO

-- Decrypt a column and convert its data to varchar
CREATE OR ALTER PROCEDURE sp_getPrices
AS 
BEGIN
    OPEN SYMMETRIC KEY EncryptPrices DECRYPTION
    BY CERTIFICATE wwiGlobalCert1
    SELECT 
    CONVERT(VARCHAR(50), DECRYPTBYKEY(E_StandardUniCost)) as StandardUniCost,
    CONVERT(VARCHAR(50), DECRYPTBYKEY(E_CurrentRetailPrice)) as CurrentRetailPrice,
    CONVERT(VARCHAR(50), DECRYPTBYKEY(E_RecommendedRetailPrice)) as RecommendedRetailPrice
    from Stock.ProductModel
    CLOSE SYMMETRIC KEY EncryptPrices
end
GO


CREATE OR ALTER FUNCTION Authentication.fn_authenticateUser
(@email varchar(255), @passwd nvarchar(32))
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
GO