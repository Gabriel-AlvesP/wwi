-- Business logic sps, triggers and udfs 
USE WWIGlobal
GO

-- SALES
-- Create sale
exec sp_generate_action 'salesorderheader', 'insert'
GO
CREATE OR ALTER PROC Sales.sp_createSale
    @customerId     int,
    @salespersonId  int,
    @cityId         int,
    @BillToCustomer int = @customerId,
    @currency       char(3) = 'EUR'
AS BEGIN
   DECLARE @dueDate date = GETDATE()

    exec sp_salesorderheader_insert @customerId,
     @salespersonId,
     @BillToCustomer,
     @dueDate,
     @cityId,
     @currency
END
GO

CREATE OR ALTER FUNCTION Sales.fn_checkSalesODetailsEntry (
    @saleId int,
    @productId int
)
RETURNS bit
AS BEGIN

    IF EXISTS(select * from Sales.SalesOrderDetails where ProductId = @productId and SaleId = @saleId)
    BEGIN
        return 1
    END

    return 0
END
GO

CREATE OR ALTER FUNCTION Sales.fn_checkSale (
    @saleId int
)
RETURNS bit
AS BEGIN

    IF EXISTS(select * from Sales.SalesOrderHeader where SaleId = @saleId)
    BEGIN
        return 1
    END

    return 0
END
GO

-- Add a product to a sale
GO
CREATE OR ALTER PROC Sales.sp_addProductToSale
    @productId int,
    @saleId int,
    @quantity int
AS BEGIN tran 
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @listedUnitPrice money,
    @taxRateId int,
    @discount numeric(5,2) = 0

    IF Sales.fn_checkSalesODetailsEntry(@saleId, @productId) = 1
    BEGIN
        ROLLBACK TRANSACTION; 
        exec sp_throw_error 52002, 1, @productId, @saleId
    END

    IF NOT EXISTS (select * from Stock.ProductModel where @productId = ProductModelId)
    BEGIN
        ROLLBACK TRANSACTION; 
        exec sp_throw_error 52003, 1, @productId
    END

    IF Sales.fn_checkSale(@saleId) = 0
    BEGIN
        ROLLBACK TRANSACTION;
        exec sp_throw_error 52004, 1, @saleId
    END

    select @taxRateId = TaxRateId,
        @listedUnitPrice = CurrentRetailPrice 
    from Stock.ProductModel 
    where ProductModelId = @productId

    IF EXISTS (
        select * from Sales.ProductModel_Discount pd 
        inner join Sales.Discount d on pd.DiscountId = d.DiscountId
        where ProductModelId = @productId and d.EndDate > GETDATE()
        ) 
    BEGIN
        select top 1 @discount =  d.DiscountRate
        from Sales.ProductModel_Discount pmd
        inner join Sales.Discount d on d.DiscountId = pmd.DiscountId
        where ProductModelId = @productId order by d.DiscountRate desc
    END

    INSERT INTO Sales.SalesOrderDetails(ProductId, SaleId, Quantity, ListedUnitPrice, TaxRateId, DiscountRate)
    VALUES(@productId, @saleId, @quantity, @listedUnitPrice, @taxRateId, @discount)
    
    COMMIT TRANSACTION; 
GO

--exec Sales.sp_addProductToSale 2, 70511, 5
--select * from Stock.ProductModel 
--select * from Sales.SalesOrderDetails where saleid=70511
GO
-- Check sale product types (chiller or dry)
CREATE OR ALTER TRIGGER Sales.tr_checkChillerStock 
ON Sales.SalesOrderDetails
AFTER INSERT
AS
    DECLARE @saleId int

    select @saleId = SaleId from inserted

    IF (
        select count(distinct isChiller) from Stock.ProductModel pm
        inner join Sales.SalesOrderDetails sod on pm.ProductModelId = sod.ProductId
        where sod.SaleId = @saleId
        ) <> 1
    BEGIN
        ROLLBACK TRAN;
        exec sp_throw_error 52001, 1
    END
GO

