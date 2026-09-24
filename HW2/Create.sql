CREATE TABLE client (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    is_vip BOOLEAN DEFAULT FALSE
);

CREATE TABLE car (
    id SERIAL PRIMARY KEY,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    release_year INT NOT NULL,
    plate_number VARCHAR(15) UNIQUE NOT NULL,
    client_id INT REFERENCES client(id) ON DELETE CASCADE
);

CREATE TABLE mechanic (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(50),
    experience_years INT NOT NULL
);

CREATE TABLE repair_order (
    id SERIAL PRIMARY KEY,
    car_id INT REFERENCES car(id) ON DELETE CASCADE,
    mechanic_id INT REFERENCES mechanic(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    status VARCHAR(30) DEFAULT 'В обработке',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE spare_part (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES repair_order(id) ON DELETE CASCADE,
    part_name VARCHAR(100) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    quantity INT NOT NULL
);