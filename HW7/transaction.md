# HW7. Транзакции и уровни изоляции

## 1. Базовые операции с транзакциями

### 1.1. Вставка в одну таблицу и обновление в другой (`BEGIN ... COMMIT`)

#### Сценарий 1

```sql
BEGIN;

-- создаём новый заказ
INSERT INTO repair_order (car_id, mechanic_id, description, status, created_at)
VALUES (1, 1, 'Замена моторного масла', 'В работе', NOW());

-- увеличиваем стаж назначенному механику
UPDATE mechanic
SET experience_years = experience_years + 1
WHERE id = 1;

COMMIT;

-- проверка результата
SELECT * FROM repair_order ORDER BY id DESC LIMIT 1;
SELECT id, name, experience_years FROM mechanic WHERE id = 1;
```

*Результат:* Заказ создан, стаж механика успешно увеличен на 1.

<img width="496" height="105" alt="img1" src="https://github.com/user-attachments/assets/87af460e-486b-4c8e-8105-35ff30711899" />

#### Сценарий 2

```sql
BEGIN;

-- добавляем запчасть к существующему заказу
INSERT INTO order_part (order_id, part_id, quantity, price_at_purchase)
VALUES (1, 1, 2, 1500.00);

-- переводим сам заказ в статус "В работе"
UPDATE repair_order
SET status = 'В работе'
WHERE id = 1;

COMMIT;

-- проверка результата
SELECT * FROM order_part WHERE order_id = 1;
SELECT id, status FROM repair_order WHERE id = 1;
```

*Результат:* Запчасть привязана к заказу, статус заказа обновлён.


---

### 1.2. Откат изменений (`BEGIN ... ROLLBACK`)

#### Сценарий 1

```sql
BEGIN;

-- вставляем тестовый заказ
INSERT INTO repair_order (car_id, mechanic_id, description, status, created_at)
VALUES (1, 1, 'Тест отката заказа', 'В работе', NOW());

-- обновляем статус существующего заказа
UPDATE repair_order
SET status = 'Отменён'
WHERE id = 1;

-- отменяем транзакцию целиком
ROLLBACK;

-- проверка: созданного заказа нет, старый заказ не изменился
SELECT * FROM repair_order WHERE description = 'Тест отката заказа';
SELECT id, status FROM repair_order WHERE id = 1;
```

*Результат:* Запрос возвращает 0 строк, статус первого заказа остался прежним.


#### Сценарий 2

```sql
BEGIN;

-- тестовое добавление запчасти
INSERT INTO order_part (order_id, part_id, quantity, price_at_purchase)
VALUES (1, 2, 1, 9999.00);

-- тестовое изменение базовой цены в каталоге
UPDATE part_catalog
SET list_price = list_price * 2
WHERE id = 2;

ROLLBACK;

-- проверка: добавленная позиция отсутствует, цена в каталоге не менялась
SELECT * FROM order_part WHERE order_id = 1 AND price_at_purchase = 9999.00;
SELECT id, list_price FROM part_catalog WHERE id = 2;
```

*Результат:* Изменения полностью отменены, состояние таблиц вернулось к исходному.

---

### 1.3. Ошибка внутри транзакции

#### Сценарий 1. Деление на ноль

```sql
BEGIN;

INSERT INTO repair_order (car_id, mechanic_id, description, status, created_at)
VALUES (1, 1, 'Заказ перед ошибкой деления', 'В работе', NOW());

UPDATE part_catalog
SET list_price = list_price + 100
WHERE id = 1;

-- вызываем фатальную ошибку
SELECT 1 / 0;

-- транзакция прервана, коммит завершится откатом
COMMIT;

-- проверка: изменений нет
SELECT * FROM repair_order WHERE description = 'Заказ перед ошибкой деления';
```

*Результат:* Ошибка `ERROR: division by zero`. Все команды до ошибки автоматически откатаны.


#### Сценарий 2. Нарушение внешнего ключа

```sql
BEGIN;

UPDATE repair_order
SET status = 'В работе'
WHERE id = 1;

-- попытка сослаться на несуществующего механика (mechanic_id = 999999)
INSERT INTO repair_order (car_id, mechanic_id, description, status, created_at)
VALUES (1, 999999, 'Невалидный механик', 'Новый', NOW());

COMMIT;

-- проверка: статус первого заказа не изменился
SELECT id, status FROM repair_order WHERE id = 1;
```

*Результат:* Ошибка `ERROR: insert or update on table "repair_order" violates foreign key constraint`. Транзакция прервана.

---

## 2. Уровни изоляции

### 2.1. READ UNCOMMITTED / READ COMMITTED: чтение незафиксированных данных

#### Сценарий 1. Попытка Dirty Read

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE part_catalog SET list_price = 7777.00 WHERE id = 1;

-- Сессия 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- чтение строки, которую меняет незакоммиченная Сессия 1
SELECT list_price FROM part_catalog WHERE id = 1;

-- Сессия 1:
ROLLBACK;