--exec Sales.sp_removeProductfromSale 2, 70511
--select * from Sales.SalesOrderDetails where saleid=70511
GO
-- Remove a product from a sale
CREATE OR ALTER PROC Sales.sp_removeProductFromSale
    @productId  int,
    @saleId     int,
    @removeSale bit = 0
AS 
BEGIN
    IF Sales.fn_checkSalesODetailsEntry(@saleId, @productId) = 1
    BEGIN
        DELETE FROM Sales.SalesOrderDetails where ProductId = @productId and SaleId = @saleId

        IF @removeSale = 1 and not exists (select * from Sales.SalesOrderDetails where SaleId = @saleId)
        BEGIN
            DELETE FROM Sales.SalesOrderHeader where saleId = @saleId
        END
    END
    ELSE
    BEGIN
        if Sales.fn_checkSale(@saleId) = 0
        BEGIN 
            exec sp_throw_error 52004, 1, @saleId
        END

        exec sp_throw_error 52005, 1, @saleId, @productId
    END
END
GO

--exec Sales.sp_updateQuantity 1, 70511, 4
--select * from Sales.SalesOrderDetails where saleid=70511
go
-- Change product quantity in a sale
CREATE OR ALTER PROC Sales.sp_updateQuantity
    @productId int,
    @saleId int,
    @quantity int
AS BEGIN
    IF Sales.fn_checkSalesODetailsEntry(@saleId, @productId) = 1
    BEGIN
        UPDATE Sales.SalesOrderDetails SET Quantity = @quantity where ProductId = @productId and SaleId = @saleId
    END
    ELSE
    begin
        if Sales.fn_checkSale(@saleId) = 0
        BEGIN 
            exec sp_throw_error 52004, 1, @saleId
        END

        exec sp_throw_error 52005, 1, @saleId, @productId
    end

END
GO

CREATE VIEW Sales.vw_SaleProductDetails
AS 
    SELECT 
        sod.SaleId,
        sod.ProductId,
        sod.Quantity,
        sod.ListedUnitPrice,
        (sod.ListedUnitPrice * sod.Quantity) as TotalExcludingTax,
        t.[Value] as TaxRate,
        ROUND(cast ((t.[Value]/100)*(sod.ListedUnitPrice * sod.Quantity) as decimal(8, 2)), 2) as TaxAmount,
        sod.DiscountRate,
        ROUND(cast((sod.DiscountRate/100*sod.ListedUnitPrice) as decimal(8,2)), 2) as DiscountAmount,
        ROUND(cast((((sod.ListedUnitPrice) + 
        (t.[Value]/100*sod.ListedUnitPrice) -
        (sod.DiscountRate/100*sod.ListedUnitPrice)) * sod.Quantity) as decimal(8,2)), 2)
         as ProductTotal
    FROM Sales.SalesOrderDetails sod
    inner join Stock.TaxRate t on sod.TaxRateId = t.TaxRateId
GO
--select * from Sales.vw_SaleProductDetails
--GO

-- Invoice information (isChiller, Customer, TotalDue,  ...)
-- DROP VIEW Sales.vw_SaleInvoice
CREATE VIEW Sales.vw_SaleInvoice
AS 
    SELECT soh.SaleId, 
    soh.CustomerId,
    soh.BillToCustomer,
    soh.SalespersonId,
    soh.DueDate,
    p.IsChiller,
    spd.TotalItems,
    spd.TotalDue,
    soh.Currency
    from Sales.SalesOrderHeader soh 
    inner join (select saleId ,count(*) as TotalItems , sum(ProductTotal) as TotalDue from Sales.vw_SaleProductDetails group by SaleId) spd
    on spd.SaleId = soh.SaleId
    inner join (select pm.IsChiller, sod.SaleId  from Stock.ProductModel pm inner join Sales.SalesOrderDetails sod on sod.ProductId = pm.ProductModelId group by sod.SaleId, pm.IsChiller) p on spd.SaleId = p.SaleId
GO
--select * from Sales.vw_SaleInvoice order by SaleId
--GO

