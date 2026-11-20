# HW6. Подзапросы в SQL

---

## 1. Скалярные подзапросы в `SELECT`

### 1.1. Количество заказов по каждому автомобилю

```sql
SELECT
    car_model.brand,
    car_model.model,
    (
        SELECT COUNT(*)
        FROM repair_order
        WHERE repair_order.car_id = car.id
    ) AS total_orders
FROM car
JOIN car_model ON car_model.id = car.model_id;
```

> **Ожидаемый результат:** по одной строке на каждый автомобиль (`brand`, `model`) и количество заказов на ремонт для него (`0`, если ремонтов не было).

### 1.2. Суммарные затраты на запчасти по каждому клиенту

```sql
SELECT
    client.name,
    (
        SELECT SUM(order_part.price_at_purchase * order_part.quantity)
        FROM car
        JOIN repair_order ON repair_order.car_id = car.id
        JOIN order_part ON order_part.order_id = repair_order.id
        WHERE car.client_id = client.id
    ) AS total_spent
FROM client;
```

> **Ожидаемый результат:** список всех клиентов и сумма их расходов на запчасти по всем заказам (`NULL`, если покупок запчастей не было).

---

## 2. Подзапросы в `FROM`

### 2.1. Средний стаж механиков, у которых есть хотя бы один заказ

```sql
SELECT ROUND(AVG(sub.experience_years), 2) AS avg_exp
FROM (
    SELECT
        mechanic.experience_years,
        COUNT(repair_order.id) AS order_count
    FROM mechanic
    LEFT JOIN repair_order ON repair_order.mechanic_id = mechanic.id
    GROUP BY mechanic.id, mechanic.experience_years
) sub
WHERE sub.order_count > 0;
```

> **Ожидаемый результат:** одно число — средний стаж механиков с ненулевым количеством заказов.

### 2.2. Максимальная сумма заказа по запчастям

```sql
SELECT MAX(order_cost) AS max_order_sum
FROM (
    SELECT
        order_id,
        SUM(price_at_purchase * quantity) AS order_cost
    FROM order_part
    GROUP BY order_id
) t;
```

> **Ожидаемый результат:** одно число — наибольшая суммарная стоимость запчастей среди всех заказов.

---

## 3. Фильтрация через `IN`

### 3.1. VIP-клиенты, у которых есть автомобили

```sql
SELECT *
FROM client
WHERE is_vip = TRUE
  AND id IN (
      SELECT client_id
      FROM car
      WHERE client_id IS NOT NULL
  );
```

> **Ожидаемый результат:** клиенты с `is_vip = TRUE`, за которыми числится хотя бы одна запись в `car`.

### 3.2. Заказы на автомобили старше 2020 года

```sql
SELECT *
FROM repair_order
WHERE car_id IN (
    SELECT id
    FROM car
    WHERE release_year < 2020
);
```

> **Ожидаемый результат:** заказы на ремонт автомобилей с `release_year < 2020`.

### 3.3. Позиции запчастей в выполненных заказах

```sql
SELECT *
FROM order_part
WHERE order_id IN (
    SELECT id
    FROM repair_order
    WHERE status = 'Выполнен'
);
```

> **Ожидаемый результат:** строки из `order_part`, относящиеся только к заказам со статусом `'Выполнен'`.

### 3.4. Клиенты, чьи машины обслуживал механик №1

```sql
SELECT *
FROM client
WHERE id IN (
    SELECT car.client_id
    FROM car
    JOIN repair_order ON repair_order.car_id = car.id
    WHERE repair_order.mechanic_id = 1
      AND car.client_id IS NOT NULL
);
```

> **Ожидаемый результат:** клиенты, автомобили которых хотя бы раз назначались механику с `id = 1`.

---

## 4. Подзапросы в `HAVING`

### 4.1. Механики с числом заказов выше среднего

```sql
SELECT
    mechanic_id,
    COUNT(*) AS orders_count
FROM repair_order
WHERE mechanic_id IS NOT NULL
GROUP BY mechanic_id
HAVING COUNT(*) > (
    SELECT AVG(cnt)
    FROM (
        SELECT COUNT(*) AS cnt
        FROM repair_order
        WHERE mechanic_id IS NOT NULL
        GROUP BY mechanic_id
    ) sub
);
```

> **Ожидаемый результат:** механики, у которых заказов больше среднего количества заказов на одного механика.

### 4.2. Заказы с суммой запчастей выше средней по заказам

```sql
SELECT
    order_id,
    SUM(price_at_purchase * quantity) AS order_total
FROM order_part
GROUP BY order_id
HAVING SUM(price_at_purchase * quantity) > (
    SELECT AVG(order_sum)
    FROM (
        SELECT SUM(price_at_purchase * quantity) AS order_sum
        FROM order_part
        GROUP BY order_id
    ) t;
```

> **Ожидаемый результат:** заказы, суммарная стоимость запчастей в которых превышает среднюю стоимость запчастей по заказам.

---

## 5. Операторы `ALL` и `ANY`

### 5.1. Самые свежие автомобили по году выпуска

