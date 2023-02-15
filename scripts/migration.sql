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
    CLOSE country_cur
    DEALLOCATE country_cur
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
    CLOSE country_state_cur
    DEALLOCATE country_state_cur
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
    CLOSE city_cur
    DEALLOCATE city_cur
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
    CLOSE city_cur
    DEALLOCATE city_cur
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
    CLOSE postalCode_cur
    DEALLOCATE postalCode_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_address
AS
BEGIN
    DECLARE address_cur CURSOR FOR 
    SELECT 
    substring(Customer, charindex('(', Customer)+1, charindex(')',Customer)-1-charindex('(', Customer)), 
    [Postal Code] 
    from WWI_OldData.dbo.Customer 
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
            set @city = substring(@cityAndState, 1, charindex(',',@cityAndState)-1)
            set @stateCode = substring(@cityAndState, charindex(',', @cityAndState)+1, len(@cityAndState))
        
            select @cityId = cityId from Location.City c join Location.CityName cn on c.CityNameId = cn.CityNameId where stateProvinceCode = @stateCode and cn.Name = @city

            IF NOT EXISTS (select addressId from Location.Address where cityId = @cityId and @postalCode = postalCode)
            BEGIN
                INSERT INTO Location.Address(PostalCode, CityId) VALUES(@postalCode, @cityId)
            END
            FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode
        END 
        ELSE 
        BEGIN 
            INSERT INTO Location.Address(PostalCode) VALUES(@postalCode)
            FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode
        END 
    END
    CLOSE address_cur
    DEALLOCATE address_cur
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
    CLOSE buyingGroup_cur
    DEALLOCATE buyingGroup_cur
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
        IF NOT EXISTS (SELECT categoryId from Customers.BusinessCategory where Name = @businessCategory)
        BEGIN
            INSERT INTO Customers.BusinessCategory(Name) Values(@businessCategory)
        END
        FETCH NEXT FROM businessCat_cur INTO @businessCategory
    END
    CLOSE businessCat_cur
    DEALLOCATE businessCat_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_customer
AS
BEGIN
    DECLARE customer_cur CURSOR FOR 
    SELECT 
    [Customer Key]
    Category,
    [Buying Group],
    substring(Customer, charindex('(', Customer)+1, charindex(')',Customer)-1-charindex('(', Customer)), -- Address
    [Postal Code],
    [Primary Contact]
    from WWI_OldData.dbo.Customer 

    DECLARE 
    @customerId int,
    @category varchar(50), @categoryId int,
    @buyingGroup varchar(100), @buyingGroupId int,
    @cityAndState varchar(55), @city varchar(50), @stateCode char(2), @cityId int, @addressId int,
    @postalCode int,
    @contact varchar(50),
    @isHeadOffice bit

    OPEN customer_cur
    FETCH NEXT FROM customer_cur 
    INTO @customerId, @category, @buyingGroup, @cityAndState, @postalCode, @contact

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Start Address handling 
        IF @cityAndState like '%,%'
        BEGIN 
            -- Customer is not headoffice, insert address (check cityName and state)
            set @city = substring(@cityAndState, 1, charindex(',',@cityAndState)-1)
            set @stateCode = substring(@cityAndState, charindex(',', @cityAndState)+1, len(@cityAndState))
        
            select @cityId = cityId from Location.City c join Location.CityName cn on c.CityNameId = cn.CityNameId where stateProvinceCode = @stateCode and cn.Name = @city

            IF NOT EXISTS (select addressId from Location.Address where cityId = @cityId and @postalCode = postalCode)
            BEGIN
                INSERT INTO Location.Address(PostalCode, CityId) VALUES(@postalCode, @cityId)
                set @addressId = SCOPE_IDENTITY()
            END
            ELSE
            BEGIN
                select @addressId = addressId from Location.Address where CityId = @cityId and PostalCode = @postalCode
            END 
            set @isHeadOffice = 0
        END 
        ELSE 
        BEGIN 
            -- Customer is headOffice, inster address with only postal code
            IF NOT EXISTS (SELECT addressId from Location.Address where PostalCode = @postalCode and CityId is null)
            BEGIN
                INSERT INTO Location.Address(PostalCode) VALUES(@postalCode)
                set @addressId = SCOPE_IDENTITY()
            END
            ELSE
            BEGIN
                SELECT @addressId = AddressId from Location.Address where PostalCode = @postalCode and CityId is null
            END
            set @isHeadOffice = 1
        END 
        -- End Address handling

        -- Start Customer 
        select @buyingGroupId = buyingGroupId from Customers.BuyingGroup where Name = @buyingGroup
        select @categoryId = categoryId from Customers.BusinessCategory where Name = @category
        IF @categoryId is NULL
        BEGIN
            -- Check for misspelled categories (Quiosk, GiftShop)
            IF @category like 'Q%'
            BEGIN
                select @categoryId = categoryId from Customers.BusinessCategory where Name = 'Kiosk'
            END
            ELSE
            BEGIN
                select @categoryId = categoryId from Customers.BusinessCategory where Name = 'Gift Shop'
            END
        END

        IF NOT EXISTS (
            SELECT CustomerId 
            from Customers.Customer 
            where BuyingGroupId = @buyingGroup
            and CategoryId = @categoryId
            and AddressId = @addressId
        )
        BEGIN
            INSERT INTO Customers.Customer(customerId, isHeadOffice, BuyingGroupId, CategoryId, AddressId) 
            VALUES(@customerId, @isHeadOffice, @buyingGroupId, @categoryId, @addressId)

            -- Insert customer primary contact
            INSERT Customers.Contacts(Name, IsPrimary, CustomerId) VALUES(@contact, 1, @customerId)
        END

        FETCH NEXT FROM customer_cur 
        INTO @customerId, @category, @buyingGroup, @cityAndState, @postalCode, @contact
    END
    CLOSE customer_cur
    DEALLOCATE customer_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_employee
