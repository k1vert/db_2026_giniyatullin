# HW5. Агрегатные функции и группировка данных

## 1. COUNT()

### 1.1. Общее количество заказов на ремонт

```sql
SELECT COUNT(*) AS total_orders
FROM repair_order;
```

Ожидаемый результат: одно число — количество всех зарегистрированных заказов на ремонт.

### 1.2. Количество автомобилей, хотя бы раз поступавших в ремонт

```sql
SELECT COUNT(DISTINCT car_id) AS repaired_cars
FROM repair_order;
```

Ожидаемый результат: количество различных автомобилей, для которых создан хотя бы один заказ, без повторного учёта одного автомобиля.

## 2. SUM()

### 2.1. Общая стоимость всех использованных запчастей

```sql
SELECT COALESCE(SUM(quantity * price_at_purchase), 0) AS total_parts_cost
FROM order_part;
```

Ожидаемый результат: суммарная стоимость всех позиций запчастей с учётом количества и цены на момент покупки. При отсутствии позиций выводится 0.

### 2.2. Стоимость запчастей по каждому заказу

```sql
SELECT
    ro.id AS order_id,
    COALESCE(SUM(op.quantity * op.price_at_purchase), 0) AS parts_cost
FROM repair_order ro
LEFT JOIN order_part op ON op.order_id = ro.id
GROUP BY ro.id
ORDER BY ro.id;
```

Ожидаемый результат: идентификатор каждого заказа и сумма затрат на запчасти в нём, включая заказы без запчастей с суммой 0.

## 3. AVG()

### 3.1. Средний стаж механиков

```sql
SELECT ROUND(AVG(experience_years), 2) AS average_experience
FROM mechanic;
```

Ожидаемый результат: среднее количество лет опыта механиков с округлением до двух знаков после запятой.

### 3.2. Средняя цена запчастей из каталога

```sql
SELECT ROUND(AVG(list_price), 2) AS average_list_price
FROM part_catalog;
```

Ожидаемый результат: средняя базовая стоимость одной позиции каталога запчастей.

## 4. MIN()

### 4.1. Дата самого раннего заказа

```sql
SELECT MIN(created_at) AS first_order_date
FROM repair_order;
```

Ожидаемый результат: дата и время самого раннего зарегистрированного заказа на ремонт.

### 4.2. Минимальная цена запчасти в каталоге

```sql
SELECT MIN(list_price) AS cheapest_part_price
FROM part_catalog;
```

Ожидаемый результат: минимальная базовая цена среди всех запчастей.

## 5. MAX()

### 5.1. Максимальный стаж механика

```sql
SELECT MAX(experience_years) AS maximum_experience
FROM mechanic;
```

Ожидаемый результат: наибольший стаж работы среди механиков автосервиса.

### 5.2. Самая дорогая позиция запчастей в заказах

```sql
SELECT MAX(quantity * price_at_purchase) AS most_expensive_order_item
FROM order_part;
```

Ожидаемый результат: максимальная стоимость одной позиции заказа с учётом количества запчастей.

## 6. STRING_AGG()

### 6.1. Перечень специализаций каждого механика

```sql
SELECT
    m.id AS mechanic_id,
    m.name AS mechanic_name,
    STRING_AGG(s.name, ', ' ORDER BY s.name) AS specializations
FROM mechanic m
LEFT JOIN mechanic_specialization ms ON ms.mechanic_id = m.id
LEFT JOIN specialization s ON s.id = ms.specialization_id
GROUP BY m.id, m.name
ORDER BY m.name, m.id;
```

Ожидаемый результат: каждый механик и его специализации, объединённые через запятую. Для механика без специализаций поле будет NULL.

### 6.2. Список моделей автомобилей по каждой марке

```sql
SELECT
    brand,
    STRING_AGG(DISTINCT model, ', ' ORDER BY model) AS models
FROM car_model
GROUP BY brand
ORDER BY brand;
```

