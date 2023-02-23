-- Access levels
use WWIGlobal
GO

--TODO: access levels
--Create roles
DROP ROLE IF EXISTS wwiAdmin
DROP ROLE IF EXISTS Salesperson
DROP ROLE IF EXISTS [Rocky Mountain]
DROP ROLE IF EXISTS LogisticUser
GO
CREATE ROLE  wwiAdmin
CREATE ROLE Salesperson
CREATE ROLE [Rocky Mountain] 
CREATE ROLE LogisticUser
GO

-- Access

-- Admin: all access
GRANT CONTROL on DATABASE::WWIGlobal to wwiAdmin
GO

-- EmployeeSalesPerson: All access to sales tables, read access to the rest
GRANT ALTER ON SCHEMA::Sales to Salesperson
GRANT SELECT ON DATABASE::WWIGlobal to Salesperson
GO

-- SalesTerritory: Info related with its own territory (use Rocky Mountain)
GRANT SELECT ON Location.SalesTerritory TO [Rocky Mountain] WITH GRANT OPTION;
GO

CREATE FUNCTION dbo.fn_SecureSalesTerritory(@salesTer AS sysname)  
    RETURNS TABLE  
WITH SCHEMABINDING  
AS  
    RETURN SELECT 1 AS 'SecureSalesTerritory'   
WHERE @SalesTer = USER_NAME();  
GO

CREATE SECURITY POLICY SalesTerritory
ADD FILTER PREDICATE dbo.fn_SecureSalesTerritory(Territory) 
-- TODO: Create a view and change to the view
on Location.SalesTerritory
WITH (STATE = ON);   
Alter Security Policy SalesTerritory with (State = off)
GO

--  “LogisticUser” que gere os transportes associados serviços de entrega. Este
-- utilizador tem acesso total, à view criada do tópico 2.2.1 
GRANT ALTER ON SCHEMA::Shipments to LogisticUser
GRANT SELECT ON SCHEMA::Sales To LogisticUser
GO
--GRANT ALTER ON 

-- Login
create user administrator WITHOUT LOGIN
create user salespersona  WITHOUT LOGIN
create user [Rocky Mountain] WITHOUT LOGIN
create user logistico WITHOUT LOGIN
GO

-- Add longin 
alter role wwiAdmin add member administrator
alter role Salesperson add member salespersona
alter role [Rocky Mountain] add member [Rocky Mountain]
alter role LogisticUser add member logistico
GO