-- Access levels
use WWIGlobal
GO

--TODO: access levels
--Create roles
DROP ROLE IF EXISTS wwiAdmin
DROP ROLE IF EXISTS Salesperson
DROP ROLE IF EXISTS SalesTer
DROP ROLE IF EXISTS LogisticUser
GO
CREATE ROLE  wwiAdmin
CREATE ROLE Salesperson
CREATE ROLE SalesTer
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
--GRANT

--  “LogisticUser” que gere os transportes associados serviços de entrega. Este
-- utilizador tem acesso total, à view criada do tópico 2.2.1 
GRANT ALTER ON SCHEMA::Shipments to LogisticUser
GRANT SELECT ON SCHEMA::Sales To LogisticUser
GO
--GRANT ALTER ON 

-- Login
create login administrator with password = 'Adminarino1'
create login salespersona with password = 'salerman!'
create login salesTerrit with password = 'territory?'
create login logistico with password = 'shipmentss'

create user administrator for login administrator 
create user salespersona for login salespersona
create user salesTerrit for login salesTerrit 
create user logistico for login logistico
GO

-- Add longin 
alter role wwiAdmin add member administrator
alter role Salesperson add member salespersona
alter role SalesTer add member salesTerrit
alter role LogisticUser add member logistico
GO