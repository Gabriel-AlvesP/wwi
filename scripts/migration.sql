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
				substring(si.product, 1, charindex('(', si.product)-2)
			else
				-- Products without color on the name
				case when si.product like '%[0-9][gm]' or si.product like '%[1-9]mm'
				then
					-- Remove size from products
					 SUBSTRING(si.product, 1,  len(si.product) - charindex(' ', reverse(si.product)))
				else
					-- Products without the size on the name
					si.product
				end
			end 
		ELSE
			-- Product with sub-model
			substring(si.product, 1, charindex('-', si.product)-1)
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

CREATE OR ALTER PROCEDURE sp_import_productModel
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
			substring(si.product, 1, charindex('(', si.product)-2)
		else
			-- Products without color on the name
			case when si.product like '%[0-9][gm]' or si.product like '%[1-9]mm'
			then
				-- Remove size from products
				 SUBSTRING(si.product, 1,  len(si.product) - charindex(' ', reverse(si.product)))
			else
				-- Products without the size on the name
				si.product
			end
		end 
	ELSE
		-- Product with sub-model
		substring(si.product, 1, charindex('-', si.product)-1)
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
			substring(
				substring(si.product, charindex('-', si.product)+2, len(si.product)),
				1,
				charindex(')', substring(si.product, charindex('-', si.product)+2, len(si.product)))
			)
		else
			case when 
				substring(si.product, charindex('-', si.product)+2, len(si.product)) 
	 		like '%(%'
			then
				-- Remove color
				SUBSTRING(
					substring(si.product, charindex('-', si.product)+2, len(si.product)),
					1,
					charindex('(', substring(si.product, charindex('-', si.product)+2, len(si.product)) )-1
				)
			ELSE
				substring(si.product, charindex('-', si.product)+2, len(si.product)) 
			END
		END
	ELSE
        Null
	END as model,

    -- color_name
    case when si.product
	COLLATE Latin1_General_CS_AS
	like '%([ABCDEFGHIJKLMNOPKRSTUVXWYZ]%)%' 
    THEN
        case when substring(si.product, charindex('(', si.product)+1, len(si.product))
        COLLATE Latin1_General_CS_AS like '[ABCDEFGHIJKLMNOPKRSTUVXWYZ]%'
        THEN 
	        substring(
	            substring(si.product, charindex('(', si.product)+1, len(si.product)),
	            1,
	            charindex(')', substring(si.product, charindex('(', si.product)+1, len(si.product)))-1
	        )
        ELSE
            --(hip hip array) (color)
            substring(
                substring(si.product, charindex('(', si.product)+1, len(si.product)),
                charindex(')', substring(si.product, charindex('(', si.product)+1, len(si.product)))+1,
                len(substring(si.product, charindex('(', si.product)+1, len(si.product)))
            )
       END
    ELSE
        Null
    END as nameColor,
    color,
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
    @productModelId int,
    @product varchar(255), @productId int,
    @color_name varchar(40), @color varchar(40), @colorId int,
    @model varchar(255),
    @sellingPackage varchar(100), @sellingPackageId int,
    @buyingPackage varchar(100), @buyingPackageId int,
    @brand varchar(40), @brandId int,
    @size varchar(100), @sizeId int,
    @leadTimeDays tinyint,
    @packageQuantity int,
    @isChiller bit,
    @barcode int,
    @taxRate numeric(6,3), @taxRateId int,
    @unitCost money, 
    @recommendedRetail money,
    @weight numeric(8,3) 

    OPEN product_cur
    FETCH NEXT FROM product_cur INTO @product,
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
        IF @color = 'N/A'
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
        SELECT @taxRateId = TaxRateId from Stock.TaxRate where Value = @taxRate
        SELECT @productModelId = productModelId from Stock.ProductModel where ProductModel = @model and ProductId = @productId
        
        IF @productModelId is not null
        BEGIN
            UPDATE Stock.ProductModel SET 
			BrandId = @brandId,
			SizeId = @sizeId,
			TaxRateId = @taxRateId,
			Barcode = @barcode,
			StandardUnitCost = @unitCost,
			RecommendedRetailPrice = @recommendedRetail,
			Weight = @weight,
			IsChiller = @isChiller,
			LeadTimeDays = @leadTimeDays,
			PackageQuantity = @packageQuantity,
			BuyingPackageId = @buyingPackageId,
			SellingPackageId = @sellingPackageId
            WHERE productModelId = @productModelId
        END
        ELSE
        BEGIN
            INSERT INTO Stock.ProductModel(
            ProductId,
			ProductModel,
			BrandId,
			SizeId,
			TaxRateId,
			Barcode,
			StandardUnitCost,
			RecommendedRetailPrice,
			Weight,
			IsChiller,
			LeadTimeDays,
			PackageQuantity,
			BuyingPackageId,
			SellingPackageId
            ) VALUES(
                @productId,
                @model,
                @brandId,
                @sizeId,
                @taxRateId,
                @barcode,
                @unitCost,
                @recommendedRetail,
                @weight,
                @isChiller,
                @leadTimeDays,
                @packageQuantity,
                @buyingPackageId,
                @sellingPackageId
			)

            INSERT INTO Stock.Color_Product(ColorId, ProductModelId) VALUES(@colorId, SCOPE_IDENTITY())
        END

	    FETCH NEXT FROM product_cur INTO @product,
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

