use WWIGlobal;
GO

CREATE TABLE BusinessCategory (
    CategoryId int IDENTITY(1,1),
    Name varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY(CategoryId)
);

CREATE TABLE BuyingGroup (
    BuyingGroupId int IDENTITY(1,1),
    Name varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY(BuyingGroupId)
)

CREATE TABLE Employee (
    EmployeeId int IDENTITY(1,1),
    Name varchar(255) NOT NULL,
    PreferredName varchar(255),
    Photo varchar(255),
    PRIMARY KEY(EmployeeId)
);

CREATE TABLE Salesman (
    SalesmanId int,
    CommissionRate decimal(12,2),
    Earnings decimal(12,2),
    PRIMARY KEY(SalesmanId),

    CONSTRAINT FK_EmployeeSalesman
    FOREIGN KEY(SalesmanId) REFERENCES Employee(EmployeeId);
);

CREATE TABLE Continent (
    ContinentId tinyint IDENTITY(1,1),
    Name varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY(ContinentId)
)

CREATE TABLE Coutry (
    CountryId tinyint IDENTITY(1,1),
    Name varchar(255) NOT NULL UNIQUE,
    ContinentId tinyint,
    PRIMARY KEY(CountryId),

    CONSTRAINT FK_ContinentCountry
    FOREIGN KEY(ContinentId) REFERENCES Continent(ContinentId);
)

CREATE TABLE CityName (
    CityNameId int IDENTITY(1,1),
    Name varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY(CityNameId)
)

CREATE TABLE SalesTerritory (
    SalesTerritoryId int IDENTITY(1,1),
    Territory varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY(SalesTerritoryId)
)

-- TODO:
-- CREATE TABLE StateProvince
-- CREATE TABLE City (

CREATE TABLE Curency (
    Abbreviation char(3),
    Name varchar(255),
    PRIMARY KEY(Abbreviation)
);

CREATE TABLE Color (
    ColorId int IDENTITY(1,1),
    Name varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY(ColorId)
)
