-- Migration
use WWIGlobal
GO

CREATE OR ALTER PROCEDURE sp_import_continents
AS
BEGIN
    DECLARE continent_cur CURSOR FOR SELECT distinct Continent from WWI_OldData.dbo.City
    DECLARE @continent varchar(25)

    OPEN continent_cur
    FETCH NEXT FROM continent_cur INTO @continent

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT Name FROM Location.Continent WHERE Name = @continent)
        BEGIN 
            FETCH NEXT FROM continent_cur INTO @continent
        END
        ELSE
        BEGIN
            INSERT INTO Location.Continent(Name) VALUES(@continent)
            FETCH NEXT FROM continent_cur INTO @continent
        END
    END
    CLOSE continent_cur
    DEALLOCATE continent_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_countries
AS
BEGIN
    DECLARE country_cur CURSOR FOR select distinct Country, Continent from WWI_OldData.dbo.City
    DECLARE @country varchar(100), @continent varchar(25)

    OPEN country_cur
    FETCH NEXT FROM country_cur INTO @country, @continent

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS(select countryId from Location.Country where Name = @country)
        BEGIN 
            FETCH NEXT FROM country_cur INTO @country, @continent
        END
        ELSE
        BEGIN
            INSERT INTO LOCATION.Country VALUES(@country, (select continentId from Location.Continent where Name = @continent))
            FETCH NEXT FROM country_cur INTO @country, @continent
        END
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_sales_territory
AS
BEGIN
    DECLARE salesTer_cur CURSOR FOR SELECT distinct [Sales Territory] from WWI_OldData.dbo.City
    DECLARE @salesTer varchar(100)

    OPEN salesTer_cur
    FETCH NEXT FROM salesTer_cur INTO @salesTer

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT Territory FROM Location.SalesTerritory WHERE Territory = @salesTer)
        BEGIN 
            FETCH NEXT FROM salesTer_cur INTO @salesTer
        END
        ELSE
        BEGIN
            INSERT INTO Location.SalesTerritory(Territory) VALUES(@salesTer)
            FETCH NEXT FROM salesTer_cur INTO @salesTer
        END
    END
    CLOSE salesTer_cur
    DEALLOCATE salesTer_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_state_province @filepath nvarchar(255) = 'D:\GitHub\wwi\states.txt'
AS
BEGIN
	CREATE TABLE #BulkTemporary
	(
	    Code char(2),
	    Name varchar(100)
	)    

    DECLARE @sql nvarchar(500) = 'Bulk INSERT #BulkTemporary FROM ''' + @filepath +
	'WITH (FIELDTERMINATOR = '';'', ROWTERMINATOR = ''\n'')'
    EXEC(@sql)
	
    DECLARE stateProv_cur CURSOR FOR SELECT * FROM #BulkTemporary
    DECLARE @code char(2), @name varchar(255), @salesTerId int

    OPEN stateProv_cur
    FETCH NEXT FROM stateProv_cur INTO @code, @name

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (select code from Location.StateProvince where @code = code)
        BEGIN
            FETCH NEXT FROM stateProv_cur INTO @code, @name
        END
        ELSE
        BEGIN
            select @salesTerId = SalesTerritoryId 
            from WWIGlobal.[Location].SalesTerritory 
            where Territory = (SELECT TOP 1 [Sales Territory] from WWI_OldData.dbo.City where [State Province] = @name)

            INSERT INTO Location.StateProvince VALUES(@code, @name, @salesTerId)
            FETCH NEXT FROM stateProv_cur INTO @code, @name
        END 
    END

	--Drop temporary table
	DROP TABLE #BulkTemporary
    CLOSE stateProv_cur
    DEALLOCATE stateProv_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_state_country
