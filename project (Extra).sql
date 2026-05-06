USE TMP_project;


-- (JOIN + GROUP BY + ORDER BY + TOP)
SELECT TOP 10
    c.customer_id,
    c.customer_name,
    c.segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_sales f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.segment
ORDER BY total_revenue DESC;


-- (JOIN + GROUP BY + HAVING with multiple conditions)
SELECT
    l.state,
    l.region,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(AVG(f.discount) * 100, 1) AS avg_discount_pct,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_sales  f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY
    l.state,
    l.region
HAVING
    COUNT(DISTINCT f.order_id) > 100
    AND AVG(f.discount) * 100 > 20
ORDER BY avg_discount_pct DESC;


-- (JOIN + GROUP BY + window-style share via subquery)
SELECT
    sh.ship_mode,
    COUNT(*) AS shipments,
    ROUND(AVG(DATEDIFF(DAY, f.order_date, f.ship_date)), 1) AS avg_ship_days,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.sales) * 100.0 /
          (SELECT SUM(sales) FROM fact_sales), 2) AS revenue_share_pct
FROM fact_sales f
JOIN dim_shipping sh ON f.ship_id = sh.ship_id
GROUP BY sh.ship_mode
ORDER BY total_sales DESC;


-- (JOIN + GROUP BY + correlated subquery for running total)
SELECT
    YEAR(f.order_date) AS yr,
    MONTH(f.order_date) AS mo,
    ROUND(SUM(f.sales), 2) AS monthly_sales,
    ROUND(SUM(f.profit), 2) AS monthly_profit,
    ROUND((
        SELECT SUM(f2.sales)
        FROM fact_sales f2
        WHERE YEAR(f2.order_date) * 100 + MONTH(f2.order_date)
              <= YEAR(f.order_date) * 100 + MONTH(f.order_date)
    ), 2) AS running_total_sales
FROM fact_sales f
GROUP BY
    YEAR(f.order_date),
    MONTH(f.order_date)
ORDER BY yr, mo;