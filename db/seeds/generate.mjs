#!/usr/bin/env node
// Sinh dữ liệu mẫu (schema + data) cho PostgreSQL, MySQL, SQLite và Redis.
// Dữ liệu tổng hợp, tất định (RNG có seed) — chạy lại cho kết quả giống nhau.
//   node db/seeds/generate.mjs
//
// Bộ dữ liệu gồm 17 bảng có quan hệ + views + triggers + object types (PG),
// tổng ~40k–50k dòng; Redis ~1000 key đa dạng.
import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = dirname(fileURLToPath(import.meta.url))

// ── RNG tất định (mulberry32) ─────────────────────────────────────────────────────
let _s = 0x9e3779b9
function rnd() {
  _s |= 0
  _s = (_s + 0x6d2b79f5) | 0
  let t = Math.imul(_s ^ (_s >>> 15), 1 | _s)
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}
const int = (a, b) => a + Math.floor(rnd() * (b - a + 1))
const pick = (arr) => arr[Math.floor(rnd() * arr.length)]
const chance = (p) => rnd() < p
const pad = (n, w = 5) => String(n).padStart(w, '0')
const money = (a, b) => Number((a + rnd() * (b - a)).toFixed(2))

// ── Quy mô (điều chỉnh tại đây) ───────────────────────────────────────────────────
const N = {
  users: 1500,
  addresses: 2000,
  categories: 30,
  suppliers: 60,
  warehouses: 6,
  products: 1000,
  variants: 2500,
  carts: 1200,
  orders: 4000,
  reviews: 2500,
  events: 8000,
}

// ── Pools tổng hợp ─────────────────────────────────────────────────────────────────
const FIRST = ['Ava', 'Liam', 'Noah', 'Mia', 'Zoe', 'Leo', 'Ivy', 'Eli', 'Nora', 'Kai', 'Luna', 'Max', 'Ada', 'Finn', 'Ela', 'Theo', 'Remy', 'Cleo', 'Jude', 'Sky', 'Ren', 'Mai', 'Bao', 'Linh', 'Quan']
const LAST = ['Tran', 'Nguyen', 'Le', 'Pham', 'Stone', 'Reed', 'Fox', 'Hale', 'Vu', 'Do', 'Bui', 'Cole', 'Lane', 'Ray', 'Wells', 'Park', 'Kim', 'Shaw', 'Ford', 'Hunt']
const CITY = ['Hanoi', 'Saigon', 'Da Nang', 'Hue', 'Can Tho', 'Berlin', 'Lyon', 'Osaka', 'Austin', 'Porto', 'Leeds', 'Turin', 'Ghent', 'Cebu', 'Pune']
const COUNTRY = ['VN', 'DE', 'FR', 'JP', 'US', 'PT', 'GB', 'IT', 'BE', 'PH']
const ADJ = ['Compact', 'Wireless', 'Matte', 'Rugged', 'Slim', 'Ultra', 'Eco', 'Smart', 'Pro', 'Mini', 'Vivid', 'Quiet', 'Rapid', 'Solar', 'Nordic']
const NOUN = ['Keyboard', 'Mouse', 'Hub', 'Cable', 'Lamp', 'Stand', 'Mat', 'Charger', 'Webcam', 'Speaker', 'Bottle', 'Backpack', 'Monitor', 'Dock', 'Pen']
const CATNAME = ['Electronics', 'Peripherals', 'Audio', 'Cables', 'Lighting', 'Office', 'Accessories', 'Storage', 'Networking', 'Wearables', 'Power', 'Mobile', 'Gaming', 'Home', 'Outdoor', 'Cameras', 'Tablets', 'Drones', 'Smart Home', 'Tools', 'Kitchen', 'Travel', 'Fitness', 'Books', 'Garden', 'Pets', 'Beauty', 'Auto', 'Sports', 'Toys']
const COLOR = ['Black', 'White', 'Silver', 'Blue', 'Red', 'Green', 'Graphite', 'Sand']
const SIZE = ['XS', 'S', 'M', 'L', 'XL']
const CARRIER = ['UPS', 'FedEx', 'DHL', 'GHN', 'VNPost']
const SUPNAME = ['Globex', 'Initech', 'Umbrella', 'Hooli', 'Acme', 'Stark', 'Wayne', 'Soylent', 'Vandelay', 'Pied Piper', 'Cyberdyne', 'Tyrell', 'Wonka', 'Gekko', 'Massive Dynamic']
const WORDS = ['great value', 'works as described', 'fast shipping', 'would buy again', 'solid build', 'a bit pricey', 'exceeded expectations', 'minor issues', 'highly recommended', 'does the job', 'packaging was nice', 'arrived early', 'color slightly off', 'battery lasts long']
const EVENT_KIND = ['login', 'logout', 'view_product', 'add_to_cart', 'checkout', 'search', 'review', 'page_view']

