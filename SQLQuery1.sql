use WWI_OldData;

select * from Sale;
select * from [Stock Item];
select * from Employee;
select * from City;
select * from Customer;
GO

select * from City where [State Province] = 'Puerto Rico%' order by [Sales Territory] asc;


--select
--s.[WWI Invoice ID],
--s.[Stock Item Key],
--s.Quantity,
--s.[Unit Price],
--s.[Tax Rate],
--s.[Total Excluding Tax],
--s.[Tax Amount],
--s.[Total Including Tax],
--s.Profit
--from Sale s order by [WWI Invoice ID] asc;

--select si.[Stock Item Key],
--si.[Stock Item],
--si.[Quantity Per Outer],
--si.[Tax Rate],
--si.[Unit Price],
--si.[Lead Time Days],
--si.[Recommended Retail Price]
--from [Stock Item] si;

--select [Postal Code] from Customer group by [Postal Code] having count(Customer) > 1;
--select * from Customer where [Postal Code] = 90010;
--select * from Sale order by [WWI Invoice ID] asc;
--select * from [Stock Item] ;