--TODO: SalesOrderHeader,
CREATE OR ALTER PROCEDURE sp_import_salesOrderHeader
AS
BEGIN
    DECLARE sales_sp CURSOR FOR select [WWI Invoice ID], [City Key], [Customer Key], [Invoice Date Key], [Salesperson Key] from WWI_OldData.dbo.Sale 

    DECLARE 
    @invoiceID int,
    @customerId int,
    @salespersonId int, 
    @billToCustomer int,
    @dueDate date,
    @oldCityId int, @cityName varchar(50), @state varchar(50),
    @cityId int, @cityNameId int, @stateId char(2), 
    @Currency char(3) = 'EUR'

    OPEN sales_sp
    FETCH NEXT FROM sales_sp INTO  @invoiceId, @oldCityId, @customerId, @dueDate, @salespersonId

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (SELECT SaleId from Sales.SalesOrderHeader where  SaleId = @invoiceID)
        BEGIN
            IF NOT EXISTS (SELECT SaleId from Sales.SalesOrderHeader where CustomerId = @customerId)
            BEGIN
                --???    
            END
            FETCH NEXT FROM sales_sp INTO  @invoiceId, @oldCityId, @customerId, @dueDate, @salespersonId
        END 
        ELSE 
        BEGIN 
	        -- cityId
	        select @cityName = City, @state = [State Province] from WWI_OldData.dbo.City where [City Key] = @oldCityId
	        SELECT @cityNameId = cityNameId from Location.CityName where Name = @cityName 
	        SELECT @stateId = Code from Location.StateProvince where Name = @state
	        SELECT @cityId = cityId from Location.City where CityNameId = @cityNameId and StateProvinceCode = @stateId
	
	        -- salespersonId
	        select @salespersonId = EmployeeId from CompanyResources.Employee where CONCAT_WS( ' ', FirstName, LastName) = (select Employee from WWI_OldData.dbo.Employee where [Employee Key] = @salespersonId)
	
	        -- BillTo
	        select @billToCustomer = CustomerId from Customers.Customer where BuyingGroupId = (select BuyingGroupId from Customers.Customer where CustomerId = @customerId) and IsHeadOffice = 1
	
	        INSERT INTO Sales.SalesOrderHeader(saleId, CustomerId, SalespersonId, BillToCustomer, DueDate, CityId, Currency ) VALUES(@invoiceID, @customerId, @salespersonId, @billToCustomer, @dueDate, @cityId, 'EUR')        

            FETCH NEXT FROM sales_sp INTO  @invoiceId, @oldCityId, @customerId, @dueDate, @salespersonId
	   END
    END
END
GO

--TODO: SalesOrderDetails
CREATE OR ALTER PROCEDURE sp_import_salesOrderDetails
AS
BEGIN
    DECLARE sales_sp CURSOR FOR select * from WWI_OldData.dbo.Sale 

    DECLARE 
    @productId int,
    @saleId int,
    @quantity smallint,
    @listedUnitPrice money,
    @TaxRateId int,

    OPEN sales_sp
    FETCH NEXT FROM sales_sp INTO  @customerId

    WHILE @@FETCH_STATUS = 0
    BEGIN
       IF NOT EXISTS(SELECT productId from Sales.SalesOrderDetails where ProductId = @productId and SaleId = @saleId)         
       BEGIN

       END
       ELSE
       BEGIN
       END
    END
END
GO

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

-- exec migration
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
exec sp_import_product;
exec sp_import_productModel;
exec sp_import_salesOrderHeader;
exec sp_import_salesOrderDetails;
exec sp_populate;
GO

-- TODO: REMOVE TESTING STUFF
use WWI_OldData
select * from City
select * from [Stock Item];
select * from dbo.Customer;
select * from dbo.Employee;
select * from Sale where [WWI Invoice ID] = 16008; 
select * from Sale where [Sale Key] = 16008; 
select [WWI Invoice ID], [City Key], [Customer Key], [Invoice Date Key], [Salesperson Key]  from Sale order by [Invoice Date Key], [WWI Invoice ID]
GO