```sql

SELECT 

&#x20;   car\_model.brand,

&#x20;   car\_model.model,

&#x20;   (SELECT COUNT(\*) FROM repair\_order WHERE repair\_order.car\_id = car.id) AS total\_orders

FROM car

JOIN car\_model ON car\_model.id = car.model\_id;



SELECT 

&#x20;   client.name,

&#x20;   (SELECT SUM(order\_part.price\_at\_purchase \* order\_part.quantity) 

&#x20;    FROM car

&#x20;    JOIN repair\_order ON repair\_order.car\_id = car.id

&#x20;    JOIN order\_part ON order\_part.order\_id = repair\_order.id

&#x20;    WHERE car.client\_id = client.id) AS total\_spent

FROM client;



SELECT AVG(sub.experience\_years) AS avg\_exp

FROM (

&#x20;   SELECT mechanic.experience\_years, COUNT(repair\_order.id) AS order\_count

&#x20;   FROM mechanic

&#x20;   LEFT JOIN repair\_order ON repair\_order.mechanic\_id = mechanic.id

&#x20;   GROUP BY mechanic.id, mechanic.experience\_years

) sub

WHERE sub.order\_count > 0;



SELECT MAX(order\_cost) AS max\_order\_sum

FROM (

&#x20;   SELECT order\_id, SUM(price\_at\_purchase \* quantity) AS order\_cost

&#x20;   FROM order\_part

&#x20;   GROUP BY order\_id

) t;



SELECT \*

FROM client

WHERE is\_vip = TRUE 

&#x20; AND id IN (SELECT client\_id FROM car);



SELECT \*

FROM repair\_order

WHERE car\_id IN (

&#x20;   SELECT id 

&#x20;   FROM car 

&#x20;   WHERE release\_year < 2020

);



SELECT mechanic\_id, COUNT(\*) AS orders\_count

FROM repair\_order

GROUP BY mechanic\_id

HAVING COUNT(\*) > (

&#x20;   SELECT AVG(cnt) 

&#x20;   FROM (SELECT COUNT(\*) AS cnt FROM repair\_order GROUP BY mechanic\_id) sub

);



SELECT order\_id, SUM(price\_at\_purchase \* quantity) AS order\_total

FROM order\_part

GROUP BY order\_id

HAVING SUM(price\_at\_purchase \* quantity) > (

&#x20;   SELECT AVG(order\_sum) 

&#x20;   FROM (

&#x20;       SELECT SUM(price\_at\_purchase \* quantity) AS order\_sum 

&#x20;       FROM order\_part 

&#x20;       GROUP BY order\_id

&#x20;   ) t

);



SELECT \*

FROM car

WHERE release\_year >= ALL (SELECT release\_year FROM car);



SELECT \*

FROM mechanic

WHERE experience\_years >= ALL (SELECT experience\_years FROM mechanic);



SELECT \*

FROM order\_part

WHERE order\_id IN (

&#x20;   SELECT id 

&#x20;   FROM repair\_order 

&#x20;   WHERE status = 'Выполнен'

);



SELECT \*

FROM client

WHERE id IN (

&#x20;   SELECT car.client\_id 

&#x20;   FROM car

&#x20;   JOIN repair\_order ON repair\_order.car\_id = car.id

&#x20;   WHERE repair\_order.mechanic\_id = 1

);



SELECT \*

FROM car

WHERE release\_year >= ANY (

&#x20;   SELECT release\_year 

&#x20;   FROM car 

&#x20;   WHERE client\_id = 1

);



SELECT \*

FROM mechanic

WHERE experience\_years = ANY (

&#x20;   SELECT mechanic.experience\_years 

&#x20;   FROM mechanic

&#x20;   JOIN mechanic\_specialization ON mechanic\_specialization.mechanic\_id = mechanic.id

&#x20;   WHERE mechanic\_specialization.specialization\_id = 1

);



SELECT \*

FROM client

WHERE EXISTS (

&#x20;   SELECT 1 

&#x20;   FROM client AS sub\_client 

&#x20;   WHERE sub\_client.id = client.id AND sub\_client.address IS NOT NULL

);



SELECT \*

FROM mechanic

WHERE EXISTS (

&#x20;   SELECT 1 

&#x20;   FROM repair\_order 

&#x20;   WHERE repair\_order.mechanic\_id = mechanic.id 

&#x20;     AND repair\_order.status = 'В работе'

);



SELECT \*

FROM repair\_order

WHERE (car\_id, mechanic\_id) IN (

&#x20;   SELECT MIN(car\_id), MIN(mechanic\_id) 

&#x20;   FROM repair\_order 

&#x20;   GROUP BY status

);



SELECT \*

FROM car\_model

WHERE (brand, model) IN (

&#x20;   SELECT brand, MIN(model) 

&#x20;   FROM car\_model 

&#x20;   GROUP BY brand

);



SELECT \*

FROM car AS car\_outer

WHERE release\_year > (

&#x20;   SELECT AVG(car\_inner.release\_year)

&#x20;   FROM car AS car\_inner

&#x20;   WHERE car\_inner.client\_id = car\_outer.client\_id

);



SELECT \*

FROM order\_part AS part\_outer

WHERE price\_at\_purchase > (

&#x20;   SELECT AVG(part\_inner.price\_at\_purchase)

&#x20;   FROM order\_part AS part\_inner

&#x20;   WHERE part\_inner.order\_id = part\_outer.order\_id

);



SELECT \*

FROM mechanic AS mech\_outer

WHERE experience\_years > (

&#x20;   SELECT AVG(mech\_inner.experience\_years)

&#x20;   FROM mechanic AS mech\_inner

&#x20;   JOIN mechanic\_specialization AS spec\_inner ON spec\_inner.mechanic\_id = mech\_inner.id

&#x20;   WHERE spec\_inner.specialization\_id IN (

&#x20;       SELECT spec\_outer.specialization\_id 

&#x20;       FROM mechanic\_specialization AS spec\_outer 

&#x20;       WHERE spec\_outer.mechanic\_id = mech\_outer.id

&#x20;   )

);



SELECT \*

FROM repair\_order AS order\_outer

WHERE (

&#x20;   SELECT SUM(order\_part.quantity) 

&#x20;   FROM order\_part 

&#x20;   WHERE order\_part.order\_id = order\_outer.id

) > (

&#x20;   SELECT AVG(order\_qty)

&#x20;   FROM (

&#x20;       SELECT SUM(order\_part\_sub.quantity) AS order\_qty

&#x20;       FROM repair\_order AS order\_inner

&#x20;       JOIN order\_part AS order\_part\_sub ON order\_part\_sub.order\_id = order\_inner.id

&#x20;       WHERE order\_inner.mechanic\_id = order\_outer.mechanic\_id

&#x20;       GROUP BY order\_inner.id

&#x20;   ) sub

);



SELECT \*

FROM client AS client\_outer

WHERE is\_vip = TRUE

&#x20; AND (

&#x20;     SELECT COUNT(\*) 

&#x20;     FROM car 

&#x20;     WHERE car.client\_id = client\_outer.id

&#x20; ) > (

&#x20;     SELECT AVG(car\_count)

&#x20;     FROM (

&#x20;         SELECT COUNT(\*) AS car\_count

&#x20;         FROM car AS car\_sub

&#x20;         JOIN client AS client\_sub ON client\_sub.id = car\_sub.client\_id

&#x20;         WHERE client\_sub.is\_vip = TRUE

&#x20;         GROUP BY client\_sub.id

&#x20;     ) sub\_avg

&#x20; );



```