-- Сессия 2:
COMMIT;
```

*Результат:* Сессия 2 видит исходное значение цены. В PostgreSQL `READ UNCOMMITTED` работает как `READ COMMITTED`, грязное чтение исключено.


#### Сценарий 2. Видимость только после фиксации

```sql
-- Сессия 1:
BEGIN;
UPDATE repair_order SET status = 'Диагностика' WHERE id = 1;

-- Сессия 2:
BEGIN;
-- чтение до фиксации Сессии 1 (видим старый статус)
SELECT status FROM repair_order WHERE id = 1;

-- Сессия 1:
COMMIT;

-- Сессия 2:
-- чтение после фиксации Сессии 1 (видим новый статус 'Диагностика')
SELECT status FROM repair_order WHERE id = 1;
COMMIT;
```

*Результат:* Изменения становятся доступны для Сессии 2 строго после `COMMIT` в Сессии 1.

---

### 2.2. READ COMMITTED: неповторяющееся чтение (Non-repeatable Read)

#### Сценарий 1

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- первое чтение цены
SELECT list_price FROM part_catalog WHERE id = 1;

-- Сессия 2:
BEGIN;
UPDATE part_catalog SET list_price = 1250.00 WHERE id = 1;
COMMIT;

-- Сессия 1:
-- повторное чтение в той же транзакции даёт уже новое значение
SELECT list_price FROM part_catalog WHERE id = 1;
COMMIT;
```

*Результат:* В рамках одной транзакции получены разные значения цены строки до и после коммита параллельной сессии.


#### Сценарий 2

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- первое чтение стажа
SELECT experience_years FROM mechanic WHERE id = 1;

-- Сессия 2:
BEGIN;
UPDATE mechanic SET experience_years = experience_years + 1 WHERE id = 1;
COMMIT;

-- Сессия 1:
-- повторный запрос возвращает изменённое количество лет
SELECT experience_years FROM mechanic WHERE id = 1;
COMMIT;
```

*Результат:* Демонстрация неповторяющегося чтения при параллельном `UPDATE`.


---

### 2.3. REPEATABLE READ: снимок данных

#### Сценарий 1. Отсутствие неповторяющегося чтения

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- фиксируем снимок данных
SELECT status FROM repair_order WHERE id = 1;

-- Сессия 2:
BEGIN;
UPDATE repair_order SET status = 'Завершён' WHERE id = 1;
COMMIT;

-- Сессия 1:
-- повторный запрос читает данные из своего снимка (старый статус)
SELECT status FROM repair_order WHERE id = 1;
COMMIT;

-- вне транзакции видим актуальное значение
SELECT status FROM repair_order WHERE id = 1;
```

*Результат:* Внутри Сессии 1 данные не изменились, несмотря на коммит Сессии 2.


#### Сценарий 2. Конкурентное изменение одной строки

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT list_price FROM part_catalog WHERE id = 1;

-- Сессия 2:
BEGIN;
UPDATE part_catalog SET list_price = 2000.00 WHERE id = 1;
COMMIT;

-- Сессия 1:
-- попытка обновить строку, изменённую параллельной транзакцией
UPDATE part_catalog SET list_price = 2500.00 WHERE id = 1;
ROLLBACK;
```

*Результат:* СУБД возвращает `ERROR: could not serialize access due to concurrent update`.


---

### 2.4. REPEATABLE READ: фантомное чтение

#### Сценарий 1

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- считаем число заказов
SELECT COUNT(*) FROM repair_order WHERE status = 'Новый';

-- Сессия 2:
BEGIN;
INSERT INTO repair_order (car_id, mechanic_id, description, status, created_at)
VALUES (1, 1, 'Фантомный заказ 1', 'Новый', NOW());
COMMIT;

-- Сессия 1:
-- повторный подсчёт: результат остаётся прежним
SELECT COUNT(*) FROM repair_order WHERE status = 'Новый';
COMMIT;
```

*Результат:* В PostgreSQL уровень `REPEATABLE READ` предотвращает фантомное чтение через MVCC.

#### Сценарий 2

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM order_part WHERE order_id = 1;

-- Сессия 2:
BEGIN;
INSERT INTO order_part (order_id, part_id, quantity, price_at_purchase)
VALUES (1, 1, 1, 500.00);
COMMIT;

-- Сессия 1:
-- число позиций в заказе не увеличилось
SELECT COUNT(*) FROM order_part WHERE order_id = 1;
COMMIT;
```

*Результат:* Новые вставленные строки не попадают в снимок Сессии 1.

---

### 2.5. SERIALIZABLE: конфликт параллельных транзакций

#### Сценарий 1. Конфликт уникальности

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO specialization (name) VALUES ('Колорист');

-- Сессия 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO specialization (name) VALUES ('Колорист');

-- Сессия 1:
COMMIT;

-- Сессия 2:
-- висит в ожидании, после чего завершается ошибкой уникальности
COMMIT;
```

*Результат:* Сессия 2 блокируется до завершения Сессии 1, затем падает с ошибкой уникального ключа.


