use WWIGlobal
GO

select * from Stock.ProductModel

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
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE wwiGlobalCert1;
GO


-- Add column which will hold encrypted data in binary
ALTER TABLE Stock.ProductModel
ADD E_StandardUnitCost VARBINARY(256), 
E_CurrentRetailPrice VARBINARY(256),
E_RecommendedRetailPrice VARBINARY(256)
GO


-- Update binary column with encrypted data created by certificate and key
OPEN SYMMETRIC KEY EncryptPrices DECRYPTION
BY CERTIFICATE wwiGlobalCert1;

UPDATE Stock.ProductModel
SET 
    E_StandardUnitCost = ENCRYPTBYKEY(KEY_GUID('EncryptPrices'), convert(varchar(255), StandardUnitCost)),
    E_CurrentRetailPrice = ENCRYPTBYKEY(KEY_GUID('EncryptPrices'), convert(varchar(255),CurrentRetailPrice)),
    E_RecommendedRetailPrice = ENCRYPTBYKEY(KEY_GUID('EncryptPrices'), convert(varchar(255),RecommendedRetailPrice ))
GO

-- Drop the original column
ALTER TABLE Stock.ProductModel 
DROP COLUMN StandardUnitCost,
CurrentRetailPrice,
RecommendedRetailPrice
GO

CREATE SYMMETRIC KEY EncryptTransport
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE wwiGlobalCert1;
GO

ALTER TABLE Shipments.Transport
ADD E_TrackingNumber VARBINARY(256)
GO

OPEN SYMMETRIC KEY EncryptTransport DECRYPTION
BY CERTIFICATE wwiGlobalCert1
UPDATE Shipments.Transport
SET 
    E_TrackingNumber = ENCRYPTBYKEY(KEY_GUID('EncryptTransport'), TrackingNumber)
GO

ALTER TABLE Shipments.Transport
DROP COLUMN TrackingNumber
GO

-- Decrypt a column and convert its data to varchar
CREATE OR ALTER PROCEDURE dbo.sp_getPrices
AS 
BEGIN
    OPEN SYMMETRIC KEY EncryptPrices DECRYPTION
    BY CERTIFICATE wwiGlobalCert1
    SELECT 
    CONVERT(VARCHAR(50), DECRYPTBYKEY(E_StandardUnitCost)) as StandardUniCost,
    CONVERT(VARCHAR(50), DECRYPTBYKEY(E_CurrentRetailPrice)) as CurrentRetailPrice,
    CONVERT(VARCHAR(50), DECRYPTBYKEY(E_RecommendedRetailPrice)) as RecommendedRetailPrice
    from Stock.ProductModel
    CLOSE SYMMETRIC KEY EncryptPrices
end
GO
exec dbo.sp_getPrices
Go
