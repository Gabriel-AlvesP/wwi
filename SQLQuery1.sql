use WWI_OldData;
GO

select * from Sale order by [Sale Key] asc;
select * from [Stock Item]; 
select * from Customer;
GO

-- Filegroup queries

-- Employee
select * from Employee order by Employee;
select count(distinct Employee) from Employee;
select AVG(LEN(e.Employee)) as 'Name',  AVG(Len(e.[Preferred Name])) as 'Prefered Name' from Employee e;
select Count(distinct e.Employee) as 'IsSalesman' from Employee e where e.[Is Salesperson] = 1;

-- From City Table 
-- SalesTerritory
select * from City;
select count(distinct [Sales Territory]) from City;
select AVG(LEN([Sales Territory])) from City;

-- City Name
select distinct City from City;
select count(distinct City) as 'Distinct Cities', AVG(LEN(City)) as 'AVG LEN' from City;

-- Continent
select distinct Continent from City;
select count(distinct Continent), AVG(LEN(Continent)) from City;

-- Country 
select distinct Country from City;
select count(distinct Country) as 'Distinct Countries', AVG(LEN(Country)) from City;

-- State Province
select distinct [State Province] from City;
select count(distinct [State Province]) as 'Distinct States', AVG(LEN([State Province])) as 'States Avg len' from City;

-- Category
select distinct Category from Customer order by Category;
select count(distinct Category) from Customer; -- same as the excel

-- Postal Code
select distinct [Postal Code] from Customer order by [Postal Code];
select count(distinct [Postal Code]) from Customer ;