```sql
SELECT *
FROM car
WHERE release_year >= ALL (
    SELECT release_year
    FROM car
    WHERE release_year IS NOT NULL
);
```

> **Ожидаемый результат:** автомобиль (или несколько при равенстве лет) с максимальным `release_year` в таблице `car`.

### 5.2. Механики с максимальным стажем

```sql
SELECT *
FROM mechanic
WHERE experience_years >= ALL (
    SELECT experience_years
    FROM mechanic
    WHERE experience_years IS NOT NULL
);
```

> **Ожидаемый результат:** механик с наибольшим значением `experience_years`.

### 5.3. Автомобили не старше хотя бы одного авто клиента №1

```sql
SELECT *
FROM car
WHERE release_year >= ANY (
    SELECT release_year
    FROM car
    WHERE client_id = 1
      AND release_year IS NOT NULL
);
```

> **Ожидаемый результат:** машины с годом выпуска не меньше минимального года среди автомобилей клиента `id = 1`.

### 5.4. Механики со стажем, совпадающим со стажем спеца по специализации №1

```sql
SELECT *
FROM mechanic
WHERE experience_years = ANY (
    SELECT mechanic.experience_years
    FROM mechanic
    JOIN mechanic_specialization ON mechanic_specialization.mechanic_id = mechanic.id
    WHERE mechanic_specialization.specialization_id = 1
);
```

> **Ожидаемый результат:** механики, чей `experience_years` совпадает хотя бы с одним механиком, имеющим специализацию `id = 1`.

---

## 6. Проверка существования через `EXISTS`

### 6.1. Клиенты с указанным адресом

```sql
SELECT *
FROM client
WHERE EXISTS (
    SELECT 1
    FROM client AS sub_client
    WHERE sub_client.id = client.id
      AND sub_client.address IS NOT NULL
);
```

> **Ожидаемый результат:** клиенты, у которых поле `address` заполнено (`NOT NULL`).

### 6.2. Механики с активными заказами «В работе»

```sql
SELECT *
FROM mechanic
WHERE EXISTS (
    SELECT 1
    FROM repair_order
    WHERE repair_order.mechanic_id = mechanic.id
      AND repair_order.status = 'В работе'
);
```

> **Ожидаемый результат:** механики, у которых есть хотя бы один заказ в статусе `'В работе'`.

---

## 7. Сравнение кортежей (`IN` по нескольким столбцам)

### 7.1. Заказы с парой `(car_id, mechanic_id)`, равной минимальным значениям по статусу

```sql
SELECT *
FROM repair_order
WHERE (car_id, mechanic_id) IN (
    SELECT
        MIN(car_id),
        MIN(mechanic_id)
    FROM repair_order
    GROUP BY status
);
```

> **Ожидаемый результат:** заказы, чья пара `(car_id, mechanic_id)` совпадает с вычисленной для какого-либо статуса парой `(MIN(car_id), MIN(mechanic_id))`.

### 7.2. Первая по алфавиту модель для каждой марки

```sql
SELECT *
FROM car_model
WHERE (brand, model) IN (
    SELECT
        brand,
        MIN(model)
    FROM car_model
    GROUP BY brand
);
```

> **Ожидаемый результат:** по одной строке на марку с минимальным по алфавиту названием модели (`MIN(model)`).

---

## 8. Коррелированные подзапросы со сравнением по контексту

### 8.1. Автомобили новее среднего года выпуска машин того же клиента

```sql
SELECT *
FROM car AS car_outer
WHERE release_year > (
    SELECT AVG(car_inner.release_year)
    FROM car AS car_inner
    WHERE car_inner.client_id = car_outer.client_id
);
```

> **Ожидаемый результат:** машины клиента, у которых `release_year` выше среднего по всем машинам этого же клиента.

### 8.2. Позиции запчастей дороже средней цены в том же заказе

```sql
SELECT *
FROM order_part AS part_outer
WHERE price_at_purchase > (
    SELECT AVG(part_inner.price_at_purchase)
    FROM order_part AS part_inner
    WHERE part_inner.order_id = part_outer.order_id
);
```

> **Ожидаемый результат:** строки из `order_part`, у которых `price_at_purchase` превышает среднюю цену запчастей в пределах того же `order_id`.

### 8.3. Механики со стажем выше среднего по своим специализациям

```sql
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
```

> **Ожидаемый результат:** механики, чей стаж больше среднего стажа механиков, пересекающихся с ними по специализациям.

### 8.4. Заказы с количеством запчастей выше среднего по заказам этого же механика

```sql
SELECT *
FROM repair_order AS order_outer
WHERE order_outer.mechanic_id IS NOT NULL
  AND (
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
```

> **Ожидаемый результат:** заказы с назначенным механиком, где суммарное число запчастей превышает среднее число запчастей по заказам того же механика.

### 8.5. VIP-клиенты с числом машин выше среднего среди VIP-клиентов

```sql
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
```

> **Ожидаемый результат:** клиенты с `is_vip = TRUE`, у которых количество автомобилей больше среднего числа автомобилей у VIP-клиентов.