Ожидаемый результат: по одной строке на марку автомобиля с перечислением всех её уникальных моделей.

## 7. GROUP BY

### 7.1. Количество автомобилей каждой марки

```sql
SELECT
    cm.brand,
    COUNT(*) AS cars_count
FROM car c
INNER JOIN car_model cm ON cm.id = c.model_id
GROUP BY cm.brand
ORDER BY cars_count DESC, cm.brand;
```

Ожидаемый результат: количество зарегистрированных автомобилей каждой марки по убыванию.

### 7.2. Количество заказов в каждом статусе

```sql
SELECT
    status,
    COUNT(*) AS orders_count
FROM repair_order
GROUP BY status
ORDER BY orders_count DESC, status;
```

Ожидаемый результат: число заказов для каждого значения статуса ремонта.

## 8. HAVING

### 8.1. Механики, которым назначено более одного заказа

```sql
SELECT
    m.id AS mechanic_id,
    m.name AS mechanic_name,
    COUNT(ro.id) AS orders_count
FROM mechanic m
LEFT JOIN repair_order ro ON ro.mechanic_id = m.id
GROUP BY m.id, m.name
HAVING COUNT(ro.id) > 1
ORDER BY orders_count DESC, m.name;
```

Ожидаемый результат: только механики, которым назначено хотя бы два заказа на ремонт.

### 8.2. Клиенты, потратившие на запчасти более 5000

```sql
SELECT
    cl.id AS client_id,
    cl.name AS client_name,
    SUM(op.quantity * op.price_at_purchase) AS total_spent
FROM client cl
INNER JOIN car c ON c.client_id = cl.id
INNER JOIN repair_order ro ON ro.car_id = c.id
INNER JOIN order_part op ON op.order_id = ro.id
GROUP BY cl.id, cl.name
HAVING SUM(op.quantity * op.price_at_purchase) > 5000
ORDER BY total_spent DESC, cl.name;
```

Ожидаемый результат: клиенты, суммарные расходы которых на запчасти во всех их заказах превышают 5000.

## 9. GROUPING SETS

### 9.1. Количество заказов по механикам, статусам и в целом

```sql
SELECT
    m.id AS mechanic_id,
    m.name AS mechanic_name,
    ro.status,
    COUNT(*) AS orders_count,
    GROUPING(m.id, ro.status) AS grouping_level
FROM repair_order ro
INNER JOIN mechanic m ON m.id = ro.mechanic_id
GROUP BY GROUPING SETS (
    (m.id, m.name, ro.status),
    (m.id, m.name),
    (ro.status),
    ()
)
ORDER BY grouping_level, mechanic_id NULLS LAST, ro.status NULLS LAST;
```

Ожидаемый результат: количество заказов отдельно для каждой пары «механик — статус», итоги по механикам, итоги по статусам и общий итог для заказов с назначенным механиком. `grouping_level` показывает уровень агрегирования.

### 9.2. Количество автомобилей по марке и VIP-статусу владельца

```sql
SELECT
    cm.brand,
    cl.is_vip,
    COUNT(*) AS cars_count,
    GROUPING(cm.brand, cl.is_vip) AS grouping_level
FROM car c
INNER JOIN car_model cm ON cm.id = c.model_id
INNER JOIN client cl ON cl.id = c.client_id
GROUP BY GROUPING SETS (
    (cm.brand, cl.is_vip),
    (cm.brand),
    (cl.is_vip),
    ()
)
ORDER BY grouping_level, cm.brand NULLS LAST, cl.is_vip NULLS LAST;
```

Ожидаемый результат: статистика автомобилей по сочетанию марки и VIP-статуса владельца, а также отдельные итоги по маркам, VIP-статусам и всем автомобилям.

## 10. ROLLUP

### 10.1. Количество автомобилей с итогами по маркам

