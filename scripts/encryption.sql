use WWIGlobal
GO

-- TODO:  Implemente o código necessário à encriptação, do campo relativo ao token do “traking number” do serviço.

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

CREATE SYMMETRIC KEY EncryptTransport
WITH ALGORITHM = TRIPLE_DES 
ENCRYPTION BY CERTIFICATE wwiGlobalCert1
GO

-- Add column which will hold encrypted data in binary
ALTER TABLE Stock.ProductModel
ADD E_StandardUnitCost VARBINARY(256), 
E_CurrentRetailPrice VARBINARY(256),
E_RecommendedRetailPrice VARBINARY(256)
GO

ALTER TABLE Shipments.Transport
ADD E_TrackingNumber VARBINARY(256)
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

OPEN SYMMETRIC KEY EncryptTransport DECRYPTION
BY CERTIFICATE wwiGlobalCert1
UPDATE Shipments.Transport
SET 
    E_TrackingNumber = ENCRYPTBYKEY(KEY_GUID('EncryptTransport'), TrackingNumber)
GO

-- Drop the original column
ALTER TABLE Stock.ProductModel 
DROP COLUMN StandardUniCost,
CurrentRetailPrice,
RecommendedRetail
GO

ALTER TABLE Shipments.Transport
DROP COLUMN TrackingNumber
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
