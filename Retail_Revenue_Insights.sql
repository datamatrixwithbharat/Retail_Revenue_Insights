CREATE DATABASE Retail_Revenue_Insights;

USE Retail_Revenue_Insights;

CREATE TABLE Customers (
	customer_id VARCHAR(255) PRIMARY KEY,
    customer_name VARCHAR(255),
    contact_no VARCHAR(255),
    nid VARCHAR(255)
);

CREATE TABLE Products (
	product_id VARCHAR(150) PRIMARY KEY,
    product_name VARCHAR(255),
    descrip VARCHAR(300),
    unit_price DECIMAL(10,2),
    manu_country VARCHAR(255),
    supplier VARCHAR(255),
    measuring_unit VARCHAR(255)
);

CREATE TABLE Locations (
	store_id VARCHAR(150) PRIMARY KEY,
    division VARCHAR(255),
    district VARCHAR(255),
    sub_district VARCHAR(255)
);

CREATE TABLE Order_time (
	time_id VARCHAR(150) PRIMARY KEY,
    r_date VARCHAR(150),
    r_hour INT,
    r_day INT,
    r_week VARCHAR(150),
    r_month INT,
    r_quarter VARCHAR(100),
    r_year INT
);

CREATE TABLE Payment_method (
	payment_id VARCHAR(150) PRIMARY KEY,
    pay_mode VARCHAR(100),
    bank VARCHAR(155)
);

