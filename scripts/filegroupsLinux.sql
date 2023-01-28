use master
GO

-- Put objects that compete heavily for space in different filegroups.
-- Put different tables used in the same join queries in different filegroups.
-- Put heavily accessed tables and the nonclustered indexes that belong to those tables on different filegroups.

-- TODO:
-- Create Db / Primary File Group
create database WWIGlobal
    on primary ( --Tables:??? Continent, Country, CityName, PostalCode, SalesTerritory, StatesProvince
	name = 'WWIPrimary',
    filename = '/var/opt/mssql/data/wwi_primary.mdf',
    size = 100MB,
    maxsize = 300MB,
    filegrowth = 20MB
    ),

    --Tables: Product, ProductModel, Color, Color_Product, Size
    filegroup (
	name = 'WWIStock',
    filename = '/var/opt/mssql/data/wwi_stock.ndf',
    size = 100MB,
    maxsize = 250MB,
    filegrowth = 20MB
    ),

    (
	name = '',
    filename = '/var/opt/mssql/data/.ndf',
    size = 200MB,
    maxsize = 400MB,
    filegrowth = 25MB
    ),

    --Tabelas: SaleOrderhHeader,
    filegroup (
        name = 'WWISales',
        filename = '/var/opt/mssql/data/.ndf',
        size = 10MB,
        maxsize = 50MB,
        filegrowth = 2MB
    ),

    -- Tables: SaleOrderDetails
    filegroup (
        name = 'WWISales',
        filename = '/var/opt/mssql/data/.ndf',
        size = 10MB,
        maxsize = 50MB,
        filegrowth = 2MB
    )

-- Log File
log on (
    name = 'wwi_log.ldf',
    filename = 'D:\',
    SIZE = 500MB,
    MAXSIZE = 3000MB,
    FILEGROWTH = 500MB
)
GO

-- TODO: Add filegroup
ALTER DATABASE WWI
  MODIFY FILEGROUP <FILEGROUP> DEFAULT;
GO
