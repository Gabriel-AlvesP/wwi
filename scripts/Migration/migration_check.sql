-- Migration check
use WWIGlobal
GO

-- Inicio requisitos min --
----------------------------------------------

-- Number of Customers :)
select count(Customer) from WWI_OldData.dbo.Customer;
GO
--
select count(*) from Customers.Customer;
GO
--
-----------------------------------------------

-- Customers per Category :)
select Category, count(*) 
from WWI_OldData.dbo.Customer 
group by Category
GO
--
select c.CategoryId, bc.Name, count(*) 
from Customers.Customer c 
left join Customers.BusinessCategory bc 
on bc.CategoryId = c.CategoryId 
group by c.categoryId, bc.Name
GO
--

-----------------------------------------------

-- Employee sales (sales per employee) :)
select e.Employee, count(distinct s.[WWI Invoice ID]) 
from WWI_OldData.dbo.Sale s 
join WWI_OldData.dbo.Employee e 
on e.[Employee Key] = s.[Salesperson Key] 
group by  e.Employee 
order by e.Employee
GO
--
select concat(e.FirstName, ' ', e.LastName), count(*) 
from Sales.SalesOrderHeader soh 
join CompanyResources.Employee e 
on e.EmployeeId = soh.SalespersonId 
group by e.FirstName, e.LastName 
order by e.FirstName, e.LastName
GO
--

-----------------------------------------------

-- Value in sales per Stock item - dinheiro em vendas por produto
select x.product, sum(sum) from ( select distinct case when si.product
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
sum(s.[Total Excluding Tax]) as sum
from (
	select distinct [Stock Item] as product,
	[Stock Item Key] 
	from WWI_OldData.dbo.[Stock Item]
) si 
join WWI_OldData.dbo.Sale s on si.[Stock Item Key] = s.[Stock Item Key]
right join Sales.SalesOrderHeader soh on soh.SaleId = s.[WWI Invoice ID] and s.[Customer Key] = soh.CustomerId
group by si.product ) x group by x.product order by x.product
GO

--
select 
p.Name, sum(sod.Quantity * pm.StandardUnitCost)
from Sales.SalesOrderDetails sod 
inner join Stock.ProductModel pm on sod.ProductId = pm.ProductModelId 
inner join Stock.Product p on p.ProductId = pm.ProductId
group by p.Name
order by p.Name
GO
--

-----------------------------------------------

-- Value in sales per year and stock item
select x.product, year, sum(sum) from ( select distinct case when si.product
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
sum(s.[Total Excluding Tax]) as sum,
Year(s.[Invoice Date Key]) as year
from (
	select distinct [Stock Item] as product,
	[Stock Item Key] 
	from WWI_OldData.dbo.[Stock Item]
) si 
inner join WWI_OldData.dbo.Sale s on si.[Stock Item Key] = s.[Stock Item Key]
right join Sales.SalesOrderHeader soh on soh.SaleId = s.[WWI Invoice ID] and s.[Customer Key] = soh.CustomerId
group by si.product, s.[Invoice Date Key]) x 
group by x.product, year 
order by year, x.product
GO
--
select p.name, YEAR(soh.DueDate), SUM(pm.StandardUnitCost * sod.Quantity) 
from Sales.SalesOrderDetails sod
inner join Stock.ProductModel pm on sod.Productid = pm.ProductModelId
inner join Stock.Product p on pm.ProductId = p.ProductId
inner join Sales.SalesOrderHeader soh on sod.SaleId = soh.Saleid 
group by  p.Name, YEAR(soh.DueDate)
order by YEAR(soh.DueDate), p.Name
GO
--

-----------------------------------------------

