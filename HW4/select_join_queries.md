1. SELECT + CASE

1.1. Форматирование статуса клиентов и проверка адресов
```SQL
SELECT 
    name,
    phone,
    CASE 
        WHEN is_vip = TRUE THEN 'VIP Клиент'
        ELSE 'Стандартный клиент'
    END AS client_status,
    CASE 
        WHEN address IS NOT NULL THEN address
        ELSE 'Адрес не указан'
    END AS formatted_address
FROM client;
```
Ожидаемый результат: выводятся все клиенты, где вместо boolean-значений выводятся понятные статусы лояльности, а незаполненные адреса заменяются строкой «Адрес не указан».

1.2. Категоризация квалификации механиков
```SQL
SELECT 
    name,
    experience_years,
    CASE 
        WHEN experience_years >= 8 THEN 'Мастер (Senior)'
        WHEN experience_years BETWEEN 3 AND 7 THEN 'Специалист (Middle)'
        ELSE 'Стажер (Junior)'
    END AS qualification_level
FROM mechanic;
```
Ожидаемый результат: каждый механик получает категорию квалификации на основе стажа работы.
2. INNER JOIN

2.1. Автомобили с моделями и владельцами
```SQL
SELECT 
    c.plate_number,
    cm.brand,
    cm.model,
    cl.name AS owner_name
FROM car c
INNER JOIN car_model cm ON c.model_id = cm.id
INNER JOIN client cl ON c.client_id = cl.id;
```
Ожидаемый результат: список автомобилей с их гос. номерами, маркой, моделью и именем владельца. Автомобили без привязанных владельцев или моделей в выборку не попадут.
2.2. Запчасти в позициях заказов
```SQL
SELECT 
    op.order_id,
    pc.part_name,
    op.quantity,
    op.price_at_purchase
FROM order_part op
INNER JOIN part_catalog pc ON op.part_id = pc.id;
```
Ожидаемый результат: подробный список всех использованных в заказах деталей с фактическим названием из каталога, количеством и сохраненной ценой покупки.
3. LEFT JOIN

3.1. Клиенты и их автомобили
```SQL
SELECT 
    cl.name AS client_name,
    cl.phone,
    c.plate_number
FROM client cl
LEFT JOIN car c ON cl.id = c.client_id;
```
Ожидаемый результат: присутствуют абсолютно все клиенты. Для клиентов, у которых пока нет зарегистрированного автомобиля, в столбце plate_number будет NULL.
3.2. Каталог запчастей и статистика их использования в заказах
```SQL
SELECT 
    pc.part_name,
    pc.list_price,
    op.order_id,
    op.quantity
FROM part_catalog pc
LEFT JOIN order_part op ON pc.id = op.part_id;
```
Ожидаемый результат: выводятся все детали из каталога. Запчасти, которые еще ни разу не заказывались, имеют значение NULL в столбцах order_id и quantity.
4. RIGHT JOIN

4.1. Модели автомобилей и фактические машины в автосервисе
```SQL
SELECT 
    c.plate_number,
    c.release_year,
    cm.brand,
    cm.model
FROM car c
RIGHT JOIN car_model cm ON c.model_id = cm.id;
```
Ожидаемый результат: выводятся все доступные в системе модели автомобилей (правая таблица). Если модель заведена в справочник, но конкретных машин такой модели клиенты не сдавали, данные авто будут содержать NULL.
4.2. Заказы на ремонт и механики
```SQL
SELECT 
    ro.id AS order_id,
    ro.description,
    m.name AS mechanic_name
FROM repair_order ro
RIGHT JOIN mechanic m ON ro.mechanic_id = m.id;
```
Ожидаемый результат: выводятся все механики (правая таблица). Если у механика сейчас нет привязанных заказов, поля order_id и description будут содержать NULL.
5. CROSS JOIN

5.1. Все возможные комбинации механиков и специализаций
```SQL
SELECT 
    m.name AS mechanic_name,
    s.name AS specialization_name
FROM mechanic m
CROSS JOIN specialization s
ORDER BY m.name, s.name;
```
Ожидаемый результат: при N механиках и M специализациях результат содержит N * M строк, показывая полный матричный перебор всех возможных навыков для каждого сотрудника.
5.2. Матрица моделей авто и каталога запчастей
```SQL
SELECT 
    cm.brand,
    cm.model,
    pc.part_name
FROM car_model cm
CROSS JOIN part_catalog pc
ORDER BY cm.brand, pc.part_name;
```
Ожидаемый результат: декартово произведение всех моделей автомобилей и всех доступных на складе деталей.
6. FULL OUTER JOIN

6.1. Полное сопоставление механиков и специализаций
```SQL
SELECT 
    m.id AS mechanic_id,
    m.name AS mechanic_name,
    s.id AS specialization_id,
    s.name AS specialization_name
FROM mechanic m
FULL OUTER JOIN mechanic_specialization ms ON m.id = ms.mechanic_id
FULL OUTER JOIN specialization s ON ms.specialization_id = s.id
ORDER BY m.id NULLS LAST, s.id NULLS LAST;
```
Ожидаемый результат: выводятся абсолютно все механики и все специализации. Механик без специализации имеет NULL в полях специализации; специализация без механика имеет NULL в полях механика.
6.2. Полная картина клиентов и заказов на ремонт
```SQL
SELECT 
    cl.name AS client_name,
    c.plate_number,
    ro.id AS order_id,
    ro.status
FROM client cl
FULL OUTER JOIN car c ON cl.id = c.client_id
FULL OUTER JOIN repair_order ro ON c.id = ro.car_id
ORDER BY cl.name NULLS LAST, ro.id NULLS LAST;
```
Ожидаемый результат: выводятся все клиенты и все заказы. Клиент без заказов содержит NULL в полях заказа; заказ без клиента (например, отвязанный) содержит NULL в полях клиента.