HW6. Подзапросы (Subqueries)

1. Скалярные подзапросы в SELECT

1.1. Количество заказов по каждому автомобилю

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


Ожидаемый результат: выводятся все автомобили с маркой и моделью, а также точное количество зарегистрированных для каждого авто заказов на ремонт (0, если заказов не было).

1.2. Суммарные затраты на запчасти по каждому клиенту

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


Ожидаемый результат: список всех клиентов автосервиса и общая сумма затрат на установленные запчасти по всем их заказам (NULL при отсутствии позиций).

2. Подзапросы в предложении FROM

2.1. Средний стаж механиков, имеющих хотя бы один заказ

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


Ожидаемый результат: единственное число — средний опыт работы (в годах) среди мастеров, на которых назначен хотя бы один ремонт.

2.2. Максимальная стоимость заказа по запчастям

SELECT MAX(order_cost) AS max_order_sum
FROM (
    SELECT
        order_id,
        SUM(price_at_purchase * quantity) AS order_cost
    FROM order_part
    GROUP BY order_id
) t;


Ожидаемый результат: наибольшая сумма стоимости запчастей среди всех когда-либо оформленных заказов.

3. Фильтрация через предикат IN

3.1. VIP-клиенты, владеющие автомобилями

SELECT *
FROM client
WHERE is_vip = TRUE
  AND id IN (
      SELECT client_id
      FROM car
      WHERE client_id IS NOT NULL
  );


Ожидаемый результат: список клиентов со статусом VIP (is_vip = TRUE), за которыми в системе зарегистрирован хотя бы один автомобиль.

3.2. Заказы на автомобили старше 2020 года выпуска

SELECT *
FROM repair_order
WHERE car_id IN (
    SELECT id
    FROM car
    WHERE release_year < 2020
);


Ожидаемый результат: все заказы на ремонт, открытые для машин с годом выпуска до 2020 года.

3.3. Использованные запчасти в выполненных заказах

SELECT *
FROM order_part
WHERE order_id IN (
    SELECT id
    FROM repair_order
    WHERE status = 'Выполнен'
);


Ожидаемый результат: записи из таблицы позиций заказов (order_part), относящиеся строго к завершённым ремонтным работам.

3.4. Клиенты, обслуживавшиеся у механика №1

SELECT *
FROM client
WHERE id IN (
    SELECT car.client_id
    FROM car
    JOIN repair_order ON repair_order.car_id = car.id
    WHERE repair_order.mechanic_id = 1
      AND car.client_id IS NOT NULL
);


Ожидаемый результат: клиенты, автомобили которых хотя бы один раз ремонтировал механик с идентификатором 1.

4. Подзапросы в секции HAVING

4.1. Механики с количеством заказов выше среднего

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


Ожидаемый результат: перечень идентификаторов механиков с количеством заказов, превышающим среднее количество заказов на одного назначенного сотрудника.

4.2. Заказы с затратами на запчасти выше среднего чека

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
    ) t
);


Ожидаемый результат: идентификаторы заказов и их суммы затрат на запчасти, которые превышают среднюю стоимость запчастей по всем заказам.

5. Предикаты ALL и ANY

5.1. Самые новые автомобили в автосервисе (ALL)

SELECT *
FROM car
WHERE release_year >= ALL (
    SELECT release_year
    FROM car
    WHERE release_year IS NOT NULL
);


Ожидаемый результат: один или несколько автомобилей, имеющих максимальный год выпуска среди всех зарегистрированных машин.

5.2. Механики с рекордным стажем (ALL)

SELECT *
FROM mechanic
WHERE experience_years >= ALL (
    SELECT experience_years
    FROM mechanic
    WHERE experience_years IS NOT NULL
);


Ожидаемый результат: механик (или несколько мастеров), чей стаж равен абсолютному максимуму по компании.

5.3. Автомобили не старше хотя бы одного авто клиента №1 (ANY)

SELECT *
FROM car
WHERE release_year >= ANY (
    SELECT release_year
    FROM car
    WHERE client_id = 1
      AND release_year IS NOT NULL
);