AS
BEGIN
    DECLARE employee_cur CURSOR FOR 
    select 
	    substring(Employee, 1, charindex(' ', Employee)-1) as 'firstname',
	    substring(Employee, charindex(' ', Employee)+1, LEN(Employee)) as 'lastname',
        [Preferred Name],
	    [Is Salesperson],
	    Photo
    from (
        select distinct Employee, Photo, [Is Salesperson], [Preferred Name]
        from WWI_OldData.dbo.Employee) e

    DECLARE 
    @firstName varchar(30), 
    @lastName varchar(30),
    @prefName varchar(30),
    @prefNameBit bit,
    @isSalesperson bit,
    @photo varchar(255)
    
    OPEN employee_cur
    FETCH NEXT FROM employee_cur INTO @firstName, @lastName, @prefName, @isSalesperson, @photo

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (
            SELECT EmployeeId 
            from CompanyResources.Employee 
            where FirstName = @firstName
            and LastName = @lastName
        )
        BEGIN
            IF @prefName = @firstName
            BEGIN
                set @prefNameBit = 0
            END
            ELSE
            BEGIN
                set @prefNameBit = 1
            END 

            INSERT INTO CompanyResources.Employee(FirstName, LastName, PreferredName, Photo) 
            VALUES(@firstName, @lastName, @prefNameBit, @photo)

            IF @isSalesperson = 1
            BEGIN
                INSERT INTO Sales.Salesperson(SalespersonId) VALUES(SCOPE_IDENTITY())
            END
        END

        FETCH NEXT FROM employee_cur INTO @firstName, @lastName, @prefName, @isSalesperson, @photo
    END
    CLOSE employee_cur
    DEALLOCATE employee_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_colors
AS
BEGIN
    DECLARE colors_cur CURSOR FOR 
    select distinct ss.color,
     si.Color 
    from (
        select distinct substring(x, 1, charindex(')', x)-1) as color 
        from (
	        select 
            substring([Stock Item],
            charindex('(', [Stock Item])+1,
            Len([Stock Item])) as x
	        from  WWI_OldData.dbo.[Stock Item] si
	        where si.[Stock Item]
	        COLLATE Latin1_General_CS_AS
	        like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%)%'
        ) s 
        where x 
        COLLATE Latin1_General_CS_AS 
        like '[ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'
    ) ss 
    full join WWI_OldData.dbo.[Stock Item] si on ss.color = si.color
    where ss.color is not null or si.Color <> 'N/A'

    DECLARE @nameColor varchar(40), @colorCol varchar(40)

    OPEN colors_cur
    FETCH NEXT FROM colors_cur INTO @nameColor, @colorCol

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT colorId from Stock.Color where @nameColor = Name or @colorCol = Name) 
        BEGIN
            IF @nameColor is not null 
            BEGIN
                INSERT INTO Stock.Color(Name) VALUES(@nameColor)
            END
            ELSE
            BEGIN
                INSERT INTO Stock.Color(Name) VALUES(@colorCol)
            END
        END

        FETCH NEXT FROM colors_cur INTO @nameColor, @colorCol
    END
    CLOSE colors_cur
    DEALLOCATE colors_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_brand
AS
BEGIN
    DECLARE brand_cur CURSOR FOR 
    SELECT distinct Brand from [WWI_OldData].dbo.[Stock Item]

    DECLARE @brand varchar(60)

    OPEN brand_cur
    FETCH NEXT FROM brand_cur INTO @brand

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT brandId from Stock.Brand where Name = @brand)
        BEGIN
            INSERT INTO Stock.Brand(Name) VALUES(@brand)
        END
        FETCH NEXT FROM brand_cur INTO @brand
    END
    CLOSE brand_cur
    DEALLOCATE brand_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_package
