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


-- SalesTerritory: Info related with its own territory (use Rocky Mountain)


--  “LogisticUser” que gere os transportes associados serviços de entrega. Este
-- utilizador tem acesso total, à view criada do tópico 2.2.1 e à s tabelas de gestão de transportes
-- e apenas de consulta às tabelas associadas às vendas.
GRANT ALTER ON SCHEMA::Shipments to LogisticUser
GRANT SELECT ON SCHEMA::Sales To LogisticUser
--GRANT ALTER ON 

-- Login

-- Add longin 
-- alter role wwiAdmin add member