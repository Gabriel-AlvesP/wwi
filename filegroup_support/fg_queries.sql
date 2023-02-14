use WWI_OldData
GO

-- In business time (01/01/2013 - 31/05/2016)
select MIN([Invoice Date Key]), MAX([Invoice Date Key]) from Sale ;
go

-- Filegroup queries
-- The following group of queries are group by table names (new database)

-- Employee
select Employee,
	substring(Employee, 1, charindex(' ', Employee)-1) as 'firstname',
	substring(Employee, charindex(' ', Employee)+1, LEN(Employee)) as 'lastname'
from (select distinct Employee from Employee) e; -- All name, first name, last name

select count(distinct Employee) as 'Different Names' from Employee; -- Number of different names

select
	AVG(LEN(substring(Employee, 1, charindex(' ', Employee)-1))) as 'firstname',
	AVG(LEN(substring(Employee, charindex(' ', Employee)+1, LEN(Employee)))) as 'lastname'
from (select distinct Employee from Employee) e; -- 1s and Last names average length
GO

--Salesman
select Count(distinct e.Employee) as 'IsSalesman' from Employee e where e.[Is Salesperson] = 1; -- Salesman number
GO

-- From City Table
-- SalesTerritory
select  count([Sales Territory]), count(distinct [Sales Territory]) as 'Different SalesTerritory' from City;
select AVG(LEN([Sales Territory])) as 'AVG Len' from (select distinct [Sales Territory] from City) c;
GO

-- City Name
select count(City), count(distinct City) as 'Different Cities' from City;
select AVG(LEN(City)) as 'Avg Len' from (select distinct City from City) c;
GO

-- (City, State Province) different entries
select city, [State Province], Count(*) from City group by City, [State Province] order by city;
GO
select count(city) from (select city from City group by City, [State Province], country) x;
select count(city) from (select city from City group by City, [State Province], country, [Latest Recorded Population]) x;
GO

-- Continent
select distinct Continent from City;
select count(distinct Continent) as 'Different Continents', AVG(LEN(Continent)) as 'Avg len' from City;
GO

-- Country
select distinct Country from City;
select count(distinct Country) as 'Different Countries', AVG(LEN(Country)) as 'Avg len' from City;
GO

-- State Province
select count([State Province]), count(distinct [State Province]) as 'Different States' from City;
select AVG(LEN([State Province])) as 'States Avg len' from (select [State Province] from City) c;
GO

--Sales Territory
select distinct [Sales Territory] from City;
GO

-- Postal Code
select count([Postal Code]), count(distinct [Postal Code]) as 'Different Postal Codes' from Customer;
GO

-- Business Category
select distinct Category from Customer;
select count(distinct Category) from Customer; -- same as the lookup.xlsx
-- GiftShop, Kiosk repeated
-- correction: 5
GO

-- Buying Group
select count([Buying Group]), count(distinct [Buying Group]) from Customer;
select avg(len([Buying Group])) from (select distinct [Buying Group] from Customer) c;
GO

-- Colors
select [Stock Item] from [Stock Item];
select [Stock Item] from [Stock Item] si where si.[Stock Item] COLLATE Latin1_General_CS_AS like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%' ;

select distinct Color from [Stock Item];
select distinct substring(x, 1, charindex(')', x)-1) as color from (
	select substring([Stock Item], charindex('(', [Stock Item])+1, Len([Stock Item])) as x
	from [Stock Item] si
	where si.[Stock Item]
	COLLATE Latin1_General_CS_AS
	like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%)%'
) s where x COLLATE Latin1_General_CS_AS like '[ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'; -- Get different color from stock item name
-- The last 'where' is essential bc of this pattern xxxx(something)(Color) -> something

------------------------------------------------------------------------------------------------------

-- Product, Product Model
-- Tip: Product pattern %[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% - model% number||(Color) size
select distinct [Stock Item], si.Size, si.[Typical Weight Per Unit] from [Stock Item] si order by [Stock Item];
GO

-- Different Products without models
--select avg(len(NoModelProducts)) from ( -- Avg
select distinct NoModelProducts from (select case when sol like '%[0-9][gm]' or sol like '%[1-9]mm'
then
	-- Remove size from products
	 SUBSTRING(sol, 1,  len(sol) - charindex(' ', reverse(sol)))
else
	-- Products without the size on the name
	sol
end as NoModelProducts
from (
	select case when si COLLATE Latin1_General_CS_AS like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'
	then
		-- Remove color from the product name
		substring(si, 1, charindex('(', si)-2)
	else
		-- Products without color on the name
		si
	end as sol
	from (
		-- Remove Products with models
		select distinct [Stock Item] as 'si' from [Stock Item]
		where [Stock Item]
		COLLATE Latin1_General_CS_AS not like '%[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% -%'
	) si
) x) y
--)z; -- Avg
GO

-- Products w/ models (4)
--select avg(len(sol)) from ( -- Avg
select distinct substring([Stock Item], 1, charindex('-', [Stock Item])-1) as sol from [Stock Item] where [Stock Item]
COLLATE Latin1_General_CS_AS like '%[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% -%'
--) x -- Avg
GO

-- Number of models (33)
--select avg(len(productModel)) from ( -- Avg
	select distinct productModel from (select case when x.sq like '(%'
	then
		substring(x.sq, 1, charindex(')', x.sq))
	else
		case when x.sq like '%(%'
		then
			SUBSTRING(x.sq, 1, charindex('(', x.sq)-1)
		else
			x.sq
		end
	end as productModel
	from (
		select
			distinct substring([Stock Item],
			charindex('-', [Stock Item])+2, len([Stock Item])) as 'sq'
		from [Stock Item]
		where [Stock Item] COLLATE Latin1_General_CS_AS like '%[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% -%') x) y
--) z; -- Avg
GO

-----------------------------------------------------------

-- Size
select distinct Size from [Stock Item]
GO

-- Brand
select Avg(len(Brand)) from (select distinct Brand from [Stock Item]) x;
GO

-- Package
-- Bag, Each, Packet, Pair, Carton = 5
select distinct [Selling Package] from [Stock Item];
select distinct [Buying Package] from [Stock Item];
GO

-- Color_Product
select color, [Stock Item] from [Stock Item] where color != 'N/A' and color is not null and  [Stock Item]
	COLLATE Latin1_General_CS_AS
	not like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%)%'; -- check for items without the color in the name and with the column color not null

select count(substring([Stock Item], charindex('(', [Stock Item])+1, Len([Stock Item]))) as 'N Product w/ Color'
	from [Stock Item] si
	where si.[Stock Item]
	COLLATE Latin1_General_CS_AS
	like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%)%';
GO

-- SalesOrderHeader, Bills
select * from Sale order by [WWI Invoice ID];
select count(distinct s.[WWI Invoice ID]) from Sale s;
GO
-- SalesOrderDetail
select count(*) from Sale;
GO

select distinct [Tax Rate] from Sale;

-- Customer
select * from Customer;
select count(distinct [WWI Customer ID]), count(distinct Customer) from Customer;
select Customer, [Postal Code], count(*) from Customer group by Customer, [Postal Code]
select AVG(LEN([Primary Contact])) from Customer;
GO
