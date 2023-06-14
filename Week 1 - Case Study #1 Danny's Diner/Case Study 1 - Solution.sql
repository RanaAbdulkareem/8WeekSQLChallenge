
-- Case Study Questions & Solutions --

  
-- 1. What is the total amount each customer spent at the restaurant? --

  SELECT customer_id, sum(price) AS total_amount
  FROM sales sa
  JOIN menu me
  ON me.product_id = sa.product_id
  GROUP BY customer_id;
  
----------------------------------------------


-- 2. How many days has each customer visited the restaurant? --

SELECT customer_id, count(DISTINCT order_date) AS days
FROM sales
GROUP BY customer_id;

----------------------------------------------


-- 3. What was the first item from the menu purchased by each customer? --

WITH product_rank AS (
SELECT customer_id, 
       product_id,
       RANK() OVER (PARTITION BY customer_id 
                    ORDER BY order_date) AS ranking
FROM sales)
  
SELECT DISTINCT customer_id, product_name
FROM product_rank ran
JOIN menu men
ON ran.product_id = men.product_id
WHERE ranking = 1;

----------------------------------------------


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers? --

SELECT product_name AS best_seller, 
       count(*) AS sold
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
GROUP BY product_name
ORDER BY sold DESC
LIMIT 1;

----------------------------------------------


-- 5. Which item was the most popular for each customer? --

WITH items AS (
SELECT sa.customer_id, 
       sa.product_id, 
       me.product_name, 
       count(*) AS purchased
FROM sales sa
JOIN menu me
ON sa.product_id = me.product_id
GROUP BY sa.customer_id, 
         sa.product_id)
, 
bestseller_items AS (
SELECT * , 
rank() OVER (PARTITION BY customer_id 
             ORDER By purchased DESC) AS ranking
FROM items)
  
SELECT customer_id, 
       product_name,
       purchased AS times_purchased
FROM bestseller_items
WHERE ranking = 1;

----------------------------------------------


-- 6. Which item was purchased first by the customer after they became a member? --

SELECT sa.customer_id, 
       product_name,  
       MIN(order_date) AS order_date, 
       join_date
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu men
ON sa.product_id = men.product_id
WHERE sa.order_date >= mem.join_date
GROUP By customer_id
ORDER BY join_date;


-- Another method:

WITH orders_after_join AS (
SELECT mem.customer_id,
       sal.product_id,
       rank() OVER (PARTITION BY customer_id 
                    ORDER BY order_date) AS ranking
FROM sales sal
JOIN members mem
ON mem.customer_id = sal.customer_id
WHERE sal.order_date > mem.join_date
)

SELECT customer_id,
	   product_name
FROM orders_after_join ord 
JOIN menu men
ON men.product_id = ord.product_id
WHERE ranking = 1
ORDER BY customer_id;


----------------------------------------------


-- 7. Which item was purchased just before the customer became a member? --

WITH orders_before_join  AS (
SELECT sa.customer_id, 
       product_name, 
       order_date, 
       join_date,
       RANK() OVER (PARTITION BY customer_id 
                    ORDER BY order_date DESC) AS ranking
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu men
ON sa.product_id = men.product_id
WHERE sa.order_date < mem.join_date)
  
SELECT customer_id, 
       product_name 
FROM orders_before_join
WHERE ranking = 1
ORDER BY customer_id;

----------------------------------------------


-- 8. What is the total items and amount spent for each member before they became a member? --

SELECT sa.customer_id, 
       count(sa.product_id) AS total_items, 
       sum(price) AS amount_spent
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu men
ON sa.product_id = men.product_id
WHERE sa.order_date < mem.join_date
GROUP By customer_id;
ORDER BY customer_id;
----------------------------------------------


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? --

SELECT sa.customer_id,
       sum(CASE 
           WHEN product_name = 'sushi' 
           THEN  price * 10 * 2
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

WITH dates AS (
SELECT customer_id,
	     join_date + 6 AS first_week
FROM members)
  
SELECT sal.customer_id,
       sum(case
		       WHEN order_date BETWEEN join_date AND first_week  
           THEN price * 10 * 2
           WHEN product_name = "sushi" 
           THEN price * 10 * 2
           ELSE price * 10
           END) points
FROM dates dat
JOIN sales sal
ON dat.customer_id = sal.customer_id
JOIN menu men
ON sal.product_id = men.product_id
JOIN members mem
ON sal.customer_id = mem.customer_id
WHERE order_date < "2021-02-01"
GROUP BY customer_id
ORDER BY customer_id;

----------------------------------------------


-- Bonus Questions 

-- 1. Join All The Things --

SELECT sa.customer_id, 
       order_date, 
       product_name, 
       price, 
       CASE 
       WHEN order_date >= join_date 
       THEN 'Y'
       ELSE 'N'
       END 'member'
FROM sales sa
LEFT JOIN members mem
ON sa.customer_id = mem.customer_id
JOIN menu me
ON sa.product_id = me.product_id
ORDER BY customer_id, 
         order_date, 
         product_name;

----------------------------------------------


-- 2. Rank All The Things --

WITH rank_tab AS (
SELECT sal.customer_id, 
	     order_date, 
       product_name, 
       price,
       CASE 
       WHEN (order_date >= join_date) 
       THEN 'Y'
       ELSE 'N'
       END AS membership
FROM sales sal
JOIN menu men
ON men.product_id = sal.product_id
left JOIN members mem
ON mem.customer_id = sal.customer_id)

SELECT *,
       CASE
       WHEN membership = "N" 
       THEN null
       ELSE
       RANK() OVER (PARTITION BY customer_id, membership
                    ORDER BY order_date) 
		   END AS ranking
FROM rank_tab;

----------------------------------------------------------------

