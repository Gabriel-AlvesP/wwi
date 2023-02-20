-- Migration check
use WWIGlobal
GO

-- Number of Customers :)
select * from WWI_OldData.dbo.Customer
select count(Customer) from WWI_OldData.dbo.Customer;
select count(Customer) from WWI_OldData.dbo.Customer;
select count(*) from Customers.Customer;
GO
-----------------------------------------------

-- Customers per Category :)
select Category, count(*) from WWI_OldData.dbo.Customer group by Category
select CategoryId, count(*) from Customers.Customer group by categoryId
-----------------------------------------------
GO

-- Number of Cities :)
select count(distinct City) from WWI_OldData.dbo.City
select count(Name) from Location.CityName
GO
-----------------------------------------------

-- States (57) .txt file :)
select count(*) as StatesNumber from Location.StateProvince 
select * from [Location].StateProvince
GO
-----------------------------------------------

-- State_Country :)
select * from Location.StateProvince_Country
GO
-----------------------------------------------

-- Address
select count(*) from Location.Address
-----------------------------------------------

-- Different products (Models)
select * from Stock.ProductModel 
select distinct case when si.product
COLLATE Latin1_General_CS_AS not like '%[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% -%'
THEN
	-- Product without sub-model
	case when si.product COLLATE Latin1_General_CS_AS like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'
	then
		-- Remove color from the product name
		trim(substring(si.product, 1, charindex('(', si.product)-2))
	else
		-- Products without color on the name
		case when si.product like '%[0-9][gm]' or si.product like '%[1-9]mm'
		then
			-- Remove size from products
			 trim(SUBSTRING(si.product, 1,  len(si.product) - charindex(' ', reverse(si.product))))
		else
			-- Products without the size on the name
			si.product
		end
	end 
ELSE
	-- Product with sub-model
	trim(substring(si.product, 1, charindex('-', si.product)-2))
END as product, 

    -- Model
case when si.product COLLATE Latin1_General_CS_AS like '%[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% -%'
THEN
	case when 
		-- Model
		substring(si.product, charindex('-', si.product)+2, len(si.product))
	like '(%'
	then
		-- (hip hip array)
		trim(substring(
			substring(si.product, charindex('-', si.product)+2, len(si.product)),
			1,
			charindex(')', substring(si.product, charindex('-', si.product)+2, len(si.product)))
		))

	else
		case when 
			substring(si.product, charindex('-', si.product)+2, len(si.product)) 
 		like '%(%'
		then
			-- Remove color
			trim(SUBSTRING(
				substring(si.product, charindex('-', si.product)+2, len(si.product)),
				1,
				charindex('(', substring(si.product, charindex('-', si.product)+2, len(si.product)) )-1
			))
		ELSE
			trim(substring(si.product, charindex('-', si.product)+2, len(si.product)))
		END
	END
ELSE
        ''
END as model,
[Selling Package],
[Buying Package],
Brand,
Size,
[Lead Time Days],
[Quantity Per Outer],
[Is Chiller Stock],
case when Barcode = N'N/A' THEN
        '' 
    ELSE
        cast(barcode as varchar(25))
    END,
[Tax Rate],
[Unit Price],
[Recommended Retail Price],
[Typical Weight Per Unit]
from (
	select distinct [Stock Item] as product,
	[Selling Package],
	[Buying Package],
	Brand,
	Size,
	[Lead Time Days],
	[Quantity Per Outer],
	[Is Chiller Stock],
	Barcode,
	[Tax Rate],
	[Unit Price],
	[Recommended Retail Price],
	[Typical Weight Per Unit] 
	from WWI_OldData.dbo.[Stock Item]
) si ;

-- Number of sales
select count(distinct [WWI Invoice Id]) from WWI_OldData.dbo.Sale 
select count(*) from Sales.SalesOrderHeader
select * from Sales.SalesOrderHeader
GO
-----------------------------------------------

-- SalesOrderDetails
-- Transactions Number (SalesOrderDetails)
select count([WWI Invoice ID]) from WWI_OldData.dbo.Sale s join Sales.SalesOrderHeader soh on s.[WWI Invoice ID] = soh.SaleId and s.[Customer Key] = soh.CustomerId
select  count(*) from Sales.SalesOrderDetails 
select * from Sales.SalesOrderDetails

-- Old database
select [WWI Invoice ID], [Customer Key], [Stock Item Key] ,Quantity, [Unit Price] from WWI_OldData.dbo.Sale order by [WWI Invoice ID]
-- what new salesorderheader should contain
select [WWI Invoice ID], [Customer Key], s.Quantity, s.[Unit Price] from WWI_OldData.dbo.Sale s join Sales.SalesOrderHeader soh on s.[WWI Invoice ID] = soh.SaleId and s.[Customer Key] = soh.CustomerId order by [WWI Invoice ID]
-- New SalesOrderDetails
select sod.SaleId, soh.CustomerId, sod.ProductId, sod.Quantity, sod.ListedUnitPrice, sod.TaxRateId, sod.DiscountId from Sales.SalesOrderDetails sod left join Sales.SalesOrderHeader soh on sod.SaleId = soh.SaleId order by sod.SaleId

-----------------------------------------------

select * from Stock.ProductModel