// Enum (object types)
const ENUMS = {
  user_status: ['active', 'active', 'active', 'pending', 'blocked'],
  order_status: ['pending', 'paid', 'shipped', 'delivered', 'cancelled'],
  payment_method: ['card', 'paypal', 'bank', 'cod'],
  payment_status: ['pending', 'completed', 'failed', 'refunded'],
  cart_status: ['open', 'open', 'converted', 'abandoned'],
  shipment_status: ['preparing', 'shipped', 'in_transit', 'delivered', 'returned'],
  product_status: ['active', 'active', 'draft', 'discontinued'],
}
const uniq = (arr) => arr.filter((v, i, a) => a.indexOf(v) === i)

// ── Functions / Procedures (PostgreSQL) — 10 hàm đa dạng + 1 procedure ─────────────
const PG_FUNCTIONS = `-- Functions (đa dạng kiểu)
-- 1. Scalar SQL, IMMUTABLE
CREATE OR REPLACE FUNCTION fn_full_name(first_name text, last_name text)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT trim(coalesce(first_name, '') || ' ' || coalesce(last_name, ''));
$$;

-- 2. Tham số mặc định
CREATE OR REPLACE FUNCTION fn_apply_discount(price numeric, pct numeric DEFAULT 10)
RETURNS numeric LANGUAGE sql IMMUTABLE AS $$
  SELECT round(price * (1 - pct / 100.0), 2);
$$;

-- 3. Tham số VARIADIC
CREATE OR REPLACE FUNCTION fn_concat_tags(VARIADIC tags text[])
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT array_to_string(tags, ', ');
$$;

-- 4. plpgsql, đọc dữ liệu (STABLE)
CREATE OR REPLACE FUNCTION fn_order_total(p_order_id bigint)
RETURNS numeric LANGUAGE plpgsql STABLE AS $$
DECLARE total numeric;
BEGIN
  SELECT COALESCE(SUM(quantity * unit_price), 0) INTO total FROM order_items WHERE order_id = p_order_id;
  RETURN total;
END; $$;

-- 5. Scalar SQL đọc bảng
CREATE OR REPLACE FUNCTION fn_user_order_count(p_user_id bigint)
RETURNS integer LANGUAGE sql STABLE AS $$
  SELECT count(*)::int FROM orders WHERE user_id = p_user_id;
$$;

-- 6. RETURNS TABLE + tham số mặc định
CREATE OR REPLACE FUNCTION fn_recent_orders(p_days integer DEFAULT 30)
RETURNS TABLE(id bigint, user_id bigint, total numeric, created_at timestamptz)
LANGUAGE sql STABLE AS $$
  SELECT id, user_id, total, created_at FROM orders
  WHERE created_at >= now() - make_interval(days => p_days)
  ORDER BY created_at DESC;
$$;

-- 7. RETURNS SETOF
CREATE OR REPLACE FUNCTION fn_user_emails()
RETURNS SETOF text LANGUAGE sql STABLE AS $$
  SELECT email FROM users ORDER BY id;
$$;

-- 8. Trả về JSON
CREATE OR REPLACE FUNCTION fn_order_summary_json(p_order_id bigint)
RETURNS json LANGUAGE sql STABLE AS $$
  SELECT json_build_object(
    'id', o.id, 'status', o.status, 'total', o.total,
    'items', (SELECT count(*) FROM order_items oi WHERE oi.order_id = o.id)
  ) FROM orders o WHERE o.id = p_order_id;
$$;

-- 9. Tham số kiểu ENUM + CASE (plpgsql)
CREATE OR REPLACE FUNCTION fn_label_order_status(s order_status)
RETURNS text LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  RETURN CASE s
    WHEN 'pending' THEN 'Cho xu ly'
    WHEN 'paid' THEN 'Da thanh toan'
    WHEN 'shipped' THEN 'Dang giao'
    WHEN 'delivered' THEN 'Hoan tat'
    WHEN 'cancelled' THEN 'Da huy'
    ELSE 'Khac'
  END;
END; $$;

-- 10. Trigger function (RETURNS trigger)
CREATE OR REPLACE FUNCTION fn_set_row_timestamp()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END; $$;

-- Bonus: PROCEDURE (không trả về)
CREATE OR REPLACE PROCEDURE sp_touch_order(p_order_id bigint)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE orders SET updated_at = now() WHERE id = p_order_id;
END; $$;
`

