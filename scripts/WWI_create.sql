CREATE TABLE Customers.Customer (
  CustomerId     int IDENTITY NOT NULL, 
  Name           varchar(255) NOT NULL, 
  PrimaryContact varchar(255) NOT NULL, 
  IsHeadOffice   bit NOT NULL, 
  BuyingGroupId  int NOT NULL, 
  CategoryId     int NOT NULL, 
  AddressId      int NOT NULL, 
  PRIMARY KEY (CustomerId));
CREATE TABLE Token (
  Token        varchar(255) NOT NULL, 
  SentDate     datetime NOT NULL, 
  SystemUserId int NOT NULL, 
  PRIMARY KEY (Token));
CREATE TABLE Sales.Discount (
  DiscountId   int IDENTITY NOT NULL, 
  StartDate    date NOT NULL, 
  EndDate      date NOT NULL, 
  DiscountRate int NOT NULL, 
  PRIMARY KEY (DiscountId));
CREATE TABLE ErrorLogs (
  ErrorLogId int IDENTITY NOT NULL, 
  ErrorId    int NOT NULL, 
  UserName   varchar(255) NULL, 
  [Date]     datetime NOT NULL, 
  PRIMARY KEY (ErrorLogId));
CREATE TABLE Error (
  ErrorId      int IDENTITY NOT NULL, 
  ErrorMessage varchar(255) NOT NULL, 
  PRIMARY KEY (ErrorId));
CREATE TABLE CompanyResources.Employee (
  EmployeeId    int IDENTITY NOT NULL, 
  FirstName     varchar(60) NOT NULL, 
  LastName      varchar(60) NOT NULL, 
  PreferredName bit NOT NULL, 
  Photo         varchar(255) NULL, 
  PRIMARY KEY (EmployeeId));
CREATE TABLE Stock.ProductModel (
  ProductModelId         int IDENTITY NOT NULL, 
  ProductId              int NOT NULL, 
  ProductModel           varchar(255) NULL, 
  Brand                  varchar(255) NULL, 
  [Size]                 varchar(20) NULL, 
  Barcode                int NOT NULL, 
  StandardUnitCost       numeric(12, 2) NOT NULL, 
  RecommendedRetailPrice numeric(12, 2) NOT NULL, 
  TaxRate                numeric(6, 3) NOT NULL, 
  Weight                 numeric(8, 3) NOT NULL, 
  IsChiller              bit NOT NULL, 
  LeadTimeDays           tinyint NOT NULL, 
  PackageQuantity        int NOT NULL, 
  BuyingPackage          varchar(20) NOT NULL, 
  SellingPackage         varchar(20) NOT NULL, 
  PRIMARY KEY (ProductModelId));
CREATE TABLE Customers.BusinessCategory (
  CategoryId int IDENTITY NOT NULL, 
  Name       varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (CategoryId));
CREATE TABLE Location.StateProvince (
  Code             char(2) NOT NULL, 
  Name             varchar(255) NOT NULL UNIQUE, 
  SalesTerritoryId int NULL, 
  PRIMARY KEY (Code));
CREATE TABLE Location.CityName (
  CityNameId int IDENTITY NOT NULL, 
  Name       varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (CityNameId));
CREATE TABLE Location.Country (
  CountryId   tinyint IDENTITY NOT NULL, 
  Name        varchar(255) NOT NULL UNIQUE, 
  ContinentId tinyint NOT NULL, 
  PRIMARY KEY (CountryId));
CREATE TABLE Location.SalesTerritory (
  SalesTerritoryId int IDENTITY NOT NULL, 
  Territory        varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (SalesTerritoryId));
CREATE TABLE Sales.SalesOrderHeader (
  SaleId               int IDENTITY NOT NULL, 
  CustomerId           int NOT NULL, 
  SalespersonId        int NOT NULL, 
  BillToCustomer       int NOT NULL, 
  DueDate              date NOT NULL, 
  DeliveryDate         date NOT NULL, 
  CityId               int NOT NULL, 
  CurrencyAbbreviation char(3) NOT NULL, 
  IsChiller            bit NOT NULL, 
  TotalItems           int NOT NULL, 
  TotalDue             numeric(12, 2) NOT NULL, 
  PRIMARY KEY (SaleId));
CREATE TABLE Stock.Color (
  ColorId tinyint IDENTITY NOT NULL, 
  Name    varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (ColorId));
CREATE TABLE Stock.Color_Product (
  ColorsColorId   tinyint NOT NULL, 
  StockItemItemId int NOT NULL, 
  PRIMARY KEY (ColorsColorId, 
  StockItemItemId));
CREATE TABLE Sales.SalesOrderDetail (
  ProductId         int NOT NULL, 
  SaleId            int NOT NULL, 
  Quantity          smallint NOT NULL, 
  ListedUnitPrice   numeric(12, 2) NOT NULL, 
  TotalExcludingTax numeric(12, 2) NOT NULL, 
  TaxRate           numeric(6, 3) NOT NULL, 
  TaxAmount         numeric(12, 2) NOT NULL, 
  DiscountId        int NULL, 
  LineTotal         numeric(12, 2) NOT NULL, 
  PRIMARY KEY (ProductId, 
  SaleId));
