
-- D. Pricing and Ratings

/* 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
      how much money has Pizza Runner made so far if there are no delivery fees?  */

SELECT SUM(CASE 
           WHEN piz_nam.pizza_name = 'Meatlovers' THEN 12
           WHEN piz_nam.pizza_name = 'Vegetarian' THEN 10 
           END) AS sales

FROM runner_orders run_ord
JOIN customer_orders cus_ord
ON cus_ord.order_id = run_ord.order_id
JOIN pizza_names piz_nam
ON piz_nam.pizza_id = cus_ord.pizza_id
WHERE run_ord.cancellation IS NULL;
  
------------------------------------------------------------

/* 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
 how would you design an additional table for this new dataset - 
 generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5. */
 
 
CREATE TABLE rating(
                    customer_id int, 
		      runner_id int, 
                       order_id int, 
			  rating int
);

------------
INSERT INTO rating(
                   customer_id, 
		     runner_id, 
                     order_id
) 
   SELECT DISTINCT customer_id, 
		     runner_id, 
	       cus_ord.order_id 

FROM customer_orders cus_ord 
JOIN runner_orders run_ord
ON run_ord.order_id = cus_ord.order_id
WHERE cancellation IS NULL;

------------
UPDATE rating
SET rating = CASE 
             WHEN order_id IN (2,10) THEN 5
	     WHEN order_id = 3 THEN 2
	     WHEN order_id = 1 THEN 3
	     WHEN order_id IN (7,8) THEN 5
	     WHEN order_id = 4 THEN 1
	     WHEN order_id = 5 THEN 4
	     END;
 
------------------------------------------------------------

 /* Using your newly generated table - can you join all of the information together to form a table which has the following information 
 for successful deliveries?

    customer_id
    order_id
    runner_id
    rating
    order_time
    pickup_time
    Time between order and pickup
    Delivery duration
    Average speed
    Total number of pizzas
*/


CREATE TABLE statistics (customer_id int, 
					      order_id int, 
					     runner_id int, 
                                                rating int, 
				      order_time timestamp, 
				     pickup_time timestamp, 
		time_between_order_and_pickup decimal(5,2),
                            delivery_duration decimal(5,2), 
                                average_speed decimal(5,2), 
			       total_number_of_pizzas int);

----------------------
INSERT INTO statistics (
                                          customer_id, 
					     order_id,
					    runner_id, 
					   order_time, 
                                          pickup_time, 
				    delivery_duration,
					average_speed, 
			       total_number_of_pizzas, 
						rating
)
                                           
                      SELECT DISTINCT rat.customer_id,
                                         rat.order_id, 
					rat.runner_id, 
				   cus_ord.order_time, 
                                  run_ord.pickup_time, 
                                     run_ord.duration,
                ROUND(AVG((distance / duration)), 2) * 60 AS average_speed, 
		         COUNT(cus_ord.pizza_id) AS total_number_of_pizzas, 
                                            rat.rating
                                            
FROM customer_orders cus_ord
JOIN rating rat
ON rat.customer_id = cus_ord.customer_id AND rat.order_id = cus_ord.order_id
JOIN runner_orders run_ord
ON rat.runner_id = run_ord.runner_id AND rat.order_id = run_ord.order_id
WHERE run_ord.cancellation IS NULL
GROUP BY cus_ord.order_id;

------------------------
UPDATE statistics 
SET time_between_order_and_pickup = TIMESTAMPDIFF(minute ,order_time, pickup_time);

------------------------------------------------------------

/* 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
each runner is paid $0.30 per kilometre traveled - 
how much money does Pizza Runner have left over after these deliveries? */

WITH sal AS (

	     SELECT SUM(CASE 
			WHEN piz_nam.pizza_name = 'Meatlovers' THEN 12
                        WHEN piz_nam.pizza_name = 'Vegetarian' THEN 10 
		        END) AS sales, 
			SUM(run_ord.distance) 
	     FROM customer_orders cus_ord
	     JOIN pizza_names piz_nam
	     ON cus_ord.pizza_id = piz_nam.pizza_id
	     JOIN runner_orders run_ord
	     ON run_ord.order_id = cus_ord.order_id 
	     AND run_ord.cancellation IS NULL),
       
    expen AS (
     
             SELECT SUM(run_ord.distance) * 0.30 AS expenses
	     FROM runner_orders run_ord)
       
SELECT ROUND((sales - expenses), 2) AS profit
FROM sal
JOIN expen;
     
     