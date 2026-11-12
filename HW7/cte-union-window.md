```sql
WITH client_costs AS (
    SELECT c.client_id, SUM(op.price_at_purchase * op.quantity) AS total_spent
    FROM car c
    JOIN repair_order ro ON ro.car_id = c.id
    JOIN order_part op ON op.order_id = ro.id
    GROUP BY c.client_id
)
SELECT cl.name, cc.total_spent
FROM client cl
JOIN client_costs cc ON cc.client_id = cl.id;

WITH spec_stats AS (
    SELECT ms.specialization_id, AVG(m.experience_years) AS avg_exp
    FROM mechanic m
    JOIN mechanic_specialization ms ON ms.mechanic_id = m.id
    GROUP BY ms.specialization_id
)
SELECT s.name, ss.avg_exp
FROM specialization s
JOIN spec_stats ss ON ss.specialization_id = s.id;

WITH finished_orders AS (
    SELECT * FROM repair_order WHERE status = 'Выполнен'
)
SELECT id, description, created_at
FROM finished_orders;

SELECT name FROM client
UNION
SELECT name FROM mechanic;

SELECT phone FROM client
INTERSECT
SELECT phone FROM client WHERE is_vip = TRUE;

SELECT brand FROM car_model
EXCEPT
SELECT cm.brand 
FROM car_model cm
JOIN car c ON c.model_id = cm.id
WHERE c.release_year < 2020;

SELECT id, mechanic_id, status,
       COUNT(*) OVER (PARTITION BY mechanic_id) AS total_mechanic_orders
FROM repair_order;

SELECT order_id, part_id, quantity,
       SUM(quantity) OVER (PARTITION BY order_id) AS total_parts_in_order
FROM order_part;

SELECT order_id, part_id, price_at_purchase,
       SUM(price_at_purchase) OVER (PARTITION BY order_id ORDER BY id) AS running_total
FROM order_part;

SELECT id, client_id, release_year,
       ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY release_year) as car_seq
FROM car;

SELECT id, price_at_purchase,
       AVG(price_at_purchase) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS moving_avg_rows
FROM part_catalog;

SELECT id, price_at_purchase,
       SUM(price_at_purchase) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accum_rows
FROM part_catalog;

SELECT id, price_at_purchase,
       SUM(price_at_purchase) OVER (ORDER BY price_at_purchase RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accum_range
FROM part_catalog;

SELECT id, price_at_purchase,
       SUM(price_at_purchase) OVER (ORDER BY price_at_purchase RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING) AS range_window
FROM part_catalog;

SELECT id, name, experience_years,
       ROW_NUMBER() OVER (ORDER BY experience_years DESC) AS rn
FROM mechanic;

SELECT id, name, experience_years,
       RANK() OVER (ORDER BY experience_years DESC) AS rnk
FROM mechanic;

SELECT id, name, experience_years,
       DENSE_RANK() OVER (ORDER BY experience_years DESC) AS dense_rnk
FROM mechanic;

SELECT id, name, experience_years,
       NTILE(2) OVER (ORDER BY experience_years DESC) AS nt
FROM mechanic;

SELECT id, price_at_purchase,
       LAG(price_at_purchase, 1, 0.00) OVER (ORDER BY id) as prev_price
FROM order_part;

SELECT id, price_at_purchase,
       LEAD(price_at_purchase, 1, 0.00) OVER (ORDER BY id) as next_price
FROM order_part;

SELECT id, price_at_purchase,
       FIRST_VALUE(price_at_purchase) OVER (ORDER BY id) as first_price
FROM order_part;

SELECT id, price_at_purchase,
       LAST_VALUE(price_at_purchase) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_price
FROM order_part;
```
