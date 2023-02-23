-- Migration
-- NOTE: This file contains the execs as well
use WWI_OldData
GO
IF (SELECT OBJECTPROPERTY(OBJECT_ID(N'City'),'TableHasPrimaryKey')) = 0 
AND (SELECT OBJECTPROPERTY(OBJECT_ID(N'Employee'),'TableHasPrimaryKey')) = 0
AND (SELECT OBJECTPROPERTY(OBJECT_ID(N'Stock Item'),'TableHasPrimaryKey')) = 0
BEGIN
ALTER TABLE City ADD CONSTRAINT PK_OldData_City PRIMARY KEY([City Key])
ALTER TABLE Employee ADD CONSTRAINT PK_OldData_Employee PRIMARY KEY([Employee Key])
ALTER TABLE [Stock Item] ADD CONSTRAINT PK_OldData_StockItem PRIMARY KEY([Stock Item Key])
CREATE NONCLUSTERED INDEX nc_invoiceId_customerId ON WWI_OldData.dbo.Sale([WWI Invoice ID]) include ( [Customer Key], [Stock Item Key], Quantity, [Unit Price], [Tax Rate])
END
GO


use WWIGlobal
GO
SET ANSI_NULLS OFF;
GO
SET NOCOUNT ON;
GO

CREATE FUNCTION dbo.fn_parseStateProv(@stateProv varchar(100))
RETURNS varchar(100)
AS BEGIN
    
        IF @stateProv like '%(%' 
        begin
            return trim(SUBSTRING(@stateProv, 1, CHARINDEX('(', @stateProv)))

        end

        IF @stateProv like '%[%'        
        begin
            return  trim(SUBSTRING(@stateProv, 1, CHARINDEX('[', @stateProv)))
        end

    return @stateProv
end
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

CREATE OR ALTER PROCEDURE sp_import_states
    @filepath nvarchar(255) = 'D:\GitHub\wwi\data\states.txt'
