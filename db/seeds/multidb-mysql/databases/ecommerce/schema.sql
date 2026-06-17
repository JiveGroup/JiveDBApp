-- jdb_ecommerce — E-commerce domain (15 tables, area-prefixed: catalog_/orders_/marketing_).
-- MySQL has no schemas-within-a-database, so the 3 areas are kept as table prefixes.
SET FOREIGN_KEY_CHECKS = 0;

-- ── catalog ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS catalog_categories (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  slug       VARCHAR(140) NOT NULL UNIQUE,
  parent_id  BIGINT NULL,
  is_active  TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES catalog_categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS catalog_brands (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  country    VARCHAR(40),
  website    VARCHAR(200),
  rating     DECIMAL(3,2),
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS catalog_suppliers (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(120) NOT NULL,
  country        VARCHAR(40),
  contact_email  VARCHAR(255),
  lead_time_days INT UNSIGNED,
  status         ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
  created_at     DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS catalog_products (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT NOT NULL,
  brand_id    BIGINT NULL,
  supplier_id BIGINT NULL,
  name        VARCHAR(200) NOT NULL,
  sku         VARCHAR(40) NOT NULL UNIQUE,
  description TEXT,
  price       DECIMAL(12,2) NOT NULL,
  cost        DECIMAL(12,2) NOT NULL,
  status      ENUM('active','draft','discontinued','archived') NOT NULL DEFAULT 'active',
  created_at  DATETIME NOT NULL,
  updated_at  DATETIME NOT NULL,
  FOREIGN KEY (category_id) REFERENCES catalog_categories(id),
  FOREIGN KEY (brand_id)    REFERENCES catalog_brands(id),
  FOREIGN KEY (supplier_id) REFERENCES catalog_suppliers(id),
  KEY idx_products_category (category_id),
  KEY idx_products_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS catalog_product_variants (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id   BIGINT NOT NULL,
  sku          VARCHAR(48) NOT NULL UNIQUE,
  variant_name VARCHAR(120) NOT NULL,
  color        VARCHAR(30),
  size         VARCHAR(20),
  price        DECIMAL(12,2) NOT NULL,
  stock_qty    INT UNSIGNED NOT NULL DEFAULT 0,
  weight_g     INT UNSIGNED,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (product_id) REFERENCES catalog_products(id),
  KEY idx_variants_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── orders ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders_customers (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  first_name   VARCHAR(60) NOT NULL,
  last_name    VARCHAR(60) NOT NULL,
  email        VARCHAR(255) NOT NULL UNIQUE,
  phone        VARCHAR(30),
  country      VARCHAR(40),
  city         VARCHAR(60),
  loyalty_tier ENUM('bronze','silver','gold','platinum') NOT NULL DEFAULT 'bronze',
  created_at   DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orders_orders (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  customer_id  BIGINT NOT NULL,
  order_number VARCHAR(30) NOT NULL UNIQUE,
  status       ENUM('pending','paid','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  subtotal     DECIMAL(14,2) NOT NULL,
  discount     DECIMAL(12,2) NOT NULL DEFAULT 0,
  shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  total        DECIMAL(14,2) NOT NULL,
  placed_at    DATETIME NOT NULL,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES orders_customers(id),
  KEY idx_orders_customer (customer_id),
  KEY idx_orders_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orders_items (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id     BIGINT NOT NULL,
  variant_sku  VARCHAR(48) NOT NULL,
  product_name VARCHAR(200) NOT NULL,
  quantity     INT UNSIGNED NOT NULL,
  unit_price   DECIMAL(12,2) NOT NULL,
  line_total   DECIMAL(14,2) NOT NULL,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders_orders(id),
  KEY idx_items_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orders_payments (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id   BIGINT NOT NULL,
  method     ENUM('card','paypal','bank_transfer','cod','wallet') NOT NULL,
  amount     DECIMAL(14,2) NOT NULL,
  status     ENUM('pending','authorized','captured','failed','refunded') NOT NULL DEFAULT 'pending',
  paid_at    DATETIME NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders_orders(id),
  KEY idx_payments_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS orders_shipments (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id     BIGINT NOT NULL,
  carrier      VARCHAR(40) NOT NULL,
  tracking_no  VARCHAR(40) NOT NULL UNIQUE,
  status       ENUM('label_created','in_transit','out_for_delivery','delivered','returned') NOT NULL DEFAULT 'label_created',
  shipped_at   DATETIME NULL,
  delivered_at DATETIME NULL,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders_orders(id),
  KEY idx_shipments_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── marketing ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS marketing_campaigns (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(150) NOT NULL,
  channel    ENUM('email','social','search','display','affiliate','influencer') NOT NULL,
  budget     DECIMAL(12,2),
  start_date DATE NOT NULL,
  end_date   DATE NULL,
  status     ENUM('planned','active','paused','completed') NOT NULL DEFAULT 'planned',
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS marketing_coupons (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code          VARCHAR(30) NOT NULL UNIQUE,
  discount_type ENUM('percent','fixed') NOT NULL,
  discount_val  DECIMAL(10,2) NOT NULL,
  max_uses      INT UNSIGNED,
  used_count    INT UNSIGNED NOT NULL DEFAULT 0,
  expires_at    DATE NULL,
  created_at    DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS marketing_reviews (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id  BIGINT NOT NULL,
  customer_id BIGINT NOT NULL,
  rating      TINYINT NOT NULL,
  title       VARCHAR(150),
  body        TEXT,
  is_verified TINYINT(1) NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (product_id)  REFERENCES catalog_products(id),
  FOREIGN KEY (customer_id) REFERENCES orders_customers(id),
  KEY idx_reviews_product (product_id),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS marketing_wishlists (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  variant_sku VARCHAR(48) NOT NULL,
  added_at    DATETIME NOT NULL,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES orders_customers(id),
  KEY idx_wishlists_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS marketing_ad_spend (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  campaign_id BIGINT NOT NULL,
  spend_date  DATE NOT NULL,
  impressions INT UNSIGNED NOT NULL DEFAULT 0,
  clicks      INT UNSIGNED NOT NULL DEFAULT 0,
  conversions INT UNSIGNED NOT NULL DEFAULT 0,
  cost        DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(id),
  KEY idx_adspend_campaign (campaign_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