CREATE TABLE Customers.BuyingGroup (
  BuyingGroupId int IDENTITY NOT NULL, 
  Name          varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (BuyingGroupId));
CREATE TABLE Logs (
  [Schema]   varchar(255) NOT NULL, 
  TableName  varchar(255) NOT NULL, 
  ColumnName varchar(255) NOT NULL, 
  DataType   varchar(255) NOT NULL, 
  Length     bigint NOT NULL, 
  IsNullable bit NOT NULL, 
  IsUnique   bit NOT NULL, 
  UpdateDate datetime NOT NULL);
CREATE TABLE CompanyResources.Bills (
  SaleId int NOT NULL, 
  Profit numeric(12, 2) NOT NULL, 
  PRIMARY KEY (SaleId));
CREATE TABLE Location.Address (
  AddressId  int IDENTITY NOT NULL, 
  Address    varchar(255) NULL UNIQUE, 
  PostalCode int NOT NULL, 
  CityId     int NULL, 
  PRIMARY KEY (AddressId));
CREATE TABLE SystemUser (
  CustomerId int NOT NULL, 
  Email      varchar(255) NOT NULL UNIQUE, 
  Password   varchar(25) NOT NULL, 
  PRIMARY KEY (CustomerId));
CREATE TABLE Sales.Currency (
  Abbreviation char(3) NOT NULL, 
  Name         varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (Abbreviation));
CREATE TABLE Sales.Salesperson (
  SalespersonId  int NOT NULL, 
  CommissionRate tinyint NOT NULL, 
  Earnings       numeric(12, 2) NOT NULL, 
  PRIMARY KEY (SalespersonId));
CREATE TABLE Sales.CurrencyRate (
  FromCurrency char(3) NOT NULL, 
  ToCurrency   char(3) NOT NULL, 
  Rate         numeric(6, 3) NOT NULL, 
  UpdateDate   datetime NOT NULL, 
  PRIMARY KEY (FromCurrency, 
  ToCurrency));
CREATE TABLE Predictions (
  TableName       varchar(255) NOT NULL, 
  EntriesNumber   bigint NOT NULL, 
  EstimatedMemory bigint NOT NULL, 
  UpdateDate      datetime NOT NULL);
CREATE TABLE Shipments.Logistic (
  LogisticId int IDENTITY NOT NULL, 
  Name       varchar(255) NOT NULL, 
  PRIMARY KEY (LogisticId));
CREATE TABLE Shipments.Transport (
  SaleId       int NOT NULL, 
  ShippingDate date NOT NULL, 
  DeliveryDate date NOT NULL, 
  LogisticId   int NOT NULL, 
  PRIMARY KEY (SaleId));
CREATE TABLE Location.Continent (
  ContinentId tinyint IDENTITY NOT NULL, 
  Name        varchar(255) NOT NULL UNIQUE, 
  PRIMARY KEY (ContinentId));
CREATE TABLE Location.City (
  CityId            int IDENTITY NOT NULL, 
  CityNameId        int NOT NULL, 
  Population        int NOT NULL, 
  StateProvinceCode char(2) NOT NULL, 
  CountryId         tinyint NOT NULL, 
  PRIMARY KEY (CityId));
CREATE TABLE Location.PostalCode (
  Code int IDENTITY NOT NULL, 
  PRIMARY KEY (Code));
CREATE TABLE StateProvince_Country (
  StateProvinceCode char(2) NOT NULL, 
  CountryId         tinyint NOT NULL, 
  PRIMARY KEY (StateProvinceCode, 
  CountryId));
CREATE TABLE Stock.Product (
  ProductId int IDENTITY NOT NULL, 
  Name      varchar(255) NOT NULL, 
  PRIMARY KEY (ProductId));
