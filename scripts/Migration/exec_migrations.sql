-- NOTE: TO USE THIS FILE REMOVE THE EXECS FROM THE migration.sql file

-- Clustered index to some old data tables
use WWI_OldData
GO
IF (SELECT OBJECTPROPERTY(OBJECT_ID(N'City'),'TableHasPrimaryKey')) = 0 
AND (SELECT OBJECTPROPERTY(OBJECT_ID(N'Employee'),'TableHasPrimaryKey')) = 0
AND (SELECT OBJECTPROPERTY(OBJECT_ID(N'Stock Item'),'TableHasPrimaryKey')) = 0
BEGIN
ALTER TABLE City ADD CONSTRAINT PK_OldData_City PRIMARY KEY([City Key])
ALTER TABLE Employee ADD CONSTRAINT PK_OldData_Employee PRIMARY KEY([Employee Key])
ALTER TABLE [Stock Item] ADD CONSTRAINT PK_OldData_StockItem PRIMARY KEY([Stock Item Key])
END
GO

use WWIGlobal
GO
-- exec migration
SET ANSI_NULLS OFF;
GO
SET NOCOUNT ON;
GO
SET STATISTICS TIME ON
GO
SET STATISTICS IO ON
GO
exec sp_populate_currency;
GO
exec sp_populate_currencyRate;
GO
exec sp_import_continents;
GO
exec sp_import_countries;
GO
exec sp_import_sales_territory;
GO
exec sp_import_states;
GO
exec sp_import_city_names;
GO
exec sp_import_cities;
GO
exec sp_import_postalCode;
GO
exec sp_import_address;
GO
exec sp_import_buyingGroups;
GO
exec sp_import_businessCategory;
GO
exec sp_import_customer;
GO
exec sp_import_employee;
GO
exec sp_import_colors;
GO
exec sp_import_brand;
GO
exec sp_import_package;
GO
exec sp_import_size;
GO
exec sp_import_taxRate;
GO
exec sp_import_product;
GO
exec sp_import_productM;
GO
exec sp_import_salesOH; -- 9min 
GO
exec sp_import_salesOrderDetails;
GO
SET NOCOUNT OFF;
GO
SET ANSI_NULLS ON;
GO