-- ============================================================================
--  PostgreSQL — Câu truy vấn DEMO (chạy trên dữ liệu mẫu jdb)
--  Copy từng câu vào SQL Editor rồi ⌘/Ctrl+R. Hầu hết chỉ ĐỌC (an toàn).
-- ============================================================================

-- 1) Cơ bản: liệt kê người dùng mới nhất
SELECT id, email, full_name, status, created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- 2) Lọc theo ENUM
SELECT id, email, status FROM users WHERE status = 'active' LIMIT 20;

-- 3) Đếm người dùng theo trạng thái
SELECT status, COUNT(*) AS total
FROM users
GROUP BY status
ORDER BY total DESC;

-- 4) JOIN: đơn hàng kèm email khách
SELECT o.id, u.email, o.status, o.total, o.created_at
FROM orders o
JOIN users u ON u.id = o.user_id
ORDER BY o.created_at DESC
LIMIT 15;

-- 5) Tổng hợp: doanh thu theo tháng
SELECT date_trunc('month', created_at) AS month,
       COUNT(*) AS orders,
       SUM(total) AS revenue
FROM orders
GROUP BY 1
ORDER BY 1 DESC;

-- 6) Top khách chi tiêu nhiều nhất
SELECT u.id, u.email, COUNT(o.id) AS orders, SUM(o.total) AS spent
FROM users u
JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.email
ORDER BY spent DESC
LIMIT 10;

-- 7) Hàm cửa sổ: xếp hạng sản phẩm theo giá trong từng danh mục
SELECT category_id, name, price,
       RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS price_rank
FROM products
ORDER BY category_id, price_rank
LIMIT 30;

-- 8) LEFT JOIN: người dùng chưa có đơn hàng
SELECT u.id, u.email
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL
LIMIT 20;

-- 9) Điểm đánh giá trung bình theo sản phẩm
SELECT p.id, p.name, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(r.id) AS reviews
FROM products p
JOIN reviews r ON r.product_id = p.id
GROUP BY p.id, p.name
HAVING COUNT(r.id) >= 2
ORDER BY avg_rating DESC
LIMIT 15;

-- 10) Tồn kho thấp (gộp theo sản phẩm qua biến thể)
SELECT p.id, p.name, COALESCE(SUM(i.quantity), 0) AS stock
FROM products p
LEFT JOIN product_variants v ON v.product_id = p.id
LEFT JOIN inventory i ON i.variant_id = v.id
GROUP BY p.id, p.name
ORDER BY stock ASC
LIMIT 15;

-- 11) CTE: đơn hàng đã thanh toán + số mặt hàng
WITH paid AS (
  SELECT id, user_id, total FROM orders WHERE status = 'paid'
)
SELECT pd.id, pd.total, COUNT(oi.id) AS items
FROM paid pd
JOIN order_items oi ON oi.order_id = pd.id
GROUP BY pd.id, pd.total
ORDER BY pd.total DESC
LIMIT 15;

-- 12) Dùng VIEW có sẵn
SELECT * FROM v_user_orders ORDER BY spent DESC LIMIT 10;
SELECT * FROM v_product_stock WHERE stock = 0 LIMIT 10;

-- 13) Gọi FUNCTION (đặc thù PostgreSQL)
SELECT fn_apply_discount(100, 15) AS price_after_discount;
SELECT fn_order_total(1) AS order_1_total;
SELECT * FROM fn_recent_orders(30) LIMIT 10;
SELECT fn_order_summary_json(1) AS summary;

-- 14) JSON tổng hợp
SELECT json_build_object('users', (SELECT COUNT(*) FROM users),
                         'orders', (SELECT COUNT(*) FROM orders),
                         'revenue', (SELECT COALESCE(SUM(total),0) FROM orders)) AS stats;

-- 15) GHI (ví dụ — bỏ ghi chú để chạy, sẽ thay đổi dữ liệu):
-- INSERT INTO users (email, full_name, status, created_at, updated_at)
--   VALUES ('demo@example.com', 'Demo User', 'active', now(), now());
-- UPDATE products SET price = price * 1.10 WHERE status = 'active';


-- ============================================================================
--  NÂNG CAO — 10 câu truy vấn PHỨC TẠP (CTE đệ quy, window, LATERAL, ROLLUP,
--  GROUPING SETS, FILTER, PERCENTILE, JSON lồng, cohort, RFM). Chỉ ĐỌC — an toàn.
--  Đã kiểm chứng chạy được trên schema 01-schema.sql.
-- ============================================================================

-- 16) CTE ĐỆ QUY: cây danh mục (đường dẫn + độ sâu) + số sản phẩm trực tiếp
WITH RECURSIVE cat_tree AS (
  SELECT id, name, parent_id, name::text AS path, 1 AS depth
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.name, c.parent_id, ct.path || ' > ' || c.name, ct.depth + 1
  FROM categories c
  JOIN cat_tree ct ON c.parent_id = ct.id
),
prod_counts AS (
  SELECT category_id, COUNT(*) AS direct_products FROM products GROUP BY category_id
)
SELECT ct.id,
       repeat('  ', ct.depth - 1) || ct.name AS tree,
       ct.path, ct.depth,
       COALESCE(pc.direct_products, 0) AS direct_products
