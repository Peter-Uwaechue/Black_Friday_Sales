# 🛍️ Retail Sales Performance Analysis — Black Friday Dataset

![SQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-Dashboard-217346?logo=microsoftexcel&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-success)
![Rows](https://img.shields.io/badge/Records-550%2C068-blue)

An end-to-end retail analytics project that transforms **550,068 raw Black Friday transactions** into a decision-ready, interactive sales dashboard — covering data ingestion, integrity checks, standardization, exploratory analysis, and visualization.

---

## Table of Contents

- [Project Summary](#-project-summary)
- [Business Questions](#-business-questions)
- [Dataset](#-dataset)
- [Tech Stack](#-tech-stack)
- [Methodology](#-methodology)
  - [1. Ingestion](#1-ingestion)
  - [2. Data Integrity Check](#2-data-integrity-check)
  - [3. Standardization Layer](#3-standardization-layer)
  - [4. Exploratory Data Analysis](#4-exploratory-data-analysis)
  - [5. Export](#5-export)
- [Dashboard](#-dashboard)
- [Key Insights](#-key-insights)
- [Repository Structure](#-repository-structure)
- [How to Reproduce](#-how-to-reproduce)
- [Author](#-author)

---

## 📋 Project Summary

A US-based retail chain's Black Friday transaction log was analyzed to understand **customer spending behavior across demographics, geography, and product categories**. The raw CSV was loaded into MySQL, validated for duplicates, standardized into an analysis-ready view, and queried across nine dimensions to surface spend, frequency, and average-order-value patterns. Findings were visualized in a filterable Excel dashboard for stakeholders without SQL access.

| Metric | Value |
|---|---|
| Transactions analyzed | **550,068** |
| Total spend | **$5,095,812,742** |
| Unique customers | **5,891** |
| Duplicate records found | **0** |
| Dimensions analyzed | Gender, Age, Occupation, City Category, Residency Tenure, Marital Status, Product Category |

---

## ❓ Business Questions

This analysis was designed to answer:

1. Which customer segments (gender, age, marital status) drive the most revenue?
2. Which city categories and occupations contribute most to total spend?
3. Which products and product categories have the highest sales volume vs. highest average order value?
4. How does customer tenure in a city correlate with spending?
5. Who are the highest-value customers, and what does the long tail of spend look like?

---

## 🗃️ Dataset

**Source file:** `Black Friday Dataset.csv`
**Staging table:** `black_friday_sales` → **Analysis view:** `blackfriday_sales`

| Column | Type | Description |
|---|---|---|
| `User_ID` | int | Unique customer identifier |
| `Product_ID` | varchar(20) | Unique product identifier |
| `Gender` | varchar(10) | `f`/`m` → decoded to `Female`/`Male` |
| `Age` | varchar(10) | Age bracket, e.g. `26-35` |
| `Occupation` | int | Occupation code (anonymized) |
| `City_Category` | varchar(3) | `A`, `B`, or `C` |
| `Stay_in_Current_City_Years` | varchar(5) | Years resident in current city |
| `Marital_Status` | int | `0`/`1` → decoded to `Single`/`Married` |
| `Product_Category_1` | int | Primary product category |
| `Product_Category_2` | int, nullable | Secondary product category |
| `Product_Category_3` | int, nullable | Tertiary product category |
| `Purchase` | int | Transaction amount (USD) |

> **Data quality note:** `Product_Category_2` and `Product_Category_3` contained blank strings rather than true nulls in the raw file. These were converted to proper `NULL` values at load time using MySQL staging variables (`@variable1`, `@variable2`), avoiding silent miscounts in later aggregations.

---

## 🛠️ Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| Storage & Processing | **MySQL 8.0** | Bulk load, deduplication, standardization, aggregation |
| Analysis | **Window Functions** (`ROW_NUMBER()`) | Integrity checks |
| Abstraction | **SQL Views** | Reusable, decoded analysis layer |
| Visualization | **Microsoft Excel** | Pivot tables, slicers, KPI cards, charts |

---

## 🧪 Methodology

### 1. Ingestion

The raw CSV is bulk-loaded via `LOAD DATA INFILE`, with empty-string category fields converted to `NULL` inline using session variables:

```sql
create table black_friday_sales (
  User_ID int, Product_ID varchar(20), Gender varchar(10), Age varchar(10),
  Occupation int, City_Category varchar(3), Stay_in_Current_City_Years varchar(5),
  Marital_Status int, Product_Category_1 int, Product_Category_2 int null,
  Product_Category_3 int null, Purchase int
);

load data infile 'Black Friday Dataset.csv' into table black_friday_sales
fields terminated by ','
ignore 1 rows
(User_id, Product_id, Gender, Age, Occupation, City_Category,
 Stay_in_Current_City_Years, Marital_Status, Product_Category_1,
 @variable1, @variable2, Purchase)
set Product_Category_2 = if(@variable1 = '', null, @variable1),
    Product_Category_3 = if(@variable2 = '', null, @variable2);
```

### 2. Data Integrity Check

Before any analysis, a `ROW_NUMBER()` window function partitioned across **every column** identifies exact duplicate rows:

```sql
with cte1 as (
  select *, row_number() over (
    partition by User_id, Product_id, Gender, Age, Occupation, City_Category,
    Stay_in_Current_City_Years, Marital_Status, Product_Category_1,
    Product_Category_2, Product_Category_3, Purchase
  ) as row_num
  from black_friday_sales
)
select * from cte1 where row_num > 1;
```

> ✅ **Result: 0 rows returned.** The dataset is confirmed free of duplicate transactions, so all downstream totals are reliable.

### 3. Standardization Layer

Rather than decoding `Gender` and `Marital_Status` in every query, a single view centralizes that logic — a one-time transformation that every subsequent query and the dashboard both rely on:

```sql
create view blackfriday_sales as
select User_ID, Product_ID,
  case when gender = 'f' then 'Female' when gender = 'm' then 'Male' end Gender,
  Age, Occupation, City_Category, Stay_in_Current_City_Years,
  case when Marital_Status = 0 then 'Single' when Marital_Status = 1 then 'Married' end Marital_Status,
  Product_Category_1, Product_Category_2, Product_Category_3, Purchase
from black_friday_sales;
```

### 4. Exploratory Data Analysis

Each dimension below was analyzed with three consistent metrics — **total spend** (`SUM`), **average order value** (`AVG`), and **transaction frequency** (`COUNT`) — to distinguish *high-volume* segments from *high-value* ones.

| Dimension | Question Answered |
|---|---|
| **Customer** | Who are the top 10 spenders? |
| **Product** | Which products sell the most units? |
| **Gender** | Do men or women spend more, on average and in total? |
| **Age Group** | Which age brackets drive revenue vs. order size? |
| **Occupation** | Which occupation codes over-index on spend? |
| **City Category** | Which city tier contributes most revenue? |
| **Residency Tenure** | Does length of stay in a city affect spend? |
| **Marital Status** | Do single or married customers spend more? |
| **Product Category** | Which categories have the highest unit price vs. volume? |

Example — average order value by age group:

```sql
select age, avg(purchase) average_purchase from blackfriday_sales
group by age
order by average_purchase desc;
```

> The complete set of 25+ queries (sum/avg/count across every dimension) is in [`black_friday_analysis.sql`](./black_friday_analysis.sql).

### 5. Export

The cleaned, decoded dataset is exported for downstream BI tools:

```sql
SELECT User_ID, Product_ID, Gender, Age, Occupation, City_Category,
       Stay_In_Current_City_Years, Marital_Status, Product_Category_1,
       Product_Category_2, Product_Category_3, Purchase
FROM blackfriday_sales
INTO OUTFILE 'clean_black_friday.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';
```

---

## 📊 Dashboard

![Retail Sales Performance Dashboard](black_friday_dashboard.PNG)

An interactive Excel dashboard built on the cleaned dataset, allowing non-technical stakeholders to filter and explore spend patterns live.

| Component | Detail |
|---|---|
| KPI card | Total Spend across all transactions |
| Slicers | Gender, Age, City Category |
| Chart 1 | Total Spend by Gender and Age Group (clustered bar) |
| Chart 2 | Total Spend by City Category (donut) |
| Chart 3 | Top 10 Product Categories by Average Spend (bar) |
| Chart 4 | Total Spend by Years of Residence and Marital Status (stacked bar) |

---

## 🔎 Key Insights

- **Total spend across all 550,068 transactions is $5,095,812,742.**
- **Male customers account for ~76.7% of total spend ($3.91B)** vs. **~23.3% for female customers ($1.19B)** — a far wider gap than population splits alone would suggest, pointing to either higher male transaction frequency, higher-value purchases, or both.
- The **26-35 age group is the single largest revenue driver**, contributing **~39.9% of total spend ($2.03B)** — more than double the next-closest bracket (36-45, $1.03B).
- **City Category B leads all city tiers**, generating **41.5% of total spend ($2.12B)**, ahead of City C (32.7%, $1.66B) and City A (25.8%, $1.32B) — despite B not being the largest city tier by typical urban-center assumptions, suggesting B-tier cities over-index on retail spend per capita.
- The **top single customer (User ID 1004277) spent $10.5M** — over 2,000x the dataset's average transaction value — highlighting a long-tail customer base where a small number of high-frequency or bulk buyers contribute disproportionately.
- **Single customers with 1 year of residency in their current city** form the largest segment in the residency/marital-status breakdown, suggesting relocation or new-household setup may be a meaningful spend driver worth deeper segmentation.

---

## 📁 Repository Structure

```
.
├── README.md                              # This file
├── black_friday_analysis.sql              # Full MySQL pipeline: load → clean → EDA → export
├── Peter_s_black_friday_full_project.xlsx # Cleaned data, pivot tables, dashboard
└── black_friday_dashboard.PNG             # Dashboard screenshot
```

---

## ▶️ How to Reproduce

1. Download the [Black Friday dataset](https://www.kaggle.com/datasets/sdolezel/black-friday) (or your own copy of the source CSV).
2. Run [`black_friday_analysis.sql`](./black_friday_analysis.sql) against a MySQL 8.0+ instance (update the `LOAD DATA INFILE` path to your local file location; `secure_file_priv` and `local_infile` may need to be configured).
3. Open `Peter_s_black_friday_full_project.xlsx` and refresh the pivot tables against the exported `clean_black_friday.csv`, or point them at your own query results.

---

## 👤 Author

**Peter** — Data Analyst
*Tools: SQL (MySQL) · Excel · Data Cleaning · Exploratory Data Analysis · Dashboarding*