Ожидаемый результат: автомобили, чей год выпуска не меньше минимального года выпуска среди автомобилей клиента с id = 1.

5.4. Механики со стажем, равным стажу любого специалиста категории №1 (ANY)

SELECT *
FROM mechanic
WHERE experience_years = ANY (
    SELECT mechanic.experience_years
    FROM mechanic
    JOIN mechanic_specialization ON mechanic_specialization.mechanic_id = mechanic.id
    WHERE mechanic_specialization.specialization_id = 1
);


Ожидаемый результат: механики, стаж работы которых совпадает со стажем хотя бы одного механика, закреплённого за специализацией с id = 1.

6. Проверка существования через EXISTS

6.1. Клиенты с указанным адресом проживания

SELECT *
FROM client
WHERE EXISTS (
    SELECT 1
    FROM client AS sub_client
    WHERE sub_client.id = client.id
      AND sub_client.address IS NOT NULL
);


Ожидаемый результат: профили клиентов, у которых поле адреса заполнено строковым значением (address IS NOT NULL).

6.2. Механики с активными заказами в работе

SELECT *
FROM mechanic
WHERE EXISTS (
    SELECT 1
    FROM repair_order
    WHERE repair_order.mechanic_id = mechanic.id
      AND repair_order.status = 'В работе'
);


Ожидаемый результат: сотрудники сервиса, у которых на текущий момент есть хотя бы один незавершённый ремонт в статусе «В работе».

7. Сравнение составных значений (Кортежи в IN)

7.1. Заказы, совпадающие с минимальными связками по статусам

SELECT *
FROM repair_order
WHERE (car_id, mechanic_id) IN (
    SELECT
        MIN(car_id),
        MIN(mechanic_id)
    FROM repair_order
    GROUP BY status
);


Ожидаемый результат: заказы, в которых комбинация (car_id, mechanic_id) в точности совпала с парой минимальных идентификаторов автомобиля и механика, рассчитанных в рамках любого статуса.

7.2. Первая по алфавиту модель для каждого бренда

SELECT *
FROM car_model
WHERE (brand, model) IN (
    SELECT
        brand,
        MIN(model)
    FROM car_model
    GROUP BY brand
);


Ожидаемый результат: по одной записи на каждую марку автомобиля, соответствующей первой по алфавиту модели внутри бренда.

8. Коррелированные подзапросы со сравнением по контексту

8.1. Машины новее среднего возраста автопарка своего владельца

SELECT *
FROM car AS car_outer
WHERE release_year > (
    SELECT AVG(car_inner.release_year)
    FROM car AS car_inner
    WHERE car_inner.client_id = car_outer.client_id
);


Ожидаемый результат: автомобили конкретных владельцев, чей год выпуска новее среднего арифметического года выпуска всех машин данного клиента.

8.2. Позиции запчастей дороже средней цены деталей в своём заказе

SELECT *
FROM order_part AS part_outer
WHERE price_at_purchase > (
    SELECT AVG(part_inner.price_at_purchase)
    FROM order_part AS part_inner
    WHERE part_inner.order_id = part_outer.order_id
);


Ожидаемый результат: строки из таблицы заказанных запчастей, стоимость покупки которых выше средней цены детали в рамках этого конкретного заказа.

8.3. Механики со стажем выше среднего среди коллег своего профиля

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


Ожидаемый результат: сотрудники, имеющие опыт больше среднего показателя среди всех мастеров, обладающих теми же специализациями.

8.4. Заказы с числом запчастей выше среднего для данного механика

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


Ожидаемый результат: наряды на ремонт с назначенным мастером, в которых общее число использованных запчастей выше среднего объёма запчастей во всех заказах этого механика.

8.5. VIP-клиенты с количеством машин выше среднего среди VIP-сегмента

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


Ожидаемый результат: клиенты со статусом VIP, у которых в гараже зарегистрировано строго больше автомобилей, чем в среднем у клиентов из группы VIP.