-- verificação da data de entrega de uma venda de acordo com as datas de entrega dos produtos a ela associados 
CREATE OR ALTER TRIGGER  Sales.tr_checkShipmentDate
ON Sales.SalesOrderDetails
AFTER INSERT
AS
    DECLARE @leadtimedays int, @productId int, @saleId int, @saleDate date ,@shipmentDate date, @realShipmentDate date

    select @productId = productId, @saleId = saleId from inserted

    --select @leadtimedays = leadtimedays from Stock.ProductModel where ProductModelId = @productId
    -- Product with higher leadtimedays value
    select top 1 @leadtimedays = pm.LeadTimeDays  from Sales.SalesOrderDetails sod inner join Stock.ProductModel pm on pm.ProductModelId = sod.ProductId where saleId = @saleId order by LeadTimeDays desc

    select @saleDate = DueDate from Sales.SalesOrderHeader where SaleId = @saleId

    set @realShipmentDate = DATEADD(day, @leadtimedays, @saleDate)
    
    IF NOT exists (select saleid from Shipments.Transport where SaleId = @saleId)
    BEGIN
        INSERT INTO Shipments.Transport(SaleId, ShippingDate) VALUES(@saleId, @realShipmentDate)
    END
    ELSE
    BEGIN
        IF NOT EXISTS (select saleId from Shipments.Transport where ShippingDate = @realShipmentDate)
        BEGIN
            UPDATE Shipments.Transport SET ShippingDate = @realShipmentDate where SaleId = @saleId
        END
    END
GO

CREATE OR ALTER PROC Sales.sp_newDiscount
    @startDate      varchar(20),
    @endDate        varchar(20),
    @discountRate   numeric(5,2) 

as BEGIN
    set @endDate =  convert(date, @endDate)
    set @startDate = convert(date, @startDate)
    IF @endDate < getdate()
        exec sp_throw_error 52010

    if @endDate < @startDate
        exec sp_throw_error 52008

    INSERt INTO Sales.Discount(StartDate, EndDate, DiscountRate)
    VALUES(convert(date, @startDate), @endDate, cast(@discountRate as numeric(5,2)))
END
GO

GO
CREATE OR ALTER PROCEDURE Sales.sp_applyDiscount
    @discountId int,
    @productId int
AS BEGIN
    DECLARE @endDate date

    IF EXISTS (SELECT * from Sales.ProductModel_Discount where ProductModelId = @productId and DiscountId = @discountId)
    BEGIN
        exec sp_throw_error 52007, 1, @discountId, @productId
        return 0
    END

    IF NOT EXISTS (select * from Stock.ProductModel where ProductModelId = @productId)
    BEGIN
        exec sp_throw_error 52003, 1, @productId
        return 0
    END    

    IF NOT EXISTS (SELECT * from Sales.Discount where DiscountId = @discountId)
    BEGIN
        exec sp_throw_error 52003, 1, @discountId
        return 0
    end

    select @endDate = endDate from Sales.Discount where DiscountId = @discountId

    IF @endDate < GETDATE()
    BEGIN
        exec sp_throw_error 52009
    END

    INSERT INTO Sales.ProductModel_Discount(ProductModelId, DiscountId) VALUES(@productId, @discountId)
END
GO


CREATE OR ALTER PROC Sales.sp_deleteProductDiscount
    @discountId int,
    @productId int
as BEGIN
    IF EXISTS (SELECT * from Sales.ProductModel_Discount where ProductModelId = @productId and DiscountId = @discountId)
    BEGIN
        exec sp_throw_error 52011, 1, @discountId, @productId
    END

    delete from Sales.ProductModel_Discount where DiscountId = @discountId and ProductModelId = @productId
END
GO

-- permitir alterar as datas de início e fim de uma promoção 
-- Change 
CREATE OR ALTER PROC Sales.sp_updateDiscountDates
    @discountId int,
    @startDate date,
    @endDate date
AS BEGIN
    IF NOT EXISTS(select * from Sales.Discount where DiscountId = @discountId)
    BEGIN
        exec sp_throw_error 52006, 1, @discountId
    END

    IF @startDate > @endDate
    BEGIN
        exec sp_throw_error 52008 
    END

    IF @enddate < GETDATE()
    BEGIN 
        exec sp_throw_error 52010
    END

    update Sales.Discount set StartDate = @startDate, EndDate = @endDate where DiscountId = @discountId
