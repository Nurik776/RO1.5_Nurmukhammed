CREATE SCHEMA IF NOT EXISTS restaurant_service;
SET search_path TO restaurant_service;

CREATE TABLE IF NOT EXISTS roles (
    role_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    salary DECIMAL(10, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit VARCHAR(10) NOT NULL
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    role_id INT NOT NULL REFERENCES roles(role_id)
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS tables (
    table_id SERIAL PRIMARY KEY,
    table_number INT UNIQUE NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    status VARCHAR(20) DEFAULT 'Free' CHECK (status IN ('Free', 'Reserved', 'Occupied'))
);

CREATE TABLE IF NOT EXISTS menu (
    item_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL CHECK (base_price >= 0),
    tax_rate DECIMAL(5, 2) DEFAULT 0.12,
    total_price DECIMAL(10, 2) GENERATED ALWAYS AS (base_price * (1 + tax_rate)) STORED,
    category_id INT NOT NULL REFERENCES categories(category_id)
);

CREATE TABLE IF NOT EXISTS recipes (
    recipe_id SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES menu(item_id),
    product_id INT NOT NULL REFERENCES products(product_id),
    amount_needed DECIMAL(10, 3) NOT NULL CHECK (amount_needed > 0)
);

CREATE TABLE IF NOT EXISTS bookings (
    booking_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    table_id INT NOT NULL REFERENCES tables(table_id),
    booking_date TIMESTAMP NOT NULL CHECK (booking_date > '2026-01-01 00:00:00'),
    guests_count INT NOT NULL CHECK (guests_count > 0)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL REFERENCES tables(table_id),
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    order_status VARCHAR(20) NOT NULL CHECK (order_status IN ('New', 'In Progress', 'Done', 'Cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_details (
    detail_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    item_id INT NOT NULL REFERENCES menu(item_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    price_at_sale DECIMAL(10, 2) NOT NULL,
    row_total DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * price_at_sale) STORED
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT UNIQUE NOT NULL REFERENCES orders(order_id),
    sum_total DECIMAL(10, 2) NOT NULL CHECK (sum_total >= 0),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('Cash', 'Card', 'Online')),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name, salary) VALUES ('Администратор', 60000), ('Официант', 30000) ON CONFLICT DO NOTHING;
INSERT INTO categories (name) VALUES ('Горячее'), ('Напитки') ON CONFLICT DO NOTHING;
INSERT INTO products (name, quantity, unit) VALUES ('Мясо', 50, 'кг'), ('Кофе', 10, 'кг') ON CONFLICT DO NOTHING;
INSERT INTO employees (first_name, last_name, phone, role_id) VALUES ('Дмитрий', 'Волков', '89005554433', 1) ON CONFLICT DO NOTHING;
INSERT INTO customers (full_name, email) VALUES ('Игорь Николаев', 'igor@mail.ru') ON CONFLICT DO NOTHING;
INSERT INTO tables (table_number, capacity, status) VALUES (1, 4, 'Free'), (2, 2, 'Reserved') ON CONFLICT DO NOTHING;
INSERT INTO menu (title, base_price, category_id) VALUES ('Стейк', 1200, 1), ('Эспрессо', 150, 2) ON CONFLICT DO NOTHING;
INSERT INTO recipes (item_id, product_id, amount_needed) VALUES (1, 1, 0.400) ON CONFLICT DO NOTHING;
INSERT INTO bookings (customer_id, table_id, booking_date, guests_count) VALUES (1, 2, '2026-05-10 19:00:00', 2) ON CONFLICT DO NOTHING;
INSERT INTO orders (table_id, employee_id, order_status) VALUES (1, 1, 'In Progress') ON CONFLICT DO NOTHING;
INSERT INTO order_details (order_id, item_id, quantity, price_at_sale) VALUES (1, 1, 1, 1200), (1, 2, 2, 150) ON CONFLICT DO NOTHING;
INSERT INTO payments (order_id, sum_total, payment_method) VALUES (1, 1500, 'Card') ON CONFLICT DO NOTHING;