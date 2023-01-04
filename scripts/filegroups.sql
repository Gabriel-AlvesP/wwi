use master

-- TODO:
-- Create Db / Primary File Group
create database wwi on primary ( --Tables: 
	name = 'WWIPrimary',
    filename = 'D:\',
    size = 100MB,
    maxsize = 300MB,
    filegrowth = 20MB
),

filegroup ( --Tables:
	name = '',
    filename = 'D:\',
    size = 100MB,
    maxsize = 250MB,
    filegrowth = 20MB
),
(
	name = '',
    filename = 'D:\',
    size = 200MB,
    maxsize = 400MB,
    filegrowth = 25MB
),
(
	name = '',
    filename = 'D:\',
    size = 200MB,
    maxsize = 400MB,
    filegrowth = 25MB
),

filegroup ( --Tabelas:
	name = '',
    filename = 'D:\',
    size = 10MB,
    maxsize = 50MB,
    filegrowth = 2MB
),

filegroup ( --Tabelas: 
	name = '',
    filename = 'D:\',
    size = 200MB,
    maxsize = 400MB,
    filegrowth = 25MB
),
(
	name = '',
    filename = 'D:\',
    size = 350MB,
    maxsize = 600MB,
    filegrowth = 50MB
)

-- Log File
log on ( 
	name = 'wwi_log.ldf',
    filename = 'D:\',
	SIZE = 500MB,
	MAXSIZE = 3000MB,
	FILEGROWTH = 500MB
)
go