ALTER TABLE ErrorLogs ADD CONSTRAINT FKErrorLogs128846 FOREIGN KEY (ErrorId) REFERENCES Error (ErrorId);
ALTER TABLE Sales.SalesOrderHeader ADD CONSTRAINT FKSalesOrder501237 FOREIGN KEY (CustomerId) REFERENCES Customers.Customer (CustomerId);
ALTER TABLE Stock.Color_Product ADD CONSTRAINT FKColor_Prod374161 FOREIGN KEY (ColorsColorId) REFERENCES Stock.Color (ColorId);
ALTER TABLE Stock.Color_Product ADD CONSTRAINT FKColor_Prod267232 FOREIGN KEY (StockItemItemId) REFERENCES Stock.ProductModel (ProductModelId);
ALTER TABLE Sales.SalesOrderDetail ADD CONSTRAINT FKSalesOrder561622 FOREIGN KEY (ProductId) REFERENCES Stock.ProductModel (ProductModelId);
ALTER TABLE Sales.SalesOrderDetail ADD CONSTRAINT FKSalesOrder444426 FOREIGN KEY (SaleId) REFERENCES Sales.SalesOrderHeader (SaleId);
ALTER TABLE Customers.Customer ADD CONSTRAINT FKCustomer989078 FOREIGN KEY (BuyingGroupId) REFERENCES Customers.BuyingGroup (BuyingGroupId);
ALTER TABLE Customers.Customer ADD CONSTRAINT FKCustomer142132 FOREIGN KEY (CategoryId) REFERENCES Customers.BusinessCategory (CategoryId);
ALTER TABLE Sales.SalesOrderHeader ADD CONSTRAINT FKSalesOrder38550 FOREIGN KEY (BillToCustomer) REFERENCES Customers.Customer (CustomerId);
ALTER TABLE Sales.SalesOrderDetail ADD CONSTRAINT FKSalesOrder274263 FOREIGN KEY (DiscountId) REFERENCES Sales.Discount (DiscountId);
ALTER TABLE CompanyResources.Bills ADD CONSTRAINT FKBills423134 FOREIGN KEY (SaleId) REFERENCES Sales.SalesOrderHeader (SaleId);
ALTER TABLE Token ADD CONSTRAINT FKToken31840 FOREIGN KEY (SystemUserId) REFERENCES SystemUser (CustomerId);
ALTER TABLE SystemUser ADD CONSTRAINT FKSystemUser205753 FOREIGN KEY (CustomerId) REFERENCES Customers.Customer (CustomerId);
ALTER TABLE Sales.SalesOrderHeader ADD CONSTRAINT FKSalesOrder216469 FOREIGN KEY (SalespersonId) REFERENCES Sales.Salesperson (SalespersonId);
ALTER TABLE Sales.CurrencyRate ADD CONSTRAINT FKCurrencyRa46653 FOREIGN KEY (FromCurrency) REFERENCES Sales.Currency (Abbreviation);
ALTER TABLE Sales.CurrencyRate ADD CONSTRAINT FKCurrencyRa922024 FOREIGN KEY (ToCurrency) REFERENCES Sales.Currency (Abbreviation);
ALTER TABLE Sales.SalesOrderHeader ADD CONSTRAINT FKSalesOrder637919 FOREIGN KEY (CurrencyAbbreviation) REFERENCES Sales.Currency (Abbreviation);
ALTER TABLE Location.StateProvince ADD CONSTRAINT FKStateProvi737346 FOREIGN KEY (SalesTerritoryId) REFERENCES Location.SalesTerritory (SalesTerritoryId);
ALTER TABLE Shipments.Transport ADD CONSTRAINT FKTransport646807 FOREIGN KEY (SaleId) REFERENCES Sales.SalesOrderHeader (SaleId);
ALTER TABLE Shipments.Transport ADD CONSTRAINT FKTransport627008 FOREIGN KEY (LogisticId) REFERENCES Shipments.Logistic (LogisticId);
ALTER TABLE Location.Country ADD CONSTRAINT FKCountry458801 FOREIGN KEY (ContinentId) REFERENCES Location.Continent (ContinentId);
ALTER TABLE Location.City ADD CONSTRAINT FKCity345217 FOREIGN KEY (CityNameId) REFERENCES Location.CityName (CityNameId);
ALTER TABLE Sales.SalesOrderHeader ADD CONSTRAINT FKSalesOrder352570 FOREIGN KEY (CityId) REFERENCES Location.City (CityId);
ALTER TABLE Location.Address ADD CONSTRAINT FKAddress489264 FOREIGN KEY (CityId) REFERENCES Location.City (CityId);
ALTER TABLE Location.Address ADD CONSTRAINT FKAddress632364 FOREIGN KEY (PostalCode) REFERENCES Location.PostalCode (Code);
ALTER TABLE Customers.Customer ADD CONSTRAINT FKCustomer133437 FOREIGN KEY (AddressId) REFERENCES Location.Address (AddressId);
ALTER TABLE Sales.Salesperson ADD CONSTRAINT FKSalesperso253703 FOREIGN KEY (SalespersonId) REFERENCES CompanyResources.Employee (EmployeeId);
ALTER TABLE StateProvince_Country ADD CONSTRAINT FKStateProvi145043 FOREIGN KEY (StateProvinceCode) REFERENCES Location.StateProvince (Code);
ALTER TABLE StateProvince_Country ADD CONSTRAINT FKStateProvi235227 FOREIGN KEY (CountryId) REFERENCES Location.Country (CountryId);
ALTER TABLE Location.City ADD CONSTRAINT FKCity262519 FOREIGN KEY (StateProvinceCode, CountryId) REFERENCES StateProvince_Country (StateProvinceCode, CountryId);
ALTER TABLE Stock.ProductModel ADD CONSTRAINT FKProductMod591355 FOREIGN KEY (ProductId) REFERENCES Stock.Product (ProductId);
