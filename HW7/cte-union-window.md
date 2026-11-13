CTE и Подзапросы (Common Table Expressions)

1.1. Что хотим получить
Суммарные расходы каждого клиента на запчасти и ремонт

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
```

1.2. Что хотим получить
Средний стаж механиков по каждой специализации

```sql
WITH spec_stats AS (
    SELECT ms.specialization_id, AVG(m.experience_years) AS avg_exp
    FROM mechanic m
    JOIN mechanic_specialization ms ON ms.mechanic_id = m.id
    GROUP BY ms.specialization_id
)
SELECT s.name, ss.avg_exp
FROM specialization s
JOIN spec_stats ss ON ss.specialization_id = s.id;
```

1.3. Что хотим получить
Список всех выполненных заказов на ремонт

```sql
WITH finished_orders AS (
    SELECT * FROM repair_order WHERE status = 'Выполнен'
)
SELECT id, description, created_at
FROM finished_orders;
```

Операторы надмножеств (UNION, INTERSECT, EXCEPT)

2.1. Что хотим получить
Уникальный список всех имен клиентов и механиков

```sql
SELECT name FROM client
UNION
SELECT name FROM mechanic;
```

2.2. Что хотим получить
Номера телефонов клиентов, являющихся VIP

```sql
SELECT phone FROM client
INTERSECT
SELECT phone FROM client WHERE is_vip = TRUE;
```

2.3. Что хотим получить
Бренды автомобилей, у которых нет машин старше 2020 года

```sql
SELECT brand FROM car_model
EXCEPT
SELECT cm.brand 
FROM car_model cm
JOIN car c ON c.model_id = cm.id
WHERE c.release_year < 2020;
```

Базовые оконные функции

3.1. Что хотим получить
Количество заказов механика в разрезе каждого заказа

```sql
SELECT id, mechanic_id, status,
       COUNT(*) OVER (PARTITION BY mechanic_id) AS total_mechanic_orders
FROM repair_order;
```

3.2. Что хотим получить
Суммарное количество деталей в каждом заказе

```sql
SELECT order_id, part_id, quantity,
       SUM(quantity) OVER (PARTITION BY order_id) AS total_parts_in_order
FROM order_part;
```

3.3. Что хотим получить
Нарастающий итог стоимости деталей по порядку ID в заказе

```sql
SELECT order_id, part_id, price_at_purchase,
       SUM(price_at_purchase) OVER (PARTITION BY order_id ORDER BY id) AS running_total
FROM order_part;
```

3.4. Что хотим получить
Порядковый номер автомобиля для каждого клиента по году выпуска


```sql
SELECT id, client_id, release_year,
       ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY release_year) as car_seq
FROM car;
```

Фреймы окон (ROWS и RANGE)

4.1. Что хотим получить
Скользящее среднее цены детали по текущей и предыдущей строке

```sql
SELECT id, price_at_purchase,
       AVG(price_at_purchase) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS moving_avg_rows
FROM part_catalog;
```

4.2. Что хотим получить
Накопительная сумма цен от начала таблицы до текущей строки

```sql
SELECT id, price_at_purchase,
       SUM(price_at_purchase) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accum_rows
FROM part_catalog;
```

4.3. Что хотим получить
Накопительная сумма цен по логическому диапазону значений (RANGE)

```sql
SELECT id, price_at_purchase,
       SUM(price_at_purchase) OVER (ORDER BY price_at_purchase RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS accum_range
FROM part_catalog;
```

4.4. Что хотим получить
Сумма цен товаров в диапазоне цены +/- 1000 от текущей

```sql
SELECT id, price_at_purchase,
       SUM(price_at_purchase) OVER (ORDER BY price_at_purchase RANGE BETWEEN 1000 PRECEDING AND 1000 FOLLOWING) AS range_window
FROM part_catalog;
```

Функции ранжирования

5.1. Что хотим получить
Сквозная нумерация механиков по убыванию стажа (ROW_NUMBER)

```sql
SELECT id, name, experience_years,
       ROW_NUMBER() OVER (ORDER BY experience_years DESC) AS rn
FROM mechanic;
```

5.2. Что хотим получить
Ранг механиков по стажу с пропусками номеров (RANK)

```sql
SELECT id, name, experience_years,
       RANK() OVER (ORDER BY experience_years DESC) AS rnk
FROM mechanic;
```

5.3. Что хотим получить
Плотный ранг механиков по стажу без пропусков (DENSE_RANK)

```sql
SELECT id, name, experience_years,
       DENSE_RANK() OVER (ORDER BY experience_years DESC) AS dense_rnk
FROM mechanic;
```

5.4. Что хотим получить
Разбиение механиков на 2 равные группы по стажу (NTILE)

```sql
SELECT id, name, experience_years,
       NTILE(2) OVER (ORDER BY experience_years DESC) AS nt
FROM mechanic;
```

Функции смещения (LAG, LEAD, FIRST_VALUE, LAST_VALUE)

6.1. Что хотим получить
Цена предыдущей детали по порядку ID (LAG)
```sql
SELECT id, price_at_purchase,
       LAG(price_at_purchase, 1, 0.00) OVER (ORDER BY id) as prev_price
FROM order_part;
```

```sql
6.2. Что хотим получить
Цена следующей детали по порядку ID (LEAD)

SELECT id, price_at_purchase,
       LEAD(price_at_purchase, 1, 0.00) OVER (ORDER BY id) as next_price
FROM order_part;
```

6.3. Что хотим получить
Первая цена детали в наборе данных (FIRST_VALUE)
```sql
SELECT id, price_at_purchase,
       FIRST_VALUE(price_at_purchase) OVER (ORDER BY id) as first_price
FROM order_part;
```

```sql
6.4. Что хотим получить
Последняя цена детали в наборе данных с полным фреймом (LAST_VALUE)

SELECT id, price_at_purchase,
       LAST_VALUE(price_at_purchase) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_price
FROM order_part;
```
