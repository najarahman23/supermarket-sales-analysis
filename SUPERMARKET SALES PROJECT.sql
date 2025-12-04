create database supermarket_sales;
use supermarket_sales;

select * from supermarket_sales;

DESCRIBE supermarket_sales;

#Standardize & Trim Text Columns
UPDATE supermarket_sales
SET
    `Invoice ID` = TRIM(`Invoice ID`),
    Branch = TRIM(Branch),
    City = TRIM(City),
    `Customer type` = TRIM(`Customer type`),
    Gender = TRIM(Gender),
    `Product line` = TRIM(`Product line`),
    Payment = TRIM(Payment);

#Convert Date & Time Columns
UPDATE supermarket_sales
SET Date = STR_TO_DATE(Date, '%m/%d/%Y');

#Convert Time:
UPDATE supermarket_sales
SET Time = STR_TO_DATE(Time, '%H:%i:%s');

SELECT Date, Time FROM supermarket_sales LIMIT 10;

#Convert Numeric Columns
UPDATE supermarket_sales
SET
    `Unit price` = CAST(`Unit price` AS DECIMAL(10,2)),
    Quantity = CAST(Quantity AS UNSIGNED),
    `Tax 5%` = CAST(`Tax 5%` AS DECIMAL(10,2)),
    Total = CAST(Total AS DECIMAL(10,2)),
    cogs = CAST(cogs AS DECIMAL(10,2)),
    `gross margin percentage` = CAST(`gross margin percentage` AS DECIMAL(10,4)),
    `gross income` = CAST(`gross income` AS DECIMAL(10,2)),
    Rating = CAST(Rating AS DECIMAL(5,2));
    
#Tax must be 5% of COGS:    
UPDATE supermarket_sales
SET `Tax 5%` = ROUND(cogs * 0.05, 2)
WHERE `Tax 5%` <> ROUND(cogs * 0.05, 2);

#Total must equal COGS + Tax:
UPDATE supermarket_sales
SET Total = ROUND(cogs + `Tax 5%`, 2)
WHERE Total <> ROUND(cogs + `Tax 5%`, 2);

#hour of day
ALTER TABLE supermarket_sales ADD COLUMN Hour INT;
UPDATE supermarket_sales
SET Hour = HOUR(Time);

#weekday
alter table  supermarket_sales add column weekday varchar(20);
update supermarket_sales
set weekday=dayname(date);

#month
ALTER TABLE supermarket_sales ADD COLUMN MonthName VARCHAR(10);
UPDATE supermarket_sales
SET MonthName = MONTHNAME(Date);

#Detect Missing Values:
SELECT 
    SUM(CASE WHEN `Unit price` IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN Total IS NULL THEN 1 ELSE 0 END) AS null_total,
    SUM(CASE WHEN cogs IS NULL THEN 1 ELSE 0 END) AS null_cogs
FROM supermarket_sales;

#Detect Outliers:
SELECT *
FROM supermarket_sales
WHERE
    `Unit price` < 0
    OR Quantity < 0
    OR Total < 0;
    
#Duplicate Invoice Check
SELECT `Invoice ID`, COUNT(*)
FROM supermarket_sales
GROUP BY `Invoice ID`
HAVING COUNT(*) > 1;
    
#Check distinct dates range
SELECT MIN(Date) AS min_date, MAX(Date) AS max_date, COUNT(DISTINCT Date) AS distinct_days
FROM supermarket_sales;

#Total sales, total gross income, avg rating, total transactions:
SELECT 
  COUNT(*) AS transactions,
  SUM(Total) AS total_sales,
  SUM(`gross income`) AS total_gross_income,
  AVG(Rating) AS avg_rating,
  AVG(Total) AS avg_order_value
FROM supermarket_sales;


#Sales by Branch, City, Product line, Payment, Gender, Customer,type:
#Sales by Branch
SELECT Branch, COUNT(*) AS txns, SUM(Total) AS sales, AVG(Total) AS avg_txn
FROM supermarket_sales
GROUP BY Branch
ORDER BY sales DESC;

# Sales by City
SELECT City, COUNT(*) AS txns, SUM(Total) AS sales
FROM supermarket_sales
GROUP BY City
ORDER BY sales DESC;

#Sales by Product line
SELECT `Product line`, COUNT(*) AS txns, SUM(Total) AS sales, SUM(`gross income`) AS gross_income, AVG(Rating) AS avg_rating
FROM supermarket_sales
GROUP BY `Product line`
ORDER BY sales DESC;

#Sales by Payment method
select payment, count(*) as txns, sum(total)as sales, avg(total) as avg_sales
from supermarket_sales
group by payment
order by sales desc;

#Sales by Gender
SELECT Gender, COUNT(*) AS txns, SUM(Total) AS sales, AVG(Total) AS avg_order
FROM supermarket_sales
GROUP BY Gender;

#Sales by Customer type (eg:Member vs Normal)
SELECT `Customer type`, COUNT(*) AS txns, SUM(Total) AS sales, AVG(Total) AS avg_txn
FROM supermarket_sales
GROUP BY `Customer type`;


