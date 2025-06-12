
SELECT product_name
     , COUNT(product_name) as repeated
  FROM orders.orders
 GROUP BY product_name
HAVING COUNT(product_name) > 1
 ORDER BY 2,1;