FROM cat_tree ct
LEFT JOIN prod_counts pc ON pc.category_id = ct.id
ORDER BY ct.path;

-- 17) WINDOW: Top 3 sản phẩm theo doanh thu TRONG TỪNG danh mục (RANK + % danh mục)
WITH product_rev AS (
  SELECT p.id, p.name, p.category_id,
         SUM(oi.quantity * oi.unit_price) AS revenue,
         SUM(oi.quantity)                 AS units
  FROM order_items oi
  JOIN product_variants v ON v.id = oi.variant_id
  JOIN products p         ON p.id = v.product_id
  JOIN orders o           ON o.id = oi.order_id AND o.status <> 'cancelled'
  GROUP BY p.id, p.name, p.category_id
),
ranked AS (
  SELECT pr.*, c.name AS category,
         RANK() OVER (PARTITION BY pr.category_id ORDER BY pr.revenue DESC) AS rnk,
         ROUND(100.0 * pr.revenue
               / SUM(pr.revenue) OVER (PARTITION BY pr.category_id), 2)     AS pct_of_category
  FROM product_rev pr
  JOIN categories c ON c.id = pr.category_id
)
SELECT category, name, revenue, units, rnk, pct_of_category
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- 18) PHÂN KHÚC RFM khách hàng (NTILE tứ phân vị Recency/Frequency/Monetary)
WITH base AS (
  SELECT u.id, u.email,
         MAX(o.created_at)          AS last_order,
         COUNT(o.id)                AS frequency,
         COALESCE(SUM(o.total), 0)  AS monetary
  FROM users u
  JOIN orders o ON o.user_id = u.id AND o.status <> 'cancelled'
  GROUP BY u.id, u.email
),
scored AS (
  SELECT *,
         NTILE(4) OVER (ORDER BY last_order DESC) AS r_score,  -- càng gần đây điểm càng nhỏ (1 = tốt)
         NTILE(4) OVER (ORDER BY frequency  DESC) AS f_score,
         NTILE(4) OVER (ORDER BY monetary   DESC) AS m_score
  FROM base
)
SELECT email,
       date_trunc('day', last_order) AS last_order,
       frequency, monetary,
       r_score, f_score, m_score,
       (r_score::text || f_score::text || m_score::text) AS rfm,
       CASE
         WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2 THEN 'Champions'
         WHEN r_score <= 2 AND f_score <= 2                 THEN 'Loyal'
         WHEN r_score >= 3 AND f_score >= 3                 THEN 'At risk'
         ELSE 'Others'
       END AS segment
FROM scored
ORDER BY monetary DESC
LIMIT 25;

-- 19) DOANH THU theo tháng: running total + tăng trưởng MoM + trung bình trượt 3 tháng
WITH monthly AS (
  SELECT date_trunc('month', o.created_at) AS month,
         SUM(o.total)              AS revenue,
         COUNT(*)                  AS orders,
         COUNT(DISTINCT o.user_id) AS buyers
  FROM orders o
  WHERE o.status <> 'cancelled'
  GROUP BY 1
)
SELECT to_char(month, 'YYYY-MM') AS month,
       revenue, orders, buyers,
       SUM(revenue) OVER (ORDER BY month) AS running_revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) AS mom_change,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS mom_pct,
       ROUND(AVG(revenue) OVER (ORDER BY month
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m
FROM monthly
ORDER BY month;

-- 20) LATERAL: mỗi user active → đơn gần nhất + sản phẩm mua nhiều nhất
SELECT u.email,
       lo.id AS last_order_id, lo.total AS last_total, lo.created_at AS last_at,
       tp.product AS top_product, tp.units
FROM users u
JOIN LATERAL (
  SELECT o.id, o.total, o.created_at
  FROM orders o
  WHERE o.user_id = u.id
  ORDER BY o.created_at DESC
  LIMIT 1
) lo ON true
LEFT JOIN LATERAL (
  SELECT p.name AS product, SUM(oi.quantity) AS units
  FROM orders o
  JOIN order_items oi     ON oi.order_id = o.id
  JOIN product_variants v ON v.id = oi.variant_id
  JOIN products p         ON p.id = v.product_id
  WHERE o.user_id = u.id
  GROUP BY p.name
  ORDER BY units DESC
  LIMIT 1
) tp ON true
WHERE u.status = 'active'
ORDER BY lo.created_at DESC
LIMIT 20;

-- 21) ROLLUP + GROUPING(): doanh thu theo danh mục × trạng thái đơn, có dòng tổng
SELECT CASE WHEN GROUPING(c.name)   = 1 THEN '(all categories)' ELSE c.name        END AS category,
       CASE WHEN GROUPING(o.status) = 1 THEN '(all statuses)'   ELSE o.status::text END AS status,
       COUNT(DISTINCT o.id) AS orders,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM orders o