// ── Functions (MySQL) — vài hàm tiêu biểu (cần cờ trust để tạo khi bật binlog) ──────
const MY_FUNCTIONS = `SET GLOBAL log_bin_trust_function_creators = 1;
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
DELIMITER ;`

// ── Thời gian ──────────────────────────────────────────────────────────────────────
const NOW = Date.UTC(2025, 11, 31, 12, 0, 0)
const DAY = 86400000
const tsAgo = (maxDays) => new Date(NOW - int(0, maxDays) * DAY - int(0, DAY - 1))
const tsBetween = (d0, maxDaysAfter) => new Date(d0.getTime() + int(0, maxDaysAfter) * DAY + int(0, DAY - 1))
function fmtTs(d) {
  const p = (n) => String(n).padStart(2, '0')
  return `${d.getUTCFullYear()}-${p(d.getUTCMonth() + 1)}-${p(d.getUTCDate())} ${p(d.getUTCHours())}:${p(d.getUTCMinutes())}:${p(d.getUTCSeconds())}`
}

// ── Đặc tả bảng (dùng chung cho 3 dialect) ────────────────────────────────────────
// type: pk | int | fk | text:N | money | bool | ts | enum:NAME | email
const TABLES = [
  { name: 'users', cols: [
    { name: 'id', type: 'pk' },
    { name: 'email', type: 'email', unique: true },
    { name: 'full_name', type: 'text:120' },
    { name: 'status', type: 'enum:user_status' },
    { name: 'created_at', type: 'ts' },
    { name: 'updated_at', type: 'ts' },
  ] },
  { name: 'addresses', cols: [
    { name: 'id', type: 'pk' },
    { name: 'user_id', type: 'fk', ref: 'users(id)' },
    { name: 'line1', type: 'text:160' },
    { name: 'city', type: 'text:80' },
    { name: 'country', type: 'text:2' },
    { name: 'is_default', type: 'bool' },
    { name: 'created_at', type: 'ts' },
  ] },
  { name: 'categories', cols: [
    { name: 'id', type: 'pk' },
    { name: 'name', type: 'text:120' },
    { name: 'slug', type: 'text:140', unique: true },
    { name: 'parent_id', type: 'fk', ref: 'categories(id)', null: true },
    { name: 'created_at', type: 'ts' },
  ] },
  { name: 'suppliers', cols: [
    { name: 'id', type: 'pk' },
    { name: 'name', type: 'text:120' },
    { name: 'country', type: 'text:2' },
    { name: 'rating', type: 'int' },
    { name: 'created_at', type: 'ts' },
  ] },
  { name: 'warehouses', cols: [
    { name: 'id', type: 'pk' },
    { name: 'code', type: 'text:12', unique: true },
    { name: 'city', type: 'text:80' },
    { name: 'country', type: 'text:2' },
  ] },
  { name: 'products', cols: [
    { name: 'id', type: 'pk' },
    { name: 'category_id', type: 'fk', ref: 'categories(id)' },
    { name: 'supplier_id', type: 'fk', ref: 'suppliers(id)' },
    { name: 'name', type: 'text:200' },
    { name: 'sku', type: 'text:40', unique: true },
    { name: 'price', type: 'money' },
    { name: 'status', type: 'enum:product_status' },
    { name: 'created_at', type: 'ts' },
    { name: 'updated_at', type: 'ts' },
  ] },
  { name: 'product_variants', cols: [
    { name: 'id', type: 'pk' },
    { name: 'product_id', type: 'fk', ref: 'products(id)' },
    { name: 'sku', type: 'text:48', unique: true },
    { name: 'color', type: 'text:24' },
    { name: 'size', type: 'text:8' },
    { name: 'price', type: 'money' },
    { name: 'created_at', type: 'ts' },
  ] },
  { name: 'inventory', cols: [
    { name: 'id', type: 'pk' },
    { name: 'variant_id', type: 'fk', ref: 'product_variants(id)' },
    { name: 'warehouse_id', type: 'fk', ref: 'warehouses(id)' },
    { name: 'quantity', type: 'int' },
    { name: 'updated_at', type: 'ts' },
  ], unique: ['variant_id', 'warehouse_id'] },
  { name: 'carts', cols: [
    { name: 'id', type: 'pk' },
    { name: 'user_id', type: 'fk', ref: 'users(id)' },
    { name: 'status', type: 'enum:cart_status' },
    { name: 'created_at', type: 'ts' },
  ] },
  { name: 'cart_items', cols: [
    { name: 'id', type: 'pk' },
    { name: 'cart_id', type: 'fk', ref: 'carts(id)' },
    { name: 'variant_id', type: 'fk', ref: 'product_variants(id)' },
    { name: 'quantity', type: 'int' },
    { name: 'added_at', type: 'ts' },
  ] },
  { name: 'orders', cols: [
    { name: 'id', type: 'pk' },
    { name: 'user_id', type: 'fk', ref: 'users(id)' },
    { name: 'address_id', type: 'fk', ref: 'addresses(id)' },
    { name: 'status', type: 'enum:order_status' },
    { name: 'total', type: 'money' },
    { name: 'payment_method', type: 'enum:payment_method' },
    { name: 'created_at', type: 'ts' },
    { name: 'updated_at', type: 'ts' },
  ] },
  { name: 'order_items', cols: [
    { name: 'id', type: 'pk' },
    { name: 'order_id', type: 'fk', ref: 'orders(id)' },
    { name: 'variant_id', type: 'fk', ref: 'product_variants(id)' },
    { name: 'quantity', type: 'int' },
    { name: 'unit_price', type: 'money' },
  ] },
  { name: 'payments', cols: [
    { name: 'id', type: 'pk' },
    { name: 'order_id', type: 'fk', ref: 'orders(id)' },
    { name: 'method', type: 'enum:payment_method' },
    { name: 'status', type: 'enum:payment_status' },
    { name: 'amount', type: 'money' },
    { name: 'paid_at', type: 'ts', null: true },
  ] },
  { name: 'shipments', cols: [
    { name: 'id', type: 'pk' },
    { name: 'order_id', type: 'fk', ref: 'orders(id)' },
    { name: 'warehouse_id', type: 'fk', ref: 'warehouses(id)' },
    { name: 'carrier', type: 'text:16' },
    { name: 'tracking', type: 'text:24' },
    { name: 'status', type: 'enum:shipment_status' },
    { name: 'shipped_at', type: 'ts', null: true },
  ] },
  { name: 'reviews', cols: [
    { name: 'id', type: 'pk' },
    { name: 'product_id', type: 'fk', ref: 'products(id)' },
    { name: 'user_id', type: 'fk', ref: 'users(id)' },
    { name: 'rating', type: 'int' },
    { name: 'body', type: 'text:240' },
    { name: 'created_at', type: 'ts' },
  ] },
  { name: 'events', cols: [
    { name: 'id', type: 'pk' },
    { name: 'user_id', type: 'fk', ref: 'users(id)', null: true },
    { name: 'kind', type: 'text:24' },
    { name: 'payload', type: 'text:200' },
    { name: 'created_at', type: 'ts' },
  ] },
  // audit_log: do trigger trên orders điền (không seed trực tiếp)
  { name: 'audit_log', cols: [
    { name: 'id', type: 'pk' },
    { name: 'entity', type: 'text:24' },
    { name: 'entity_id', type: 'int' },
    { name: 'action', type: 'text:16' },
    { name: 'at', type: 'ts' },
  ] },
]
const SEEDED = TABLES.filter((t) => t.name !== 'audit_log')

