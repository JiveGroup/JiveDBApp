-- Câu truy vấn DEMO (schema sinh tự động). Mỗi bảng có cột khác nhau (ngẫu nhiên)
-- nhưng LUÔN có id + created_at. Dùng SELECT * để khám phá. Đổi core_user sang bảng khác tuỳ ý.

-- 1) Liệt kê toàn bộ bảng
SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY table_name;

-- 2) Khám phá 1 bảng
SELECT * FROM core_user ORDER BY id DESC LIMIT 20;

-- 3) Đếm dòng
SELECT count(*) AS total FROM core_user;

-- 4) Bản ghi mới nhất
SELECT * FROM core_user ORDER BY created_at DESC LIMIT 10;

-- 5) Nhóm theo tháng (created_at)
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, count(*) AS `rows` FROM core_user GROUP BY month ORDER BY month DESC;

-- 6) Cột của một bảng
SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'core_user' ORDER BY ordinal_position;

-- 7) Tổng số bảng
SELECT count(*) AS tables FROM information_schema.tables WHERE table_schema = DATABASE();


-- ============================================================================
--  NÂNG CAO — 10 câu truy vấn PHỨC TẠP cho MySQL 8 (CTE đệ quy, window,
--  WITH ROLLUP + GROUPING(), conditional aggregation, JSON lồng, cohort).
--  Dùng nhóm bảng core_* có quan hệ: core_user → core_order,
--  core_user → core_item → core_event(amount), core_tag → core_note.
--  Chỉ ĐỌC — an toàn. Đã kiểm chứng chạy trên schema 01-schema.sql.
-- ============================================================================

-- 8) CTE ĐỆ QUY: tạo dải tháng (lịch) + đếm đơn theo tháng, lấp tháng trống
WITH RECURSIVE bounds AS (
  SELECT DATE_FORMAT(MIN(created_at), '%Y-%m-01') AS lo, DATE_FORMAT(MAX(created_at), '%Y-%m-01') AS hi FROM core_order
),
months AS (
  SELECT CAST((SELECT lo FROM bounds) AS DATE) AS m
  UNION ALL
  SELECT m + INTERVAL 1 MONTH FROM months WHERE m < (SELECT CAST(hi AS DATE) FROM bounds)
)
SELECT DATE_FORMAT(m, '%Y-%m') AS month, COUNT(o.id) AS orders
FROM months
LEFT JOIN core_order o ON DATE_FORMAT(o.created_at, '%Y-%m') = DATE_FORMAT(m, '%Y-%m')
GROUP BY m
ORDER BY m;

-- 9) WINDOW: Top 3 core_item theo doanh thu (core_event.amount) TRONG TỪNG country
WITH item_rev AS (
  SELECT i.id, i.full_name, i.country,
         COALESCE(SUM(e.amount), 0) AS revenue, COUNT(e.id) AS events
  FROM core_item i
  JOIN core_event e ON e.core_item_id = i.id
  GROUP BY i.id, i.full_name, i.country
),
ranked AS (
  SELECT ir.*,
         RANK() OVER (PARTITION BY country ORDER BY revenue DESC) AS rnk,
         ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY country), 2) AS pct
  FROM item_rev ir
  WHERE country IS NOT NULL
)
SELECT country, full_name, revenue, events, rnk, pct
FROM ranked
WHERE rnk <= 3
ORDER BY country, rnk;

-- 10) NTILE: phân khúc user theo số đơn (tần suất) + doanh thu (qua core_item→core_event)
WITH u AS (
  SELECT cu.id, cu.full_name,
         (SELECT COUNT(*) FROM core_order o WHERE o.core_user_id = cu.id) AS orders,
         (SELECT COALESCE(SUM(e.amount), 0)
          FROM core_item i JOIN core_event e ON e.core_item_id = i.id
          WHERE i.core_user_id = cu.id) AS revenue
  FROM core_user cu
)
SELECT full_name, orders, revenue,
       NTILE(4) OVER (ORDER BY orders DESC)  AS freq_q,
       NTILE(4) OVER (ORDER BY revenue DESC) AS rev_q,
       CASE WHEN orders = 0 AND revenue = 0 THEN 'Dormant'
            WHEN revenue > 0 AND orders > 0 THEN 'Engaged'
            ELSE 'Partial' END AS segment
FROM u
ORDER BY revenue DESC, orders DESC
LIMIT 25;

-- 11) DOANH THU theo tháng (core_event.amount): running total + MoM + trung bình trượt 3 tháng
WITH monthly AS (
  SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, SUM(amount) AS revenue, COUNT(*) AS events
  FROM core_event GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT month, ROUND(revenue, 2) AS revenue, events,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS running_revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) AS mom_change,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS mom_pct,
       ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m
FROM monthly
ORDER BY month;

