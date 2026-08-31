// ============================================================================
//  MongoDB — Câu truy vấn DEMO (chạy trên dữ liệu mẫu jdb_dev)
//  Copy từng câu vào SQL/Mongo Editor rồi chạy. Hầu hết chỉ ĐỌC (an toàn).
// ============================================================================

// 1) Cơ bản: người dùng mới nhất
db.users.find({}, { email: 1, full_name: 1, status: 1, created_at: 1 })
  .sort({ created_at: -1 })
  .limit(10);

// 2) Lọc theo trạng thái
db.users.find({ status: "active" }, { email: 1, status: 1 }).limit(20);

// 3) Đếm người dùng theo trạng thái ($group)
db.users.aggregate([
  { $group: { _id: "$status", total: { $sum: 1 } } },
  { $sort: { total: -1 } },
]);

// 4) $lookup: đơn hàng kèm email khách (tương đương JOIN)
db.orders.aggregate([
  { $sort: { created_at: -1 } },
  { $limit: 15 },
  { $lookup: { from: "users", localField: "user_id", foreignField: "_id", as: "user" } },
  { $unwind: "$user" },
  { $project: { _id: 1, "user.email": 1, status: 1, total: 1, created_at: 1 } },
]);

// 5) Doanh thu theo tháng
db.orders.aggregate([
  { $group: { _id: { $dateToString: { format: "%Y-%m", date: "$created_at" } }, orders: { $sum: 1 }, revenue: { $sum: "$total" } } },
  { $sort: { _id: -1 } },
]);

// 6) Top khách chi tiêu nhiều nhất
db.orders.aggregate([
  { $group: { _id: "$user_id", orders: { $sum: 1 }, spent: { $sum: "$total" } } },
  { $sort: { spent: -1 } },
  { $limit: 10 },
  { $lookup: { from: "users", localField: "_id", foreignField: "_id", as: "user" } },
  { $unwind: "$user" },
  { $project: { email: "$user.email", orders: 1, spent: 1 } },
]);

// 7) $setWindowFields: xếp hạng sản phẩm theo giá trong danh mục (MongoDB 5+)
db.products.aggregate([
  { $setWindowFields: { partitionBy: "$category_id", sortBy: { price: -1 }, output: { price_rank: { $rank: {} } } } },
  { $sort: { category_id: 1, price_rank: 1 } },
  { $limit: 30 },
]);

// 8) Người dùng chưa có đơn hàng nào ($lookup + $match rỗng)
db.users.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "user_id", as: "orders" } },
  { $match: { orders: { $size: 0 } } },
  { $project: { email: 1 } },
  { $limit: 20 },
]);

// 9) Điểm đánh giá trung bình theo sản phẩm
db.reviews.aggregate([
  { $group: { _id: "$product_id", avg_rating: { $avg: "$rating" }, reviews: { $sum: 1 } } },
  { $sort: { avg_rating: -1 } },
  { $limit: 15 },
]);

// 10) Document lồng nhau: sự kiện có payload dạng object (không phải chuỗi JSON)
db.events.find({ "payload.v": { $gt: 5 } }, { kind: 1, payload: 1 }).limit(10);

// 11) Đếm document theo collection (kiểm tra sau khi seed).
//     Bỏ qua `system.*` (root user cũng không được aggregate trên system.views)
//     và bỏ qua view (countDocuments trên view chạy được nhưng chậm và không phải
//     thứ ta muốn đếm ở đây).
db.getCollectionInfos({ type: "collection" })
  .filter((c) => !c.name.startsWith("system."))
  .forEach((c) => print(c.name + ": " + db[c.name].countDocuments()));

// ---- Ví dụ GHI (bỏ comment để chạy, KHÔNG an toàn nếu chạy nhiều lần) ----

// db.users.updateOne({ _id: 1 }, { $set: { status: "blocked" } });
// db.carts.deleteMany({ status: "abandoned" });

// ============================================================================
//  Bên dưới: demo riêng cho dữ liệu bổ sung ở 02-features.js
// ============================================================================