// ── Sinh dữ liệu (mảng JS) ─────────────────────────────────────────────────────────
const D = {}
function gen() {
  D.users = []
  for (let i = 1; i <= N.users; i++) {
    const c = tsAgo(720)
    D.users.push({ id: i, email: `${pick(FIRST).toLowerCase()}.${pick(LAST).toLowerCase()}${i}@example.com`, full_name: `${pick(FIRST)} ${pick(LAST)}`, status: pick(ENUMS.user_status), created_at: c, updated_at: c })
  }
  D.addresses = []
  for (let i = 1; i <= N.addresses; i++)
    D.addresses.push({ id: i, user_id: int(1, N.users), line1: `${int(1, 999)} ${pick(NOUN)} St`, city: pick(CITY), country: pick(COUNTRY), is_default: chance(0.35), created_at: tsAgo(700) })

  D.categories = []
  for (let i = 1; i <= N.categories; i++)
    D.categories.push({ id: i, name: CATNAME[(i - 1) % CATNAME.length], slug: `${CATNAME[(i - 1) % CATNAME.length].toLowerCase().replace(/[^a-z]+/g, '-')}-${i}`, parent_id: i > 6 && chance(0.5) ? int(1, 6) : null, created_at: tsAgo(900) })

  D.suppliers = []
  for (let i = 1; i <= N.suppliers; i++)
    D.suppliers.push({ id: i, name: `${pick(SUPNAME)} ${pick(['Ltd', 'Inc', 'Co', 'Group'])}`, country: pick(COUNTRY), rating: int(1, 5), created_at: tsAgo(900) })

  D.warehouses = []
  for (let i = 1; i <= N.warehouses; i++) D.warehouses.push({ id: i, code: `WH-${pad(i, 3)}`, city: pick(CITY), country: pick(COUNTRY) })

  D.products = []
  for (let i = 1; i <= N.products; i++) {
    const c = tsAgo(640)
    D.products.push({ id: i, category_id: int(1, N.categories), supplier_id: int(1, N.suppliers), name: `${pick(ADJ)} ${pick(NOUN)}`, sku: `P-${pad(i, 6)}`, price: money(5, 900), status: pick(ENUMS.product_status), created_at: c, updated_at: c })
  }

  D.product_variants = []
  for (let i = 1; i <= N.variants; i++) {
    const pid = int(1, N.products)
    const base = D.products[pid - 1].price
    D.product_variants.push({ id: i, product_id: pid, sku: `V-${pad(i, 7)}`, color: pick(COLOR), size: pick(SIZE), price: Number(Math.max(1, base + money(-10, 40)).toFixed(2)), created_at: tsAgo(600) })
  }

  D.inventory = []
  let invId = 1
  for (let v = 1; v <= N.variants; v++) {
    const used = new Set()
    const k = int(1, 3)
    for (let j = 0; j < k; j++) {
      const w = int(1, N.warehouses)
      if (used.has(w)) continue
      used.add(w)
      D.inventory.push({ id: invId++, variant_id: v, warehouse_id: w, quantity: int(0, 500), updated_at: tsAgo(120) })
    }
  }

  D.carts = []
  for (let i = 1; i <= N.carts; i++) D.carts.push({ id: i, user_id: int(1, N.users), status: pick(ENUMS.cart_status), created_at: tsAgo(200) })

  D.cart_items = []
  let ciId = 1
  for (let c = 1; c <= N.carts; c++) {
    const k = int(1, 5)
    for (let j = 0; j < k; j++) D.cart_items.push({ id: ciId++, cart_id: c, variant_id: int(1, N.variants), quantity: int(1, 6), added_at: tsAgo(190) })
  }

  D.orders = []
  D.order_items = []
  let oiId = 1
  for (let o = 1; o <= N.orders; o++) {
    const created = tsAgo(560)
    const status = pick(ENUMS.order_status)
    const lines = int(1, 4)
    let total = 0
    for (let j = 0; j < lines; j++) {
      const v = int(1, N.variants)
      const qty = int(1, 5)
      const price = D.product_variants[v - 1].price
      total += qty * price
      D.order_items.push({ id: oiId++, order_id: o, variant_id: v, quantity: qty, unit_price: price })
    }
    D.orders.push({ id: o, user_id: int(1, N.users), address_id: int(1, N.addresses), status, total: Number(total.toFixed(2)), payment_method: pick(ENUMS.payment_method), created_at: created, updated_at: created })
  }

  D.payments = []
  for (let o = 1; o <= N.orders; o++) {
    const ord = D.orders[o - 1]
    const st = ord.status === 'cancelled' ? 'failed' : ord.status === 'pending' ? 'pending' : pick(['completed', 'completed', 'refunded'])
    D.payments.push({ id: o, order_id: o, method: ord.payment_method, status: st, amount: ord.total, paid_at: st === 'pending' ? null : tsBetween(ord.created_at, 5) })
  }

  D.shipments = []
  let shId = 1
  for (let o = 1; o <= N.orders; o++) {
    const ord = D.orders[o - 1]
    if (ord.status === 'pending' || ord.status === 'cancelled') continue
    const st = ord.status === 'delivered' ? 'delivered' : pick(['shipped', 'in_transit'])
    D.shipments.push({ id: shId++, order_id: o, warehouse_id: int(1, N.warehouses), carrier: pick(CARRIER), tracking: `TRK${pad(o, 8)}`, status: st, shipped_at: tsBetween(ord.created_at, 6) })
  }

  D.reviews = []
  for (let i = 1; i <= N.reviews; i++) D.reviews.push({ id: i, product_id: int(1, N.products), user_id: int(1, N.users), rating: int(1, 5), body: `${pick(WORDS)}, ${pick(WORDS)}`, created_at: tsAgo(500) })

  D.events = []
  for (let i = 1; i <= N.events; i++) D.events.push({ id: i, user_id: chance(0.9) ? int(1, N.users) : null, kind: pick(EVENT_KIND), payload: `{"ref":${int(1, 9999)},"v":${int(1, 9)}}`, created_at: tsAgo(365) })
}

