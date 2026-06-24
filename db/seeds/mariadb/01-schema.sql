-- MySQL: 17 bảng + views + triggers (trạng thái dùng ENUM)
SET FOREIGN_KEY_CHECKS=0;
CREATE TABLE users (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  email varchar(255) NOT NULL UNIQUE,
  full_name varchar(120) NOT NULL,
  status enum('active','pending','blocked') NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE addresses (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id bigint NOT NULL,
  line1 varchar(160) NOT NULL,
  city varchar(80) NOT NULL,
  country varchar(2) NOT NULL,
  is_default tinyint(1) NOT NULL,
  created_at datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE categories (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(120) NOT NULL,
  slug varchar(140) NOT NULL UNIQUE,
  parent_id bigint,
  created_at datetime NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE suppliers (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(120) NOT NULL,
  country varchar(2) NOT NULL,
  rating int NOT NULL,
  created_at datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE warehouses (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code varchar(12) NOT NULL UNIQUE,
  city varchar(80) NOT NULL,
  country varchar(2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE products (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  category_id bigint NOT NULL,
  supplier_id bigint NOT NULL,
  name varchar(200) NOT NULL,
  sku varchar(40) NOT NULL UNIQUE,
  price decimal(12,2) NOT NULL,
  status enum('active','draft','discontinued') NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE product_variants (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id bigint NOT NULL,
  sku varchar(48) NOT NULL UNIQUE,
  color varchar(24) NOT NULL,
  size varchar(8) NOT NULL,
  price decimal(12,2) NOT NULL,
  created_at datetime NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE inventory (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  variant_id bigint NOT NULL,
  warehouse_id bigint NOT NULL,
  quantity int NOT NULL,
  updated_at datetime NOT NULL,
  FOREIGN KEY (variant_id) REFERENCES product_variants(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  UNIQUE (variant_id, warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE carts (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id bigint NOT NULL,
  status enum('open','converted','abandoned') NOT NULL,
  created_at datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE cart_items (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  cart_id bigint NOT NULL,
  variant_id bigint NOT NULL,
  quantity int NOT NULL,
  added_at datetime NOT NULL,
  FOREIGN KEY (cart_id) REFERENCES carts(id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE orders (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id bigint NOT NULL,
  address_id bigint NOT NULL,
  status enum('pending','paid','shipped','delivered','cancelled') NOT NULL,
  total decimal(12,2) NOT NULL,
  payment_method enum('card','paypal','bank','cod') NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (address_id) REFERENCES addresses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE order_items (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id bigint NOT NULL,
  variant_id bigint NOT NULL,
  quantity int NOT NULL,
  unit_price decimal(12,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE payments (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id bigint NOT NULL,
  method enum('card','paypal','bank','cod') NOT NULL,
  status enum('pending','completed','failed','refunded') NOT NULL,
  amount decimal(12,2) NOT NULL,
  paid_at datetime,
  FOREIGN KEY (order_id) REFERENCES orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE shipments (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id bigint NOT NULL,
  warehouse_id bigint NOT NULL,
  carrier varchar(16) NOT NULL,
  tracking varchar(24) NOT NULL,
  status enum('preparing','shipped','in_transit','delivered','returned') NOT NULL,
  shipped_at datetime,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE reviews (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id bigint NOT NULL,
  user_id bigint NOT NULL,
  rating int NOT NULL,
  body varchar(240) NOT NULL,
  created_at datetime NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE events (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id bigint,
  kind varchar(24) NOT NULL,
  payload varchar(200) NOT NULL,
  created_at datetime NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE audit_log (
  id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,
  entity varchar(24) NOT NULL,
  entity_id int NOT NULL,
  action varchar(16) NOT NULL,
  at datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE VIEW v_order_summary AS
  SELECT o.id, u.email, o.status, o.total, o.created_at
  FROM orders o JOIN users u ON u.id = o.user_id;
CREATE VIEW v_product_stock AS
  SELECT p.id, p.name, COALESCE(SUM(i.quantity), 0) AS stock
  FROM products p
  LEFT JOIN product_variants v ON v.product_id = p.id
  LEFT JOIN inventory i ON i.variant_id = v.id
  GROUP BY p.id, p.name;
CREATE VIEW v_user_orders AS
  SELECT u.id, u.email, COUNT(o.id) AS orders, COALESCE(SUM(o.total), 0) AS spent
  FROM users u LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id, u.email;

SET GLOBAL log_bin_trust_function_creators = 1;
DELIMITER $$
CREATE FUNCTION fn_full_name(first_name VARCHAR(120), last_name VARCHAR(120))
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN RETURN TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))); END$$
CREATE FUNCTION fn_apply_discount(price DECIMAL(12,2), pct DECIMAL(5,2))
RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN RETURN ROUND(price * (1 - pct / 100), 2); END$$
CREATE FUNCTION fn_order_total(p_order_id BIGINT)
RETURNS DECIMAL(12,2) READS SQL DATA
BEGIN
  DECLARE total DECIMAL(12,2);
  SELECT COALESCE(SUM(quantity * unit_price), 0) INTO total FROM order_items WHERE order_id = p_order_id;
  RETURN total;
END$$
CREATE FUNCTION fn_user_order_count(p_user_id BIGINT)
RETURNS INT READS SQL DATA
BEGIN
  DECLARE c INT;
  SELECT COUNT(*) INTO c FROM orders WHERE user_id = p_user_id;
  RETURN c;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users FOR EACH ROW BEGIN SET NEW.updated_at = NOW(); END$$
CREATE TRIGGER trg_products_updated BEFORE UPDATE ON products FOR EACH ROW BEGIN SET NEW.updated_at = NOW(); END$$
CREATE TRIGGER trg_orders_updated BEFORE UPDATE ON orders FOR EACH ROW BEGIN SET NEW.updated_at = NOW(); END$$
CREATE TRIGGER trg_orders_audit AFTER INSERT ON orders FOR EACH ROW BEGIN
  INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', NOW());
END$$
DELIMITER ;
SET FOREIGN_KEY_CHECKS=1;
