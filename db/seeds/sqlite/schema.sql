-- SQLite: 17 bảng + views + triggers (trạng thái ràng buộc CHECK)
PRAGMA foreign_keys=OFF;
CREATE TABLE users (
  id integer PRIMARY KEY,
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  status text NOT NULL,
  created_at text NOT NULL,
  updated_at text NOT NULL,
  CHECK (status IN ('active', 'pending', 'blocked'))
);
CREATE TABLE addresses (
  id integer PRIMARY KEY,
  user_id integer NOT NULL,
  line1 text NOT NULL,
  city text NOT NULL,
  country text NOT NULL,
  is_default integer NOT NULL,
  created_at text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE categories (
  id integer PRIMARY KEY,
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  parent_id integer,
  created_at text NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories(id)
);
CREATE TABLE suppliers (
  id integer PRIMARY KEY,
  name text NOT NULL,
  country text NOT NULL,
  rating integer NOT NULL,
  created_at text NOT NULL
);
CREATE TABLE warehouses (
  id integer PRIMARY KEY,
  code text NOT NULL UNIQUE,
  city text NOT NULL,
  country text NOT NULL
);
CREATE TABLE products (
  id integer PRIMARY KEY,
  category_id integer NOT NULL,
  supplier_id integer NOT NULL,
  name text NOT NULL,
  sku text NOT NULL UNIQUE,
  price numeric NOT NULL,
  status text NOT NULL,
  created_at text NOT NULL,
  updated_at text NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CHECK (status IN ('active', 'draft', 'discontinued'))
);
CREATE TABLE product_variants (
  id integer PRIMARY KEY,
  product_id integer NOT NULL,
  sku text NOT NULL UNIQUE,
  color text NOT NULL,
  size text NOT NULL,
  price numeric NOT NULL,
  created_at text NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
CREATE TABLE inventory (
  id integer PRIMARY KEY,
  variant_id integer NOT NULL,
  warehouse_id integer NOT NULL,
  quantity integer NOT NULL,
  updated_at text NOT NULL,
  FOREIGN KEY (variant_id) REFERENCES product_variants(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  UNIQUE (variant_id, warehouse_id)
);
CREATE TABLE carts (
  id integer PRIMARY KEY,
  user_id integer NOT NULL,
  status text NOT NULL,
  created_at text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  CHECK (status IN ('open', 'converted', 'abandoned'))
);
CREATE TABLE cart_items (
  id integer PRIMARY KEY,
  cart_id integer NOT NULL,
  variant_id integer NOT NULL,
  quantity integer NOT NULL,
  added_at text NOT NULL,
  FOREIGN KEY (cart_id) REFERENCES carts(id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id)
);
CREATE TABLE orders (
  id integer PRIMARY KEY,
  user_id integer NOT NULL,
  address_id integer NOT NULL,
  status text NOT NULL,
  total numeric NOT NULL,
  payment_method text NOT NULL,
  created_at text NOT NULL,
  updated_at text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (address_id) REFERENCES addresses(id),
  CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled')),
  CHECK (payment_method IN ('card', 'paypal', 'bank', 'cod'))
);
CREATE TABLE order_items (
  id integer PRIMARY KEY,
  order_id integer NOT NULL,
  variant_id integer NOT NULL,
  quantity integer NOT NULL,
  unit_price numeric NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (variant_id) REFERENCES product_variants(id)
);
CREATE TABLE payments (
  id integer PRIMARY KEY,
  order_id integer NOT NULL,
  method text NOT NULL,
  status text NOT NULL,
  amount numeric NOT NULL,
  paid_at text,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  CHECK (method IN ('card', 'paypal', 'bank', 'cod')),
  CHECK (status IN ('pending', 'completed', 'failed', 'refunded'))
);
CREATE TABLE shipments (
  id integer PRIMARY KEY,
  order_id integer NOT NULL,
  warehouse_id integer NOT NULL,
  carrier text NOT NULL,
  tracking text NOT NULL,
  status text NOT NULL,
  shipped_at text,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CHECK (status IN ('preparing', 'shipped', 'in_transit', 'delivered', 'returned'))
);
CREATE TABLE reviews (
  id integer PRIMARY KEY,
  product_id integer NOT NULL,
  user_id integer NOT NULL,
  rating integer NOT NULL,
  body text NOT NULL,
  created_at text NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE events (
  id integer PRIMARY KEY,
  user_id integer,
  kind text NOT NULL,
  payload text NOT NULL,
  created_at text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE TABLE audit_log (
  id integer PRIMARY KEY,
  entity text NOT NULL,
  entity_id integer NOT NULL,
  action text NOT NULL,
  at text NOT NULL
);

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


CREATE TRIGGER trg_users_updated AFTER UPDATE ON users FOR EACH ROW BEGIN
  UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
END;
CREATE TRIGGER trg_products_updated AFTER UPDATE ON products FOR EACH ROW BEGIN
  UPDATE products SET updated_at = datetime('now') WHERE id = NEW.id;
END;
CREATE TRIGGER trg_orders_updated AFTER UPDATE ON orders FOR EACH ROW BEGIN
  UPDATE orders SET updated_at = datetime('now') WHERE id = NEW.id;
END;
CREATE TRIGGER trg_orders_audit AFTER INSERT ON orders FOR EACH ROW BEGIN
  INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', datetime('now'));
END;
PRAGMA foreign_keys=ON;
