use master
GO

create database WWIGlobal
on primary (
    name = 'wwi_primary' -- system objects
    filename = '/var/opt/mssql/data/wwi_primary.mdf',
    size = 10MB,
    maxsize = 20MB,
    filegrowth = 10MB
),

-- Features: +/-Access, +/-Read, -Write
-- Tables: Continent, Country, StateProvince, SalesTerritory, State_Country, CityName, City, Token, Error, Logistic, TaxRate, Currency, Color, Package, BusinessCategory
filegroup WWIGlobal_fg1 (
    name = 'wwi_fg1',
    filename = '/var/opt/mssql/data/wwi_fg1.ndf',
    size = 10MB,
    maxsize = 30MB,
    filegrowth = 10MB
),

-- Features: +Write, +Access
-- Tables: SalesOrderHeader, Employee, ErrorLogs, ColumnInfo, Estimation, SystemUser, Discount, ProductModel, Size, Contact, BuyingGroup, Transport
filegroup WWIGlobal_fg2 (
    name = 'wwi_fg2',
    filename = '/var/opt/mssql/data/wwi_fg1.ndf'
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 20MB
),

-- Features: +Read, +Write
-- Tables: SalesOrderDetails, CurrencyRate, Salesman, PostalCode, Address, Customer, Color_Product, Product, Brand
filegroup WWIGlobal_fg3 (
    name = 'wwi_fg3_1',
    filename = '/var/opt/mssql/data/wwi_fg1.ndf'
    size = 20MB,
    maxsize 60MB,
    filegrowth = 20MB
),
(
    name = 'wwi_fg3_2',
    filename = '/var/opt/mssql/data/wwi_fg1.ndf'
    size = 30MB,
    maxsize = 80MB,
    filegrowth = 25MB
)

-- Log File
log on (
    name = 'wwi_log',
    filename = '/var/opt/mssql/data/wwi_log.ldf',
    SIZE = 10MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 20MB
)
GO

ALTER DATABASE WWIGlobal
MODIFY FILEGROUP WWIGlobal_fg2 DEFAULT;
GO