```sql
SELECT
    cm.brand,
    cm.model,
    COUNT(*) AS cars_count,
    GROUPING(cm.brand, cm.model) AS grouping_level
FROM car c
INNER JOIN car_model cm ON cm.id = c.model_id
GROUP BY ROLLUP(cm.brand, cm.model)
ORDER BY grouping_level, cm.brand NULLS LAST, cm.model NULLS LAST;
```

Ожидаемый результат: число автомобилей каждой модели, промежуточные итоги по маркам и общий итог по автосервису.

### 10.2. Заказы по статусам и месяцам с промежуточными итогами

```sql
SELECT
    status,
    DATE_TRUNC('month', created_at)::date AS order_month,
    COUNT(*) AS orders_count,
    GROUPING(status, DATE_TRUNC('month', created_at)) AS grouping_level
FROM repair_order
GROUP BY ROLLUP(status, DATE_TRUNC('month', created_at))
ORDER BY grouping_level, status NULLS LAST, order_month NULLS LAST;
```

Ожидаемый результат: количество заказов каждого статуса за каждый месяц, итоги по статусам за все месяцы и общее количество заказов.

## 11. CUBE

### 11.1. Количество автомобилей по VIP-статусу и марке

```sql
SELECT
    cl.is_vip,
    cm.brand,
    COUNT(*) AS cars_count,
    GROUPING(cl.is_vip, cm.brand) AS grouping_level
FROM car c
INNER JOIN client cl ON cl.id = c.client_id
INNER JOIN car_model cm ON cm.id = c.model_id
GROUP BY CUBE(cl.is_vip, cm.brand)
ORDER BY grouping_level, cl.is_vip NULLS LAST, cm.brand NULLS LAST;
```

Ожидаемый результат: количество машин для всех комбинаций VIP-статуса и марки, итоги только по статусам, только по маркам и общий итог.

### 11.2. Расходы на запчасти по статусам ремонта и срокам гарантии

```sql
SELECT
    ro.status,
    pc.warranty_months,
    SUM(op.quantity * op.price_at_purchase) AS total_parts_cost,
    GROUPING(ro.status, pc.warranty_months) AS grouping_level
FROM repair_order ro
INNER JOIN order_part op ON op.order_id = ro.id
INNER JOIN part_catalog pc ON pc.id = op.part_id
GROUP BY CUBE(ro.status, pc.warranty_months)
ORDER BY grouping_level, ro.status NULLS LAST, pc.warranty_months NULLS LAST;
```

Ожидаемый результат: стоимость использованных запчастей по комбинациям статуса ремонта и гарантийного срока, промежуточные итоги по каждому признаку и общая сумма.

## 12. SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY

### 12.1. Марки автомобилей с ремонтами за последний год

```sql
SELECT
    cm.brand,
    COUNT(ro.id) AS orders_count
FROM repair_order ro
INNER JOIN car c ON c.id = ro.car_id
INNER JOIN car_model cm ON cm.id = c.model_id
WHERE ro.created_at >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY cm.brand
HAVING COUNT(ro.id) >= 1
ORDER BY orders_count DESC, cm.brand;
```

Ожидаемый результат: марки автомобилей, по которым за последний год был оформлен хотя бы один заказ, с количеством заказов по убыванию.

### 12.2. Механики с дорогостоящими завершёнными ремонтами

```sql
SELECT
    m.id AS mechanic_id,
    m.name AS mechanic_name,
    SUM(op.quantity * op.price_at_purchase) AS total_parts_cost
FROM mechanic m
INNER JOIN repair_order ro ON ro.mechanic_id = m.id
INNER JOIN order_part op ON op.order_id = ro.id
WHERE ro.status = 'Выполнен'
GROUP BY m.id, m.name
HAVING SUM(op.quantity * op.price_at_purchase) > 5000
ORDER BY total_parts_cost DESC, m.name;
```

Ожидаемый результат: механики, у которых суммарная стоимость запчастей в завершённых ремонтах превышает 5000, отсортированные по величине расходов.
