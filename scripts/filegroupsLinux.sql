use master
GO

-- Fill filegoups strategies:

-- Per Schema
--      Nice for database backup/restore
--      Poor optimization because the heavy tables and the tables in the same 'join' queries' will be together
-- For Performance
--      Pain in the *** for online restore but we won't do it anyway :)

-- TODO: Check each filegroup size
create database WWIGlobal
on primary (
    name = 'wwi_primary',
    filename = '/var/opt/mssql/data/wwi_primary.mdf',
    size = 10MB,
    maxsize = 20MB,
    filegrowth = 5MB
),

-- Features: +/-Read, -Write
-- Tables: Continent, Country, StateProvince, SalesTerritory, State_Country, CityName
-- Tables Initial Avg storage: 16 + 17 + 848 + 135 + 159 + 349080 = 350255 B = 350,255 KB
filegroup (
    name = 'wwi_fg1_1'
    filename = '/var/opt/mssql/data/wwi_primary.mdf',
    size = 10MB,
    maxsize = 20MB,
    filegrowth = 5MB
),
-- Features: +Read, +/-Write
-- Tables: City, BusinessCategory, Logistic, Currency, PostalCode, Color, Error, Discount, Token
filegroup (
    name = 'wwi_fg2_1',
    filename = '/var/opt/mssql/data/wwi_stock.ndf',
    size = 200,
    maxsize = 600,
    filegrowth = 50
),
(
    name = 'wwi_fg2_2',
    filename = '/var/opt/mssql/data/.ndf',
    size = 200MB,
    maxsize = 400MB,
    filegrowth = 25MB
),

-- Features: +Read, +Write
-- Tables: SalesOrderHeader, BuyingGroup, Address, Product, Color_Product
filegroup (
    name = 'wwi_read_write2_1'
    filename = '/var/opt/mssql/data/.ndf',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
),
(
    name = 'WWI_read_write2_2'
    filename = '/var/opt/mssql/data/.ndf',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
),

-- Features: +Read, +Write
-- Tables: SalesOrderDetails, Size, Employee, Bills, SystemUser, CurrencyRate
filegroup (
    name = 'wwi_read_write3_1',
    filename = '/var/opt/mssql/data/.ndf',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
),
(
    name = 'WWI_SalesDetails2'
    filename = '/var/opt/mssql/data/.ndf',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
),

-- Features: +Read, +Write
-- Tables: ProductModel, Transport, Salesperson, Customer, ErrorLogs, Monitoring, Estimation
-- Tables Initial Avg storage: + 1102 + 140 + 7638 = 8880 + ProductModel + ErrorLogs + Monitoring
filegroup (
    name = 'wwi_read_write3_1',
    filename = '/var/opt/mssql/data/.ndf',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
),
(
    name = 'WWI_SalesDetails2'
    filename = '/var/opt/mssql/data/.ndf',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
)

-- Log File
log on (
    name = 'wwi_log.ldf',
    filename = '/var/opt/mssql/data/wwi_log.ldf',
    SIZE = 500MB,
    MAXSIZE = 3000MB,
    FILEGROWTH = 500MB
)
GO

ALTER DATABASE wwi_fg1_1
MODIFY FILEGROUP <FILEGROUP> DEFAULT;
GO
