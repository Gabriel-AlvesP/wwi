# WWI (World Wide Importers)

A database administration project.

## TODO

### [ ] MR

MR draft.

#### [x] **Employee**

| Status | Column         | Content | Handling   |
| :----: | -------------- | ------- | ---------- |
|   x    | Employee Key   |         | -          |
|   x    | Employee       |         | Now `Name` |
|   x    | Preferred Name |         | -          |
|   x    | Is Salesperson |         | \*\*       |
|   x    | Photo          |         | -          |

**Notes** :

\*\* Maybe i'll change it later

#### [ ] **Sale**

| Status | Column              | Content                    | Handling               |
| :----: | ------------------- | -------------------------- | ---------------------- |
|   x    | Sale Key            |                            | -                      |
|   x    | City Key            | Sale City != Customer City | -                      |
|   x    | Customer Key        |                            | -                      |
|   x    | Stock Item key      |                            | into `StockItem_Sales` |
|   x    | Invoice Date Key    |                            | Into `Invoices`        |
|        | Delivery Date Key   |                            |                        |
|        | Salesperson Key     |                            |                        |
|        | WWI Invoice ID      |                            |                        |
|        | Description         |                            |                        |
|        | Package             |                            |                        |
|        | Quantity            |                            |                        |
|        | Unit Price          |                            |                        |
|        | Tax Rate            |                            |                        |
|        | Total Excluding Tax |                            |                        |
|        | Tax Amount          |                            |                        |
|        | Profit              |                            |                        |
|        | Total Including Tax |                            |                        |
|        | Total Dry Items     |                            |                        |
|        | Total Chiller Items |                            |                        |

#### [ ] **Stock Item**

| Status | Column                   | Content                  | Handling |
| :----: | ------------------------ | ------------------------ | -------- |
|   x    | Stock Item Key           | -                        |          |
|        | Stock Item               | name (color) size/weight |          |
|   x    | Color                    |                          |          |
|        | Selling Package          |                          |          |
|        | Buying Package           |                          |          |
|   x    | Brand                    |                          |          |
|   x    | Size                     |                          |          |
|        | Lead Time Days           |                          |          |
|        | Quantity Per Outer       |                          |          |
|        | Is Chiller Stock         |                          |          |
|   x    | Barcode                  |                          |          |
|   x    | Tax Rate                 |                          |          |
|   x    | Unit Price               |                          |          |
|   x    | Recommended Retail Price |                          |          |
|   x    | Typical Weight Per Unit  |                          |          |

#### [x] **Customer**

| Status | Column           | Compound Content                                   | Handling                                                                |
| :----: | ---------------- | -------------------------------------------------- | ----------------------------------------------------------------------- |
|   x    | Customer Key     | -                                                  | -                                                                       |
|   x    | WWI Customer ID  | -                                                  | Deleted                                                                 |
|   x    | Customer         | BuyingGroup (Office - Head Office/City, StateCode) | -                                                                       |
|   x    | Bill To Customer |                                                    | \*Into `sale`, self reference/relationship, or skipped ? - Into `Sales` |
|   x    | Category         |                                                    | New Table `Categories`                                                  |
|   x    | Buying Group     |                                                    | New Table `Buying Groups`                                               |
|   x    | Primary Contact  |                                                    | -                                                                       |
|   x    | Postal Code      | \*\*                                               | -                                                                       |

**Notes** :

\* `Sale` is appropriated if it can change or skipped if the bill is directed always to the HeadOffice of the `Buying group`

\*\* Same PostalCode for different Cities, which means Cities and Postal Codes are not associated

#### [x] **City**

| Status | Column                     | Compound Content | Handling                    |
| :----: | -------------------------- | ---------------- | --------------------------- |
|   x    | City Key                   |                  | -                           |
|   x    | City                       |                  | -                           |
|   x    | State Province             |                  | Into `States` (May be null) |
|   x    | Country                    |                  | Into `Countries`            |
|   x    | Continent                  |                  | Into `Countries`            |
|   x    | Sales Territory            |                  | Into `Sales Territories`    |
|   x    | Latest Recorded Population |                  | -                           |

**Notes** :

Repeated rows!!!

#### [x] States (.txt)

#### [x] Category (excel)

### Filegroups

### Migration

### Migration Check
