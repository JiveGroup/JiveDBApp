// MongoDB — "hâm nóng" sau khi seed: nạp sẵn số liệu cho 2 panel vốn TRỐNG TRƠN
// khi mở lần đầu. Viết tay (generator không đụng tới).
//
// TẠI SAO KHÔNG GỘP VÀO 02-features.js:
// Hai số liệu dưới đây gắn với TIẾN TRÌNH mongod đang chạy, không phải với dữ liệu
// trên đĩa. Mà các script trong /docker-entrypoint-initdb.d chạy trên một mongod
// TẠM THỜI (không --replSet), sau đó entrypoint tắt nó đi và khởi động lại instance
// thật. Nên nếu đặt ở 02-features.js thì:
//   - bộ đếm $indexStats bị reset về 0 khi restart → công hâm nóng mất sạch;
//   - mức profiling cũng trở về 0.
// Vì vậy file này được service `mongodb-rs-init` gọi SAU khi instance thật sẵn sàng.
// Chạy lại thủ công lúc nào cũng được (idempotent, chỉ đọc + bật profiler).
db = db.getSiblingDB('jdb_dev');

// ============================================================================
// 1) PROFILER / SLOW QUERIES — tab này đọc `system.profile`, mà collection đó
//    chỉ tồn tại sau khi bật profiler. Trên container mới tinh, profiler ở mức 0
//    nên bảng slow query trống trơn: không có planSummary/docsExamined/millis nào
//    để xem. Ở đây ta bật mức 1 với slowms=0 (ghi lại MỌI thao tác), chạy vài truy
//    vấn nặng có chủ đích, rồi hạ ngưỡng về 100ms — profiler vẫn bật nhưng từ giờ
//    chỉ bắt thao tác thật sự chậm.
// ============================================================================
db.setProfilingLevel(1, { slowms: 0 });

// Mỗi truy vấn dưới đây cố ý KHÔNG có index phục vụ → COLLSCAN, và/hoặc sort
// trong bộ nhớ. Chúng chính là loại truy vấn mà Query X-Ray sẽ gợi ý tạo index.
db.events.find({ kind: 'checkout' }).sort({ created_at: -1 }).limit(50).toArray();
db.orders.find({ total: { $gt: 100 } }).sort({ created_at: -1 }).limit(50).toArray();
db.reviews.find({ rating: { $gte: 4 } }).sort({ body: 1 }).limit(50).toArray();
db.users.find({ full_name: /an/i }).limit(50).toArray();
db.order_items.aggregate([
  { $group: { _id: '$order_id', lines: { $sum: 1 }, qty: { $sum: '$quantity' } } },
  { $sort: { qty: -1 } },
  { $limit: 20 },
]).toArray();
db.orders.aggregate([
  { $lookup: { from: 'users', localField: 'user_id', foreignField: '_id', as: 'u' } },
  { $unwind: '$u' },
  { $group: { _id: '$u.status', revenue: { $sum: '$total' } } },
]).toArray();

db.setProfilingLevel(1, { slowms: 100 });

// ============================================================================
// 2) INDEX USAGE — bộ đếm ops của $indexStats bắt đầu từ 0 và reset mỗi lần
//    mongod khởi động lại. Seed cố ý tạo `stores_tags_unused` để minh hoạ cờ
//    "unused", NHƯNG nếu không có truy vấn nào chạm tới các index CÒN LẠI thì
//    chúng cũng đều hiện ops=0 — cả bảng đỏ rực chữ "unused" và mất hẳn ý nghĩa
//    tương phản. Loạt truy vấn dưới đây chạm đúng các index cần trông "đã dùng".
//
//    CỐ Ý KHÔNG chạm tới:
//      - stores_tags_unused    → ví dụ "unused" chủ đích của seed
//      - articles_views_hidden → index ẩn, planner không bao giờ chọn (đúng bản chất)
//      - archived_orders_*     → collection rỗng
// ============================================================================
const anAuthor = db.authors.findOne({}, { email: 1 });
if (anAuthor) db.authors.find({ email: anAuthor.email }).toArray();          // authors_email_unique
db.authors.find({ deceasedAt: { $lt: new Date() } }).toArray();              // authors_deceasedAt_sparse

db.products.find({ category_id: 5 }).sort({ price: -1 }).limit(20).toArray(); // products_category_price
db.products.find({ sku: 'P-000001' }).toArray();                             // sku_1
db.users.find({ email: 'nobody@example.com' }).toArray();                    // email_1
db.categories.find({ slug: 'electronics-1' }).toArray();                     // slug_1
db.warehouses.find({ code: 'WH-001' }).toArray();                            // code_1
db.product_variants.find({ sku: 'V-0000001' }).toArray();                    // sku_1
db.inventory.find({ variant_id: 1, warehouse_id: 1 }).toArray();             // variant_id_1_warehouse_id_1

db.orders.find({ status: 'cancelled', total: { $gt: 100 } }).toArray();      // orders_cancelled_total_partial
db.events.find({ 'payload.v': 5 }).limit(20).toArray();                      // events_payload_wildcard
db.reviews.find({ $text: { $search: 'value' } }).limit(20).toArray();        // reviews_body_text

const aSession = db.user_sessions.findOne({}, { userId: 1 });
if (aSession) db.user_sessions.find({ userId: aSession.userId }).toArray();  // user_sessions_userId_hashed
db.user_sessions.find({ expiresAt: { $gt: new Date() } }).toArray();         // user_sessions_ttl

db.stores.find({                                                             // stores_location_2dsphere
  location: { $near: { $geometry: { type: 'Point', coordinates: [105.8342, 21.0278] }, $maxDistance: 200000 } },
}).toArray();

db.attachments.files.find({ filename: 'welcome.txt' }).toArray();            // filename_1
db.avatars.files.find({ filename: 'default.png' }).toArray();                // filename_1

// Index chunk của bucket `avatars`: chỉ được đụng tới khi thực sự tải file khỏi
// bucket đó. `attachments.chunks` thì đã có sẵn ops>0 do quá trình insert kiểm
// tra ràng buộc unique, còn `avatars` chỉ có 2 file nên vẫn ở 0 — mà một index
// ops=0 ngoài dự kiến sẽ làm loãng đúng cái tương phản "used vs unused" mà seed
// dựng ra. Đọc thử 1 file để đưa nó về trạng thái "đã dùng".
const anAvatar = db.avatars.files.findOne({}, { _id: 1 });
if (anAvatar) db.avatars.chunks.find({ files_id: anAvatar._id, n: 0 }).toArray();

// Đếm index ops=0 trên toàn DB (bỏ _id_ và collection rỗng archived_orders).
// Kỳ vọng ĐÚNG 2: stores_tags_unused (ví dụ "unused" chủ đích) và
// articles_views_hidden (index ẩn — planner không bao giờ chọn).
// Lưu ý: accesses.ops là Long nên phải Number() trước khi so sánh với 0.
const zero = [];
db.getCollectionInfos({ type: 'collection' }).forEach((c) => {
  if (c.name.startsWith('system.') || c.name === 'archived_orders') return;
  try {
    db[c.name].aggregate([{ $indexStats: {} }]).toArray().forEach((i) => {
      if (i.name !== '_id_' && Number(i.accesses.ops) === 0) zero.push(c.name + '.' + i.name);
    });
  } catch (e) { /* view không hỗ trợ $indexStats */ }
});
print('03-warmup.js: done — profiler level 1 (slowms 100), system.profile=' +
  db.system.profile.countDocuments() + ' entries; index còn ops=0: ' + zero.length +
  ' [' + zero.sort().join(', ') + '] (kỳ vọng đúng 2).');
