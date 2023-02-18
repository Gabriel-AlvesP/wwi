use WWIGlobal
GO
select * from Sales.Currency;
select * from Sales.CurrencyRate;
select * from Location.Continent
select * from Location.Country;
select * from Location.SalesTerritory
select * from Location.StateProvince
select * from Location.StateProvince_Country
select * from Location.CityName
select * from Location.City
select * from [Location].PostalCode
select * from Location.Address
select * from Customers.BuyingGroup
select * from Customers.BusinessCategory
select * from Customers.Customer
select * from CompanyResources.Employee
select * from Sales.Salesperson
select * from Stock.Color
select * from Stock.Brand
select * from Stock.Package
select * from Stock.[Size]
select * from Stock.TaxRate
select * from Stock.Product
select * from Stock.ProductModel order by ProductId, SizeId
select * from Stock.Color_Product
GO
select distinct ProductId , Model, BrandId , SizeId, Barcode , StandardUnitCost , TaxRateId , RecommendedRetailPrice , Weight , IsChiller , LeadTimeDays , PackageQuantity , BuyingPackageId , SellingPackageId  from Stock.ProductModel

select distinct ProductId , Model, SizeId, StandardUnitCost , TaxRateId , RecommendedRetailPrice , Weight , IsChiller , LeadTimeDays , PackageQuantity , BuyingPackageId , SellingPackageId  from Stock.ProductModel

SELECT distinct  ProductId , Model , SellingPackageId ,  SizeId , StandardUnitCost, Weight  from Stock.ProductModel

-- Migration check

-- Number of Customers

select count(distinct [WWI Customer ID]), count(distinct Customer) from WWI_OldData.dbo.Customer;
select count(*) from Customers.Customer