CREATE TABLE Sales (
	payment_id VARCHAR(150),
    customer_id VARCHAR(150),
    time_id VARCHAR(150),
    product_id VARCHAR(150),
    store_id VARCHAR(150),
    quantity INT,
    measuring_unit VARCHAR(150),
    unit_price DECIMAL(10,2),
    total_price DECIMAL(10,2),
    
    FOREIGN KEY (payment_id) REFERENCES Payment_method(payment_id),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (time_id) REFERENCES Order_time(time_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (store_id) REFERENCES Locations(store_id)
);

-- 1. Customer Analysis

-- Who are the top 10 customers by total revenue?
-- rank | customer | revenue | 

SELECT 
	s.customer_id, 
    c.customer_name, 
    SUM(s.total_price) AS revenue 
FROM Sales s
LEFT JOIN Customers c
	ON s.customer_id = c.customer_id
GROUP BY 
	s.customer_id, 
    c.customer_name
ORDER BY 
	revenue DESC
LIMIT 10; 

-- What is the average purchase value per customer?
SELECT 
	customer_id, 
    AVG(total_price) AS average_purchase_value
FROM sales
GROUP BY customer_id;

SELECT AVG(total_price) AS average_purchase_value FROM sales;

-- How many unique customers made purchases each year?
-- distinct customer count | year

SELECT 
	COUNT(DISTINCT(s.customer_id)) AS unique_customer, 
    o.r_year AS year 
FROM Sales s
LEFT JOIN Order_time o
	ON s.time_id = o.time_id
GROUP BY year;


-- Which customers are most consistent (monthly/quarterly activity)?
SELECT 
	s.customer_id,
    COUNT(DISTINCT(o.r_quarter)) AS active_quarters,
    o.r_year AS year
FROM Sales s
LEFT JOIN Order_time o
	ON s.time_id = o.time_id
GROUP BY 
	s.customer_id,
    o.r_year
HAVING active_quarters >= 4
ORDER BY s.customer_id;

-- What percentage of customers are new vs returning each year?
-- new | returning | year
with new_c AS (		-- finding customer first purchase year
	SELECT 
		DISTINCT(s.customer_id) AS customer_id,
        MIN(o.r_year) AS first_purchase_year
	FROM sales s
	LEFT JOIN order_time o
		ON s.time_id = o.time_id
	GROUP BY s.customer_id
	ORDER BY s.customer_id
),
limit_c AS (	-- avoiding customer recurring by limiting a customer per year
	SELECT
		DISTINCT customer_id,
        o.r_year
	FROM sales s 
    LEFT JOIN order_time o
		ON s.time_id = o.time_id
),
tags AS ( 	-- joining limit_c and new_c for tagging cutomers as new and returning
	SELECT 
		l.customer_id,
		l.r_year AS current_year, 
		nc.first_purchase_year,
		CASE
			WHEN l.r_year = nc.first_purchase_year THEN 'New'
			WHEN l.r_year > nc.first_purchase_year THEN 'Returning'
		END AS customer_type
	FROM limit_c l
	LEFT JOIN new_c nc
		ON l.customer_id = nc.customer_id
),
totals AS ( 	-- counting new and returning customers per year
	SELECT
		COUNT(
			CASE
				WHEN customer_type = 'New' THEN 1
			END
        ) AS new_customers,
        COUNT(
			CASE
				WHEN customer_type = 'Returning' THEN 1
			END
        ) AS Returning_customers,
        COUNT(customer_id) AS total_customers_per_year,
        current_year AS year_
	FROM tags
	GROUP BY year_
    ORDER BY year_
)
SELECT -- calculating percentage of new and returning customers
	(new_customers/total_customers_per_year) * 100 AS new_customers_percentage,
    (Returning_customers/total_customers_per_year) * 100 AS Returning_customers_percentage,
    year_
FROM totals;

-- checking the above query by inserting a new record
select count(*) from sales;

INSERT INTO sales(payment_id, customer_id, time_id, product_id, store_id, quantity, measuring_unit, unit_price, total_price)
VALUES('P030', 'C123456', 'T00094', 'I00195', 'S00496', 8, 'ct', 14.00, 112.00);

INSERT INTO customers(customer_id, customer_name, contact_no, nid)
VALUES('C123456', 'Venna Bharat', '8809494024013', '1234567891234');

-- deleting the added record after successful testing of the written query
DELETE FROM sales
WHERE customer_id = 'C123456';

DELETE FROM customers
WHERE customer_id = 'C123456';

-- What is the most common payment method used by customers?
SELECT 
	COUNT(s.customer_id) AS total_payments_made,
    p.pay_mode AS payment_mode
FROM sales s
LEFT JOIN payment_method p
	ON s.payment_id = p.payment_id
GROUP BY p.pay_mode
ORDER BY total_payments_made DESC;


-- Which districts have the highest number of active customers?
SELECT 
	COUNT(DISTINCT s.customer_id) AS active_customers, 
    l.district
FROM sales s 
LEFT JOIN locations l
	ON s.store_id = l.store_id
GROUP BY l.district
ORDER BY active_customers DESC;


-- Which products generate the most revenue overall?
SELECT 
	s.product_id, 
    p.product_name, 
    SUM(s.total_price) AS revenue 
FROM sales s
LEFT JOIN products p 
	ON s.product_id = p.product_id
GROUP BY s.product_id
ORDER BY revenue DESC;


-- Which products have the highest units sold vs revenue generated (high volume vs high value)?
SELECT 
	s.product_id, 
	p.product_name,
    SUM(s.quantity) AS units_sold,
    SUM(s.total_price) AS revenue
FROM sales s
LEFT JOIN products p 
	ON s.product_id = p.product_id
GROUP BY s.product_id
ORDER BY units_sold DESC;


-- What are the top 5 most returned or least performing products (if returns can be implied)?
SELECT 
	s.product_id, 
	p.product_name,
    SUM(s.quantity) AS units_sold,
    SUM(s.total_price) AS revenue
FROM sales s
LEFT JOIN products p 
	ON s.product_id = p.product_id
GROUP BY s.product_id
ORDER BY units_sold, revenue
LIMIT 5;


-- Which supplier’s products generate the most revenue?
SELECT 
	SUM(s.total_price) AS revenue_generated_by_sales,
	p.supplier
FROM sales s
LEFT JOIN products p
	ON s.product_id = p.product_id
GROUP BY p.supplier
ORDER BY revenue_generated_by_sales DESC;


-- Which product categories (if desc or naming conventions allow grouping) perform best by region?
-- division | descrip -> compared to sales

SELECT 
	l.division,
    p.descrip,
    AVG(s.total_price) AS average_revenue_generated
FROM sales s
LEFT JOIN products p
	ON s.product_id = p.product_id
LEFT JOIN locations l 
	ON s.store_id = l.store_id
GROUP BY l.division, p.descrip
HAVING average_revenue_generated > (
	SELECT AVG(total_price) FROM sales
)
ORDER BY division, average_revenue_generated DESC;


-- What is the total revenue per year, quarter, and month?

WITH monthly_sales AS (
	SELECT 
		r_month,
		r_year,
		SUM(total_price)AS Revenue
	FROM sales s
	LEFT JOIN order_time o
		ON s.time_id = o.time_id
	GROUP BY r_year, r_month
	ORDER BY r_year, r_month
),
quarterly_sales AS (
	SELECT 
		r_quarter,
		r_year,
		SUM(total_price)AS Revenue
	FROM sales s
	LEFT JOIN order_time o
		ON s.time_id = o.time_id
	GROUP BY r_year, r_quarter
	ORDER BY r_year, r_quarter
),
yearly_sales AS (
	SELECT 
		r_year,
		SUM(total_price)AS Revenue
	FROM sales s
	LEFT JOIN order_time o
		ON s.time_id = o.time_id
	GROUP BY r_year
	ORDER BY r_year
)
SELECT * FROM yearly_sales; -- use quarterly_sales, monthly_sales, yearly_sales

-- How does total sales volume trend across time (month-over-month, year-over-year)?

WITH monthly_sales AS (
	SELECT 
		r_month,
        r_year, 
        SUM(total_price) AS revenue
	FROM sales s 
    LEFT JOIN order_time o 
		ON s.time_id = o.time_id 
	GROUP BY r_year, r_month
    ORDER BY r_year, r_month
),
yearly_sales AS(
	SELECT 
		r_year,
        SUM(total_price) AS revenue
	FROM sales s 
    LEFT JOIN order_time o 
		ON s.time_id = o.time_id 
	GROUP BY r_year
    ORDER BY r_year
),
mom AS (
	SELECT 
		r_month,
		r_year, 
		revenue AS monthly_revenue, 
        ((revenue) - IFNULL(LAG(revenue) OVER(ORDER BY r_year, r_month), 0)) AS mom,
        ROUND(
			(
				(revenue) - IFNULL(LAG(revenue) OVER(ORDER BY r_year, r_month), 0))
                /
                IFNULL(LAG(revenue) OVER(ORDER BY r_year, r_month), 0) * 100, 2
		) AS percentage_of_change
		-- SUM(revenue) OVER(PARTITION BY r_year ORDER BY r_month) AS cumulative_monthly_sales
	FROM monthly_sales
	ORDER BY r_year, r_month
),
yoy AS (
	SELECT
		r_year,
        revenue AS yearly_revenue,
        ((revenue) - IFNULL(LAG(revenue) OVER(ORDER BY r_year), 0)) AS yoy,
        ROUND((((revenue) - IFNULL(LAG(revenue) OVER(ORDER BY r_year), 0))) / IFNULL(LAG(revenue) OVER(ORDER BY r_year), 0) * 100, 2) AS percentage_of_change
        -- SUM(revenue) OVER(ORDER BY r_year) AS cumulative_yearly_sales
	FROM yearly_sales
    ORDER BY r_year
)
SELECT * FROM mom; -- replace mom/yoy with yoy/mom


-- What is the average order value over time?
-- we need to calculate average order value per month/quarter/year

SELECT -- monthly trend
	r_month,
    r_year,
    AVG(s.total_price) AS monthly_average_order_value
FROM sales s
 LEFT JOIN order_time o
	ON s.time_id = o.time_id
GROUP BY r_year, r_month
ORDER BY r_year, r_month;

SELECT -- Quarterly trend
	r_quarter,
    r_year,
    AVG(s.total_price) AS monthly_average_order_value
FROM sales s
 LEFT JOIN order_time o
	ON s.time_id = o.time_id
GROUP BY r_year, r_quarter
ORDER BY r_year, r_quarter;

SELECT -- yearly trend
    r_year,
    AVG(s.total_price) AS monthly_average_order_value
FROM sales s
 LEFT JOIN order_time o
	ON s.time_id = o.time_id
GROUP BY r_year
ORDER BY r_year;


-- Which store locations (division/district) generate the most revenue?
-- sum of sales by division in descending order

SELECT
	l.division,
    SUM(total_price) AS revenue
FROM sales s 
LEFT JOIN locations l
	ON s.store_id = l.store_id
GROUP BY l.division
ORDER BY revenue DESC;
    
    
-- What are the peak sales hours in a day?
-- count of orders and revenue per hour

SELECT 
	r_hour,
	COUNT(*) AS total_orders,
    SUM(total_price) AS revenue
FROM sales s 
LEFT JOIN order_time o 
	ON s.time_id = o.time_id
GROUP BY r_hour
ORDER BY total_orders DESC, revenue DESC;


-- How does sales performance vary between weekdays and weekends?
-- r_date is imported as VARCHAR. So modify the data to YYYY-MM-DD HH:MM:SS and then change the data type to datetime

UPDATE order_time
SET r_date = REPLACE(r_date, '/', '-');

ALTER TABLE order_time
ADD order_date DATETIME;

UPDATE order_time
SET order_date = CONCAT(
						SUBSTRING_INDEX(SUBSTRING_INDEX(r_date, "-", -1), " ", 1),
						"-",
						SUBSTRING_INDEX(SUBSTRING_INDEX(r_date, "-", 2), "-", -1),
						"-",
						SUBSTRING_INDEX(SUBSTRING_INDEX(r_date, "-", 2), "-", 1),
						" ",
						SUBSTRING_INDEX(r_date, " ", -1)
				);

SELECT 
	CASE 
		WHEN DAYNAME(order_date) IN('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
	END AS day_type,
    SUM(total_price) AS revenue,
    AVG(total_price) AS average_purchase_value,
    COUNT(*) AS total_orders
FROM sales s
LEFT JOIN order_time o
	ON s.time_id = o.time_id
GROUP BY day_type
ORDER BY revenue DESC; -- So weekday sales are higher than weekend sales


-- What is the YoY revenue growth for the business?
-- calculate year-over-year revenue change percentage (growth/decline)

SELECT 
	r_year,
    SUM(total_price) as revenue,
    ROUND(
		((SUM(total_price) - LAG(SUM(total_price)) OVER(ORDER BY r_year)) / 
		LAG(SUM(total_price)) OVER(ORDER BY r_year)) * 100, 
	2)AS revenue_change_year_over_year 
FROM sales s 
LEFT JOIN order_time o 
	ON  s.time_id = o.time_id
 GROUP BY r_year
 ORDER BY r_year;


-- What is the YoY change in number of transactions?
-- Here transactions are orders placed

SELECT 
	r_year,
    COUNT(*) as total_orders,
    ROUND(
		((COUNT(*) - LAG(COUNT(*)) OVER(ORDER BY r_year)) / 
		LAG(COUNT(*)) OVER(ORDER BY r_year)) * 100, 
	2)AS percentage_of_change_in_orders_year_over_year 
FROM sales s 
LEFT JOIN order_time o 
	ON  s.time_id = o.time_id
 GROUP BY r_year
 ORDER BY r_year;


-- What is the YoY change in average transaction value?
-- Here average transaction value is the average total_price

SELECT 
	r_year,
    ROUND(
		AVG(total_price)
        , 2) AS average_transaction_value,
    ROUND(
		((AVG(total_price) - LAG(AVG(total_price)) OVER(ORDER BY r_year)) / 
		LAG(AVG(total_price)) OVER(ORDER BY r_year)) * 100, 
	2)AS percentage_of_change_in_average_transaction_value_year_over_year 
FROM sales s 
LEFT JOIN order_time o 
	ON  s.time_id = o.time_id
 GROUP BY r_year
 ORDER BY r_year;


-- How has each product's revenue changed YoY?
-- Here we need to find revenue by product and YOY

SELECT 
	product_name,
    r_year, 
    SUM(total_price) AS revenue,
	(
		(SUM(total_price) - LAG(SUM(total_price)) OVER(PARTITION BY product_name ORDER BY product_name, r_year)) / 
		LAG(SUM(total_price)) OVER(PARTITION BY product_name ORDER BY product_name, r_year)
	) * 100 AS revenue_YOY
FROM sales s
LEFT JOIN products p
	ON s.product_id = p.product_id
LEFT JOIN order_time o 
	ON s.time_id = o.time_id
GROUP BY product_name, r_year
ORDER BY product_name, r_year;


-- How has the customer base grown or declined YoY?
-- percentage of customers YOY

SELECT 
	r_year, 
	COUNT(DISTINCT customer_id) AS customer_count,
    ROUND((
		(COUNT(DISTINCT customer_id) - LAG(COUNT(DISTINCT customer_id)) OVER(ORDER BY r_year)) / 
        LAG(COUNT(DISTINCT customer_id)) OVER(ORDER BY r_year)
    ) * 100, 2) AS Customer_YOY
FROM sales s 
LEFT JOIN order_time o 
	ON s.time_id = o.time_id 
GROUP BY r_year
ORDER BY r_year;


-- Which payment methods are increasing in popularity YoY?
-- Recomended not to use aggregate functions in LAG
SELECT 
	pay_mode, 
	r_year, 
    COUNT(pay_mode) AS order_count,
    ROUND((
		(COUNT(pay_mode) - LAG(COUNT(pay_mode)) OVER(PARTITION BY pay_mode ORDER BY r_year)) / 
        LAG(COUNT(pay_mode)) OVER(PARTITION BY pay_mode ORDER BY r_year)
	) * 100, 2) AS transactions_yoy
FROM payment_method p
RIGHT JOIN sales s
	ON p.payment_id = s.payment_id
LEFT JOIN order_time o 
	ON s.time_id = o.time_id
GROUP BY pay_mode, r_year
ORDER BY pay_mode, r_year;

-- Which regions/districts have the highest YoY revenue growth?
-- YOY revenue by districts
WITH yearly_revenue AS (
	SELECT 
		district, 
		r_year,
		SUM(total_price) AS revenue
	FROM sales s
	LEFT JOIN order_time o 
		ON s.time_id = o.time_id 
	LEFT JOIN locations l 
		ON s.store_id = l.store_id
	GROUP BY district, r_year
), 
yoy AS (
	SELECT 
		district,
		r_year, 
		revenue, 
		ROUND((
			(revenue - LAG(revenue) OVER(PARTITION BY district ORDER BY r_year)) / 
			LAG(revenue) OVER(PARTITION BY district ORDER BY r_year)
		) * 100, 2) AS yoy
	FROM yearly_revenue
	ORDER BY district, r_year
)
SELECT
	district,
    r_year,
    revenue,
    yoy
FROM (
	SELECT 
		district,
        r_year,
        revenue,
        yoy, 
        RANK() OVER(PARTITION BY r_year ORDER BY yoy DESC) AS yoy_growth_percentage
	FROM yoy
    WHERE yoy IS NOT NULL
) AS ranking
WHERE yoy_growth_percentage = 1
ORDER BY r_year;


-- Are there any underperforming stores that could be optimized or closed?
-- YOY revenue drop by store_id, declining customers/count of customer by store_id in DESC

-- considering stores with less than 10% revenue compared to top performing store
WITH min_store_performance AS (
	SELECT 
		ROUND(0.1 * revenue, 2) AS revenue_limit -- 10% of top performing store revenue
	FROM (
		SELECT 
			store_id, 
			SUM(total_price) AS revenue 
		FROM sales
		GROUP BY store_id
		ORDER BY revenue DESC
		LIMIT 1) AS new_Q
)
SELECT 
	store_id, 
    SUM(total_price) AS revenue
FROM sales
GROUP BY store_id
HAVING revenue < (
	SELECT 
		revenue_limit
	FROM min_store_performance
); -- no under performing stores

-- finding YOY store revenue
WITH store_revenue AS (
	SELECT
		store_id,
		r_year, 
		SUM(total_price) AS revenue
	FROM sales s
	LEFT JOIN order_time o 
		ON s.time_id = o.time_id
	GROUP BY store_id, r_year
	ORDER BY store_id, r_year
), 
calculated_yoy AS (
	SELECT 
		*, 
		ROUND( (
			(revenue - LAG(revenue) OVER(PARTITION BY store_id ORDER BY store_id, r_year)) / 
			LAG(revenue) OVER(PARTITION BY store_id ORDER BY store_id, r_year)
		) * 100, 2) AS yoy
	FROM store_revenue
)
SELECT 
	*
FROM calculated_yoy;

-- count of customers by store_id in DESC
SELECT 
	store_id,
	COUNT(DISTINCT customer_id) AS customer_count
FROM sales
GROUP BY store_id
ORDER BY customer_count;


-- Which product and region combinations show high demand potential?
-- product_id | quantity | division
WITH div_sales AS (
	SELECT
		s.product_id,
		p.product_name,
		division,
		SUM(quantity) AS total_sold
	FROM sales s
	LEFT JOIN locations l 
		ON s.store_id = l.store_id
	LEFT JOIN products p
		ON s.product_id = p.product_id
	GROUP BY product_id, division
	ORDER BY total_sold DESC
), 
ranked_comb AS (
	SELECT 
		*,
		DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold DESC) AS rank_
	FROM div_sales
	ORDER BY total_sold DESC
)
SELECT * FROM ranked_comb
WHERE rank_ BETWEEN 1 AND 5;


-- Which customer segment shows the highest loyalty (based on repeated transactions and spend)?
-- descrip AS category, customer frequence, revenue

SELECT 
	descrip AS cust_category,
    COUNT(customer_id) AS frequency,
    SUM(total_price) AS revenue
FROM sales s 
LEFT JOIN products p 
	ON s.product_id = p.product_id
GROUP BY descrip
ORDER BY revenue DESC;

-- Identify upselling opportunities — customers who buy X also often buy Y.
-- As this data contains customers bought one product at a time, there are no product pairs bought together.

-- THE END --