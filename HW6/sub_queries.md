'''sql
SELECT 
    car_model.brand,
    car_model.model,
    (SELECT COUNT(*) FROM repair_order WHERE repair_order.car_id = car.id) AS total_orders
FROM car
JOIN car_model ON car_model.id = car.model_id;
'''

SELECT 
    client.name,
    (SELECT SUM(order_part.price_at_purchase * order_part.quantity) 
     FROM car
     JOIN repair_order ON repair_order.car_id = car.id
     JOIN order_part ON order_part.order_id = repair_order.id
     WHERE car.client_id = client.id) AS total_spent
FROM client;

SELECT AVG(sub.experience_years) AS avg_exp
FROM (
    SELECT mechanic.experience_years, COUNT(repair_order.id) AS order_count
    FROM mechanic
    LEFT JOIN repair_order ON repair_order.mechanic_id = mechanic.id
    GROUP BY mechanic.id, mechanic.experience_years
) sub
WHERE sub.order_count > 0;

SELECT MAX(order_cost) AS max_order_sum
FROM (
    SELECT order_id, SUM(price_at_purchase * quantity) AS order_cost
    FROM order_part
    GROUP BY order_id
) t;

SELECT *
FROM client
WHERE is_vip = TRUE 
  AND id IN (SELECT client_id FROM car);

SELECT *
FROM repair_order
WHERE car_id IN (
    SELECT id 
    FROM car 
    WHERE release_year < 2020
);

SELECT mechanic_id, COUNT(*) AS orders_count
FROM repair_order
GROUP BY mechanic_id
HAVING COUNT(*) > (
    SELECT AVG(cnt) 
    FROM (SELECT COUNT(*) AS cnt FROM repair_order GROUP BY mechanic_id) sub
);

SELECT order_id, SUM(price_at_purchase * quantity) AS order_total
FROM order_part
GROUP BY order_id
HAVING SUM(price_at_purchase * quantity) > (
    SELECT AVG(order_sum) 
    FROM (
        SELECT SUM(price_at_purchase * quantity) AS order_sum 
        FROM order_part 
        GROUP BY order_id
    ) t
);

SELECT *
FROM car
WHERE release_year >= ALL (SELECT release_year FROM car);

SELECT *
FROM mechanic
WHERE experience_years >= ALL (SELECT experience_years FROM mechanic);

SELECT *
FROM order_part
WHERE order_id IN (
    SELECT id 
    FROM repair_order 
    WHERE status = 'Выполнен'
);

SELECT *
FROM client
WHERE id IN (
    SELECT car.client_id 
    FROM car
    JOIN repair_order ON repair_order.car_id = car.id
    WHERE repair_order.mechanic_id = 1
);

SELECT *
FROM car
WHERE release_year >= ANY (
    SELECT release_year 
    FROM car 
    WHERE client_id = 1
);

SELECT *
FROM mechanic
WHERE experience_years = ANY (
    SELECT mechanic.experience_years 
    FROM mechanic
    JOIN mechanic_specialization ON mechanic_specialization.mechanic_id = mechanic.id
    WHERE mechanic_specialization.specialization_id = 1
);

SELECT *
FROM client
WHERE EXISTS (
    SELECT 1 
    FROM client AS sub_client 
    WHERE sub_client.id = client.id AND sub_client.address IS NOT NULL
);

SELECT *
FROM mechanic
WHERE EXISTS (
    SELECT 1 
    FROM repair_order 
    WHERE repair_order.mechanic_id = mechanic.id 
      AND repair_order.status = 'В работе'
);

SELECT *
FROM repair_order
WHERE (car_id, mechanic_id) IN (
    SELECT MIN(car_id), MIN(mechanic_id) 
    FROM repair_order 
    GROUP BY status
);

SELECT *
FROM car_model
WHERE (brand, model) IN (
    SELECT brand, MIN(model) 
    FROM car_model 
    GROUP BY brand
);

SELECT *
FROM car AS car_outer
WHERE release_year > (
    SELECT AVG(car_inner.release_year)
    FROM car AS car_inner
    WHERE car_inner.client_id = car_outer.client_id
);

SELECT *
FROM order_part AS part_outer
WHERE price_at_purchase > (
    SELECT AVG(part_inner.price_at_purchase)
    FROM order_part AS part_inner
    WHERE part_inner.order_id = part_outer.order_id
);

SELECT *
FROM mechanic AS mech_outer
WHERE experience_years > (
    SELECT AVG(mech_inner.experience_years)
    FROM mechanic AS mech_inner
    JOIN mechanic_specialization AS spec_inner ON spec_inner.mechanic_id = mech_inner.id
    WHERE spec_inner.specialization_id IN (
        SELECT spec_outer.specialization_id 
        FROM mechanic_specialization AS spec_outer 
        WHERE spec_outer.mechanic_id = mech_outer.id
    )
);

SELECT *
FROM repair_order AS order_outer
WHERE (
    SELECT SUM(order_part.quantity) 
    FROM order_part 
    WHERE order_part.order_id = order_outer.id
) > (
    SELECT AVG(order_qty)
    FROM (
        SELECT SUM(order_part_sub.quantity) AS order_qty
        FROM repair_order AS order_inner
        JOIN order_part AS order_part_sub ON order_part_sub.order_id = order_inner.id
        WHERE order_inner.mechanic_id = order_outer.mechanic_id
        GROUP BY order_inner.id
    ) sub
);

SELECT *
FROM client AS client_outer
WHERE is_vip = TRUE
  AND (
      SELECT COUNT(*) 
      FROM car 
      WHERE car.client_id = client_outer.id
  ) > (
      SELECT AVG(car_count)
      FROM (
          SELECT COUNT(*) AS car_count
          FROM car AS car_sub
          JOIN client AS client_sub ON client_sub.id = car_sub.client_id
          WHERE client_sub.is_vip = TRUE
          GROUP BY client_sub.id
      ) sub_avg
  );
