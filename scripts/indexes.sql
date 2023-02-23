-- Indexes
use WWIGlobal
GO

-- Vendas por cidade (nome da cidade, nome do vendedor, total de vendas)
--drop VIEW Sales.vw_salesPerCity
CREATE VIEW Sales.vw_salesPerCity
as 
select cn.Name, CONCAT_WS(' ', e.FirstName, e.LastName) as SalespersonName, count(*) SalesNumber 
from Sales.SalesOrderHeader soh
inner join [Location].City c on c.CityId = soh.CityId
inner join [Location].CityName cn on cn.CityNameId = c.CityNameId
inner join CompanyResources.Employee e on e.EmployeeId = soh.SalespersonId
group by cn.Name, CONCAT_WS(' ', e.FirstName, e.LastName)
GO

-- City
--DROP INDEX nc_salesOrderheader_salespersonCity ON Sales.SalesOrderHeader
CREATE NONCLUSTERED INDEX nc_salesOrderheader_salespersonCity ON Sales.SalesOrderHeader(cityId, salespersonId)
GO


--Taxa de crescimento de cada ano por categoria de cliente (atual-anterio/anterior)
--drop view Sales.vw_increaseRate
--GO
CREATE VIEW Sales.vw_increaseRate
AS
select soh1.Name, 
soh1.curYear,   
soh1.CuryearCount,
soh2.lastYearCount,
cast(((soh1.curYearCount - soh2.lastYearCount)/soh2.lastYearCount) as decimal(8,3)) as increaseRate
from 
(select year(dueDate) as curYear, bc.Name, convert(decimal(8,3), count(soh.SaleId)) as curYearCount 
    from Sales.SalesOrderHeader soh
    inner join Customers.Customer c on c.CustomerId = soh.CustomerId 
    inner join Customers.BusinessCategory bc on bc.CategoryId = c.CategoryId
    group by year(DueDate), bc.Name) soh1 
inner join (
    select year(dueDate) as salesYear, bc.Name, convert(decimal(8,3),count(soh.SaleId)) as lastYearCount 
    from Sales.SalesOrderHeader soh
    inner join Customers.Customer c on c.CustomerId = soh.CustomerId 
    inner join Customers.BusinessCategory bc on bc.CategoryId = c.CategoryId
    group by year(DueDate), bc.Name
) soh2 
on soh1.curYear-1 = soh2.salesYear and soh2.Name = soh1.Name
GO
--DROP INDEX nc_salesOrderHeader_customerId ON Sales.SalesOrderheader
CREATE NONCLUSTERED INDEX nc_salesOrderHeader_customerId ON Sales.SalesOrderheader(customerId) include (DueDate)
GO

--Número de produtos nas vendas por cor
--drop view Sales.productPercolor
CREATE VIEW Sales.vw_numberOfProducts_inSales_PerColor
AS
select p.Name, pm.Model, c.Name as ColorName, count(sod.SaleId) as Sales from  Stock.ProductModel pm
inner join Stock.Product p on p.ProductId = pm.ProductId
inner join Stock.Color_Product cp on cp.ProductModelId = pm.ProductModelId
inner join Stock.Color c on c.ColorId = cp.ColorId
inner join Sales.SalesOrderDetails sod on sod.ProductId = pm.ProductModelId
group by c.Name, p.Name, pm.Model
go
--drop  INDEX nc_salesorderdetails_productId ON Sales.SalesOrderDetails
CREATE NONCLUSTERED INDEX nc_salesorderdetails_productId ON Sales.SalesOrderDetails(ProductId)
Go

SET STATISTICS IO ON
GO
select * from Sales.vw_salesPerCity
GO
select * from Sales.vw_increaseRate
GO
select * from Sales.vw_numberOfProducts_inSales_PerColor
GO

SET STATISTICS IO OFF
GO