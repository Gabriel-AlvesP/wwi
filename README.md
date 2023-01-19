# WWI (World Wide Importers)

A database administration project.

## ER

ER draft and decision making explanation.

### Old Tables Management

#### **Employee**

| Status | Column         | Content | Handling                |
| :----: | -------------- | ------- | ----------------------- |
|   x    | Employee Key   |         | -                       |
|   x    | Employee       |         | Renamed `Name`          |
|   x    | Preferred Name |         | -                       |
|   x    | Is Salesperson |         | New table `SalesPerson` |
|   x    | Photo          |         | -                       |

#### **Sale**

| Status | Column              | Content                    | Handling                                            |
| :----: | ------------------- | -------------------------- | --------------------------------------------------- |
|   x    | Sale Key            |                            | -                                                   |
|   x    | City Key            | Sale City != Customer City | FK from `City`                                      |
|   x    | Customer Key        |                            | FK from `Customer`                                  |
|   x    | Stock Item key      |                            | Into `SalesOrderDetails` Key (ManyToMany rel)       |
|   x    | Invoice Date Key    |                            | Into `SalesOrderHeader` as DueDate                  |
|   x    | Delivery Date Key   |                            | Into `SalesOrderHeader` as DeliverDate/ShipDate     |
|   x    | Salesperson Key     |                            | FK from `Employee`                                  |
|   x    | WWI Invoice ID      |                            | Into `SalesOrderHeader` as Key                      |
|   x    | Description         |                            | Skipped (Same as `Stock Item` of `Stock Item`)      |
|   x    | Package             |                            | Skipped (same as `Selling Package` of `Stock Item`) |
|   x    | Quantity            |                            | Into `SalesOrderDetails`                            |
|   x    | Unit Price          |                            | Skipped (Same as `Unit Price` of `Stock Item`)      |
|   x    | Tax Rate            |                            | -                                                   |
|   x    | Total Excluding Tax |                            | -                                                   |
|   x    | Tax Amount          |                            | -                                                   |
|   x    | Profit              |                            | Into `CompanyBills`                                 |
|   x    | Total Including Tax |                            | Renamed (`LineTotal`)                               |
|   x    | Total Dry Items     |                            |                                                     |
|   x    | Total Chiller Items |                            |                                                     |

#### **Stock Item**

| Status | Column                   | Content                            | Handling                      |
| :----: | ------------------------ | ---------------------------------- | ----------------------------- |
|   x    | Stock Item Key           | -                                  |                               |
|        | Stock Item               | name (color) size/weight           | spli format???                |
|   x    | Color                    |                                    | Into `Color` (ManyToMany rel) |
|   x    | Selling Package          |                                    | -                             |
|   x    | Buying Package           |                                    | -                             |
|   x    | Brand                    |                                    | -                             |
|   x    | Size                     |                                    | -                             |
|   x    | Lead Time Days           |                                    | -                             |
|   x    | Quantity Per Outer       |                                    | Renamed ( PackageQuantity)    |
|   x    | Is Chiller Stock         |                                    | -                             |
|   x    | Barcode                  |                                    | -                             |
|   x    | Tax Rate                 | Different from `Sale`'s `Tax Rate` | atm the same/ **with doubts** |
|   x    | Unit Price               |                                    | -                             |
|   x    | Recommended Retail Price |                                    | -                             |
|   x    | Typical Weight Per Unit  |                                    | -                             |

#### **Customer**

| Status | Column           | Compound Content                          | Handling                                                                |
| :----: | ---------------- | ----------------------------------------- | ----------------------------------------------------------------------- |
|   x    | Customer Key     | -                                         | -                                                                       |
|   x    | WWI Customer ID  | -                                         | Deleted                                                                 |
|   x    | Customer         | BuyingGroup (Head Office/City, StateCode) | Split into Customer and `CustomerCity`                                  |
|   x    | Bill To Customer |                                           | \*Into `sale`, self reference/relationship, or skipped ? - Into `Sales` |
|   x    | Category         |                                           | New Table `Categories`                                                  |
|   x    | Buying Group     |                                           | New Table `Buying Groups`                                               |
|   x    | Primary Contact  |                                           | -                                                                       |
|   x    | Postal Code      | \*\*                                      | -                                                                       |

**Notes** :

\* `Sale` is appropriated if it can change or skipped if the bill is directed always to the HeadOffice of the `Buying group`

\*\* **Same PostalCode for different Cities, which means Cities and Postal Codes are not associated**

#### - [x] **City**

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

Table with repeated rows!!!

#### States (.txt)

.txt file with US States and abbreviations.

#### Category (excel)

Excel file with customers categories (e.g. gas station).

### ER Decision Support

#### **`SalesPerson` Table**

It's an independent table (from the `Employee` table) for scalability purposes. Example:

- CommissionRate
- Earnings

#### **`CityName` Table**

Multiple cities with the same name. A separated table for cities is useful to minimize the repetition of city names.

#### **`City` Table**

`StateProvinceCode` column :

- To identify a city, since a country with states can have more than one cities with the same name

`CountryId` column :

- To identify the country if the state is not supported

#### **`Postal Code` Table**

Nullable `cityId` :

- Because HeadOffice customers doesn't have city, only postal code !?
- Which means there are unassociated postal codes :/ !?

## Questions

1. Column `City Key`, table `Sale`:

    - Is this key associate with something at all? 
    
    - How can we know it when making a sale?

2. Columns `Tax Rate`, tables `Sale` and `Stock Item`: ???

3. Column `Sales Territory`, table `City`: Shouldn't it be somehow associate with `Sales`?

4. Column `Delivery Date`, tables `Transport` and `SalesOrderHeader`: Why are those dates so different? Aren't they related?

## TODO

- [ ] ER
- [ ] Filegroups
- [ ] Migration

