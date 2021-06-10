
-- Case Study Questions & Solutions --

  
-- 1. What is the total amount each customer spent at the restaurant? --

  SELECT customer_id, sum(price) AS total_amount
  FROM sales sa
  JOIN menu me
  ON me.product_id = sa.product_id
  GROUP BY customer_id;
  
----------------------------------------------


-- 2. How many days has each customer visited the restaurant? --

SELECT customer_id, count(DISTINCT order_date) AS num_days
FROM sales
GROUP BY customer_id;

----------------------------------------------


-- 3. What was the first item from the menu purchased by each customer? --

WITH prod_rank AS (
SELECT *, RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS prod_ranking
FROM sales)
SELECT DISTINCT customer_id, product_name
FROM prod_rank ran
JOIN menu men
ON ran.product_id = men.product_id
WHERE prod_ranking = 1;

----------------------------------------------


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers? --

SELECT product_name AS most_purchased, count(*) AS num_of_sold
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
GROUP BY sa.product_id
ORDER BY num_of_sold DESC
LIMIT 1;

----------------------------------------------


-- 5. Which item was the most popular for each customer? --

WITH items AS
(SELECT sa.customer_id, sa.product_id, me.product_name, count(*) AS num_purchased
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
GROUP BY sa.customer_id, sa.product_id)
, 
popular_items AS
(SELECT * , rank() OVER (PARTITION BY customer_id ORDER By num_purchased DESC) AS most_popular
FROM items)
SELECT customer_id, product_name, num_purchased AS times_purchased
FROM popular_items
WHERE most_popular = 1;

----------------------------------------------


-- 6. Which item was purchased first by the customer after they became a member? --

SELECT sa.customer_id, product_name,  MIN(order_date) AS order_date, join_date
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu men
ON sa.product_id = men.product_id
WHERE sa.order_date >= mem.join_date
GROUP By customer_id
ORDER BY join_date;

----------------------------------------------


-- 7. Which item was purchased just before the customer became a member? --

WITH ord_rank AS (
SELECT sa.customer_id, product_name, order_date, join_date,
RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS ord_rank_des
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu men
ON sa.product_id = men.product_id
WHERE sa.order_date < mem.join_date)
SELECT customer_id, product_name, order_date, join_date 
FROM ord_rank
WHERE ord_rank_des = 1
ORDER BY customer_id;

----------------------------------------------


-- 8. What is the total items and amount spent for each member before they became a member? --

SELECT sa.customer_id, count(sa.product_id) AS total_items, sum(price) AS amount_spent
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu men
ON sa.product_id = men.product_id
WHERE sa.order_date < mem.join_date
GROUP By customer_id;

----------------------------------------------


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? --

SELECT sa.customer_id,
sum(CASE 
WHEN product_name = 'sushi' THEN  price * 10 * 2
ELSE price*10
END) points
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
JOIN members mem
ON sa.customer_id = mem.customer_id
WHERE sa.order_date >= mem.join_date
GROUP BY customer_id
ORDER BY customer_id;

----------------------------------------------


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January? --

SELECT sa.customer_id,
sum(case
WHEN order_date + 7 THEN price * 10 * 2
ELSE price * 10
END) points
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
JOIN members mem
ON sa.customer_id = mem.customer_id
WHERE sa.order_date >= mem.join_date AND order_date < '2021-02-01' 
GROUP BY customer_id
ORDER BY customer_id;

----------------------------------------------


-- Bonus Questions 

-- 1. Join All The Things --

SELECT sa.customer_id, order_date, product_name, price, 
CASE 
WHEN order_date >= join_date THEN 'Y'
ELSE 'N'
END 'member'
FROM sales sa
LEFT JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu me
ON sa.product_id = me.product_id
ORDER BY customer_id, order_date, product_name;

----------------------------------------------


-- 2. Rank All The Things --

CREATE TEMPORARY TABLE temp AS
WITH rank_tab AS (
SELECT sa.customer_id, order_date, product_name, price,
CASE WHEN (order_date >= join_date) THEN 'Y'
ELSE 'N'
END AS membership
FROM sales sa
JOIN menu me
ON me.product_id = sa.product_id
left JOIN members mem
ON mem.customer_id = sa.customer_id)

SELECT *, 
RANK() OVER (PARTITION BY customer_id, membership ORDER BY order_date) AS Rank_
FROM rank_tab;

SELECT customer_id, order_date, product_name, price, membership AS 'member', 
CASE WHEN membership = 'Y' THEN Rank_
ELSE NULL
END AS Ranking
FROM temp
ORDER BY customer_id, order_date, price DESC;

----------------------------------------------------------------

