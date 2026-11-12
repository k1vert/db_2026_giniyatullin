```sql

INSERT INTO client (name, phone, address, is\_vip) VALUES 

('Иван Иванов', '+79001112233', 'Москва, ул. Тверская, 1', TRUE),

('Анна Смирнова', '+79002223344', 'Санкт-Петербург, Невский пр., 10', TRUE),

('Сергей Петров', '+79003334455', 'Казань, ул. Баумана, 5', FALSE);



INSERT INTO car\_model (brand, model) VALUES 

('Toyota', 'Camry'),

('BMW', 'X5'),

('Ford', 'Focus');



INSERT INTO car (model\_id, release\_year, plate\_number, client\_id) VALUES 

(1, 2020, 'А111АА777', 1),

(2, 2021, 'В222ВВ777', 2),

(3, 2019, 'С333СС777', 3);



INSERT INTO specialization (name) VALUES 

('Моторист'),

('Электрик'),

('Ходовик');



INSERT INTO mechanic (name, experience\_years) VALUES 

('Алексей', 6),

('Дмитрий', 4),

('Михаил', 8);



INSERT INTO mechanic\_specialization (mechanic\_id, specialization\_id) VALUES 

(1, 1),

(2, 2),

(3, 3);



INSERT INTO part\_catalog (part\_name, list\_price, warranty\_months) VALUES 

('Масло моторное', 5000.00, 12),

('Аккумулятор', 12000.00, 24),

('Тормозные колодки', 4000.00, 6);



INSERT INTO repair\_order (car\_id, mechanic\_id, description, status) VALUES 

(1, 1, 'Замена масла', 'Выполнен'),

(2, 2, 'Замена аккумулятора', 'Выполнен'),

(3, 3, 'Замена колодок', 'В работе');



INSERT INTO order\_part (order\_id, part\_id, quantity, price\_at\_purchase) VALUES 

(1, 1, 1, 5000.00),

(2, 2, 1, 12000.00),

(3, 3, 2, 4000.00);



WITH client\_costs AS (

&#x20;   SELECT c.client\_id, SUM(op.price\_at\_purchase \* op.quantity) AS total\_spent

&#x20;   FROM car c

&#x20;   JOIN repair\_order ro ON ro.car\_id = c.id

&#x20;   JOIN order\_part op ON op.order\_id = ro.id

&#x20;   GROUP BY c.client\_id

)

SELECT cl.name, cc.total\_spent

FROM client cl

JOIN client\_costs cc ON cc.client\_id = cl.id;



WITH spec\_stats AS (

&#x20;   SELECT ms.specialization\_id, AVG(m.experience\_years) AS avg\_exp

&#x20;   FROM mechanic m

&#x20;   JOIN mechanic\_specialization ms ON ms.mechanic\_id = m.id

&#x20;   GROUP BY ms.specialization\_id

)

SELECT s.name, ss.avg\_exp

FROM specialization s

JOIN spec\_stats ss ON ss.specialization\_id = s.id;



WITH finished\_orders AS (

&#x20;   SELECT \* FROM repair\_order WHERE status = 'Выполнен'

)

SELECT id, description, created\_at

FROM finished\_orders;



SELECT name FROM client

UNION

SELECT name FROM mechanic;



SELECT phone FROM client

INTERSECT

SELECT phone FROM client WHERE is\_vip = TRUE;



SELECT brand FROM car\_model

EXCEPT

SELECT cm.brand 

FROM car\_model cm

JOIN car c ON c.model\_id = cm.id

WHERE c.release\_year < 2020;



SELECT id, mechanic\_id, status,

&#x20;      COUNT(\*) OVER (PARTITION BY mechanic\_id) AS total\_mechanic\_orders

FROM repair\_order;



SELECT order\_id, part\_id, quantity,

&#x20;      SUM(quantity) OVER (PARTITION BY order\_id) AS total\_parts\_in\_order

FROM order\_part;



SELECT order\_id, part\_id, price\_at\_purchase,

&#x20;      SUM(price\_at\_purchase) OVER (PARTITION BY order\_id ORDER BY id) AS running\_total

FROM order\_part;



SELECT id, client\_id, release\_year,

&#x20;      ROW\_NUMBER() OVER (PARTITION BY client\_id ORDER BY release\_year) as car\_seq

FROM car;



SELECT id, price\_at\_purchase,

&#x20;      AVG(price\_at\_purchase) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS moving\_avg\_rows

FROM part\_catalog;



SELECT id, price\_at\_purchase,

&#x20;      SUM(price\_at\_purchase) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accum\_rows

FROM part\_catalog;



SELECT id, price\_at\_purchase,

&#x20;      SUM(price\_at\_purchase) OVER (ORDER BY price\_at\_purchase RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accum\_range

FROM part\_catalog;



SELECT id, price\_at\_purchase,

&#x20;      SUM(price\_at\_purchase) OVER (ORDER BY price\_at\_purchase RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING) AS range\_window

FROM part\_catalog;



SELECT id, name, experience\_years,

&#x20;      ROW\_NUMBER() OVER (ORDER BY experience\_years DESC) AS rn

FROM mechanic;



SELECT id, name, experience\_years,

&#x20;      RANK() OVER (ORDER BY experience\_years DESC) AS rnk

FROM mechanic;



SELECT id, name, experience\_years,

&#x20;      DENSE\_RANK() OVER (ORDER BY experience\_years DESC) AS dense\_rnk

FROM mechanic;



SELECT id, name, experience\_years,

&#x20;      NTILE(2) OVER (ORDER BY experience\_years DESC) AS nt

FROM mechanic;



SELECT id, price\_at\_purchase,

&#x20;      LAG(price\_at\_purchase, 1, 0.00) OVER (ORDER BY id) as prev\_price

FROM order\_part;



SELECT id, price\_at\_purchase,

&#x20;      LEAD(price\_at\_purchase, 1, 0.00) OVER (ORDER BY id) as next\_price

FROM order\_part;



SELECT id, price\_at\_purchase,

&#x20;      FIRST\_VALUE(price\_at\_purchase) OVER (ORDER BY id) as first\_price

FROM order\_part;



SELECT id, price\_at\_purchase,

&#x20;      LAST\_VALUE(price\_at\_purchase) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last\_price

FROM order\_part;