-- 12) ROW_NUMBER: mỗi user → đơn gần nhất + core_item doanh thu cao nhất
WITH last_order AS (
  SELECT core_user_id, id, status, created_at,
         ROW_NUMBER() OVER (PARTITION BY core_user_id ORDER BY created_at DESC) AS rn
  FROM core_order
),
top_item AS (
  SELECT i.core_user_id, i.full_name AS item, COALESCE(SUM(e.amount), 0) AS revenue,
         ROW_NUMBER() OVER (PARTITION BY i.core_user_id ORDER BY COALESCE(SUM(e.amount), 0) DESC) AS rn
  FROM core_item i LEFT JOIN core_event e ON e.core_item_id = i.id
  GROUP BY i.core_user_id, i.full_name
)
SELECT cu.full_name AS usr, lo.id AS last_order_id, lo.status, lo.created_at AS last_at,
       ti.item AS top_item, ROUND(ti.revenue, 2) AS item_revenue
FROM core_user cu
JOIN last_order lo ON lo.core_user_id = cu.id AND lo.rn = 1
LEFT JOIN top_item ti ON ti.core_user_id = cu.id AND ti.rn = 1
ORDER BY lo.created_at DESC
LIMIT 20;

-- 13) WITH ROLLUP + GROUPING(): số đơn theo country × status, có dòng tổng
SELECT CASE WHEN GROUPING(country) = 1 THEN '(all countries)' ELSE COALESCE(country, '?') END AS country,
       CASE WHEN GROUPING(status)  = 1 THEN '(all statuses)'  ELSE COALESCE(status, '?')  END AS status,
       COUNT(*) AS orders
FROM core_order
GROUP BY country, status WITH ROLLUP;

-- 14) COHORT: theo tháng đặt đơn ĐẦU TIÊN, số user còn hoạt động theo offset tháng
WITH first_order AS (
  SELECT core_user_id, DATE_FORMAT(MIN(created_at), '%Y-%m') AS cohort
  FROM core_order GROUP BY core_user_id
),
activity AS (
  SELECT o.core_user_id, fo.cohort, DATE_FORMAT(o.created_at, '%Y-%m') AS month
  FROM core_order o JOIN first_order fo ON fo.core_user_id = o.core_user_id
)
SELECT cohort,
       (CAST(substr(month, 1, 4) AS UNSIGNED) * 12 + CAST(substr(month, 6, 2) AS UNSIGNED))
       - (CAST(substr(cohort, 1, 4) AS UNSIGNED) * 12 + CAST(substr(cohort, 6, 2) AS UNSIGNED)) AS month_offset,
       COUNT(DISTINCT core_user_id) AS active_users
FROM activity
GROUP BY cohort, month_offset
ORDER BY cohort, month_offset;

-- 15) CONDITIONAL AGGREGATION: thống kê note theo tag (core_tag → core_note)
SELECT t.id, t.country, t.score AS tag_score,
       COUNT(n.id) AS notes,
       SUM(CASE WHEN n.active = 1 THEN 1 ELSE 0 END) AS active_notes,
       ROUND(COALESCE(SUM(n.amount), 0), 2) AS total_amount,
       ROUND(AVG(n.score), 1) AS avg_note_score
FROM core_tag t
LEFT JOIN core_note n ON n.core_tag_id = t.id
GROUP BY t.id, t.country, t.score
HAVING COUNT(n.id) > 0
ORDER BY total_amount DESC
LIMIT 25;

-- 16) JSON LỒNG: mỗi user kèm mảng đơn + số item (JSON_ARRAYAGG/JSON_OBJECT)
SELECT JSON_PRETTY(JSON_ARRAYAGG(JSON_OBJECT(
         'user', cu.full_name, 'status', cu.status,
         'orders', (SELECT JSON_ARRAYAGG(JSON_OBJECT('id', o.id, 'status', o.status, 'city', o.city))
                    FROM core_order o WHERE o.core_user_id = cu.id),
         'item_count', (SELECT COUNT(*) FROM core_item i WHERE i.core_user_id = cu.id)
       ))) AS users_json
FROM (SELECT * FROM core_user ORDER BY id LIMIT 5) cu;

-- 17) TỔNG HỢP user: số đơn vs số item + NTILE thập phân vị theo doanh thu
WITH stats AS (
  SELECT cu.id, cu.full_name,
         (SELECT COUNT(*) FROM core_order o WHERE o.core_user_id = cu.id) AS orders,
         (SELECT COUNT(*) FROM core_item i WHERE i.core_user_id = cu.id) AS items,
         (SELECT COALESCE(SUM(e.amount), 0)
          FROM core_item i JOIN core_event e ON e.core_item_id = i.id
          WHERE i.core_user_id = cu.id) AS revenue
  FROM core_user cu
)
SELECT full_name, orders, items, ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * orders / NULLIF(orders + items, 0), 1) AS order_share_pct,
       NTILE(10) OVER (ORDER BY revenue DESC) AS revenue_decile
FROM stats
WHERE orders > 0 OR items > 0
ORDER BY revenue DESC
LIMIT 30;

