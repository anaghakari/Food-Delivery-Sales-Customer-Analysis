select *
from customers;

select *
from restaurants;

select *
from orders;

select * 
from deliveries;

select *
from riders;


SELECT COUNT(*) FROM restaurants
where 
restuarant_name is null
or
city is null
or 
opening_hours is null

--Q1 
-- Write a query to find top 5 most frequently ordered dishes by customer called "Aarohi Reddy"

select c.customer_id,
c.customer_name,
o.order_item as dishes,
count(*) as total_orders,
dense_rank()over(order by count(*))
from orders as o
join
customers as c
on c.customer_id=o.customer_id
where
o.order_date>=CURRENT_DATE-INTERVAL '1 Year'
and c.customer_name='Aarohi Reddy'
Group by 1,2,3 
order by 1,4 desc

select current_date-interval '1 year'


--Q2
--Popular Timeslots 
--Identify time slots during the most orders are placed based on 2 hour difference.

select 
case
when extract (hour from order_time) between 0 and 1 then'00:00-02:00'
when extract(hour from order_time) between 2 and 3 then'02:00-04:00'
when extract(hour from order_time) between 4 and 5 then'04:00-06:00'
when extract(hour from order_time) between 6 and 7 then'06:00-08:00'
when extract(hour from order_time) between 8 and 9 then'08:00-10:00'
when extract(hour from order_time) between 10 and 11 then'10:00-12:00'
when extract(hour from order_time) between 12 and 13 then'12:00-14:00'
when extract(hour from order_time) between 14 and 15 then'14:00-16:00'
when extract(hour from order_time) between 16 and 17 then'16:00-18:00'
when extract(hour from order_time) between 18 and 19 then'18:00-20:00'
when extract(hour from order_time) between 20 and 21 then'20:00-22:00'
when extract(hour from order_time) between 22 and 23 then'22:00-24:00'

end as time_slot,
count(order_id) as order_count
from orders
group by time_slot
order by order_count desc;


select 
 order_time,
  floor(extract(hour from order_time))/2*2 as start_time,
  floor(extract(hour from order_time))/2*2+2 as end_time
  from orders;


--Q3 Order Value Analysis
-- Find average orde value per customer who has placed more than 3 orders

select customer_id,
avg(total_amount) as aov,
count(order_id) as total_orders
from orders
group by 1
having count(order_id)>3


--Q4 High value customers
--List the customers who have spent more than 3k on food orders
Select 
c.customer_id,
sum(o.total_amount) as total_spent
from orders as o
join customers as c
on c.customer_id =o.customer_id
group by 1
having sum(o.total_amount)>3000


--Q5 Orders without delivery
--Write a query to find orders that were placed but not delivered

select *
from orders as o
join deliveries as d
on o.order_id=d.order_id
where delivery_status != 'delivered'

--Q6 Restuarant Revenue 
--Rank top 5 restaurants by their total revenue from last year including their name


with ranking_table
as
(
select 
r.city,
r.restaurant_name,
sum(o.total_amount) as  revenue,
rank() over(order by sum(o.total_amount)desc) as rank
from orders as o
join restaurants as r
on o.restaurant_id=r.restaurant_id
where o.order_date >= current_date- interval'1 year'
group by 1,2
)
select *
from ranking_table
where rank <=5

--Q7 Popular dish name
--Identify the most popular dish based on number of orders

SELECT 
    o.order_item AS dish,
    COUNT(order_id) AS total_orders
FROM orders AS o
JOIN restaurants AS r 
    ON r.restaurant_id = o.restaurant_id
GROUP BY o.order_item
order by total_orders desc;

--Q8 Customer Churn
-- Find customers who havent placed an order in 2024 but did in 2023
with
select 
restaurant_id,
count(o.order_id) as total_orders,
count(case when d.delivery_id is null then 1 end) as not_delivered 
from orders as o
left join
deliveries as d
on o.order_id=d.order_id
where extract(year from order_date)=2023
group by o.restaurant_id
order by total_orders desc
)
select 
restaurant_id,
total_orders,
not_delivered,
not_delivered::numeric/total_orders*100
from cancel_ratio


--Q9 Cancellation Rate comparison 
-- Calculate and compare the order cancellation rate for each restaurant between current & prev year


WITH cancel_ratio AS (
    SELECT
        o.restaurant_id,
        EXTRACT(YEAR FROM o.order_date)::INT AS order_year,
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (WHERE d.delivery_id IS NULL) AS not_delivered
    FROM orders AS o
    LEFT JOIN deliveries AS d
        ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) IN (2024, 2025)
    GROUP BY o.restaurant_id, order_year
)
SELECT
    restaurant_id,
    order_year,
    total_orders,
    not_delivered,
    ROUND( (not_delivered::numeric / NULLIF(total_orders,0)) * 100, 2) AS cancel_ratio_pct
FROM cancel_ratio
ORDER BY restaurant_id, order_year;
--Q10
-- Riders average delivery time 
-- Determine each riders delivery time

SELECT
  d.rider_id,
  r.rider_name,
  ROUND(AVG(d.delivery_time_minutes)::numeric, 2) AS avg_minutes,
  MIN(d.delivery_time_minutes) AS min_minutes,
  MAX(d.delivery_time_minutes) AS max_minutes
FROM deliveries d
LEFT JOIN riders r USING (rider_id)
WHERE TRIM(LOWER(d.delivery_status)) = 'delivered'
GROUP BY d.rider_id, r.rider_name
ORDER BY avg_minutes;



--Q11 Monthly Restaurant Growth rate 
--Calculate each restaurant's growth ratio based on total number of delivered orders since beginning

last 20
cm--30

cs-ls/ls
30-20/20*100


