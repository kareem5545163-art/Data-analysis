CREATE DATABASE TMP_project;
USE TMP_project;

CREATE TABLE dim_customers (
    customer_id VARCHAR(50)  PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(50)  NOT NULL,
);

CREATE TABLE dim_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    country VARCHAR(50),
    city VARCHAR(100), 
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
);


CREATE TABLE dim_products (
    product_id VARCHAR(100) PRIMARY KEY, 
    product_name VARCHAR(100),
    category VARCHAR(50),
    sub_category VARCHAR(50),  
);

CREATE TABLE dim_shipping (
    ship_id INT IDENTITY(1,1) PRIMARY KEY,
    ship_mode VARCHAR(50) ,
);

CREATE TABLE fact_sales (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    customer_id VARCHAR(50),
    product_id VARCHAR(100),  
    location_id INT,
    ship_id INT,
    sales DECIMAL(18,2),
    quantity INT,
    discount DECIMAL(5,2),    
    profit DECIMAL(18,2),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (ship_id) REFERENCES dim_shipping(ship_id)
);


INSERT INTO dim_customers (customer_id, customer_name, segment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment FROM [Sample - Superstore];

INSERT INTO dim_products (product_id, product_name, category, sub_category)
SELECT DISTINCT 
    CONCAT(s.[Product_ID], '-', LEFT(s.[Product_Name], 10)), 
    s.[Product_Name], s.Category, s.[Sub_Category] 
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_products dp 
    WHERE dp.product_id = CONCAT(s.[Product_ID], '-', LEFT(s.[Product_Name], 10))
);


INSERT INTO dim_location (country, city, state, postal_code, region)
SELECT DISTINCT Country, City, State, Postal_Code, Region 
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_location dl 
    WHERE dl.country = s.Country 
      AND dl.city = s.City 
      AND dl.state = s.State 
      AND dl.postal_code = s.Postal_Code
      AND dl.region = s.Region
);


INSERT INTO dim_shipping (ship_mode)
SELECT DISTINCT Ship_Mode
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_shipping ds 
    WHERE ds.ship_mode = s.Ship_Mode
);


WITH deduped AS (
    SELECT 
        s.[Row_ID], 
        s.[Order_ID], 
        s.[Order_Date], 
        s.[Ship_Date], 
        s.[Customer_ID], 
        CONCAT(s.[Product_ID], '-', LEFT(s.[Product_Name], 10))  AS product_id,
        loc.location_id, 
        ship.ship_id, 
        s.Sales, 
        s.Quantity, 
        s.Discount, 
        s.Profit,
        ROW_NUMBER() OVER (PARTITION BY s.[Row_ID] ORDER BY loc.location_id, ship.ship_id) AS rn
    FROM [Sample - Superstore] s
    JOIN dim_location loc ON 
        s.Country       = loc.country      AND
        s.City          = loc.city         AND
        s.State         = loc.state        AND
        s.[Postal_Code] = loc.postal_code  AND
        s.Region        = loc.region
    JOIN dim_shipping ship ON 
        s.[Ship_Mode] = ship.ship_mode
)
INSERT INTO fact_sales (
    row_id, order_id, order_date, ship_date,
    customer_id, product_id, location_id, ship_id,
    sales, quantity, discount, profit
)
SELECT 
    Row_ID, Order_ID, Order_Date, Ship_Date,
    Customer_ID, product_id, location_id, ship_id,
    Sales, Quantity, Discount, Profit
FROM deduped
WHERE rn = 1
AND NOT EXISTS (
    SELECT 1 FROM fact_sales f WHERE f.row_id = deduped.Row_ID
);


INSERT INTO dim_customers (customer_ID, customer_Name, segment)
SELECT DISTINCT Customer_ID, Customer_Name, Segment 
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_customers dc 
    WHERE dc.customer_ID = s.Customer_ID
);


INSERT INTO dim_products (product_id, product_name, category, sub_category)
SELECT DISTINCT 
    CONCAT(s.[Product_ID], '-', LEFT(s.[Product_Name], 10)), 
    s.[Product_Name], s.Category, s.[Sub_Category] 
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_products dp 
    WHERE dp.product_id = CONCAT(s.[Product_ID], '-', LEFT(s.[Product_Name], 10))
);



INSERT INTO dim_location (country, city, state, postal_code, region)
SELECT DISTINCT Country, City, State, Postal_Code, Region 
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_location dl 
    WHERE dl.country = s.Country 
      AND dl.city = s.City 
      AND dl.state = s.State 
      AND dl.postal_code = s.Postal_Code
      AND dl.region = s.Region
);


INSERT INTO dim_shipping (ship_mode)
SELECT DISTINCT Ship_Mode
FROM [Sample - Superstore] s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_shipping ds 
    WHERE ds.ship_mode = s.Ship_Mode
);



INSERT INTO fact_sales (
    row_id, order_id, order_date, ship_date, 
    customer_id, product_id, location_id, ship_id, 
    sales, quantity, discount, profit
)
SELECT 
    s.[Row_ID], 
    s.[Order_ID], 
    s.[Order_Date], 
    s.[Ship_Date], 
    s.[Customer_ID], 
    CONCAT(s.[Product_ID], '-', LEFT(s.[Product_Name], 10)), 
    loc.location_id, 
    ship.ship_id, 
    s.Sales, 
    s.Quantity, 
    s.Discount, 
    s.Profit
FROM [Sample - Superstore] s
JOIN dim_location loc ON 
    s.Country = loc.country AND s.City = loc.city AND s.State = loc.state 
    AND s.[Postal_Code] = loc.postal_code AND s.Region = loc.region
JOIN dim_shipping ship ON 
    s.[Ship_Mode] = ship.ship_mode
WHERE NOT EXISTS (
    SELECT 1 FROM fact_sales f 
    WHERE f.row_id = s.Row_ID
);

SELECT 4995 + 4999 AS total_rows_affected;


-- (JOIN + GROUP BY + aggregate functions)
SELECT
    p.category,
    p.sub_category,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(AVG(f.discount) * 100, 1) AS avg_discount_pct,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales  f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY
    p.category,
    p.sub_category
ORDER BY
    p.category,
    total_sales DESC;


-- (JOIN + GROUP BY + HAVING)
SELECT
    l.region,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY
    l.region
HAVING
    SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100 < 10
ORDER BY profit_margin_pct ASC;


-- (JOIN + GROUP BY + HAVING + subquery)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    COUNT(*) AS times_sold,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_sales  f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category
HAVING SUM(f.profit) < 0
ORDER BY total_profit ASC;