// ── DDL ─────────────────────────────────────────────────────────────────────────────
function colDDL(dialect, col) {
  const NN = col.null ? '' : ' NOT NULL'
  const U = col.unique ? ' UNIQUE' : ''
  if (col.type === 'pk') {
    if (dialect === 'pg') return `  ${col.name} bigserial PRIMARY KEY`
    if (dialect === 'mysql') return `  ${col.name} bigint NOT NULL AUTO_INCREMENT PRIMARY KEY`
    return `  ${col.name} integer PRIMARY KEY`
  }
  let t
  if (col.type === 'int') t = dialect === 'mysql' ? 'int' : 'integer'
  else if (col.type === 'fk') t = dialect === 'sqlite' ? 'integer' : 'bigint'
  else if (col.type === 'money') t = dialect === 'mysql' ? 'decimal(12,2)' : dialect === 'pg' ? 'numeric(12,2)' : 'numeric'
  else if (col.type === 'bool') t = dialect === 'pg' ? 'boolean' : dialect === 'mysql' ? 'tinyint(1)' : 'integer'
  else if (col.type === 'ts') t = dialect === 'pg' ? 'timestamptz' : dialect === 'mysql' ? 'datetime' : 'text'
  else if (col.type === 'email') t = dialect === 'pg' ? 'email_addr' : dialect === 'mysql' ? 'varchar(255)' : 'text'
  else if (col.type.startsWith('text:')) t = dialect === 'sqlite' ? 'text' : `varchar(${col.type.slice(5)})`
  else if (col.type.startsWith('enum:')) {
    const name = col.type.slice(5)
    if (dialect === 'pg') t = name
    else if (dialect === 'mysql') t = `enum(${uniq(ENUMS[name]).map((v) => `'${v}'`).join(',')})`
    else t = 'text'
  }
  return `  ${col.name} ${t}${NN}${U}`
}

