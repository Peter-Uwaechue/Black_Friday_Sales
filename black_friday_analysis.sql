-- ================================================================
-- BLACK FRIDAY SALES ANALYSIS
-- MySQL 8.0
-- ================================================================

-- ----------------------------------------------------------------
-- 1. TABLE CREATION & DATA LOAD
-- ----------------------------------------------------------------
create table black_friday_sales (User_ID int, Product_ID varchar(20), Gender varchar(10), Age varchar(10), Occupation int, 
City_Category varchar(3), Stay_in_Current_City_Years varchar(5), Marital_Status int, Product_Category_1 int, Product_Category_2 int null,
Product_Category_3 int null, Purchase int) ;

load data infile  'c:/ProgramData/MySql/MySql Server 8.0/Uploads/Black Friday Dataset.csv' into table black_friday_sales
fields terminated by ','
ignore 1 rows
(User_id , Product_id , Gender , Age , Occupation , 
City_Category , Stay_in_Current_City_Years , Marital_Status , Product_Category_1 , @variable1 ,
@variable2 , Purchase)
set Product_Category_2 = if(@variable1 = '', null, @variable1),
Product_Category_3 = if(@variable2 = '', null, @variable2);

-- ----------------------------------------------------------------
-- 2. DUPLICATE CHECK
-- Result: 0 rows returned -> no duplicates found
-- ----------------------------------------------------------------
with cte1 as (select *, row_number()over(partition by User_id , Product_id , Gender , Age , Occupation , 
City_Category , Stay_in_Current_City_Years , Marital_Status , Product_Category_1 , Product_Category_2 ,
Product_Category_3 , Purchase) as row_num from black_friday_sales)
select * from cte1 where row_num > 1;

-- ----------------------------------------------------------------
-- 3. DATA STANDARDIZATION (CLEAN VIEW)
-- Decodes Gender (f/m) and Marital_Status (0/1) into readable labels
-- ----------------------------------------------------------------
create view blackfriday_sales as
select User_ID , Product_ID , case
when gender = 'f' then 'Female'
when gender = 'm' then 'Male'
end Gender, Age , Occupation , 
City_Category , Stay_in_Current_City_Years , CASE 
When Marital_Status = 0 THEN 'Single'
when Marital_Status = 1 then 'Married'
end Marital_Status, Product_Category_1 , Product_Category_2 ,
Product_Category_3 , Purchase
from black_friday_sales;

-- ----------------------------------------------------------------
-- 4. EXPLORATORY DATA ANALYSIS
-- ----------------------------------------------------------------

-- 4.1 Customer-Level Analysis: Top 10 customers by total spend
select user_id, sum(purchase) total_purchase from blackfriday_sales
group by user_id
order by total_purchase desc
limit 10;

-- 4.2 Product-Level Analysis: Top 10 products by units sold
select product_id, count(product_id) unit_sold from blackfriday_sales
group by product_id
order by unit_sold desc
limit 10;

-- 4.3 Gender Analysis
select gender, avg(purchase) average_purchase from blackfriday_sales
group by gender;

select gender, sum(purchase) total_purchase from blackfriday_sales
group by gender;

select gender, count(purchase) number_of_purchase from blackfriday_sales
group by gender;

-- 4.4 Age Group Analysis
select age, avg(purchase) average_purchase from blackfriday_sales
group by age
order by average_purchase desc;

select age, sum(purchase) total_purchase from blackfriday_sales
group by age
order by total_purchase desc;

select age, count(purchase) number_of_purchase from blackfriday_sales
group by age
order by number_of_purchase desc;

-- 4.5 Occupation Analysis
select occupation, sum(purchase) total_purchase from blackfriday_sales
group by occupation
order by total_purchase desc;

select occupation, avg(purchase) average_purchase from blackfriday_sales
group by occupation
order by average_purchase desc;

select occupation, count(purchase) number_of_purchase from blackfriday_sales
group by occupation
order by number_of_purchase desc;

-- 4.6 City Category Analysis
select city_category, sum(purchase) total_purchase from blackfriday_sales
group by city_category
order by total_purchase desc;

select city_category, avg(purchase) average_purchase from blackfriday_sales
group by city_category
order by average_purchase desc;

select city_category, count(purchase) number_of_purchase from blackfriday_sales
group by city_category
order by number_of_purchase desc;

-- 4.7 Stay in Current City (Years) Analysis
select stay_in_current_city_years, sum(purchase) total_purchase from blackfriday_sales
group by stay_in_current_city_years
order by total_purchase desc;

select stay_in_current_city_years, avg(purchase) average_purchase from blackfriday_sales
group by stay_in_current_city_years
order by average_purchase desc;

select stay_in_current_city_years, count(purchase) number_of_purchase from blackfriday_sales
group by stay_in_current_city_years
order by number_of_purchase desc;

-- 4.8 Marital Status Analysis
select Marital_status, sum(purchase) total_purchase from blackfriday_sales
group by marital_status
order by total_purchase desc;

select Marital_status, avg(purchase) average_purchase from blackfriday_sales
group by marital_status
order by average_purchase desc;

select Marital_status, count(purchase) number_of_purchase from blackfriday_sales
group by marital_status
order by number_of_purchase desc;

-- 4.9 Product Category Analysis
select product_category_1, sum(purchase) total_purchase from blackfriday_sales
group by product_category_1
order by total_purchase desc;

select product_category_1, avg(purchase) average_purchase from blackfriday_sales
group by product_category_1
order by average_purchase desc;

select product_category_1, count(purchase) number_of_purchase from blackfriday_sales
group by product_category_1
order by number_of_purchase desc;

-- ----------------------------------------------------------------
-- 5. EXPORT CLEANED DATA
-- ----------------------------------------------------------------
SELECT
User_ID, Product_ID, Gender, Age, Occupation, City_Category,
Stay_In_Current_City_Years, Marital_Status, Product_Category_1,
Product_Category_2, Product_Category_3, Purchase
FROM blackfriday_sales
INTO OUTFILE 'c:/ProgramData/MySql/MySql Server 8.0/Uploads/clean_black_friday.csv'
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';