AS
BEGIN
    DECLARE package_cur CURSOR FOR 
    select si1.[Selling Package], si2.[Buying Package] from (select distinct [Selling Package] from WWI_OldData.dbo.[Stock Item]) si1 full join (select distinct [Buying Package] from WWI_OldData.dbo.[Stock Item]) si2 on si1.[Selling Package]  = si2.[Buying Package]

    DECLARE @sellingPackage varchar(25), @buyingPackage varchar(25)

    OPEN package_cur
    FETCH NEXT FROM package_cur INTO @sellingPackage, @buyingPackage

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT packageId from Stock.Package where @sellingPackage = Name or @buyingPackage = Name) 
        BEGIN
            IF @sellingPackage is not null 
            BEGIN
                INSERT INTO Stock.Color(Name) VALUES(@sellingPackage)
            END
            ELSE
            BEGIN
                INSERT INTO Stock.Color(Name) VALUES(@buyingPackage)
            END
        END

        FETCH NEXT FROM colors_cur INTO @nameColor, @colorCol
    END
    CLOSE colors_cur
    DEALLOCATE colors_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_size
AS
BEGIN
    DECLARE size_cur CURSOR FOR 
    SELECT DISTINCT Size from WWI_OldData.dbo.[Stock Item]

    DECLARE @size varchar(25)

    OPEN size_cur
    FETCH NEXT FROM size_cur INTO @size

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT sizeId from Stock.Size where value = @size) and @size <> N'N/A'
        BEGIN
            INSERT INTO Stock.Size(Value) VALUES(@size)
        END
        FETCH NEXT FROM size_cur INTO @size
    END
    CLOSE size_cur
    DEALLOCATE size_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_taxRate
AS
BEGIN
    DECLARE taxRate_cur CURSOR FOR SELECT distinct [Tax Rate] from WWI_OldData.dbo.Sale
    DECLARE @taxRate numeric(6,3)

    OPEN taxRate_cur
    FETCH NEXT FROM taxRate_cur INTO @taxRate

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT Value from Stock.TaxRate)
        BEGIN
            INSERT INTO Stock.TaxRate(Value) VALUES(@taxRate)
        END
        FETCH NEXT FROM taxRate_cur INTO @taxRate
    END
    CLOSE taxRate_cur
    DEALLOCATE taxRate_cur
END
GO

--TODO: Product
--TODO: ProductModel
--TODO: SalesOrderHeader,
--TODO: SalesOrderDetails

-- Adenda
--TODO: Transport, Logistic

-- Migration End

-- Populate
CREATE OR ALTER PROCEDURE sp_populate
AS 
BEGIN
	IF (select count(*) from Sales.Currency) = 0 and (select count(*) from Sales.CurrencyRate ) = 0
	BEGIN 
	    INSERT INTO Sales.Currency(Abbreviation, Name) 
	    VALUES 
		('USD', 'United States Dollar'),
		('EUR', 'Euro'),
		('GBP', 'Breat Britain Pound')

		INSERT INTO Sales.CurrencyRate(FromCurrency, ToCurrency, Rate, updateDate) 
		VALUES
		('EUR', 'USD', 1.072, convert(datetime2, '2023-02-01 17:00:00', 121)),
		('EUR', 'GBT', 0.882, convert(datetime2, '2023-02-01 17:05:00', 121)),
		('USD', 'GBT', 0.823, convert(datetime2, '2023-02-01 17:15:00', 121)) 
	END
END
GO
--TODO: Populate SystemUser 

--TODO: Export to other file?!
exec sp_import_continents;
exec sp_import_countries;
exec sp_import_sales_territory;
exec sp_import_state_province;
exec sp_import_city_names;
exec sp_import_cities;
exec sp_import_postalCode;
exec sp_import_address;
exec sp_import_buyingGroups;
exec sp_import_businessCategory;
exec sp_import_customer;
exec sp_import_employee;
exec sp_import_colors;
exec sp_import_brand;
exec sp_import_package;
exec sp_import_size;
exec sp_import_taxRate;
exec sp_populate;
GO

-- TODO: REMOVE TESTING STUFF
use WWI_OldData
select * from City;
select distinct [Tax Rate], [Stock Item Key] from Sale order by [Stock Item Key]; 
select distinct [Tax Rate], [Stock Item Key], [Stock Item] from [Stock Item] order by [Stock Item Key];
select * from dbo.Customer;
select * from dbo.Employee;
GO