// 12) $text search — cần index text trên reviews.body (02-features.js đã tạo)
db.reviews.find({ $text: { $search: "great value" } }, { score: { $meta: "textScore" }, body: 1 })
  .sort({ score: { $meta: "textScore" } })
  .limit(10);

// 13) Geospatial — cửa hàng trong bán kính ~50km quanh 1 điểm (2dsphere)
db.stores.find({
  location: { $near: { $geometry: { type: "Point", coordinates: [105.8342, 21.0278] }, $maxDistance: 50000 } },
});

// 14) $graphLookup — cây danh mục đầy đủ (categories.parent_id đã có sẵn từ 01-seed.js)
db.categories.aggregate([
  { $match: { parent_id: null } },
  { $graphLookup: { from: "categories", startWith: "$_id", connectFromField: "_id", connectToField: "parent_id", as: "descendants" } },
  { $project: { name: 1, descendantCount: { $size: "$descendants" } } },
  { $sort: { descendantCount: -1 } },
]);

// 15) Đọc qua VIEW (v_order_summary — db.createView ở 02-features.js)
db.v_order_summary.find().limit(10);

// 16) Reference Map: xem cạnh tham chiếu "gãy một phần" (comments trỏ tới bài không tồn tại)
db.comments.aggregate([
  { $lookup: { from: "articles", localField: "articleId", foreignField: "_id", as: "a" } },
  { $match: { "a.0": { $exists: false } } },
  { $count: "brokenReferences" },
]);

// 17) Time-series — nhiệt độ trung bình theo kho, theo giờ (sensor_readings)
db.sensor_readings.aggregate([
  { $group: { _id: { sensor: "$meta.sensor", hour: { $dateTrunc: { date: "$ts", unit: "hour" } } }, avgValue: { $avg: "$value" } } },
  { $sort: { "_id.hour": -1 } },
  { $limit: 20 },
]);

// 18) GridFS — liệt kê file trong bucket "attachments" (giống Vault panel)
db.attachments.files.find({}, { filename: 1, length: 1, uploadDate: 1, metadata: 1 });

// 19) Validator dry-run thủ công — đếm document vi phạm $jsonSchema hiện tại của subscriptions
//     (tương đương nút "Test" trong ValidationPanel của JiveDB)
db.runCommand({
  find: "subscriptions",
  filter: { $nor: [{ $jsonSchema: db.getCollectionInfos({ name: "subscriptions" })[0].options.validator.$jsonSchema }] },
});

// 20) BSON kitchen sink — xem các document minh hoạ mọi kiểu BSON.
//     Lọc bỏ 2 document clipping (chúng nặng vài MiB) cho gọn màn hình.
db.bson_type_gallery.find({ label: { $not: /^clipping/ } });

// 21) Query X-Ray — truy vấn CỐ Ý TỆ để bật gợi ý index.
//     Điều kiện kích hoạt (driver/mongoexplain.go): COLLSCAN, HOẶC
//     docsExamined > 20 && docsExamined >= nReturned*10, HOẶC sort trong bộ nhớ.
//     Câu dưới đây dính cả ba: `status` không có index (COLLSCAN), `total` sắp xếp
//     trong bộ nhớ. Chạy rồi bấm "Explain" → IndexAdvisor đề xuất theo thứ tự ESR.
//     So sánh với câu ngay sau đó (có index, IXSCAN xanh, không có gợi ý nào).
db.orders.find({ status: "cancelled" }).sort({ total: -1 }).limit(20);
db.products.find({ category_id: 5 }).sort({ price: -1 }).limit(20); // đã có index → IXSCAN