-- Value in sales per year and city
select c.City, YEAR(s.[Invoice Date Key]), SUM(s.[Total Excluding Tax]) 
from WWI_OldData.dbo.Sale s
inner join Sales.SalesOrderHeader soh on soh.SaleId = s.[WWI Invoice ID] and s.[Customer Key] = soh.CustomerId
inner join WWI_OldData.dbo.City c on s.[City Key] = c.[City Key]
group by c.City, c.[State Province], YEAR(s.[Invoice Date Key])
order by YEAR(s.[Invoice Date Key]), c.City
GO

--
select  cn.Name, YEAR(soh.DueDate), SUM(pm.StandardUnitCost * sod.Quantity)
from Sales.SalesOrderDetails sod
inner join Stock.ProductModel pm on sod.Productid = pm.ProductModelId
inner join Sales.SalesOrderHeader soh on sod.SaleId = soh.Saleid 
inner join [Location].City c on c.CityId = soh.CityId
inner join [Location].CityName cn on cn.CityNameId = c.CityNameId
group by  YEAR(soh.DueDate), cn.Name
order by YEAR(soh.DueDate), cn.Name
GO
--

-----------------------------------------------

-- Fim requisitos min --

-----------------------------------------------

-- City tables :( 
select City, [State Province]
from WWI_OldData.dbo.City c
group by City, [State Province]
GO
--  Should have 37940 -> have 37867 => 73
select cn.Name, StateProvinceCode 
from [Location].City c
inner join [Location].CityName cn on cn.CityNameId = c.CityNameId
group by c.CityNameId, cn.Name, StateProvinceCode 
GO
--
-----------------------------------------------

-- Different products (Models) :)
select p.name ,pm.Model, pm.RecommendedRetailPrice ,pm.StandardUnitCost, pm.CurrentRetailPrice, pm.Weight
from Stock.ProductModel pm
inner join Stock.Product p on p.ProductId = pm.ProductId

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
    END as barcode,
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
) si 

-----------------------------------------------

-- Number of sales :)
select count(distinct [WWI Invoice Id]) from WWI_OldData.dbo.Sale 
select count(*) from Sales.SalesOrderHeader
GO
-----------------------------------------------

-- Number of Cities (names) :)
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
GO
-----------------------------------------------

-- Transactions Number (SalesOrderDetails) :((
select count([WWI Invoice ID]) from WWI_OldData.dbo.Sale s 
join Sales.SalesOrderHeader soh 
on s.[WWI Invoice ID] = soh.SaleId and s.[Customer Key] = soh.CustomerId
GO
--
select  count(*) from Sales.SalesOrderDetails 
GO
--

-- Old database (SaleOrderDetails)
select [WWI Invoice ID], [Customer Key], [Stock Item Key] ,Quantity, [Unit Price] from WWI_OldData.dbo.Sale order by [WWI Invoice ID]
GO
-- what new salesorderheader should contain
select [WWI Invoice ID], [Customer Key], s.Quantity, s.[Unit Price] from WWI_OldData.dbo.Sale s join Sales.SalesOrderHeader soh on s.[WWI Invoice ID] = soh.SaleId and s.[Customer Key] = soh.CustomerId order by [WWI Invoice ID]
GO
-- New SalesOrderDetails
select sod.SaleId, soh.CustomerId, sod.ProductId, sod.Quantity, sod.TaxRateId, sod.DiscountId from Sales.SalesOrderDetails sod left join Sales.SalesOrderHeader soh on sod.SaleId = soh.SaleId 
order by soh.SaleId
GO

-----------------------------------------------
use WWIGlobal;
select p.Name, b.Name, s.Value, tr.[Value], pm.*
from Stock.ProductModel pm 
inner join Stock.Product p on p.ProductId = pm.ProductId 
inner join Stock.Brand b on b.BrandId = pm.BrandId
inner join Stock.[Size] s on s.SizeId = pm.SizeId
inner join Stock.TaxRate tr on tr.TaxRateId = pm.TaxRateId
where ProductModelId= 63

select * from WWI_OldData.dbo.[Stock Item] where [Stock Item Key]= 196