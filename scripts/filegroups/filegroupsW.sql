use master
GO

create database WWIGlobal
on primary (
    name = 'wwi_primary' -- system objects
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwi_primary.mdf',
    size = 10MB,
    maxsize = 20MB,
    filegrowth = 10MB
),

-- Features: +/-Access, +/-Read, -Write
-- Tables: Continent, Country, StateProvince, SalesTerritory, State_Country, CityName, City, Token, Error, Logistic, TaxRate, Currency, Color, Package, BusinessCategory
filegroup WWIGlobal (
    name = 'wwi_fg1_1',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwi_fg1.ndf',
    size = 10MB,
    maxsize = 30MB,
    filegrowth = 10MB
),

-- Features: +Write, +Access
-- Tables: SalesOrderHeader, Employee, ErrorLogs, ColumnInfo, Estimation, SystemUser, Discount, ProductModel, Size, Contact, BuyingGroup
filegroup WWIGlobal (
    name = 'wwi_fg2_1',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwi_fg1.ndf'
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 20MB
),

-- Features: +Read, +Write
-- Tables: SalesOrderDetails, CurrencyRate, Salesman, PostalCode, Transport, Address, Customer, Color_Product, Product, Brand
filegroup WWIGlobal (
    name = 'wwi_fg3_1',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwi_fg1.ndf'
    size = 20MB,
    maxsize 60MB,
    filegrowth = 20MB
),
(
    name = 'wwi_fg3_2',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwi_fg1.ndf'
    size = 30MB,
    maxsize = 80MB,
    filegrowth = 25MB
)

-- Log File
log on (
    name = 'wwi_log',
    filename = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwi_log.ldf',
    SIZE = 10MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 20MB
)
GO

ALTER DATABASE WWIGlobal
MODIFY FILEGROUP wwi_fg1_1  DEFAULT;
GO
