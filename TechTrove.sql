--1. WHAT WERE THE ORDER COUNTS, SALES, AOV FOR MACBOOKS SOLD IN NORTH AMERICA FOR EACH QUARTER ACROSS ALL YEARS?


SELECT
    date_trunc(o.purchase_ts, quarter) AS quarterly,
    count(distinct o.purchase_ts) AS order_counts,
    CONCAT('$', ROUND(avg(o.usd_price), 2)) AS aov,
    CONCAT('$', ROUND(sum(o.usd_price), 2)) AS sales
FROM
    core.orders o
LEFT JOIN
    core.customers c ON o.customer_id = c.id
LEFT JOIN
    core.geo_lookup g ON c.country_code = g.country
WHERE
    o.product_name = 'Macbook Air Laptop'
    AND g.region = 'NA'
GROUP BY
    1
ORDER BY
    1;

--2. FOR PRODUCTS PURCHASED IN 2022 ON THE WEBSITE OR PRODUCTS PURCHASED ON MOBILE IN ANY YEAR, WHICH REGION HAS THE AVERAGE HIGHEST TIME TO DELIVER?

SELECT
    g.region,
    AVG(DATE_DIFF(os.delivery_ts, os.purchase_ts, day)) AS delivery_time
FROM
    `core.order_status` os
LEFT JOIN
    core.orders o ON o.id = os.order_id
LEFT JOIN
    core.customers c ON c.id = o.customer_id
LEFT JOIN
    core.geo_lookup g ON g.country = c.country_code
WHERE
    (EXTRACT(YEAR FROM o.purchase_ts) = 2022 AND o.purchase_platform = 'website')
    OR o.purchase_platform = 'mobile app'
GROUP BY
    g.region
ORDER BY
    delivery_time DESC;

--3. WHAT WAS THE OVERALL REFUND RATE AND REFUND COUNT FOR EACH PRODUCT OVERALL?

SELECT 
    CASE 
        WHEN o.product_name = '27in"" 4k gaming monitor' THEN '27in 4K gaming monitor' 
        ELSE o.product_name 
    END AS product_name_cleaned,
    SUM(CASE WHEN os.refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refund_count,
    AVG(CASE WHEN os.refund_ts IS NOT NULL THEN 1 ELSE 0 END) AS refund_rate
FROM 
    core.orders o
LEFT JOIN 
    core.order_status os ON o.id = os.order_id
GROUP BY 
    1 
ORDER BY 
    2 DESC; 

--4. WITHIN EACH REGION, WHAT IS THE MOST POPULAR PRODUCT?

--finding counts of products per region 

WITH find_count AS (
    SELECT 
        g.region AS region,
        CASE 
            WHEN o.product_name = '27in 4k gaming monitor' THEN '27in 4k gaming monitor' 
            ELSE o.product_name 
        END AS product_name_cleaned,
        COUNT(DISTINCT o.id) AS num_purchases
    FROM 
        core.orders o
    LEFT JOIN 
        core.customers c ON o.customer_id = c.id
    LEFT JOIN 
        core.geo_lookup g ON g.country = c.country_code
    WHERE 
        region IS NOT NULL
    GROUP BY 
        g.region, product_name_cleaned
),

ranking AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY num_purchases DESC) AS rank
    FROM 
        find_count
)

SELECT *
FROM 
    ranking
WHERE 
    rank = 1;

--5) HOW DOES THE TIME TO MAKE A PURCHASE DIFFER BETWEEN LOYALTY AND NON-LOYALTY CUSTOMERS?

SELECT
    c.loyalty_program,
    ROUND(AVG(DATE_DIFF(os.purchase_ts, c.created_on, DAY)), 1) AS days_to_purchase,
    ROUND(AVG(DATE_DIFF(os.purchase_ts, c.created_on, MONTH)), 1) AS months_to_purchase
FROM
    core.customers c
LEFT JOIN
    core.orders o ON c.id = o.customer_id
LEFT JOIN
    core.order_status os ON os.order_id = o.id
GROUP BY
    1;
