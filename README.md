# WWI (World Wide Importers)

A database administration project.

## ER

ER draft and decision making description.

### Old Tables Management

TODO: Update handling columns

#### **Employee**

| Status | Column         | Content | Handling                       |
| :----: | -------------- | ------- | ------------------------------ |
|   x    | Employee Key   |         | -                              |
|   x    | Employee       |         | Now `First Name` & `Last Name` |
|   x    | Preferred Name |         | -                              |
|   x    | Is Salesperson |         | New table `SalesPerson`        |
|   x    | Photo          |         | -                              |

#### **Sale**

| Status | Column              | Content                    | Handling                                                          |
| :----: | ------------------- | -------------------------- | ----------------------------------------------------------------- |
|   x    | Sale Key            |                            | -                                                                 |
|   x    | City Key            | Sale City != Customer City | FK from `City`                                                    |
|   x    | Customer Key        |                            | FK from `Customer`                                                |
|   x    | Stock Item key      |                            | Into `SalesOrderDetails` Key (ManyToMany rel)                     |
|   x    | Invoice Date Key    |                            | Into `SalesOrderHeader` as DueDate                                |
|   x    | Delivery Date Key   |                            | Into `SalesOrderHeader` as DeliverDate/ShipDate - Transport\*\*\* |
|   x    | Salesperson Key     |                            | FK from `Employee`                                                |
|   x    | WWI Invoice ID      |                            | -                                                                 |
|   x    | Description         |                            | Skipped (Same as `Stock Item`)                                    |
|   x    | Package             |                            | Skipped (same as `Selling Package` of `Stock Item`)               |
|   x    | Quantity            |                            | Into `SalesOrderDetails`                                          |
|   x    | Unit Price          |                            | Skipped (Same as `Unit Price` of `Stock Item`)                    |
|   x    | Tax Rate            |                            | Into `SalesOrderDetails`                                          |
|   x    | Total Excluding Tax |                            | Into `SalesOrderDetails`                                          |
|   x    | Tax Amount          |                            | Into `SalesOrderDetails`                                          |
|   x    | Profit              |                            | Into `Bills`                                                      |
|   x    | Total Including Tax |                            | -                                                                 |
|   x    | Total Dry Items     |                            | `IsChiller`\*\*                                                   |
|   x    | Total Chiller Items |                            | `IsChiller`\*\*                                                   |

\*\* the total is the total of products on the sale.

\*\*\* `Transport` (`delivery dates`) and `SalesOrderHeader` (`delivery dates`) are not the same - the data will be "duplicated".

#### **Stock Item**

| Status | Column                   | Content                            | Handling                      |
| :----: | ------------------------ | ---------------------------------- | ----------------------------- |
|   x    | Stock Item Key           | -                                  |                               |
|        | Stock Item               | name (color) size/weight           | split format???               |
|   x    | Color                    |                                    | Into `Color` (ManyToMany rel) |
|   x    | Selling Package          |                                    | `Packages` Table              |
|   x    | Buying Package           |                                    | `Packages` Table              |
|   x    | Brand                    |                                    | `Brand` Table                 |
|   x    | Size                     |                                    | `Size` Table                  |
|   x    | Lead Time Days           |                                    | -                             |
|   x    | Quantity Per Outer       |                                    | Renamed (PackageQuantity)     |
|   x    | Is Chiller Stock         |                                    | -                             |
|   x    | Barcode                  |                                    | -                             |
|   x    | Tax Rate                 | Different from `Sale`'s `Tax Rate` | atm the same/ **with doubts** |
|   x    | Unit Price               |                                    | -                             |
|   x    | Recommended Retail Price |                                    | -                             |
|   x    | Typical Weight Per Unit  |                                    | -                             |

#### **Customer**

| Status | Column           | Content                                   | Handling                                                                  |
| :----: | ---------------- | ----------------------------------------- | ------------------------------------------------------------------------- |
|   x    | Customer Key     | -                                         | -                                                                         |
|   x    | WWI Customer ID  | -                                         | Deleted                                                                   |
|   x    | Customer         | BuyingGroup (Head Office/City, StateCode) | Split into Customer and `CustomerCity`                                    |
|   x    | Bill To Customer |                                           | \*Into `sale`, self reference/relationship, or skipped ? - Into `Sales`\* |
|   x    | Category         |                                           | New Table `BusinessCategory`                                              |
|   x    | Buying Group     |                                           | New Table `BuyingGroup`                                                   |
|   x    | Primary Contact  |                                           | `Contact` Table                                                           |
|   x    | Postal Code      | \*\*                                      | `Postal Code` Table                                                       |

**Notes** :

\* `Sale` is appropriated if it can change or skipped if the bill is directed always to the HeadOffice of the `Buying group`

\*\* **Same PostalCode for different Cities, which means there are Cities with the same postal code => A place cannot be identified only by the postal code**

#### **City**

| Status | Column                     | Content | Handling                    |
| :----: | -------------------------- | ------- | --------------------------- |
|   x    | City Key                   |         | -                           |
|   x    | City                       |         | -                           |
|   x    | State Province             |         | Into `States` (May be null) |
|   x    | Country                    |         | Into `Countries`            |
|   x    | Continent                  |         | Into `Countries`            |
|   x    | Sales Territory            |         | Into `Sales Territories`    |
|   x    | Latest Recorded Population |         | -                           |

**Notes** :

Table with repeated rows!!!

#### States (.txt)

.txt file with States and its abbreviations - StateProvince

#### Category (.xlsx)

.xlsx file with customers categories (e.g. gas station) - businessCategories

### ER Decision Support

#### **`SalesPerson` Table**

It's an independent table (from the `Employee` table) for scalability purposes. Example:

- CommissionRate
- Earnings

#### **`CityName` Table**

Multiple cities with the same name. A separated table for cities is useful to minimize the repetition of city names.

#### **`City` Table**

`StateProvinceCode` + `CountryId` columns :

- A city is identified by the state and country because there are multiple cities with the same name in different states and (possibly) countries.

#### **`Address` Table**

Nullable `cityId` :

- Because HeadOffice customers don't have city, only postal code !?
- Which means there are some cities that are not associated with a postal code :/ !?

#### **`Postal Code` Table**

Postal code is in a dedicated table because there are multiple cities with the same postal code

## Questions

1. Column `City Key`, table `Sale`:

   - Is this key associate with something at all?

   - How can you know it when making a sale?

2. Columns `Tax Rate`, tables `Sale` and `Stock Item`: ???

3. Column `Sales Territory`, table `City`:

   - Shouldn't it be somehow associate with `Sales`?

## Known Issues

- barcode bigint should be a varchar

- SalesOrderDetails migration

- Address number > customer number

- Actual price to calculate the profit

- SalesOrderDetails table has 169117 and should be 170155 or 170

## TODO

- [x] ER
- [x] DDL (data definition language) files (create + drop)
- [x] Filegroups
- [ ] Migration
- [ ] Migration check