END
GO

-- Delete discounts that are no longer active
CREATE OR ALTER PROC Sales.sp_deleteOldDiscounts
AS BEGIN
    delete from Sales.Discount where EndDate < GETDATE()
END
GO

-- Authentication
-- create user
exec sp_generate_action 'systemuser', 'all'; --:)
go
CREATE OR ALTER PROC Authentication.sp_insertUser
    @customerId int,
    @email varchar(255),
    @passwd varchar(32)
AS BEGIN
    
    IF @email is null or @email = '' 
    BEGIN
        exec sp_throw_error 52101, 1
    END

    IF @passwd is null or len(@passwd) < 8
    BEGIN
        exec sp_throw_error 52103, 1
    END

    DECLARE @hashed_passwd varchar(32) = convert(varchar(32), HASHBYTES('MD5', @passwd))
    exec sp_systemuser_insert @customerId, @email, @hashed_passwd
END
GO

-- user udpate
CREATE OR ALTER PROC Authentication.sp_updateUser
    @customerId int,
    @email varchar(255),
    @oldPasswd varchar(32),
    @newPasswd varchar(32)
as BEGIN

    IF @email is null or @email = '' 
    BEGIN
        exec sp_throw_error 52101, 1
    END
    
    IF @newPasswd is null or len(@newPasswd) < 8
    BEGIN
        exec sp_throw_error 52103, 1
    END

    DECLARE @hashed_passwd varchar(32) = convert(varchar(32), HASHBYTES('MD5', @oldPasswd)),
    @hashed_newPasswd varchar(32) 

    IF NOT EXISTS(select * from Authentication.SystemUser where Email = @email and Passwd = @hashed_passwd)
    BEGIN
        exec sp_throw_error 52104
    END

    set @hashed_newPasswd = convert(varchar(32), HASHBYTES('MD5', @newPasswd))
    exec sp_systemuser_update @customerId, @email, @hashed_newPasswd
    PRINT 'Update information was successful'
END
GO

-- User authentication
CREATE OR ALTER PROC Authentication.authenticateUser
    @email varchar(255),
    @passwd varchar(32)
AS BEGIN
    IF EXISTS (select * from Authentication.SystemUser where
        email = @email
        and
        Passwd = convert(varchar(32), HASHBYTES('MD5', @passwd)) 
    )
    BEGIN
        Print 'Authentication was successful'
    END
    ELSE
    BEGIN
        Print 'Email or password do not match'
    End
END
GO

-- Recover password 
CREATE OR ALTER PROC Authentication.sp_recoverPasswd
    @email varchar(255)
AS BEGIN
    DECLARE @userId int, @token varchar(255), @hashed_token varchar(255)

    IF EXISTS (select email from Authentication.SystemUser where Email = @email)
    BEGIN
        select @userId = customerId from Authentication.SystemUser where @email = Email
            
        set @token = convert(varchar(255), newid())
        set @hashed_token = convert(varchar(255), hashbytes('MD5', @token))
        INSERT INTO Authentication.Token(Token, SystemUserId) VALUES(@hashed_token,@userId)

        print 'An email was sent to your account with a token access'

    END
    ELSE 
    BEGIN
        exec sp_throw_error 52105, 1, @email
    END
END
GO

CREATE OR ALTER PROC Authentication.sp_restorePasswd
    @token varchar(255),
    @newPasswd varchar(32)
AS
BEGIN
    DECLARE @userId int

    set @token = convert(varchar(255), hashbytes('MD5', @token))
    IF NOT EXISTS (select * from Authentication.Token where Token = @token)
    BEGIN
        exec sp_throw_error 52106
    END

    select @userId = SystemUserId from Authentication.Token where Token = @token

    update Authentication.SystemUser set Passwd = @newPasswd where CustomerId = @userId
    PRINT 'Restore password was successful'
END
GO