#### Сценарий 2. Аномалия сериализации по перекрёстным зависимостям

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT SUM(list_price) FROM part_catalog WHERE warranty_months = 12;
UPDATE part_catalog SET list_price = list_price + 50 WHERE id = 1;

-- Сессия 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT SUM(list_price) FROM part_catalog WHERE warranty_months = 12;
UPDATE part_catalog SET list_price = list_price + 50 WHERE id = 2;

-- Сессия 1:
COMMIT;

-- Сессия 2:
COMMIT;
```

*Результат:* В Сессии 2 возникает `ERROR: could not serialize access due to read/write dependencies among transactions`.

---

### 2.6. SERIALIZABLE: ошибка конкурентного обновления и перезапуск

#### Сценарий 1

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE part_catalog SET list_price = list_price + 10 WHERE id = 1;

-- Сессия 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE part_catalog SET list_price = list_price + 20 WHERE id = 1;

-- Сессия 1:
COMMIT;

-- Сессия 2:
-- выдаёт ERROR: could not serialize access due to concurrent update
ROLLBACK;

-- Перезапуск Сессии 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE part_catalog SET list_price = list_price + 20 WHERE id = 1;
COMMIT;
```

*Результат:* После отката прерванной транзакции и её повторного запуска обновление успешно фиксируется.

#### Сценарий 2

```sql
-- Сессия 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE repair_order SET status = 'В работе' WHERE id = 1;

-- Сессия 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE repair_order SET status = 'Выполнен' WHERE id = 1;

-- Сессия 1:
COMMIT;

-- Сессия 2:
ROLLBACK;

-- Перезапуск Сессии 2:
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE repair_order SET status = 'Выполнен' WHERE id = 1;
COMMIT;
```

*Результат:* Конфликт устранён повторным прогоном транзакции на актуальном состоянии базы.

---

## 3. SAVEPOINT

### 3.1. Откат части транзакции к точке сохранения

```sql
BEGIN;

-- действие до точки сохранения
UPDATE part_catalog
SET list_price = list_price + 50
WHERE id = 1;

SAVEPOINT sp_after_price;

-- ошибочное действие
UPDATE repair_order
SET status = 'Несуществующий статус'
WHERE id = 1;

-- откат ошибочного действия
ROLLBACK TO SAVEPOINT sp_after_price;

-- продолжение транзакции
UPDATE mechanic
SET experience_years = experience_years + 1
WHERE id = 1;

COMMIT;

-- проверка: первое и третье действие сохранились, второе отменено
SELECT list_price FROM part_catalog WHERE id = 1;
SELECT status FROM repair_order WHERE id = 1;
SELECT experience_years FROM mechanic WHERE id = 1;
```

*Результат:* Изменения до `SAVEPOINT` и после `ROLLBACK TO` зафиксированы, промежуточное изменение отменено.

---

### 3.2. Работа с двумя точками сохранения

```sql
BEGIN;

UPDATE part_catalog SET list_price = 1000.00 WHERE id = 1;
SAVEPOINT sp1;

UPDATE part_catalog SET list_price = 2000.00 WHERE id = 1;
SAVEPOINT sp2;

UPDATE part_catalog SET list_price = 3000.00 WHERE id = 1;

-- возврат ко второй точке: цена 2000.00
ROLLBACK TO SAVEPOINT sp2;
SELECT list_price FROM part_catalog WHERE id = 1;

-- возврат к первой точке: цена 1000.00
ROLLBACK TO SAVEPOINT sp1;
SELECT list_price FROM part_catalog WHERE id = 1;

COMMIT;

-- итоговая проверка
SELECT list_price FROM part_catalog WHERE id = 1;
```

*Результат:* Последовательный откат к `sp2`, затем к `sp1` привёл к фиксации значения `1000.00`.

---

## 4. Выводы

1. **Базовые операции:** Операторы внутри блока `BEGIN ... COMMIT` выполняются атомарно. В случае возникновения ошибок (`division by zero`, нарушение `FOREIGN KEY` / `NOT NULL`) или вызова `ROLLBACK` база автоматически отменяет все внесённые в рамках транзакции изменения.
2. **Точки сохранения (`SAVEPOINT`):** Позволяют откатывать только часть операций внутри транзакции без сброса всей сессии. Откат к более ранней точке (`sp1`) аннулирует все точки, созданные после неё.
3. **Уровни изоляции в PostgreSQL:**
   * `READ UNCOMMITTED` в реализации PostgreSQL эквивалентен `READ COMMITTED`: грязное чтение физически невозможно благодаря механизму MVCC.
   * `READ COMMITTED`: защищает от грязного чтения, но допускает неповторяющееся чтение, так как каждый отдельный запрос строит новый снимок данных.
   * `REPEATABLE READ`: снимок создаётся один раз на старте первого запроса транзакции, что исключает как неповторяющееся, так и фантомное чтение. При попытке параллельного изменения одних и тех же данных выбрасывается ошибка `could not serialize access due to concurrent update`.
   * `SERIALIZABLE`: строгая изоляция, моделирующая последовательное выполнение. При возникновении зависимостей чтения/записи транзакция прерывается и требует повторного выполнения на уровне клиента.