function schemaSQL(dialect) {
  const out = []
  if (dialect === 'pg') {
    out.push('-- PostgreSQL: object types + 17 bảng + views + triggers', 'SET client_min_messages = warning;')
    for (const [name, vals] of Object.entries(ENUMS)) {
      out.push(`DROP TYPE IF EXISTS ${name} CASCADE;`, `CREATE TYPE ${name} AS ENUM (${uniq(vals).map((v) => `'${v}'`).join(', ')});`)
    }
    out.push(`DROP DOMAIN IF EXISTS email_addr CASCADE;`, `CREATE DOMAIN email_addr AS varchar(255) CHECK (VALUE ~ '@');`)
    out.push(`DROP TYPE IF EXISTS geo_point CASCADE;`, `CREATE TYPE geo_point AS (lat double precision, lng double precision);`, '')
  } else if (dialect === 'mysql') {
    out.push('-- MySQL: 17 bảng + views + triggers (trạng thái dùng ENUM)', 'SET FOREIGN_KEY_CHECKS=0;')
  } else {
    out.push('-- SQLite: 17 bảng + views + triggers (trạng thái ràng buộc CHECK)', 'PRAGMA foreign_keys=OFF;')
  }

  for (const tb of TABLES) {
    const lines = tb.cols.map((c) => colDDL(dialect, c))
    for (const c of tb.cols) if (c.type === 'fk' && c.ref) lines.push(`  FOREIGN KEY (${c.name}) REFERENCES ${c.ref}`)
    if (tb.unique) lines.push(`  UNIQUE (${tb.unique.join(', ')})`)
    if (dialect === 'sqlite')
      for (const c of tb.cols)
        if (c.type.startsWith('enum:')) lines.push(`  CHECK (${c.name} IN (${uniq(ENUMS[c.type.slice(5)]).map((v) => `'${v}'`).join(', ')}))`)
    const suffix = dialect === 'mysql' ? ' ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' : ''
    out.push(`CREATE TABLE ${tb.name} (\n${lines.join(',\n')}\n)${suffix};`)
  }
  out.push('')

  out.push(`CREATE VIEW v_order_summary AS
  SELECT o.id, u.email, o.status, o.total, o.created_at
  FROM orders o JOIN users u ON u.id = o.user_id;`)
  out.push(`CREATE VIEW v_product_stock AS
  SELECT p.id, p.name, COALESCE(SUM(i.quantity), 0) AS stock
  FROM products p
  LEFT JOIN product_variants v ON v.product_id = p.id
  LEFT JOIN inventory i ON i.variant_id = v.id
  GROUP BY p.id, p.name;`)
  out.push(`CREATE VIEW v_user_orders AS
  SELECT u.id, u.email, COUNT(o.id) AS orders, COALESCE(SUM(o.total), 0) AS spent
  FROM users u LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id, u.email;`)
  out.push('')

  // Functions / Procedures (đa dạng kiểu) — hiện ở cây Routines + dùng cho Add Trigger.
  if (dialect === 'pg') out.push(PG_FUNCTIONS)
  else if (dialect === 'mysql') out.push(MY_FUNCTIONS)
  out.push('')

  if (dialect === 'pg') {
    out.push(`CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql;`)
    for (const t of ['users', 'products', 'orders'])
      out.push(`CREATE TRIGGER trg_${t}_updated BEFORE UPDATE ON ${t} FOR EACH ROW EXECUTE FUNCTION set_updated_at();`)
    out.push(`CREATE OR REPLACE FUNCTION log_new_order() RETURNS trigger AS $$
BEGIN INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', now()); RETURN NEW; END; $$ LANGUAGE plpgsql;`)
    out.push(`CREATE TRIGGER trg_orders_audit AFTER INSERT ON orders FOR EACH ROW EXECUTE FUNCTION log_new_order();`)
  } else if (dialect === 'mysql') {
    out.push('DELIMITER $$')
    for (const t of ['users', 'products', 'orders'])
      out.push(`CREATE TRIGGER trg_${t}_updated BEFORE UPDATE ON ${t} FOR EACH ROW BEGIN SET NEW.updated_at = NOW(); END$$`)
    out.push(`CREATE TRIGGER trg_orders_audit AFTER INSERT ON orders FOR EACH ROW BEGIN
  INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', NOW());
END$$`)
    out.push('DELIMITER ;', 'SET FOREIGN_KEY_CHECKS=1;')
  } else {
    for (const t of ['users', 'products', 'orders'])
      out.push(`CREATE TRIGGER trg_${t}_updated AFTER UPDATE ON ${t} FOR EACH ROW BEGIN
  UPDATE ${t} SET updated_at = datetime('now') WHERE id = NEW.id;
END;`)
    out.push(`CREATE TRIGGER trg_orders_audit AFTER INSERT ON orders FOR EACH ROW BEGIN
  INSERT INTO audit_log(entity, entity_id, action, at) VALUES ('order', NEW.id, 'insert', datetime('now'));
END;`)
    out.push('PRAGMA foreign_keys=ON;')
  }
  return out.join('\n') + '\n'
}