// 22) Shape Lens showcase — 4 shape với tỉ lệ biết trước (~70/20/7/3%).
//     Mở collection này rồi xem thanh Shape Lens: shape trội, 1 shape "+ added"
//     (coupon/discount), 1 shape "~ retyped" (total: decimal → double), 1 shape
//     legacy dưới 10% nên có vòng amber.
db.order_snapshots.find().limit(25);
db.order_snapshots.aggregate([                    // đếm thực tế từng shape
  // Dùng $type ... == "missing" để phân biệt FIELD VẮNG MẶT. Không dùng
  // { $ne: ["$coupon", null] }: với field vắng mặt biểu thức đó vẫn trả về true,
  // nên mọi document đều bị gom nhầm vào nhóm "có coupon".
  {
    $group: {
      _id: {
        hasCoupon: { $ne: [{ $type: "$coupon" }, "missing"] },
        totalType: { $type: "$total" },
        legacy: { $ne: [{ $type: "$customerName" }, "missing"] },
      },
      n: { $sum: 1 },
    },
  },
  { $sort: { n: -1 } },
]);

// 23) Field polymorphic — `value` xoay vòng qua 6 kiểu BSON
db.metric_samples.aggregate([
  { $group: { _id: { $type: "$value" }, n: { $sum: 1 } } },
  { $sort: { n: -1 } },
]);

// 24) _id kiểu compound (embedded document) — lọc theo _id không phải giá trị vô hướng
db.inventory_ledger.find({ "_id.warehouse": "WH-001" }).limit(10);
db.inventory_ledger.find({ _id: { sku: "P-000001", warehouse: "WH-001" } });

// 25) Reference Map — cạnh tham chiếu bằng CHUỖI (user_sessions.feature_flag_id
//     → feature_flags._id, vốn cũng là chuỗi). Khác với 2 cạnh ObjectId ở mục 16.
db.user_sessions.aggregate([
  { $lookup: { from: "feature_flags", localField: "feature_flag_id", foreignField: "_id", as: "flag" } },
  { $unwind: "$flag" },
  { $project: { feature_flag_id: 1, "flag.enabled": 1, "flag.rolloutPercent": 1 } },
  { $limit: 10 },
]);

// 26) Clipping — 2 document vượt ngưỡng 2 MiB theo 2 cách khác nhau.
//     Mở từng cái trong JiveDB để thấy marker $jdbClipped + nút "load full document",
//     và badge "clipped" trên ResultBar.
db.bson_type_gallery.find({ label: /^clipping/ }, { label: 1, note: 1 });

// 27) GridFS — 2 bucket, file đa chunk, và >50 file để lộ phân trang
db.attachments.files.aggregate([
  { $lookup: { from: "attachments.chunks", localField: "_id", foreignField: "files_id", as: "c" } },
  { $project: { filename: 1, length: 1, chunkSize: 1, chunks: { $size: "$c" } } },
  { $sort: { length: -1 } },
  { $limit: 5 },
]);
db.avatars.files.find({}, { filename: 1, length: 1, metadata: 1 });

// 28) Collection RỖNG — trạng thái empty của Find / Shape Lens / Overview
db.archived_orders.find();
db.archived_orders.countDocuments();

// 29) Validator strict/error — KHÁC với subscriptions (moderate/warn).
//     Bỏ comment dòng dưới để thấy server TỪ CHỐI thật (không chỉ cảnh báo):
// db.payment_methods.insertOne({ userId: 1, brand: "diners", last4: "12", expiresAt: new Date() });
db.getCollectionInfos({ name: "payment_methods" })[0].options;

// 30) Profiler — 03-warmup.js đã bật mức 1 và nạp sẵn dữ liệu vào system.profile
db.getProfilingStatus();
db.system.profile.find({}, { op: 1, ns: 1, millis: 1, planSummary: 1, docsExamined: 1, nreturned: 1 })
  .sort({ millis: -1 })
  .limit(10);

// 31) Index usage — index nào đã dùng, index nào chưa (cờ "unused")
//     stores_tags_unused và articles_views_hidden phải luôn ở ops = 0.
["stores", "products", "authors", "user_sessions", "articles"].forEach((c) => {
  db[c].aggregate([{ $indexStats: {} }]).toArray()
    .forEach((i) => print(c + "." + i.name + "  ops=" + i.accesses.ops));
});
