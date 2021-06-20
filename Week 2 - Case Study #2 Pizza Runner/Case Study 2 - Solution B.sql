
-- B. Runner and Customer Experience 

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2020-01-01)

-- Here is the number of runners registered each week

SELECT FLOOR(DATEDIFF(registration_date, '2020-01-01') / 7 + 1)  AS week_num , 
       COUNT(*) AS number_of_runners
FROM runners
GROUP BY week_num; 

--------------

-- And here is the number of runners worked each week

SELECT FLOOR(DATEDIFF(pickup_time, '2020-01-01') / 7 + 1)  AS week_num , 
       COUNT(DISTINCT runner_id) AS number_of_runners
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY week_num;
------------------------------------------------------------

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id, 
ROUND(AVG(TIMESTAMPDIFF(minute , order_time, pickup_time)), 2) AS avg_time
FROM customer_orders cus_ord
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id AND run_ord.cancellation IS NULL
GROUP BY run_ord.runner_id;

------------------------------------------------------------

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT cus_ord.order_id, cus_ord.order_time, 
			run_ord.pickup_time, 
	       COUNT(pizza_id) AS num_pizza, 
       TIMESTAMPDIFF(minute, cus_ord.order_time, run_ord.pickup_time) AS prepare_time
       
FROM customer_orders cus_ord
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1,2,3
ORDER BY num_pizza;

-- YES, there is a relationship between the number of pizzas and the preparing time

-------------------------------------------------------------

-- 4. What was the average distance travelled for each customer?

SELECT cus_ord.customer_id, 
ROUND(AVG(run_ord.distance), 2) AS average_distance
FROM customer_orders cus_ord
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id
GROUP BY cus_ord.customer_id;

------------------------------------------------------------

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - Min(duration)AS difference_between_times
FROM runner_orders; 

------------------------------------------------------------

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id, 
	order_id, 
	distance, 
        duration,
        ROUND(AVG((distance / duration)), 2) * 60  AS avg_speed 

FROM runner_orders
GROUP BY runner_id, order_id
HAVING AVG((distance / duration)) IS NOT NULL
ORDER BY runner_id;

-- YES, there is a trend, especially for the values of runner 2, the average speed was increasing per order
------------------------------------------------------------

-- 7. What is the successful delivery percentage for each runner?

WITH success_perc AS (

SELECT runner_id, 
	 SUM(CASE 
             WHEN cancellation IS NULL THEN 1
             ELSE 0 
             END) AS success,
         COUNT(*) AS deliveries

FROM runner_orders
GROUP BY runner_id
)

(SELECT runner_id, 
	ROUND((success/ deliveries) * 100, 0) AS success_perc

FROM success_perc
group by runner_id);

