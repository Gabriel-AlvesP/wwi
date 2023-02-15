use WWIGlobal
GO
ALTER TABLE ErrorLogs DROP CONSTRAINT FKErrorLogs128846;
ALTER TABLE Sales.SalesOrderHeader DROP CONSTRAINT FKSalesOrder501237;
ALTER TABLE Stock.Color_Product DROP CONSTRAINT FKColor_Prod455898;
ALTER TABLE Stock.Color_Product DROP CONSTRAINT FKColor_Prod770171;
ALTER TABLE Sales.SalesOrderDetails DROP CONSTRAINT FKSalesOrder561622;
ALTER TABLE Sales.SalesOrderDetails DROP CONSTRAINT FKSalesOrder444426;
ALTER TABLE Sales.SalesOrderDetails DROP CONSTRAINT FKSalesDetails_TaxRate; 
ALTER TABLE Customers.Customer DROP CONSTRAINT FKCustomer989078;
ALTER TABLE Customers.Customer DROP CONSTRAINT FKCustomer142132;
ALTER TABLE Sales.SalesOrderHeader DROP CONSTRAINT FKSalesOrder38550;
ALTER TABLE Sales.SalesOrderDetails DROP CONSTRAINT FKSalesOrder274263;
ALTER TABLE Authentication.Token DROP CONSTRAINT FKToken31840;
ALTER TABLE Authentication.SystemUser DROP CONSTRAINT FKSystemUser205753;
ALTER TABLE Sales.CurrencyRate DROP CONSTRAINT FKCurrencyRa46653;
ALTER TABLE Sales.CurrencyRate DROP CONSTRAINT FKCurrencyRa922024;
ALTER TABLE Sales.SalesOrderHeader DROP CONSTRAINT FKSalesOrder113862;
ALTER TABLE Location.StateProvince DROP CONSTRAINT FKStateProvi737346;
ALTER TABLE Shipments.Transport DROP CONSTRAINT FKTransport646807;
ALTER TABLE Shipments.Transport DROP CONSTRAINT FKTransport627008;
ALTER TABLE Location.Country DROP CONSTRAINT FKCountry458801;
ALTER TABLE Location.City DROP CONSTRAINT FKCity345217;
ALTER TABLE Sales.SalesOrderHeader DROP CONSTRAINT FKSalesOrder352570;
ALTER TABLE Location.Address DROP CONSTRAINT FKAddress489264;
ALTER TABLE Location.Address DROP CONSTRAINT FKAddress632364;
ALTER TABLE Customers.Customer DROP CONSTRAINT FKCustomer133437;
ALTER TABLE Sales.Salesperson DROP CONSTRAINT FKSalesperso253703;
ALTER TABLE Location.StateProvince_Country DROP CONSTRAINT FKStateProvi145043;
ALTER TABLE Location.StateProvince_Country DROP CONSTRAINT FKStateProvi235227;
ALTER TABLE Location.City DROP CONSTRAINT FKCity262519;
ALTER TABLE Stock.ProductModel DROP CONSTRAINT FKProductMod591355;
ALTER TABLE Stock.ProductModel DROP CONSTRAINT FKProductMod979572;
ALTER TABLE Stock.ProductModel DROP CONSTRAINT FKProductMod345309;
ALTER TABLE Stock.ProductModel DROP CONSTRAINT FKProductMod245369;
ALTER TABLE Stock.ProductModel DROP CONSTRAINT FKProductMod130361;
ALTER TABLE Stock.ProductModel DROP CONSTRAINT FKProductModel_TaxRate;
ALTER TABLE Sales.SalesOrderHeader DROP CONSTRAINT FKSalesOrder216469;
ALTER TABLE Customers.Contacts DROP CONSTRAINT FKContacts573379;
ALTER TABLE Sales.ProductModel_Discount DROP CONSTRAINT FKProductModel_Discount1; 
ALTER TABLE Sales.ProductModel_Discount DROP CONSTRAINT FKProductModel_Discount2; 
DROP TABLE Customers.Customer;
DROP TABLE Authentication.Token;
DROP TABLE Sales.Discount;
DROP TABLE ErrorLogs;
DROP TABLE Error;
DROP TABLE CompanyResources.Employee;
DROP TABLE Sales.ProductModel_Discount;
DROP TABLE Stock.ProductModel;
DROP TABLE Customers.BusinessCategory;
DROP TABLE Location.StateProvince;
DROP TABLE Location.CityName;
DROP TABLE Location.Country;
DROP TABLE Location.SalesTerritory;
DROP TABLE Sales.SalesOrderHeader;
DROP TABLE Stock.Color;
DROP TABLE Stock.Color_Product;
DROP TABLE Sales.SalesOrderDetails;
DROP TABLE Customers.BuyingGroup;
DROP TABLE SystemControl;
DROP TABLE Location.Address;
DROP TABLE Authentication.SystemUser;
DROP TABLE Sales.Currency;
DROP TABLE Sales.Salesperson;
DROP TABLE Sales.CurrencyRate;
DROP TABLE Estimation;
DROP TABLE Shipments.Logistic;
DROP TABLE Shipments.Transport;
DROP TABLE Location.Continent;
DROP TABLE Location.City;
DROP TABLE Location.PostalCode;
DROP TABLE Location.StateProvince_Country;
DROP TABLE Stock.Product;
DROP TABLE Stock.[Size];
DROP TABLE Stock.Brand;
DROP TABLE Stock.Package;
DROP TABLE Customers.Contacts;
DROP TABLE Stock.TaxRate;
GO
DROP SCHEMA Customers
GO
DROP SCHEMA Sales
GO
DROP SCHEMA CompanyResources
GO
DROP SCHEMA Stock
GO
DROP SCHEMA Location
GO
DROP SCHEMA Shipments
GO
DROP SCHEMA Authentication
GO
