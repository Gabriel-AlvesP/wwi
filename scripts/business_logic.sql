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

AS BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

    DECLARE @listedUnitPrice money,
    @taxRateId int,
    @discount numeric(5,2) = 0

    IF Sales.fn_checkSalesODetailsEntry(@saleId, @productId) = 1
    BEGIN
        ROLLBACK TRANSACTION
        exec sp_throw_error 52002, 1, @productId, @saleId
    END

    IF NOT EXISTS (select * from Stock.ProductModel where @productId = ProductModelId)
    BEGIN
        ROLLBACK TRANSACTION
        exec sp_throw_error 52003, 1, @productId
    END

    IF Sales.fn_checkSale(@saleId) = 0
    BEGIN
        ROLLBACK TRANSACTION
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
    
    COMMIT TRANSACTION
END 
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
        ROLLBACK TRAN inserted;
        exec sp_throw_error 52001, 1
    END
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

exec sp_generate_action 'discount', 'insert'
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
        return 0
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

-- verificação da data de validade de uma promoção 
CREATE OR ALTER PROC sp_deleteOldDiscounts
AS BEGIN
    delete from Sales.Discount where EndDate < GETDATE()
END
GO

-- adicionar/atualizar/remover utilizadores
exec sp_generate_action 'systemuser', 'all'; --:)
go
CREATE OR ALTER PROC Authentication.sp_insertUser
    @customerId int,
    @email varchar(255),
    @passwd varchar(32)
AS BEGIN
    IF NOT EXISTS (SELECT customerId from Customers.Customer where CustomerId = @customerId)
    BEGIN
        exec sp_throw_error 52000, 1, @customerId
    END
    
    IF @email is null or @email = '' 
    BEGIN
        exec sp_throw_error 52101, 1
    END

    IF EXISTS (select email from Authentication.SystemUser where Email = @email)
    BEGIN
        exec sp_throw_error 52102, 1, @email
    END

    IF @passwd is null or len(@passwd) < 8
    BEGIN
        exec sp_throw_error 52103, 1
    END

    exec sp_systemuser_insert @customerId, @email, convert(varchar(32), HASHBYTES('MD5', @passwd))
END
GO


CREATE OR ALTER PROC Authentication.authenticateUser
    @email varchar(255),
    @passwd nvarchar(32)
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
        Print 'Email or passwd do not match'
    End
END
GO
--autenticação por parte dos clientes com recurso ao ‘email’ e ‘password’

-- recuperar a ‘password’ com recurso a um ‘token’ de verificação gerado e enviado automaticamente para o email do utilizador

CREATE OR ALTER PROC sp_restorePasswd
AS


GO
