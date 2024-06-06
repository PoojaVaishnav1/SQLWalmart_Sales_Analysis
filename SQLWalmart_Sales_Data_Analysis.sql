CREATE TABLE IF NOT EXISTS sales(
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct NUMERIC (6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date TIMESTAMP NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct NUMERIC (11,9),
    gross_income DECIMAL(12, 4),
    rating NUMERIC(3, 1)
);

COPY sales
FROM 'C:/Users/Public/WalmartSalesData.csv' 
DELIMITER ',' 
CSV HEADER;

Select * from sales

/* Feature Engineering: */
	
--1. Add a new column named 'time_of_day'
--Query to fetch time along with day
SELECT
    time,
    (CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END) AS time_of_day
FROM sales;

--Now creating a new column and filling the values in the column
ALTER table sales ADD COLUMN time_of_day VARCHAR(20)

UPDATE sales
SET time_of_day = (
	(CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END)
);

----2. Add a new column named 'day_name'
-- QUERY to fetch date along with day.
SELECT date,
	TO_CHAR(date, 'Day') AS day_name
	from sales;

ALTER table sales ADD COLUMN day_names VARCHAR(10);

UPDATE sales
SET day_names = TO_CHAR(date, 'Day');

Select * from sales;


----2. Add a new column named 'month_name'
-- Query to fetch month from the date field
Select date,
TO_CHAR(date, 'Month') as month_name
FROM sales;

ALTER table sales ADD COLUMN month_names VARCHAR(10);

UPDATE sales
SET month_names = TO_CHAR(date, 'Month');
select * from sales;

-----------Generic Questions-------------------------------

--Q1. How many unique cities does the data have?

Select distinct city from sales;

--Q2. In which city is each branch?
select distinct city, branch from sales;

----------Product Related Questions--------------------------

-- Q1. How many unique product lines does the data have?
select count(distinct product_line) from sales;

-- Q2. What is the most common payment method?
select payment, count(payment) as payment_method from sales
group by payment
order by payment_method desc;

-- Q3. What is the most selling product line?
select product_line, count(product_line) as cnt_products from sales
group by product_line
order by cnt_products desc;

-- Q4. What is the total revenue by month?
select month_names as month,
sum(total) as total_revenue 
from sales
group by month
order by total_revenue desc;

-- Q5. What month had the largest COGS?
select month_names as month,
SUM(cogs) as cogs
from sales
group by month_names
order by cogs desc;

--Q6. What product line had the largest revenue?

select product_line, 
SUM(total) as total_revenue
FROM sales
group by product_line
order by total_revenue desc;

--Q7. What is the city with the largest revenue?

select city, branch, 
SUM(total) as total_revenue
FROM sales
group by city, branch
order by total_revenue desc;

--Q8. What product line had the largest VAT?
Select product_line,
AVG(tax_pct) as vat
from sales
group by product_line
order by vat desc;

--Q9. Which branch sold more products than average product sold?

select branch,
sum(quantity) as qty
from sales
group by branch
Having sum(quantity) > (select avg(quantity) from sales);

--Q10. What is the most common product line by gender?
select gender, product_line,
count(gender) as total_cnt
from sales
group by gender, product_line
order by total_cnt desc;

--Q11. What is the average rating of each product line?
select ROUND(avg(rating),2) as avg_rating,
product_line
from sales
group by product_line
order by avg_rating desc;

--Q12. Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales

WITH avg_sales AS (
    SELECT product_line, AVG(total) AS avg_sales
    FROM sales
    GROUP BY product_line
)

SELECT s.product_line, s.total, 
       CASE 
           WHEN s.total > a.avg_sales THEN 'Good' 
           ELSE 'Bad' 
       END AS performance
FROM sales s
JOIN avg_sales a ON s.product_line = a.product_line;

------------Sales Questions------------------------------

--Q1. Number of sales made in each time of the day per weekday

select time_of_day,
count(*) as total_sales
from sales
where TRIM(day_names) ='Monday'
group by time_of_day
order by total_sales desc;

--Q2. Which of the customer types brings the most revenue?

select customer_type,
SUM(total) as total_rev
from sales
group by customer_type
order by total_rev desc;

--Q3. Which city has the largest tax percent/ VAT (Value Added Tax)?

select city,
avg(tax_pct) as vat
from sales
group by city
order by vat desc;

--Q4. Which customer type pays the most in VAT?

select customer_type,
sum(tax_pct) as vat
from sales
group by customer_type
order by vat desc;

-----------Customer Questions-------------------------

--Q1. How many unique customer types does the data have?

select distinct customer_type from sales;

--Q2. How many unique payment methods does the data have?

select distinct payment from sales;

--Q3. What is the most common customer type?
SELECT customer_type, 
       COUNT(*) AS count
FROM sales
GROUP BY customer_type
ORDER BY count DESC
LIMIT 1;

--Q4. Which customer type buys the most?
SELECT customer_type, 
       COUNT(*) AS count
FROM sales
GROUP BY customer_type
ORDER BY count DESC
LIMIT 1;

--Q5. What is the gender of most of the customers?

SELECT gender, 
       COUNT(*) AS count
FROM sales
GROUP BY gender
ORDER BY count DESC
LIMIT 1;

--Q6. What is the gender distribution per branch?

select branch, gender,
count(gender) as gen_count
from sales
group by 1,2
order by gen_count desc;

--Q7. Which time of the day do customers give most ratings?

SELECT time_of_day, 
       COUNT(*) AS total_ratings
FROM sales
GROUP BY time_of_day
ORDER BY total_ratings DESC;

--Q8. Which time of the day do customers give most ratings per branch?

WITH ratings_per_branch AS (
    SELECT branch,
           time_of_day,
           COUNT(*) AS total_ratings
    FROM sales
    GROUP BY branch, time_of_day
),

max_ratings_per_branch AS (
    SELECT branch,
           MAX(total_ratings) AS max_ratings
    FROM ratings_per_branch
    GROUP BY branch
)

SELECT rpb.branch,
       rpb.time_of_day,
       rpb.total_ratings
FROM ratings_per_branch rpb
JOIN max_ratings_per_branch mrb
ON rpb.branch = mrb.branch AND rpb.total_ratings = mrb.max_ratings
ORDER BY rpb.branch, rpb.time_of_day;

--Q9. Which day fo the week has the best avg ratings?

SELECT day_names,
       AVG(rating) AS avg_rating
FROM sales
GROUP BY day_names
ORDER BY avg_rating DESC
LIMIT 1;

--Q10. Which day of the week has the best average ratings per branch?

WITH avg_ratings_per_branch AS (
    SELECT branch,
           day_names,
           AVG(rating) AS avg_rating
    FROM sales
    GROUP BY branch, day_names
),

best_avg_ratings_per_branch AS (
    SELECT branch,
           MAX(avg_rating) AS max_avg_rating
    FROM avg_ratings_per_branch
    GROUP BY branch
)

SELECT arb.branch,
       arb.day_names,
       arb.avg_rating
FROM avg_ratings_per_branch arb
JOIN best_avg_ratings_per_branch bar
ON arb.branch = bar.branch AND arb.avg_rating = bar.max_avg_rating
ORDER BY arb.branch, arb.day_names;