#TIME BASED TRENDS:
#Daily sales time series
SELECT Date, COUNT(*) AS txns, SUM(Total) AS daily_sales
FROM supermarket_sales
GROUP BY Date
ORDER BY Date;

#Sales by Month
SELECT 
    MONTH(Date) AS month_num,
    MONTHNAME(Date) AS month_name,
    SUM(Total) AS total_sales
FROM supermarket_sales
GROUP BY 
    MONTH(Date),
    MONTHNAME(Date)
ORDER BY month_num;

#Sales by Weekday
SELECT Weekday, SUM(Total) AS sales, COUNT(*) AS txns
FROM supermarket_sales
GROUP BY Weekday
ORDER BY FIELD(Weekday,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

#Sales by Hour (peak times)
SELECT Hour, SUM(Total) AS sales, COUNT(*) AS txns
FROM supermarket_sales
GROUP BY Hour
ORDER BY Hour;


#TOP TO BOTTOM ANALYSIS:
#Top 10 invoices by Total
SELECT `Invoice ID`, Date, Branch, Total
FROM supermarket_sales
ORDER BY Total DESC
LIMIT 10;

#Bottom 10 invoices
SELECT `Invoice ID`, Date, Branch, Total
FROM supermarket_sales
ORDER BY Total ASC
LIMIT 10;

#Top 10 product lines by gross income per txn
SELECT `Product line`, SUM(`gross income`) AS total_gross_income, AVG(`gross income`) AS avg_gross_income
FROM supermarket_sales
GROUP BY `Product line`
ORDER BY total_gross_income DESC
LIMIT 10;


#DISTRIBUTION AND VARIABILITY:
#Units sold distribution by product line
SELECT `Product line`, SUM(Quantity) AS total_qty, AVG(Quantity) AS avg_qty, STDDEV_POP(Quantity) AS sd_qty
FROM supermarket_sales
GROUP BY `Product line`
ORDER BY total_qty DESC;

# Unit price summary
SELECT MIN(`Unit price`) AS min_price, MAX(`Unit price`) AS max_price, AVG(`Unit price`) AS avg_price, STDDEV_POP(`Unit price`) AS sd_price
FROM supermarket_sales;

# Rating distribution
SELECT FLOOR(Rating) AS rating_floor, COUNT(*) AS counts, AVG(Total) AS avg_sale
FROM supermarket_sales
GROUP BY rating_floor
ORDER BY rating_floor DESC;


#PROFITABILITY AND MARGINAL ANALYSIS:
# Gross margin by product line
SELECT `Product line`,
       SUM(`gross income`) AS total_gross_income,
       SUM(Total) AS total_sales,
       AVG(`gross margin percentage`) AS avg_margin_pct
FROM supermarket_sales
GROUP BY `Product line`
ORDER BY total_gross_income DESC;

# Branch profitability
SELECT Branch, SUM(`gross income`) AS gross_income, SUM(Total) AS sales, AVG(`gross margin percentage`) AS avg_margin
FROM supermarket_sales
GROUP BY Branch
ORDER BY gross_income DESC;


#CONTRIBUTION METRICS
# Contribution of product lines to total sales
SELECT `Product line`, SUM(Total) AS sales, ROUND(100 * SUM(Total) / (SELECT SUM(Total) FROM supermarket_sales), 2) AS pct_of_total
FROM supermarket_sales
GROUP BY `Product line`
ORDER BY sales DESC;

# Contribution by city
SELECT City, SUM(Total) AS sales, ROUND(100 * SUM(Total)/(SELECT SUM(Total) FROM supermarket_sales),2) pct_of_total
FROM supermarket_sales
GROUP BY City
ORDER BY sales DESC;


#RANKS
# Running total of sales by date
SELECT Date, daily_sales,
       SUM(daily_sales) OVER (ORDER BY Date) AS running_total_sales
FROM (
  SELECT Date, SUM(Total) AS daily_sales
  FROM supermarket_sales
  GROUP BY Date
) s
ORDER BY Date;

#Rank product lines by sales
SELECT `Product line`, sales,
       RANK() OVER (ORDER BY sales DESC) AS sales_rank
FROM (
  SELECT `Product line`, SUM(Total) AS sales
  FROM supermarket_sales
  GROUP BY `Product line`
) p;

###
#1. Daily sales time series with branch breakdown
SELECT Date, Branch, SUM(Total) AS sales
FROM supermarket_sales
GROUP BY Date, Branch
ORDER BY Date, Branch;

# 2. Pivot-like summary for product lines by branch
SELECT Branch, `Product line`, SUM(Total) AS sales
FROM supermarket_sales
GROUP BY Branch, `Product line`
ORDER BY Branch, sales DESC;

#3. Average quantity per product line per transaction
SELECT `Product line`, AVG(Quantity) AS avg_qty_per_txn
FROM supermarket_sales
GROUP BY `Product line`;


SELECT *
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/supermarket_cleaned.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM supermarket_sales;