WITH monthly AS (
  SELECT
    o.restaurant_id,
    date_trunc('month', o.order_date)::date AS month_start,
    COUNT(*) AS cr_month_orders
  FROM orders AS o
  JOIN deliveries AS d
    ON d.order_id = o.order_id
  WHERE d.delivery_status = 'Delivered'
    AND o.order_date >= DATE '2024-01-01'
    AND o.order_date <  DATE '2026-01-01'
  GROUP BY o.restaurant_id, month_start
),
growth AS (
  SELECT
    restaurant_id,
    month_start,
    cr_month_orders,
    LAG(cr_month_orders) OVER (
      PARTITION BY restaurant_id
      ORDER BY month_start
    ) AS prev_month_orders
  FROM monthly
)
SELECT
  restaurant_id,
  TO_CHAR(month_start, 'YYYY-MM') AS month,
  prev_month_orders,
  cr_month_orders,
  CASE
    WHEN prev_month_orders IS NULL OR prev_month_orders = 0 THEN NULL
    ELSE ROUND(((cr_month_orders - prev_month_orders)::numeric / prev_month_orders) * 100, 2)
  END AS monthly_growth_ratio_pct
FROM growth
ORDER BY restaurant_id, month_start;


--Q 12 Customer Segretation
-- Segment customers into 'gold' or 'Silver' groups based on their last spending
-- compared to the avergae order value if a customer's total spending exceeds the AOV,
--label them as 'Gold '; otherwise label them as 'Silver'. Write an SQL Query to determine each segments.
--total number of orders and total revenue.


select 
cx_category,
sum(total_orders),
sum(total_spent)
from

(select
customer_id,
sum(total_amount) as total_spent,
count(order_id) as total_orders,
CASE WHEN sum(total_amount)>(select avg(total_amount)from orders) then 'gold'
ELSE 'silver'
END as cx_category
from orders
group by 1
) as t1
group by 1

select avg(total_amount) from orders -- 989

--Q13 Rider Monthly Earnings:
-- Calculate each riders monthly earnings, assuming they earn 8 % of the order amount 

select 
d.rider_id,
to_char(o.order_date,'mm-yy') as month,
sum(total_amount)
from orders as o
join deliveries as d
on o.order_id=d.order_id
group by 1,2
order by 1,2

--Q14 Rider Ratings Analysis
--Find the number of 5 star, 4 star, 3 star ratings each rider has
--riders recieve this rating based on delivery time.
--if orders are delivered less than 15 minutes of order receieved time the rater gets 5 star rating
--if they dleiver 15 and 20 minute they get 4 star rating
--if they deliver after 20 minutes they get 3 star rating

SELECT
  r.rider_id,
  r.rider_name,
  d.delivery_time_minutes,
  CASE
    WHEN d.delivery_time_minutes IS NULL THEN 'unknown'
    WHEN d.delivery_time_minutes < 15 THEN '5 star'
    WHEN d.delivery_time_minutes BETWEEN 15 AND 20 THEN '4 star'
    ELSE '3 star'
  END AS stars
FROM riders AS r
JOIN deliveries AS d
  ON r.rider_id = d.rider_id
  

--Q15 Order Frequency 

--Analyse order frequency per day of weel and identify the peak day for each restaurant

select *
from(
select 
r.restaurant_name,
o.order_date,
TO_CHAR(o.order_date,'Day') as day,
count(o.order_id) as total_orders,
rank()over(partition by r.restaurant_name order by  count(o.order_id)desc) as rank
from orders as o
join 
restaurants as r
on o.restaurant_id=r.restaurant_id
group by 1,2
order by 1,3 desc
) as t1
where rank =1

--Q 16
-- Customer lifetime value (CLV)
-- Calculate the total revenue generated by each customer over all their orders

select 
o.customer_id,
c.customer_name,
sum(o.total_amount) as clv
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by 1,2


--Q17
--Monthly sales trends
--Indentify sale trends by comparing each month's total sales to previous month


WITH monthly AS (
  SELECT
    EXTRACT(YEAR  FROM order_date)::INT  AS year,
    EXTRACT(MONTH FROM order_date)::INT  AS month,
    SUM(total_amount)::numeric            AS total_sales
  FROM orders
  GROUP BY 1,2
),
growth AS (
  SELECT
    year,
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year, month) AS prev_month
  FROM monthly
)
SELECT
  year,
  month,
  total_sales,
  prev_month,
  CASE
    WHEN prev_month IS NULL OR prev_month = 0 THEN NULL
    ELSE ROUND(
      ((total_sales - prev_month)::numeric
       / NULLIF(prev_month, 0)::numeric) * 100,
      2
    )
  END AS pct_change_from_prev_month
FROM growth
ORDER BY year, month;

--Q18
--Rider Efficency
--Evaluate rider efficency by determining average delivery time and identifying those with lowest and highest average

select *
from orders as o
join deliveries as d
on o.order_id=d.order_id
where d.delivery_status='delivered'




--Q19 Order item popularity
--Track poplularity of specific order items and identify seasonal demand spikes

SELECT 
    season,
    COUNT(order_id) AS total_orders
FROM (
    SELECT 
        order_id,
        EXTRACT(MONTH FROM order_date) AS month,
        CASE
            WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
            WHEN EXTRACT(MONTH FROM order_date) BETWEEN 7 AND 8 THEN 'Summer'
            ELSE 'Winter'
        END AS season
    FROM orders
) AS t1
GROUP BY season;



--Q20 Monthly restaurant Growth Rates
--Track the popularity 

select 
r.city,
sum(total_amount) as total_revenue,
rank()over(order by sum(total_amount)desc) as city_rank
from orders as o
join
restaurants as r
on o.order_id=r.restaurant_id
group by 1





