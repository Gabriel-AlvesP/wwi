use master
GO

-- Fill filegoups strategies:

-- Per Schema
--      Nice for database backup/restore
--      Poor optimization because the heavy tables and the tables in the same 'join' queries' will be together
-- For Performance
--      Pain in the *** for online restore but we won't do it anyway :)

create database WWIGlobal
on primary (
    name = 'wwi_primary',
    filename = '/var/opt/mssql/data/wwi_primary.mdf',
    size = 15MB,
    maxsize = 30MB,
    filegrowth = 15MB
),

-- Features: +/-Read, -Write
-- Tables: Continent, Country, StateProvince, SalesTerritory, State_Country, CityName
-- Tables Initial Avg storage: 16 + 17 + 848 + 135 + 159 + 349080 = 350255 B = 350,255KB
filegroup (
    name 'wwi_fg1_1',
    filename = '/var/opt/mssql/data/wwi_fg1.ndf',
    size = 30MB,
    maxsize = 60MB,
    filegrowth = 30MB
),

-- Features: +Read, +/-Write
-- Tables: City, BusinessCategory, Logistic, Currency, PostalCode, Color, Error, Discount, Token
-- Tables Initial Avg storage: 349080 + 70 + 18 + 16 + 1268 + 99 = 350551 + Error + Discount + Token
filegroup (
    name = 'wwi_fg2_1',
    filename = '/var/opt/mssql/data/wwi_fg2.ndf',
    size = 30MB,
    maxsize = 70MB,
    filegrowth = 20MB
),

-- Features: +Rserviceead, +Write
-- Tables: SalesOrderHeader, BuyingGroup, Address, Product, Color_Product
-- Tables Initial Avg storage: 1833260 + 36 + 14 + 2540 = 1835850 + Product = 1 835 850 B = 1835,85KB
filegroup (
    name = 'wwi_fg3_1'
    filename = '/var/opt/mssql/data/wwi_fg3_1.ndf',
    size = 50MB,
    maxsize = 150MB,
    filegrowth = 50MB
),
(
    name = 'wwi_fg3_2'
    filename = '/var/opt/mssql/data/wwi_fg3_2.ndf',
    size = 100MB,
    maxsize = 200MB,
    filegrowth = 50MB
),

-- Features: +Read, +Write
-- Tables: SalesOrderDetails, Size, Employee, Bills, SystemUser, CurrencyRate
-- Tables Initial Avg storage: + 418 + 846120 + 17286 + 38 = SalesOrderDetails + 863862
filegroup (
    name = 'wwi_fg4_1',
    filename = '/var/opt/mssql/data/wwi_fg4_1.ndf',
    size = 100MB,
    maxsize = 300MB,
    filegrowth = 100MB
),
(
    name = 'wwi_fg4_2'
    filename = '/var/opt/mssql/data/wwi_fg4_2.ndf',
    size = 200MB,
    maxsize = 400MB,
    filegrowth = 100MB
),

-- Features: +Read, +Write
-- Tables: ProductModel, Transport, Salesperson, Customer, ErrorLogs, Monitoring, Estimation
-- Tables Initial Avg storage: + 1102 + 140 + 7638  = 8880 + ProductModel + ErrorLogs + Monitoring + Estimation
filegroup (
    name = 'wwi_fg5_1',
    filename = '/var/opt/mssql/data/wwi_fg5_1.ndf',
    size = 100MB,
    maxsize = 200MB,
    filegrowth = 100MB
),
(
    name = 'wwi_fg5_2'
    filename = '/var/opt/mssql/data/wwi_fg5_2.ndf',
    size = 100MB,
    maxsize = 200MB,
    filegrowth = 100MB
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

ALTER DATABASE WWIGlobal
MODIFY wwi_fg1_1  DEFAULT;
GO
