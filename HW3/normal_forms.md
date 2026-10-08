  В изначальной схеме таблицы выглядели вполне нормальными, но при детальном анализе я нашел в них проблемы с нормальными формами.

  Сначала я разобрал таблицу spare_part. В ней название детали и ее цена хранить прямо в заказе было ошибкой. Это создавало сразу три аномалии: я не мог добавить новую деталь на
склад без создания заказа, при удалении заказа пропадала сама деталь из истории, а при изменении цены пришлось бы обновлять её во всех прошлых заказах. Чтобы исправить это, я
вынес каталог запчастей в отдельную таблицу part_catalog с базовой ценой и гарантией, а в таблице позиций заказа order_part оставил только ссылку на деталь, количество и цену 
на момент покупки. Это полностью решило проблемы и привело структуру к НФБК.

  Далее я раздал с таблицей car. В ней марки и модели хранились вместе, хотя марка однозначно зависит от модели. Получалась транзитивная зависимость, где ID машины определяет
модель, а модель определяет марку. Это было нарушением 3НФ. Я вынес пары марка и модель в отдельный справочник car_model, а в таблице машин оставил только ссылку на 
модель, тем самым избавившись от дублирования.

  В таблице mechanic поле специализации было одиночной строкой. Если бы механик умел делать и моторы, и электрику, мне пришлось бы либо перечислять их через запятую, 
нарушая атомарность из 1НФ, либо дублировать строки с механиком. Для этого я сделал таблицу specialization и связующую таблицу mechanic_specialization для связи многие ко 
многим. Теперь к механику можно привязать сколько угодно навыков без нарушений.

Ниже привожу итоговый DDL-скрипт моей нормализованной базы данных:

CREATE TABLE client (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
phone VARCHAR(20) UNIQUE NOT NULL,
address TEXT,
is_vip BOOLEAN DEFAULT FALSE
);

CREATE TABLE car_model (
id SERIAL PRIMARY KEY,
brand VARCHAR(50) NOT NULL,
model VARCHAR(50) NOT NULL,
CONSTRAINT unique_brand_model UNIQUE(brand, model)
);

CREATE TABLE car (
id SERIAL PRIMARY KEY,
model_id INT NOT NULL REFERENCES car_model(id),
release_year INT NOT NULL,
plate_number VARCHAR(15) UNIQUE NOT NULL,
client_id INT NOT NULL REFERENCES client(id) ON DELETE CASCADE
);

CREATE TABLE mechanic (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
experience_years INT NOT NULL CHECK (experience_years >= 0)
);

CREATE TABLE specialization (
id SERIAL PRIMARY KEY,
name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE mechanic_specialization (
mechanic_id INT REFERENCES mechanic(id) ON DELETE CASCADE,
specialization_id INT REFERENCES specialization(id) ON DELETE CASCADE,
PRIMARY KEY (mechanic_id, specialization_id)
);

CREATE TABLE repair_order (
id SERIAL PRIMARY KEY,
car_id INT NOT NULL REFERENCES car(id) ON DELETE CASCADE,
mechanic_id INT REFERENCES mechanic(id) ON DELETE SET NULL,
description TEXT NOT NULL,
status VARCHAR(100) DEFAULT 'В обработке',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE part_catalog (
id SERIAL PRIMARY KEY,
part_name VARCHAR(100) NOT NULL,
list_price NUMERIC(10,2) NOT NULL CHECK (list_price >= 0),
warranty_months INT DEFAULT 6
);

CREATE TABLE order_part (
id SERIAL PRIMARY KEY,
order_id INT NOT NULL REFERENCES repair_order(id) ON DELETE CASCADE,
part_id INT NOT NULL REFERENCES part_catalog(id),
quantity INT NOT NULL CHECK (quantity > 0),
price_at_purchase NUMERIC(10,2) NOT NULL
);
