
-- Before I start solving the questions, I must clean up the tables

-- First: Cleaning runners table .. to be consistent with the information on other tables

UPDATE runners
SET registration_date = date_sub(registration_date, INTERVAL 1 YEAR);

------------------------------------------------------------

-- Second: Cleaning customer_orders table 

UPDATE customer_orders
SET exclusions = CASE 
		 WHEN (exclusions = '' OR exclusions = 'null') THEN null
		 ELSE exclusions 
		 END,
	extras = CASE 
                 WHEN (extras = '' OR extras = 'null') THEN null
                 ELSE extras 
                 END;

------------------------------------------------------------

-- Third: Cleaning runner_orders table

UPDATE runner_orders
SET pickup_time = CASE 
                  WHEN (pickup_time = '' OR pickup_time = 'null') THEN NULL
                  ELSE pickup_time 
                  END,
       distance = CASE 
                  WHEN (distance = '' OR distance = 'null') THEN NULL
                  ELSE distance 
                  END,
       duration = CASE 
	          WHEN (duration = '' OR duration = 'null') THEN NULL
                  ELSE duration 
                  END,
   cancellation = CASE 
                  WHEN (cancellation = '' OR cancellation = 'null') THEN NULL
                  ELSE cancellation 
                  END;

--------------------------------
UPDATE runner_orders
SET pickup_time = '2020-01-02 13:12:37'
WHERE order_id = 3;
----------------------------------

UPDATE runner_orders
SET distance = regexp_replace(distance, "[a-z]", ''),
    duration = regexp_replace(duration, "[a-z]", '');
-----------------------------------

ALTER TABLE runner_orders
MODIFY pickup_time timestamp,
MODIFY distance decimal(5,2),
MODIFY duration decimal(5,2);

------------------------------------------------------------


-- A. Pizza Metrics

-- 1.How many pizzas were ordered?

SELECT COUNT(pizza_id) AS num_of_pizza_ordered
FROM customer_orders;

------------------------------------------------------------

-- 2. How many unique customer orders were made?

SELECT COUNT(distinct order_id) AS uniq_customer_orders
FROM customer_orders;  

------------------------------------------------------------

-- 3.How many successful orders were delivered by each runner? 

SELECT runner_id, count(*) AS num_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

------------------------------------------------------------

-- 4. How many of each type of pizza was delivered? 

SELECT piz.pizza_name, COUNT(cus_ord.pizza_id) num
FROM pizza_names piz
JOIN customer_orders cus_ord
ON cus_ord.pizza_id = piz.pizza_id
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id 
WHERE run_ord.cancellation IS NULL
GROUP BY piz.pizza_name;


-- ANOTHER SOLUTION
SELECT SUM(CASE
           WHEN piz_nam.pizza_name = 'Meatlovers' THEN 1 
	   ELSE 0 
           END) AS Meat_Lovers,
	   SUM(CASE 
           WHEN piz_nam.pizza_name = 'Vegetarian' THEN 1
           ELSE 0 
           END) AS Vegetarian
		
FROM pizza_names piz_nam
JOIN customer_orders cus_ord
ON cus_ord.pizza_id = piz_nam.pizza_id
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id AND run_ord.cancellation IS NULL;

------------------------------------------------------------

-- 5.How many Vegetarian and Meatlovers were ordered by each customer? 

SELECT cus_ord.customer_id,
                  SUM(CASE 
		      WHEN piz.pizza_name = 'Meatlovers' THEN 1 
                      ELSE 0 
                      END) AS meatlovers_ordered,
	              SUM(CASE 
                      WHEN piz.pizza_name = 'Vegetarian' THEN 1
                      ELSE 0 
                      END) AS vegetarian_ordered
           
FROM pizza_names piz
JOIN customer_orders cus_ord
ON cus_ord.pizza_id = piz.pizza_id
GROUP BY cus_ord.customer_id;

------------------------------------------------------------

/* 6. What was the maximum number of pizzas delivered in a single order? */

WITH orders_count AS (

SELECT cus_ord.order_id AS order_id, count(cus_ord.pizza_id) AS num_of_pizza
FROM customer_orders cus_ord
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id
WHERE run_ord.cancellation IS NULL
GROUP BY cus_ord.order_id
)

SELECT max(num_of_pizza) AS max_pizza_ordered
FROM orders_count;

------------------------------------------------------------

-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes? 

SELECT cus_ord.customer_id,
	           SUM(CASE 
		       WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
                       ELSE 0 
                       END) AS changed_,
                   SUM(CASE 
                       WHEN exclusions IS NULL AND extras IS NULL THEN 1
                       ELSE 0 
                       END) AS not_changed
                  
FROM customer_orders cus_ord
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id
WHERE run_ord.cancellation IS NULL
GROUP BY cus_ord.customer_id;

------------------------------------------------------------

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(*) AS num_pizza
FROM customer_orders cus_ord
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id
WHERE run_ord.cancellation IS NULL AND (cus_ord.exclusions IS NOT NULL AND extras IS NOT NULL);

------------------------------------------------------------

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(hour FROM order_time) AS hour_of_the_day, COUNT(*) AS num_pizza
FROM customer_orders
GROUP BY hour_of_the_day
ORDER BY hour_of_the_day;

------------------------------------------------------------

-- 10. What was the volume of orders for each day of the week? 

SELECT DAYNAME(order_time) AS week_day, COUNT(distinct order_id) AS num_pizza
FROM customer_orders
GROUP BY week_day
ORDER BY week_day;