AS
BEGIN
    DECLARE country_state_cur CURSOR FOR SELECT [State Province], Country from WWI_OldData.dbo.City GROUP BY [State Province], Country 
    DECLARE @country varchar(100), @state varchar(100), @countryId int, @stateProvId int
    
    OPEN country_state_cur
    FETCH NEXT FROM country_state_cur INTO @state, @country

    WHILE @@FETCH_STATUS = 0
    BEGIN
        select @countryId = countryId FROM Location.Country where name = @country
        select @stateProvId = Code FROM Location.StateProvince where name = @state

        IF @countryId is null or @stateProvId is null
        BEGIN 
            PRINT N'Error: There is no '+ @country +' or ' + @state + 'in the current database!'
            FETCH NEXT FROM country_state_cur INTO @state, @country
        END

        INSERT INTO Location.StateProvince_Country VALUES(@stateProvId,@countryId)
        FETCH NEXT FROM country_state_cur INTO @state, @country
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_city_names
AS
BEGIN
    DECLARE city_cur CURSOR FOR SELECT distinct City from WWI_OldData.dbo.City
    DECLARE @city varchar(100)

    OPEN city_cur 
    FETCH NEXT FROM city_cur INTO @city

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT Name FROM Location.CityName WHERE Name = @city)
        BEGIN 
            FETCH NEXT FROM city_cur INTO @city
        END
        ELSE
        BEGIN
            INSERT INTO Location.CityName(Name) VALUES(@city)
            FETCH NEXT FROM city_cur INTO @city
        END
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_cities
AS
BEGIN
    DECLARE city_cur CURSOR FOR SELECT city, [Latest Recorded Population], [State Province], Country FROM WWI_OldData.dbo.City group by City, [State Province], country, [Latest Recorded Population]

    DECLARE @city varchar(100), @cityNameId int,
    @population int,
    @stateProv varchar(255), @stateProvCode int,
    @country varchar(100), @countryId int

    OPEN city_cur
    FETCH NEXT FROM city_cur INTO @city, @stateProv, @country

    WHILE @@FETCH_STATUS = 0
    BEGIN 
        select @cityNameId = cityNameId from Location.CityName where Name = @city
        select @stateProvCode = Code from Location.StateProvince where Name = @stateProv
        select @countryId = CountryId from Location.Country where Name = @country

        IF EXISTS (
            select cityId 
            from Location.City 
            where 
                CityNameId = @cityNameId and
                StateProvinceCode = @stateProvCode and
                CountryId = @countryId
        )
        BEGIN
            UPDATE Location.City 
            SET Population = @population 
            where 
                CityNameId = @cityNameId and
                StateProvinceCode = @stateProvCode and
                 CountryId = @countryId
            FETCH NEXT FROM city_cur INTO @city, @stateProv, @country
        END
        ELSE
        BEGIN
            INSERT INTO Location.City(CityNameId, StateProvinceCode, CountryId, Population) 
            VALUES(@cityNameId, @stateProvCode, @countryId, @population)
            FETCH NEXT FROM city_cur INTO @city, @stateProv, @country
        END
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_postalCode
AS
BEGIN
    DECLARE postalCode_cur CURSOR FOR SELECT distinct [Postal Code] from WWI_OldData.dbo.Customer
    DECLARE @postalCode int

    open postalCode_cur
    FETCH NEXT FROM postalCode_cur INTO @postalCode
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (select code from [Location].PostalCode where @postalCode = Code)
        BEGIN
            INSERT INTO Location.PostalCode(Code) VALUES(@postalCode)
        END
        FETCH NEXT FROM postalCode_cur INTO @postalCode
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_address
AS
BEGIN
    DECLARE address_cur CURSOR FOR 
    SELECT 
    substring(Customer, charindex('(', Customer)+1, charindex(')',Customer)-1-charindex('(', Customer)), 
    [Postal Code] 
    from Customer 
    group by Customer, [Postal Code];

    DECLARE 
    @cityAndState varchar(55),
    @city varchar(50),
    @stateCode char(2),
    @cityId int,
    @postalCode int

    OPEN address_cur
    FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @cityAndState like '%,%'
        begin 
            set @city = substring(@cityAndState, 1, charindex(',',Customer)-1)
            set @stateCode = substring(@cityAndState, charindex(',', Customer)+1, len(Customer))
        
            select @cityId = cityId from Location.City where stateProvinceCode = @stateCode and @city = name 
            IF NOT EXISTS (select addressId from Address where cityId = @cityId and @postalCode = postalCode)
            BEGIN
                INSERT INTO Address(PostalCode, City) VALUES(@postalCode, @cityId)
            END
            FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode
        end 
        else 
        begin 
            INSERT INTO Address(PostalCode) VALUES(@postalCode)
            FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode
        end 
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_buyingGroups
AS 
BEGIN
    DECLARE buyingGroup_cur CURSOR FOR SELECT distinct [Buying group] from WWI_OldData.dbo.Customer
    DECLARE @buyingGroup varchar(100)

    OPEN buyingGroup_cur
    FETCH NEXT FROM buyingGroup_cur INTO @buyingGroup

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT name from Customers.BuyingGroup where name = @buyingGroup)
        BEGIN
            INSERT INTO Customers.BuyingGroup(Name) Values(@buyingGroup)
        END
        FETCH NEXT FROM buyingGroup_cur INTO @buyingGroup
    END
END
GO

CREATE OR ALTER PROCEDURE sp_import_businessCategory
AS 
BEGIN
    DECLARE businessCat_cur CURSOR FOR SELECT distinct Name from WWI_OldData.dbo.categories
    DECLARE @businessCategory varchar(100)

    OPEN businessCat_cur
    FETCH NEXT FROM businessCat_cur INTO @buyingGroup

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT name from Customers.BuyingGroup where name = @businessCategory)
        BEGIN
            INSERT INTO Customers.BuyingGroup(Name) Values(@businessCategory)
        END
        FETCH NEXT FROM businessCat_cur INTO @buyingGroup
    END
END
GO

--TODO: Customer
--TODO: Contacts
--TODO: Populate SystemUser 
--TODO: Color, Brand, Size, Package, Product, ProductModel
--TODO: Employee, Salesperson
--TODO: Populate Currency
--TODO: TaxRate, SalesOrderHeader, SalesOrderDetails
--TODO: Transport, Logistic

exec sp_import_continents;
exec sp_import_countries;
exec sp_import_sales_territory;
exec sp_import_state_province;
exec sp_import_city_names;
exec sp_import_cities;
exec sp_import_postaCode;
exec sp_import_address;
exec sp_import_buyingGroups;
exec sp_import_businessCategory;
GO

-- TODO: REMOVE TESTING STUFF
use WWI_OldData
select * from City;
select * from Sale;
select * from [Stock Item];
select * from dbo.Customer;
select * from dbo.Employee;
GO