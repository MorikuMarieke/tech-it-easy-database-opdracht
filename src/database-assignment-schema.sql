-- JOIN TABLES
DROP TABLE IF EXISTS tv_compatible_ci_modules;
DROP TABLE IF EXISTS tv_compatible_wall_brackets;
-- SUBTYPES
DROP TABLE IF EXISTS televisions;
DROP TABLE IF EXISTS remote_controllers;
DROP TABLE IF EXISTS ci_modules;
DROP TABLE IF EXISTS wall_brackets;
-- BASE PRODUCTS
DROP TABLE IF EXISTS products;
-- USER TABLES
DROP TABLE IF EXISTS users;

CREATE TABLE users
(
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(100) UNIQUE NOT NULL,
    user_password VARCHAR(255)        NOT NULL, -- in realistic scenario I would store this as a secure hash, not plain text.
    address       VARCHAR(255),
    user_role     VARCHAR(20) CHECK (user_role IN ('admin', 'employee')),
    pay_scale     INT                 NOT NULL CHECK (pay_scale >= 0),
    vacation_days INT CHECK (vacation_days >= 0)
);

CREATE TABLE products
(
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(50) UNIQUE,
    brand         VARCHAR(50)      NOT NULL,
    price         DOUBLE PRECISION NOT NULL CHECK (price >= 0),
    current_stock INT CHECK (current_stock >= 0),
    sold          INT DEFAULT 0 CHECK (sold >= 0),
    date_sold     DATE,
    type          VARCHAR(50)      NOT NULL CHECK (type IN ('television', 'remote_controller', 'ci_module', 'wall_bracket'))
);

CREATE TABLE remote_controllers
(
    smart        BOOLEAN,
    battery_type VARCHAR(20),
    product_id   INT PRIMARY KEY,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
);

CREATE TABLE televisions
(
    height        DOUBLE PRECISION NOT NULL,
    width         DOUBLE PRECISION NOT NULL,
    image_quality VARCHAR(50),
    screen_type   VARCHAR(50),
    wifi          BOOLEAN,
    smart_tv      BOOLEAN,
    voice_control BOOLEAN,
    hdr           BOOLEAN,
    product_id    INT PRIMARY KEY,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
    remote_id     INT UNIQUE,
    FOREIGN KEY (remote_id) REFERENCES remote_controllers (product_id)
);

CREATE TABLE ci_modules
(
    provider   VARCHAR(50),
    encoding   VARCHAR(50),
    product_id INT PRIMARY KEY,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
);

CREATE TABLE tv_compatible_ci_modules
(
    television_id INT,
    ci_module_id  INT,
    PRIMARY KEY (television_id, ci_module_id),
    FOREIGN KEY (television_id) REFERENCES televisions (product_id) ON DELETE CASCADE,
    FOREIGN KEY (ci_module_id) REFERENCES ci_modules (product_id) ON DELETE CASCADE
);

CREATE TABLE wall_brackets
(
    adjustable      BOOLEAN,
    mounting_method VARCHAR(50),
    height          DOUBLE PRECISION NOT NULL,
    width           DOUBLE PRECISION NOT NULL,
    product_id      INT PRIMARY KEY,
    FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
);

CREATE TABLE tv_compatible_wall_brackets
(
    television_id   INT,
    wall_bracket_id INT,
    PRIMARY KEY (television_id, wall_bracket_id),
    FOREIGN KEY (television_id) REFERENCES televisions (product_id) ON DELETE CASCADE,
    FOREIGN KEY (wall_bracket_id) REFERENCES wall_brackets (product_id) ON DELETE CASCADE
);

INSERT INTO products (name, brand, price, current_stock, sold, date_sold, type)
VALUES ('UltraVision 4K', 'Samsung', 899.99, 15, 5, '2025-05-01', 'television'),
       ('SlimOLED 55', 'LG', 1299.00, 5, 2, '2025-05-05', 'television'),
       ('SmartDisplay 32', 'Philips', 299.99, 20, 0, NULL, 'television'),
       ('SmartRemote X', 'Samsung', 39.99, 50, 25, '2025-05-10', 'remote_controller'),
       ('Basic Remote A', 'LG', 19.99, 80, 0, NULL, 'remote_controller'),
       ('CI+ Module Ziggo', 'Ziggo', 49.99, 30, 12, '2025-04-29', 'ci_module'),
       ('CI+ Module KPN', 'KPN', 44.95, 25, 0, NULL, 'ci_module'),
       ('WallFlex Tilt', 'Vogel''s', 79.99, 10, 5, '2025-04-30', 'wall_bracket'),
       ('SlimMount Fixed', 'Philips', 29.99, 40, 0, NULL, 'wall_bracket');

INSERT INTO remote_controllers (product_id, smart, battery_type)
VALUES (4, true, 'AAA'),
       (5, false, 'AA');

INSERT INTO televisions (product_id, height, width, image_quality, screen_type, wifi, smart_tv, voice_control, hdr,
                         remote_id)
VALUES (1, 70.0, 110.0, '4K UHD', 'LED', true, true, true, true, 4),
       (2, 65.0, 100.0, '4K OLED', 'OLED', true, true, true, true, 5),
       (3, 40.0, 70.0, 'HD', 'LCD', true, false, false, false, NULL);

INSERT INTO ci_modules (product_id, provider, encoding)
VALUES (6, 'Ziggo', 'MPEG4'),
       (7, 'KPN', 'H.264');

INSERT INTO wall_brackets (product_id, adjustable, mounting_method, height, width)
VALUES (8, true, 'tilt', 20.0, 40.0),
       (9, false, 'fixed', 15.0, 35.0);

INSERT INTO tv_compatible_ci_modules (television_id, ci_module_id)
VALUES (1, 6),
       (1, 7),
       (2, 6);

INSERT INTO tv_compatible_wall_brackets (television_id, wall_bracket_id)
VALUES (1, 8),
       (2, 8),
       (2, 9),
       (3, 9);

-- SELECTION STATEMENTS
SELECT * FROM products;

SELECT p.id     AS tv_id,
       p.name   AS tv_name,
       t.screen_type,
       r.name   AS remote_name,
       rc.smart AS remote_smart
FROM televisions t
         JOIN products p ON t.product_id = p.id
         LEFT JOIN remote_controllers rc ON t.remote_id = rc.product_id
         LEFT JOIN products r ON rc.product_id = r.id
WHERE p.type = 'television';

SELECT p.name AS tv_name,
       m.name AS ci_module_name,
       cm.provider,
       cm.encoding
FROM tv_compatible_ci_modules compat
         JOIN televisions t ON compat.television_id = t.product_id
         JOIN products p ON t.product_id = p.id
         JOIN ci_modules cm ON compat.ci_module_id = cm.product_id
         JOIN products m ON cm.product_id = m.id;

SELECT p.name  AS tv_name,
       wb.name AS bracket_name,
       w.adjustable,
       w.mounting_method
FROM tv_compatible_wall_brackets compat
         JOIN televisions t ON compat.television_id = t.product_id
         JOIN products p ON t.product_id = p.id
         JOIN wall_brackets w ON compat.wall_bracket_id = w.product_id
         JOIN products wb ON w.product_id = wb.id;

SELECT *
FROM products
WHERE current_stock > 0;

SELECT tv_p.id   AS tv_id,
       tv_p.name AS tv_name,
       tv.screen_type,
       tv.width,
       tv.height
FROM tv_compatible_wall_brackets compat
         JOIN televisions tv ON compat.television_id = tv.product_id
         JOIN products tv_p ON tv.product_id = tv_p.id
WHERE compat.wall_bracket_id = 9;