JOIN order_items oi     ON oi.order_id = o.id
JOIN product_variants v ON v.id = oi.variant_id
JOIN products p         ON p.id = v.product_id
JOIN categories c       ON c.id = p.category_id
GROUP BY ROLLUP (c.name, o.status)
ORDER BY category, status;

-- 22) COHORT: theo tháng đặt đơn ĐẦU TIÊN, số user còn hoạt động theo offset tháng
WITH first_order AS (
  SELECT user_id, date_trunc('month', MIN(created_at)) AS cohort
  FROM orders GROUP BY user_id
),
activity AS (
  SELECT o.user_id, fo.cohort, date_trunc('month', o.created_at) AS month
  FROM orders o JOIN first_order fo ON fo.user_id = o.user_id
)
SELECT to_char(cohort, 'YYYY-MM') AS cohort,
       (EXTRACT(YEAR FROM age(month, cohort)) * 12
        + EXTRACT(MONTH FROM age(month, cohort)))::int AS month_offset,
       COUNT(DISTINCT user_id) AS active_users
FROM activity
GROUP BY cohort, month_offset
ORDER BY cohort, month_offset;

-- 23) TỒN KHO: FILTER theo quốc gia + PERCENTILE_CONT (trung vị) + cờ nhập thêm
SELECT p.id, p.name,
       COUNT(DISTINCT v.id)                                   AS variants,
       COALESCE(SUM(i.quantity), 0)                           AS total_stock,
       COALESCE(SUM(i.quantity) FILTER (WHERE w.country = 'US'), 0) AS us_stock,
       COUNT(*) FILTER (WHERE i.quantity = 0)                 AS oos_locations,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY i.quantity) AS median_qty,
       CASE WHEN COALESCE(SUM(i.quantity), 0) < 20 THEN 'REORDER' ELSE 'OK' END AS flag
FROM products p
JOIN product_variants v ON v.product_id = p.id
LEFT JOIN inventory i   ON i.variant_id = v.id
LEFT JOIN warehouses w  ON w.id = i.warehouse_id
WHERE p.status = 'active'
GROUP BY p.id, p.name
HAVING COALESCE(SUM(i.quantity), 0) < 50
ORDER BY total_stock ASC
LIMIT 25;

-- 24) JSON LỒNG: mỗi đơn kèm mảng items + thông tin thanh toán (json_agg + subquery)
SELECT json_agg(t ORDER BY t.created_at DESC) AS orders_json
FROM (
  SELECT o.id, o.status, o.total, o.created_at, u.email,
         (SELECT json_agg(json_build_object(
                   'product', p.name, 'color', v.color, 'size', v.size,
                   'qty', oi.quantity, 'unit_price', oi.unit_price))
          FROM order_items oi
          JOIN product_variants v ON v.id = oi.variant_id
          JOIN products p         ON p.id = v.product_id
          WHERE oi.order_id = o.id) AS items,
         (SELECT json_build_object('method', pay.method, 'status', pay.status, 'amount', pay.amount)
          FROM payments pay WHERE pay.order_id = o.id ORDER BY pay.id LIMIT 1) AS payment
  FROM orders o
  JOIN users u ON u.id = o.user_id
  WHERE o.status IN ('paid', 'shipped', 'delivered')
  ORDER BY o.created_at DESC
  LIMIT 5
) t;

-- 25) PHỄU CHUYỂN ĐỔI: giỏ hàng → đơn theo từng user (FILTER + NTILE thập phân vị)
WITH cart_stats AS (
  SELECT user_id,
         COUNT(*)                                     AS carts,
         COUNT(*) FILTER (WHERE status = 'converted') AS converted,
         COUNT(*) FILTER (WHERE status = 'abandoned') AS abandoned
  FROM carts GROUP BY user_id
),
order_stats AS (
  SELECT user_id, COUNT(*) AS orders, SUM(total) AS spent, AVG(total) AS aov
  FROM orders WHERE status <> 'cancelled' GROUP BY user_id
)
SELECT u.email,
       COALESCE(cs.carts, 0)     AS carts,
       COALESCE(cs.converted, 0) AS converted_carts,
       COALESCE(os.orders, 0)    AS orders,
       ROUND(COALESCE(os.spent, 0), 2) AS spent,
       ROUND(COALESCE(os.aov, 0), 2)   AS avg_order_value,
       ROUND(100.0 * cs.converted / NULLIF(cs.carts, 0), 1) AS conversion_pct,
       NTILE(10) OVER (ORDER BY COALESCE(os.spent, 0) DESC)  AS spend_decile
FROM users u
LEFT JOIN cart_stats  cs ON cs.user_id = u.id
LEFT JOIN order_stats os ON os.user_id = u.id
WHERE COALESCE(cs.carts, 0) > 0 OR COALESCE(os.orders, 0) > 0
ORDER BY spent DESC
LIMIT 30;