AS
BEGIN
	CREATE TABLE #BulkTemporary
	(
	    Code char(2),
	    Name varchar(100)
	)

    DECLARE @sql nvarchar(500) = 'Bulk INSERT #BulkTemporary FROM ''' + @filepath +
	''' WITH ( FIRSTROW=2, FIELDTERMINATOR = '';'', ROWTERMINATOR = ''\n'')'
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
            from [Location].SalesTerritory 
            where Territory = (SELECT TOP 1 [Sales Territory] from WWI_OldData.dbo.City where [State Province] = @name ) collate DATABASE_DEFAULT

            INSERT INTO Location.StateProvince(Code, Name, SalesTerritoryId) VALUES(@code, @name, @salesTerId)

            DECLARE @countryId int = (select CountryId from [Location].Country where Name = 'United States')
            INSERT INTO Location.StateProvince_Country(StateProvinceCode, CountryId)
            VALUES(@code, @countryId)

            FETCH NEXT FROM stateProv_cur INTO @code, @name
        END 
    END

	DROP TABLE #BulkTemporary
    CLOSE stateProv_cur
    DEALLOCATE stateProv_cur
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
        IF NOT EXISTS (SELECT Name FROM Location.CityName WHERE Name = @city)
        BEGIN 
            INSERT INTO Location.CityName(Name) VALUES(@city)
        END
        FETCH NEXT FROM city_cur INTO @city
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
    @stateProv varchar(255), @stateProvCode char(2),
    @country varchar(100), @countryId int

    OPEN city_cur
    FETCH NEXT FROM city_cur INTO @city, @population, @stateProv, @country


    WHILE @@FETCH_STATUS = 0
    BEGIN 
        select @cityNameId = cityNameId from Location.CityName where Name = @city

        set @stateProv = dbo.fn_parseStateProv(@stateProv)
        select @stateProvCode = Code from Location.StateProvince where trim(Name) = trim(@stateProv)

        select @countryId = CountryId from Location.Country where Name = @country

        IF NOT EXISTS (SELECT countryId from Location.StateProvince_Country where CountryId = @countryId and StateProvinceCode = @stateProvCode)
        BEGIN
            INSERT INTO Location.StateProvince_Country(StateProvinceCode, CountryId) VALUES(@stateProvCode, @countryId)
        END

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
        END
        ELSE
        BEGIN
            INSERT INTO Location.City(CityNameId, StateProvinceCode, CountryId, Population) 
            VALUES(@cityNameId, @stateProvCode, @countryId, @population)
        END

        FETCH NEXT FROM city_cur INTO @city, @population, @stateProv, @country
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
    distinct substring(Customer, charindex('(', Customer)+1, charindex(')',Customer)-1-charindex('(', Customer)),
    [Postal Code] 
    from WWI_OldData.dbo.Customer 

    DECLARE 
    @cityAndState varchar(55),
    @cityNameId int,
    @stateCode char(2), 
    @cityId int,
    @postalCode int

    OPEN address_cur
    FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @cityAndState like '%,%'
        BEGIN 
            select @cityNameId = cityNameId from Location.CityName where Name = trim(substring(@cityAndState, 1, charindex(',',@cityAndState)-1))

            SET @stateCode = trim(substring(@cityAndState, charindex(',', @cityAndState)+1, len(@cityAndState)))

            select @cityId = cityId from Location.City where stateProvinceCode = @stateCode and CityId= @cityNameId

            -- City, State
            IF NOT EXISTS (select addressId from Location.Address where cityId = @cityId and @postalCode = postalCode) and @cityId is not null
            BEGIN
                INSERT INTO Location.Address(PostalCode, CityId) VALUES(@postalCode, @cityId)
            END
        END 
        ELSE 
        BEGIN 
            IF NOT EXISTS (SELECT addressId from Location.Address where cityId is null and PostalCode = @postalCode)
            BEGIN
                INSERT INTO Location.Address(PostalCode) VALUES(@postalCode)
            END
        END 
        FETCH NEXT FROM address_cur INTO @cityAndState, @postalCode
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
    FETCH NEXT FROM businessCat_cur INTO @businessCategory

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
    SET IDENTITY_INSERT Customers.Customer ON
    DECLARE customer_cur CURSOR FOR 
    SELECT 
    [Customer Key],
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
    @cityAndState varchar(55), @city varchar(50), @stateCode char(2), @cityId int, @addressId int, @citynameId varchar(100),
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
            set @city = trim(substring(@cityAndState, 1, charindex(',',@cityAndState)-1))
            set @stateCode = trim(substring(@cityAndState, charindex(',', @cityAndState)+1, len(@cityAndState)))

            -- Start city handling 
            IF NOT EXISTS (select cityId from Location.City c inner join Location.CityName cn on c.CityNameId = cn.CityNameId where stateProvinceCode = @stateCode and cn.Name = @city)
            BEGIN
                select @citynameId = CityNameId from Location.CityName where Name = @city

                INSERT INTO Location.City(Population, CityNameId, StateProvinceCode, CountryId)
                VALUES(0, @citynameId, @stateCode, 1)

                set @cityId = SCOPE_IDENTITY()
            END
            ELSE
            BEGIN
                select @cityId = cityId from Location.City c inner join Location.CityName cn on c.CityNameId = cn.CityNameId where stateProvinceCode = @stateCode and cn.Name = @city
            END
            -- End of city handling

            IF NOT EXISTS (select addressId from Location.Address where cityId = @cityId and cast(@postalCode as int) = postalCode) and @cityId is not null
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
            IF NOT EXISTS (SELECT addressId from Location.Address where PostalCode = cast(@postalCode as int) and CityId is null)
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
        
        IF not exists (select  categoryId from Customers.BusinessCategory where Name = @category)
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
            where BuyingGroupId = @buyingGroupId
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
    SET IDENTITY_INSERT Customers.Customer OFF
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
    SELECT distinct Brand from [WWI_OldData].dbo.[Stock Item] --where brand <> N'N/A'

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
        IF NOT EXISTS (SELECT packageId from Stock.Package where Name = @sellingPackage or Name = @buyingPackage) 
        BEGIN
            IF @sellingPackage is not null 
            BEGIN
                INSERT INTO Stock.Package(Name) VALUES(@sellingPackage)
            END
            ELSE
            BEGIN
                INSERT INTO Stock.Package(Name) VALUES(@buyingPackage)
            END
        END

        FETCH NEXT FROM package_cur INTO @sellingPackage, @buyingPackage
    END
    CLOSE package_cur 
    DEALLOCATE package_cur
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
        IF NOT EXISTS (SELECT sizeId from Stock.Size where value = @size) --and @size <> N'N/A'
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
    DECLARE taxRate_cur CURSOR FOR 
    select distinct s.[Tax Rate], si.[Tax Rate] 
    from WWI_OldData.dbo.Sale s 
    full join WWI_OldData.dbo.[Stock Item] si 
    on si.[Tax Rate] = s.[Tax Rate]

    DECLARE @saleTaxRate numeric(6,3), @productTaxRate numeric(6,3)

    OPEN taxRate_cur
    FETCH NEXT FROM taxRate_cur INTO @saleTaxRate, @productTaxRate

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT Value from Stock.TaxRate where [Value] = @saleTaxRate or [Value] = @productTaxRate)
        BEGIN
            IF @saleTaxRate is not null 
            BEGIN
                INSERT INTO Stock.TaxRate(Value) VALUES(@saleTaxRate)
            END
            ELSE
            BEGIN
                INSERT INTO Stock.TaxRate(Value) VALUES(@productTaxRate)
            END
        END
        FETCH NEXT FROM taxRate_cur INTO @saleTaxRate, @productTaxRate
    END
    CLOSE taxRate_cur
    DEALLOCATE taxRate_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_product
AS
BEGIN
    DECLARE product_cur CURSOR FOR 
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
		END
		from (
			select distinct [Stock Item] as product
			 from WWI_OldData.dbo.[Stock Item]
		) si;

    DECLARE @product varchar(255)
    
    OPEN product_cur
    FETCH FROM product_cur INTO @product

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT productId from Stock.Product where Name = @product)
        BEGIN
                INSERT INTO Stock.Product(Name) VALUES(@product)
        END
        FETCH NEXT FROM product_cur INTO @product
    END
    CLOSE product_cur
    DEALLOCATE product_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_productM
AS
 BEGIN
    DECLARE product_cur CURSOR FOR 
	select case when si.product
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

    -- color_name
    case when si.product
	COLLATE Latin1_General_CS_AS
	like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%)%' 
    THEN
        case when substring(si.product, charindex('(', si.product)+1, len(si.product))
        COLLATE Latin1_General_CS_AS like '[ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'
        THEN 
	        trim(substring(
	            substring(si.product, charindex('(', si.product)+1, len(si.product)),
	            1,
	            charindex(')', substring(si.product, charindex('(', si.product)+1, len(si.product)))-1
	        ))
        ELSE
            --(hip hip array) (color)
            trim(substring(
                substring(si.product, charindex('(', si.product)+1, len(si.product)),
                charindex(')', substring(si.product, charindex('(', si.product)+1, len(si.product)))+1,
                len(substring(si.product, charindex('(', si.product)+1, len(si.product)))
            ))
       END
    ELSE
        NULL
    END as nameColor,
    case when color = 'N/A' THEN
        NULL
    else
        color
    end,
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
		Color,
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
	) si;

    DECLARE
    @model varchar(255), @productModelId int,
    @product varchar(255), @productId int,
    @color_name varchar(40), @color varchar(40), @colorId int,
    @sellingPackage varchar(100), @sellingPackageId int,
    @buyingPackage varchar(100), @buyingPackageId int,
    @brand varchar(50), @brandId int,
    @size varchar(100), @sizeId int,
    @leadTimeDays tinyint,
    @packageQuantity int,
    @isChiller bit,
    @barcode varchar(25),
    @taxRate numeric(6,3), @taxRateId int,
    @unitCost money, 
    @recommendedRetail money,
    @weight numeric(8,3) 

    OPEN product_cur
    FETCH NEXT FROM product_cur INTO 
    @product,
	@model,
    @color_name,
    @color,
	@sellingPackage,
	@buyingPackage,
	@brand,
	@size,
	@leadTimeDays,
	@packageQuantity,
	@isChiller,
	@barcode,
	@taxRate,
	@unitCost,
	@recommendedRetail,
	@weight

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @color is null 
        BEGIN
            SELECT @colorId = ColorId from Stock.Color where Name = @color_name
        END 
        ELSE
        BEGIN
            SELECT @colorId = ColorId from Stock.Color where Name = @color
        END

        SELECT @productId = ProductId from Stock.Product where Name = @product
        SELECT @sellingPackageId = PackageId from Stock.Package where Name = @sellingPackage
        SELECT @buyingPackageId = PackageId from Stock.Package where Name = @buyingPackage
        SELECT @brandId = BrandId from Stock.Brand where Name = @brand
        SELECT @sizeId = sizeId from Stock.[Size] where Value = @size
        SELECT @taxRateId = TaxRateId from Stock.TaxRate where Value = cast(@taxRate as numeric(6,3))

        if not exists (select ProductModelId from Stock.ProductModel 
        where 
            ProductId = @productId 
            and model = @model 
            and @sellingPackageId = SellingPackageId 
            and @buyingPackageId = BuyingPackageId 
            and sizeId = @sizeId 
            and TaxRateId = @taxRateId 
            and StandardUnitCost = cast(@unitCost as money) 
            and Barcode  = @barcode 
            and BrandId = @brandId 
            and RecommendedRetailPrice = cast(@recommendedRetail as money) 
            and Weight = cast(@weight as numeric(8,3)) 
            and IsChiller = cast(@isChiller as bit) 
            and LeadTimeDays = cast(@leadTimeDays as tinyint)
            and PackageQuantity = cast(@packageQuantity as int))
        BEGIN
            INSERT INTO Stock.ProductModel(ProductId, Model, BrandId, SizeId, Barcode, StandardUnitCost, TaxRateId, RecommendedRetailPrice, Weight, IsChiller, LeadTimeDays, PackageQuantity, BuyingPackageId, SellingPackageId)
            VALUES (@productId, @model, @brandId, @sizeId, @barcode, cast(@unitCost as money), @taxRateId, cast(@recommendedRetail as money), cast(@weight as numeric(8,3)), cast(@isChiller as bit), cast(@leadTimeDays as tinyint), cast(@packageQuantity as int), @buyingPackageId, @sellingPackageId)

            INSERT INTO Stock.Color_Product(ColorId, ProductModelId) VALUES(@colorId, SCOPE_IDENTITY())
        END
        ELSE
        BEGIN
	        select @productModelId = ProductModelId from Stock.ProductModel 
	        where 
	            ProductId = @productId 
	            and model = @model 
	            and @sellingPackageId = SellingPackageId 
	            and @buyingPackageId = BuyingPackageId 
	            and sizeId = @sizeId 
	            and TaxRateId = @taxRateId 
	            and StandardUnitCost = cast(@unitCost as money) 
	            and Barcode  = @barcode  
	            and BrandId = @brandId 
	            and RecommendedRetailPrice = cast(@recommendedRetail as money) 
	            and Weight = cast(@weight as numeric(8,3)) 
	            and IsChiller = cast(@isChiller as bit) 
	            and LeadTimeDays = cast(@leadTimeDays as tinyint)
	            and PackageQuantity = cast(@packageQuantity as int)



            IF NOT EXISTS (SELECT colorId from Stock.Color_Product where colorId = @colorId and ProductModelId = @productModelId)
            BEGIN
                INSERT INTO Stock.Color_Product(ColorId, ProductModelId) VALUES(@colorId, @productModelId)
            END
        END

	    FETCH NEXT FROM product_cur INTO 
	    @product,
		@model,
	    @color_name,
	    @color,
		@sellingPackage,
		@buyingPackage,
		@brand,
		@size,
		@leadTimeDays,
		@packageQuantity,
		@isChiller,
		@barcode,
		@taxRate,
		@unitCost,
		@recommendedRetail,
		@weight
    END
    CLOSE product_cur
    DEALLOCATE product_cur
END
GO

CREATE OR ALTER PROCEDURE sp_import_salesOH
AS
BEGIN
    SET IDENTITY_INSERT Sales.SalesOrderHeader ON
    DECLARE salesoh_cur CURSOR FOR select [WWI Invoice ID], [City Key], [Customer Key], [Invoice Date Key], [Salesperson Key] from WWI_OldData.dbo.Sale

    DECLARE 
    @invoiceID int,
    @customerId int,
    @salespersonId int, 
    @billToCustomer int,
    @dueDate date,
    @oldCityId int, @cityName varchar(50), @state varchar(50),
    @cityId int, @cityNameId int, @stateId char(2)

    OPEN salesoh_cur
    FETCH NEXT FROM salesoh_cur INTO  @invoiceId, @oldCityId, @customerId, @dueDate, @salespersonId

    WHILE @@FETCH_STATUS = 0
    BEGIN

        IF NOT EXISTS (SELECT SaleId from Sales.SalesOrderHeader where SaleId = @invoiceID)
        BEGIN 
			-- cityId
			SELECT @cityName = City, @state = [State Province] from WWI_OldData.dbo.City where [City Key] = @oldCityId --

            set @state = dbo.fn_parseStateProv(@state)

			SELECT @cityNameId = cityNameId from Location.CityName where Name = @cityName 
			SELECT @stateId = Code from Location.StateProvince where Name = @state
			SELECT @cityId = cityId from Location.City where CityNameId = @cityNameId and StateProvinceCode = @stateId and countryId = 1
	
			-- salespersonId
			select @salespersonId = EmployeeId from CompanyResources.Employee where CONCAT_WS( ' ', FirstName, LastName) = (select Employee from WWI_OldData.dbo.Employee where [Employee Key] = @salespersonId) collate DATABASE_DEFAULT
	
			-- BillTo
			select @billToCustomer = CustomerId from Customers.Customer where BuyingGroupId = (select BuyingGroupId from Customers.Customer where CustomerId = @customerId) and IsHeadOffice = 1

	        INSERT INTO Sales.SalesOrderHeader(saleId, CustomerId, SalespersonId, BillToCustomer, DueDate, CityId, Currency)
            VALUES(@invoiceID, @customerId, @salespersonId, @billToCustomer, @dueDate, @cityId, 'EUR')
	    END

        FETCH NEXT FROM salesoh_cur INTO  @invoiceId, @oldCityId, @customerId, @dueDate, @salespersonId
    END

    CLOSE salesoh_cur
    DEALLOCATE salesoh_cur
    SET IDENTITY_INSERT Sales.SalesOrderHeader OFF
END
GO

CREATE OR ALTER PROCEDURE sp_import_salesOD
AS
BEGIN
    DECLARE sales_cur CURSOR FOR 
    select [WWI Invoice ID], [Customer Key], [Stock Item Key], Quantity, [Unit Price], [Tax Rate], Profit from WWI_OldData.dbo.Sale s right join Sales.SalesOrderHeader soh on s.[WWI Invoice ID] = soh.SaleId and s.[Customer Key] = soh.CustomerId order by [WWI Invoice ID]
    --select [WWI Invoice ID], [Customer Key], [Stock Item Key], Quantity, [Unit Price], [Tax Rate]  from WWI_OldData.dbo.Sale order by [WWI Invoice ID], [Customer Key]

    DECLARE 
    @saleId int, -- wwi invoice id
    @customerId int,
    @stockItemId int, @stockItemName varchar(100),
    @productId int, @productModelId int, @productModel varchar(100),
    @quantity smallint,
    @unitPrice money, @listedUnitPrice money,
    @taxRate numeric(6,3), @taxRateId int,
    @brandId int, @brand varchar(100),
    @sizeId int, @size varchar(50), @barcode varchar(25),
    @weight numeric(8,3),
    @isChiller bit,
    @leadTimeDays tinyint,
    @packageQuantity int, 
    @productTaxRate numeric(6,3), @productTaxRateId int,
    @sellingPackage varchar(100), @buyingPackage varchar(100),
    @sellingPackageId smallint, @buyingPackageId smallint,
    @unitCost money, @recommendedRetail money, @profit money

    OPEN sales_cur
    FETCH NEXT FROM sales_cur INTO  @saleId, @customerId, @stockItemId, @quantity, @unitPrice, @taxRate, @profit

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Product Handling

        -- Get product name
        select @stockItemName = [Stock Item], @brand = Brand, @size = size, @productTaxRate = cast([Tax Rate] as numeric(6,3)), @weight = cast([Typical Weight Per Unit] as numeric(8,3)), @isChiller = cast([Is Chiller Stock] as bit), @leadTimeDays = cast([Lead Time Days] as tinyint), @packageQuantity = cast([Quantity Per Outer] as int), @barcode = cast(Barcode as varchar(25)), @sellingPackage = [Selling Package], @buyingPackage = [Buying Package], @unitCost = cast([Unit Price] as money), @recommendedRetail = [Recommended Retail Price] from WWI_OldData.dbo.[Stock Item] where [Stock Item Key] = @stockItemId

        IF @stockItemName COLLATE Latin1_General_CS_AS not like '%[ABCDEFGHIJKLMNOPKRSTUVXWYZ]% -%'
        BEGIN
            -- Handle products without model
            SET @productModel = ''

            IF @stockItemName COLLATE Latin1_General_CS_AS like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'
            BEGIN 
                SET @stockItemName = trim(substring(@stockItemName, 1, charindex('(', @stockItemName)-2))
            END
            ELSE
            BEGIN
	            IF @stockItemName like '%[0-9][gm]' or @stockItemName like '%[1-9]mm'
	            BEGIN
		            SET @stockItemName = trim(SUBSTRING(@stockItemName, 1,  len(@stockItemName) - charindex(' ', reverse(@stockItemName))))
	            END
            END
        END
        ELSE
        BEGIN
            -- Handle products with model
            SET @productModel = substring(@stockItemName, charindex('-', @stockItemName)+2, len(@stockItemName))

            SET @stockItemName = trim(substring(@stockItemName, 1, charindex('-', @stockItemName)-2))

            IF @productModel like '(%'
            BEGIN
		        -- (hip hip array)
                SET @productModel = trim(substring(@productModel, 1, charindex(')', @productModel)))
            END 
            ELSE 
            BEGIN 
	            IF @productModel like '%(%'
	            BEGIN
				    -- remove color
				   SET @productModel = trim(substring(@productModel, 1, charindex('(', @productModel)-1))
	            END
	            ELSE
	            BEGIN
	                SET @productModel = trim(@productModel)
	            END
            END
        END

        IF @barcode = N'N/A'
        BEGIN
            SET @barcode = ''
        END

        SELECT @productId = ProductId from Stock.Product where Name = @stockItemName
        SELECT @brandId = BrandId from Stock.Brand where Name = @brand
        SELECT @sizeId = sizeId from Stock.[Size] where Value = @size
        SELECT @productTaxRateId = TaxRateId from Stock.TaxRate where Value = cast(@productTaxRate as numeric(6,3))
        SELECT @sellingPackageId = packageId from Stock.Package where Name = @sellingPackage
        SELECT @buyingPackageId = packageId from Stock.Package where Name = @buyingPackage

        IF EXISTS
        (SELECT ProductModelId from Stock.ProductModel 
        WHERE 
            ProductId = @productId 
            and model = @productModel 
            and @sellingPackageId = SellingPackageId 
            and @buyingPackageId = BuyingPackageId 
            and sizeId = @sizeId 
            and TaxRateId = @productTaxRateId 
            and StandardUnitCost = cast(@unitCost as money) 
            and Barcode = @barcode
            and BrandId = @brandId 
	        and RecommendedRetailPrice = cast(@recommendedRetail as money) 
            and Weight = cast(@weight as numeric(8,3)) 
            and IsChiller = cast(@isChiller as bit) 
            and LeadTimeDays = cast(@leadTimeDays as tinyint)
            and PackageQuantity = cast(@packageQuantity as int)
        )
	    BEGIN
	        SELECT @productModelId = ProductModelId from Stock.ProductModel 
	        WHERE 
	            ProductId = @productId 
	            and model = @productModel 
	            and @sellingPackageId = SellingPackageId 
	            and @buyingPackageId = BuyingPackageId 
	            and sizeId = @sizeId 
	            and TaxRateId = @productTaxRateId 
	            and StandardUnitCost = cast(@unitCost as money) 
	            and Barcode = @barcode
	            and BrandId = @brandId 
		        and RecommendedRetailPrice = cast(@recommendedRetail as money) 
	            and Weight = cast(@weight as numeric(8,3)) 
	            and IsChiller = cast(@isChiller as bit) 
	            and LeadTimeDays = cast(@leadTimeDays as tinyint)
	            and PackageQuantity = cast(@packageQuantity as int)
	
	        IF NOT EXISTS (
	            SELECT saleId from Sales.SalesOrderDetails where SaleId = @saleId and ProductId = @productModelId
	        )
	        BEGIN
	            SELECT @taxRateId = taxRateId from Stock.TaxRate where Value = @taxRate
                set @listedUnitPrice = cast(@unitPrice as money) + (cast(@profit as money)/cast(@quantity as money))

	            INSERT INTO Sales.SalesOrderDetails(ProductId, SaleId, Quantity, ListedUnitPrice, TaxRateId)  VALUES(@productModelId, @saleId, cast(@quantity as int), cast(@listedUnitPrice as money), @taxRateId)

                UPDATE Stock.ProductModel SET CurrentRetailPrice = cast(@listedUnitPrice as money) where ProductModelId = @productModelId

	        END
        END

        FETCH NEXT FROM sales_cur INTO  @saleId, @customerId, @stockItemId, @quantity, @unitPrice, @taxRate, @profit
    END
    CLOSE sales_cur
    DEALLOCATE sales_cur
END
GO

-- Adenda
--TODO: Transport, Logistic

-- Migration End

-- Populate
CREATE OR ALTER PROCEDURE sp_populate_currency
AS 
BEGIN
	IF NOT EXISTS (select * from Sales.Currency)
	BEGIN 
	    INSERT INTO Sales.Currency(Abbreviation, Name) 
	    VALUES 
		('USD', 'United States Dollar'),
		('EUR', 'Euro'),
		('GBP', 'Breat Britain Pound')

	END
END
GO

CREATE OR ALTER PROCEDURE sp_populate_currencyRate
AS 
BEGIN
    IF NOT EXISTS (select * from Sales.CurrencyRate )
		INSERT INTO Sales.CurrencyRate(FromCurrency, ToCurrency, Rate, updateDate) 
		VALUES
		('EUR', 'USD', 1.072, convert(datetime2, '2023-02-01 17:00:00', 121)),
		('EUR', 'GBP', 0.882, convert(datetime2, '2023-02-01 17:05:00', 121)),
		('USD', 'EUR', 0.823, convert(datetime2, '2023-02-01 17:15:00', 121)) 
END
GO

CREATE OR ALTER PROC sp_import_logistic
AS BEGIN
    Declare @JSON varchar(max)
SELECT @JSON=BulkColumn
FROM OPENROWSET (BULK 'D:\GitHub\wwi\data\adenda.json', SINGLE_CLOB) as x

declare logistic_cur cursor for SELECT name, transport FROM OPENJSON (@JSON)
WITH  (
   name varchar(10),
   transport nvarchar(max)
) 

declare @logisticName varchar(10), @transport nvarchar(max), @logisticId int

open logistic_cur
fetch next from logistic_cur into @logisticName, @transport

    while @@FETCH_STATUS = 0
    BEGIN
        IF not exists (select * from Shipments.Logistic where Name = @logisticName)
        begin
            INSERT INTO Shipments.Logistic(Name) VALUES(@logisticName)
            set @logisticId = SCOPE_IDENTITY() 

            DECLARE transport_cur cursor for select saleid, shippingDate, deliveryDate, trackingNumber 
            from OPENJSON(@transport)
			WITH  (
			    saleid int,
			    shippingDate date,
			    deliveryDate date,
			    trackingNumber varchar(255)
			)
        
		declare 
		    @saleid int,
		    @shippingDate date,
		    @deliveryDate date,
		    @trackingNumber varchar(255)

        open transport_cur
        fetch next from transport_cur into @saleid, @shippingDate, @deliveryDate, @trackingNumber

        WHILE @@FETCH_STATUS = 0
        BEGIN
            if not exists (select * from Shipments.Transport where saleId = @saleid)
            begin
                INSERT INTO Shipments.Transport(SaleId, ShippingDate, DeliveryDate, TrackingNumber, LogisticId)
                VALUES(@saleid, @shippingDate, @deliveryDate, @trackingNumber, @logisticId)
            end
            fetch next from transport_cur into @saleid, @shippingDate, @deliveryDate, @trackingNumber
        END

        close transport_cur
        deallocate transport_cur
        fetch next from logistic_cur into @logisticName, @transport
        end
    end

    close logistic_cur
    deallocate logistic_cur
end
go

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
exec sp_import_salesOH;
GO
exec sp_import_salesOD;
GO
exec sp_import_logistic
go

SET NOCOUNT OFF;
GO
SET ANSI_NULLS ON;
GO
--SET STATISTICS TIME ON
--GO
--SET STATISTICS IO ON
--GO
--SET STATISTICS IO OFF
--GO
--SET STATISTICS TIME OFF
--GO