// ── Data ─────────────────────────────────────────────────────────────────────────────
function sval(dialect, col, v) {
  if (v === null || v === undefined) return 'NULL'
  if (col.type === 'pk' || col.type === 'int' || col.type === 'fk' || col.type === 'money') return String(v)
  if (col.type === 'bool') return dialect === 'pg' ? (v ? 'true' : 'false') : v ? '1' : '0'
  if (col.type === 'ts') return `'${fmtTs(v)}'`
  return `'${String(v).replace(/'/g, "''")}'`
}

function dataSQL(dialect) {
  const out = []
  if (dialect === 'mysql') out.push('SET FOREIGN_KEY_CHECKS=0;', 'SET autocommit=0;', 'START TRANSACTION;')
  else if (dialect === 'pg') out.push('BEGIN;')
  else out.push('PRAGMA foreign_keys=OFF;', 'BEGIN;')

  for (const tb of SEEDED) {
    const rows = D[tb.name]
    if (!rows?.length) continue
    const cols = tb.cols.map((c) => c.name)
    for (let i = 0; i < rows.length; i += 500) {
      const values = rows.slice(i, i + 500).map((r) => '(' + tb.cols.map((c) => sval(dialect, c, r[c.name])).join(', ') + ')').join(',\n')
      out.push(`INSERT INTO ${tb.name} (${cols.join(', ')}) VALUES\n${values};`)
    }
  }

  if (dialect === 'pg') {
    for (const tb of SEEDED) out.push(`SELECT setval(pg_get_serial_sequence('${tb.name}','id'), (SELECT COALESCE(MAX(id),1) FROM ${tb.name}));`)
    out.push('COMMIT;')
  } else if (dialect === 'mysql') out.push('COMMIT;', 'SET FOREIGN_KEY_CHECKS=1;')
  else out.push('COMMIT;', 'PRAGMA foreign_keys=ON;')
  return out.join('\n') + '\n'
}

