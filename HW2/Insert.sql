INSERT INTO client (name, phone, is_vip) VALUES 
('Петр Алексеев', '+79991112233', FALSE),
('Тимерлан Бадуртдинов', '+79992223344', TRUE),
('Михаил Овечкин', '+79993334455', FALSE);

INSERT INTO car (brand, model, release_year, plate_number, client_id) VALUES 
('Toyota', 'Camry', 2020, 'А123АА777', 1),
('BMW', 'X5', 2021, 'В234ВВ777', 2),
('KIA', 'Rio', 2019, 'С345СС777', 3);

INSERT INTO mechanic (name, specialization, experience_years) VALUES 
('Алексей', 'Моторист', 5),
('Дмитрий', 'Электрик', 3),
('Владимир', 'Ходовая', 8);

INSERT INTO repair_order (car_id, mechanic_id, description, status) VALUES 
(1, 1, 'Замена масла в двигателе', 'В обработке'),
(2, 2, 'Диагностика проводки', 'В работе'),
(3, 3, 'Ремонт передней подвески', 'Выполнен');

INSERT INTO spare_part (order_id, part_name, price, quantity) VALUES 
(1, 'Масло моторное', 4500.00, 1),
(1, 'Фильтр масляный', 800.00, 1),
(3, 'Амортизатор передний', 6000.00, 2);