// ── Redis (~1000 key đa dạng) ─────────────────────────────────────────────────────
function redisSeed() {
  const L = ['FLUSHDB']
  for (let i = 1; i <= 300; i++) {
    const u = D.users[i - 1]
    L.push(`HSET user:${i} email ${u.email} name "${u.full_name}" status ${u.status}`)
  }
  for (let i = 1; i <= 150; i++) L.push(`SET session:tok${pad(i, 4)} user:${int(1, 300)} EX ${int(300, 86400)}`)
  for (let i = 1; i <= 150; i++) L.push(`SET product:${i}:views ${int(0, 50000)}`)
  for (let i = 1; i <= 100; i++) L.push(`HSET cart:${i} user user:${int(1, 300)} items ${int(1, 8)} status open`)
  for (let i = 1; i <= 100; i++) {
    const o = D.orders[i - 1]
    L.push(`HSET order:${i} user user:${o.user_id} total ${o.total} status ${o.status}`)
  }
  for (let i = 1; i <= 80; i++) L.push(`RPUSH feed:user:${i} ${Array.from({ length: int(3, 8) }, () => `evt${int(1, 9999)}`).join(' ')}`)
  for (let i = 1; i <= 60; i++) L.push(`SADD tags:product:${i} ${uniq(Array.from({ length: int(2, 5) }, () => pick(CATNAME).toLowerCase())).join(' ')}`)
  for (let i = 1; i <= 50; i++) L.push(`SET rate:ip:10.0.0.${i} ${int(1, 100)} EX ${int(30, 600)}`)
  for (let i = 1; i <= 10; i++)
    L.push(`ZADD leaderboard:wk${pad(i, 2)} ${Array.from({ length: int(8, 15) }, (_, k) => `${int(10, 9999)} user:${((i * 7 + k) % 300) + 1}`).join(' ')}`)
  return L.join('\n') + '\n'
}

// ── Ghi file ─────────────────────────────────────────────────────────────────────────
function write(rel, content) {
  const p = join(ROOT, rel)
  mkdirSync(dirname(p), { recursive: true })
  writeFileSync(p, content)
  return `${rel} (${(content.length / 1024).toFixed(0)} KB)`
}

gen()
const counts = Object.fromEntries(SEEDED.map((t) => [t.name, D[t.name].length]))
const total = Object.values(counts).reduce((a, b) => a + b, 0)
const written = [
  write('postgres/01-schema.sql', schemaSQL('pg')),
  write('postgres/02-data.sql', dataSQL('pg')),
  write('mysql/01-schema.sql', schemaSQL('mysql')),
  write('mysql/02-data.sql', dataSQL('mysql')),
  write('sqlite/schema.sql', schemaSQL('sqlite')),
  write('sqlite/data.sql', dataSQL('sqlite')),
  write('redis/seed.redis', redisSeed()),
]
console.log('Đã sinh:')
for (const w of written) console.log('  •', w)
for (const [k, v] of Object.entries(counts)) console.log(`  ${k.padEnd(18)} ${v}`)
console.log(`  ${'TỔNG (seed)'.padEnd(18)} ${total}  (+ audit_log do trigger điền)`)
