// MongoDB — bổ sung dữ liệu/cấu trúc để bao phủ MỌI tính năng MongoDB mà JiveDB hỗ
// trợ, ngoài bộ 16 collection thương mại điện tử của 01-seed.js. Khác với 01-seed.js
// (sinh tự động từ generate.mjs), FILE NÀY VIẾT TAY — có thể sửa trực tiếp.
//
// Chạy sau 01-seed.js (Docker nạp *.js theo thứ tự tên file), và không đụng tới 16
// collection của 01-seed.js (chỉ thêm index mới, không đổi dữ liệu) trừ khi ghi chú
// rõ là "additive". Xem README.md trong thư mục này để biết từng phần bên dưới ứng
// với tính năng nào của JiveDB.
db = db.getSiblingDB('jdb_dev');

// ── RNG có seed — lặp lại kết quả giống nhau mỗi lần chạy, cùng tinh thần với
//    generate.mjs (dùng cho phần dữ liệu viết tay bên dưới, không ảnh hưởng 01-seed.js).
function mulberry32(a) {
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rng = mulberry32(20260830);
const pick = (arr) => arr[Math.floor(rng() * arr.length)];
const randInt = (min, max) => min + Math.floor(rng() * (max - min + 1));
const randFloat = (min, max, digits = 2) => Number((min + rng() * (max - min)).toFixed(digits));

// ids thật của 01-seed.js, lấy tại thời điểm chạy (không phụ thuộc số lượng chính xác).
const userIds = db.users.find({}, { _id: 1 }).limit(3000).toArray().map((d) => d._id);
// `code` cần cho _id compound của inventory_ledger (mục 15) — thiếu nó thì rơi
// vào nhánh dự phòng và mã kho không khớp với collection `warehouses`.
const warehouseDocs = db.warehouses.find({}, { _id: 1, city: 1, code: 1 }).toArray();

// ============================================================================
// 1) INDEX BỔ SUNG trên collection CÓ SẴN — additive, không đổi dữ liệu.
//    Bao phủ: text, compound (mixed direction), partial, wildcard.
//    (unique đã có sẵn ở 01-seed.js; xem thêm hashed/2dsphere/TTL/sparse ở các
//    collection mới bên dưới.)
// ============================================================================
db.reviews.createIndex({ body: 'text' }, { name: 'reviews_body_text' });
db.products.createIndex({ category_id: 1, price: -1 }, { name: 'products_category_price' });
db.orders.createIndex(
  { total: 1 },
  { name: 'orders_cancelled_total_partial', partialFilterExpression: { status: 'cancelled' } },
);
// events.payload là object lồng nhau tự do (xem 01-seed.js) — ứng viên lý tưởng cho wildcard index.
db.events.createIndex({ 'payload.$**': 1 }, { name: 'events_payload_wildcard' });

// ============================================================================
// 2) GEOSPATIAL — collection `stores`: GeoJSON Point + index 2dsphere.
//    Dùng lại tên thành phố của warehouses (01-seed.js) cho nhất quán chủ đề.
// ============================================================================
const CITY_COORDS = {
  Ghent: [3.7174, 51.0543],
  Austin: [-97.7431, 30.2672],
  Berlin: [13.405, 52.52],
  'Can Tho': [105.7469, 10.0452],
  Cebu: [123.8854, 10.3157],
  'Da Nang': [108.2022, 16.0544],
  Hanoi: [105.8342, 21.0278],
  Hue: [107.5906, 16.4637],
  Leeds: [-1.5491, 53.8008],
  Lyon: [4.8357, 45.764],
  Osaka: [135.5023, 34.6937],
  Porto: [-8.6291, 41.1579],
  Pune: [73.8567, 18.5204],
  Saigon: [106.6297, 10.8231],
  Turin: [7.6869, 45.0703],
};
const STORE_TAGS = ['flagship', 'outlet', 'pickup-point', 'pop-up', 'warehouse-front'];

db.stores.drop();
db.stores.insertMany(
  Object.keys(CITY_COORDS).map((city, i) => {
    const [lng, lat] = CITY_COORDS[city];
    return {
      name: `${city} Store #${i + 1}`,
      city,
      location: { type: 'Point', coordinates: [lng + randFloat(-0.05, 0.05, 4), lat + randFloat(-0.05, 0.05, 4)] },
      tags: [pick(STORE_TAGS), pick(STORE_TAGS)].filter((v, idx, a) => a.indexOf(v) === idx),
      openedAt: new Date(Date.now() - randInt(30, 2000) * 86400000),
    };
  }),
);
db.stores.createIndex({ location: '2dsphere' }, { name: 'stores_location_2dsphere' });
// Cố ý KHÔNG dùng trong queries.js — minh hoạ cờ "unused index" trong Indexes panel.
db.stores.createIndex({ tags: 1 }, { name: 'stores_tags_unused' });

// ============================================================================
// 3) ĐỒ THỊ THAM CHIẾU BẰNG ObjectId — authors → articles → comments.
//    01-seed.js chỉ dùng _id kiểu int nên Reference Map chưa từng thấy tham chiếu
//    ObjectId thật. Bộ 3 collection này bao phủ:
//    - articles.writer  → authors  : tên field KHÔNG gợi ý (không có hậu tố Id/Ref)
//                                     → bắt buộc đi qua nhánh "thử mọi collection".
//    - comments.articleId → articles: tên field có hậu tố rõ ràng, nhưng ~50% trỏ
//                                     tới id KHÔNG tồn tại → tham chiếu "gãy một phần"
//                                     (confidence < 60%, KHÔNG đạt "Verified" —
//                                     tương phản với articles.writer gần như 100%).
//    - articles.relatedArticleIds  : mảng ObjectId tự tham chiếu (one-to-many).
// ============================================================================
db.authors.drop();
db.articles.drop();
db.comments.drop();

const AUTHOR_NAMES = [
  'Ava Nguyen', 'Kai Tran', 'Mia Le', 'Noah Pham', 'Zoe Vu', 'Leo Bui', 'Ivy Do',
  'Finn Hoang', 'Luna Dang', 'Theo Ly', 'Nora Vo', 'Remy Duong', 'Sky Ha', 'Jude Mai', 'Ela Trinh',
];
const authors = AUTHOR_NAMES.map((name, i) => ({
  _id: ObjectId(),
  name,
  email: `${name.toLowerCase().replace(/\s+/g, '.')}@writers.example.com`,
  bio: `${name} writes about databases, distributed systems, and the occasional cooking disaster.`,
  joinedAt: new Date(Date.now() - randInt(200, 3000) * 86400000),
  // field tuỳ chọn — chỉ 2 tác giả có, dùng để minh hoạ sparse index bên dưới.
  ...(i < 2 ? { deceasedAt: new Date(Date.now() - randInt(10, 1000) * 86400000) } : {}),
}));
db.authors.insertMany(authors);
db.authors.createIndex({ email: 1 }, { unique: true, name: 'authors_email_unique' });
db.authors.createIndex({ deceasedAt: 1 }, { sparse: true, name: 'authors_deceasedAt_sparse' });

const ARTICLE_TOPICS = [
  'Indexing strategies for time-series data', 'A tour of BSON types', 'When to reach for a view',
  'Change streams in practice', 'Schema drift and how to spot it', 'GridFS vs. object storage',
  'Aggregation pipelines that read like prose', 'Capped collections as a ring buffer',
  'Reference mapping without foreign keys', 'Sharding 101', 'The cost of an unused index',
  'Validators as living documentation', 'Geospatial queries for store locators', 'Text search, plainly',
  'Explain plans, decoded',
];
const articles = [];
for (let i = 0; i < 60; i++) {
  articles.push({
    _id: ObjectId(),
    title: `${pick(ARTICLE_TOPICS)} (part ${randInt(1, 9)})`,
    writer: pick(authors)._id, // tên field không gợi ý — test nhánh suy luận "thử mọi collection"
    tags: [pick(['mongodb', 'indexing', 'schema', 'ops', 'howto']), pick(['beginner', 'advanced'])],
    publishedAt: new Date(Date.now() - randInt(1, 900) * 86400000),
    views: randInt(0, 50000),
  });
}
// Thêm relatedArticleIds SAU khi đã có đủ _id để tham chiếu chéo (mảng ObjectId one-to-many).
for (const a of articles) {
  const others = articles.filter((o) => o._id !== a._id);
  const n = randInt(0, 3);
  a.relatedArticleIds = Array.from({ length: n }, () => pick(others)._id);
}
db.articles.insertMany(articles);

// Index ẩn — index vẫn tồn tại nhưng query planner bỏ qua hoàn toàn. Trong
// IndexesPanel, "hidden" (chip amber) là cờ DUY NHẤT chưa từng có ví dụ seed sẵn:
// các cờ unique/sparse/ttl/kind đều đã có, nên mở panel lên là thấy đủ bộ chip.
db.articles.createIndex({ views: -1 }, { name: 'articles_views_hidden' });
db.runCommand({ collMod: 'articles', index: { name: 'articles_views_hidden', hidden: true } });

const comments = [];
for (let i = 0; i < 220; i++) {
  // ~50% cố ý trỏ tới bài KHÔNG tồn tại — đủ để kéo confidence của cạnh tham chiếu
  // này xuống dưới ngưỡng "Verified" (refMinConfidence = 0.6 trong mongorefs.go),
  // tương phản với cạnh articles.writer → authors gần như 100% ở trên.
  const useRealArticle = rng() > 0.5;
  comments.push({
    _id: ObjectId(),
    articleId: useRealArticle ? pick(articles)._id : ObjectId(),
    body: pick([
      'Great write-up, this saved me an afternoon of debugging.',
      'Could you expand on the trade-offs vs. a compound index here?',
      'We hit this exact issue in production last month.',
      'Nice — bookmarking this for the next schema review.',
      'Minor nit: the example pipeline is missing a $match up front.',
    ]),
    createdAt: new Date(Date.now() - randInt(1, 700) * 86400000),
  });
}
db.comments.insertMany(comments);

// _id của feature_flags (mục 5 bên dưới là nguồn sự thật — danh sách này phải
// khớp). Khai báo sớm để user_sessions tham chiếu được bằng CHUỖI, xem ghi chú
// `feature_flag_id` ngay dưới.
const FLAG_IDS = [
  'new-checkout-flow', 'gridfs-vault-ui', 'ai-review-summaries', 'dark-mode-v2',
  'graphql-gateway', 'store-locator', 'sms-2fa', 'legacy-export-csv',
];

// ============================================================================
// 4) TTL + HASHED — collection `user_sessions`.
//    Đồng thời phủ nhánh THAM CHIẾU BẰNG CHUỖI của Reference Map: mongorefs.go
//    chỉ xét id kiểu int/string khi tên field có hậu tố FK (hasRefSuffix), rồi
//    guessTarget suy ra collection đích. `feature_flag_id` → bỏ `_id` → số nhiều
//    `feature_flags`, và giá trị là _id CHUỖI thật của collection đó
//    (refValue.kind == 's'). Trước đây mọi cạnh tham chiếu trong seed đều là
//    ObjectId hoặc int, nên nhánh chuỗi chưa từng được chạm tới.
// ============================================================================
db.user_sessions.drop();
const sessions = [];
for (let i = 0; i < 60; i++) {
  const createdAt = new Date(Date.now() - randInt(0, 20) * 3600000);
  // ~15% đã hết hạn trong quá khứ — minh hoạ TTL sẽ dọn các phiên này.
  const expiresAt = rng() < 0.15
    ? new Date(Date.now() - randInt(1, 48) * 3600000)
    : new Date(Date.now() + randInt(1, 72) * 3600000);
  sessions.push({
    _id: ObjectId(),
    userId: pick(userIds),
    token: `sess_${ObjectId().toHexString()}`,
    feature_flag_id: pick(FLAG_IDS),
    createdAt,
    expiresAt,
  });
}
db.user_sessions.insertMany(sessions);
db.user_sessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0, name: 'user_sessions_ttl' });
db.user_sessions.createIndex({ userId: 'hashed' }, { name: 'user_sessions_userId_hashed' });

// ============================================================================
// 5) _id KIỂU STRING (không phải ObjectId lẫn int) — collection `feature_flags`.
//    Bao phủ nhánh idFilter nhận _id là giá trị vô hướng bất kỳ kiểu (mongocrud.go).
// ============================================================================
db.feature_flags.drop();
db.feature_flags.insertMany([
  { _id: 'new-checkout-flow', enabled: true, rolloutPercent: 100, updatedAt: new Date(), notes: 'Fully rolled out since last quarter.' },
  { _id: 'gridfs-vault-ui', enabled: true, rolloutPercent: 100, updatedAt: new Date() },
  { _id: 'ai-review-summaries', enabled: false, rolloutPercent: 0, updatedAt: new Date(), notes: 'Waiting on model eval.' },
  { _id: 'dark-mode-v2', enabled: true, rolloutPercent: 50, updatedAt: new Date() },
  { _id: 'graphql-gateway', enabled: false, rolloutPercent: 5, updatedAt: new Date(), notes: 'Internal dogfood only.' },
  { _id: 'store-locator', enabled: true, rolloutPercent: 100, updatedAt: new Date() },
  { _id: 'sms-2fa', enabled: true, rolloutPercent: 80, updatedAt: new Date() },
  { _id: 'legacy-export-csv', enabled: false, rolloutPercent: 0, updatedAt: new Date(), notes: 'Deprecated, pending removal.' },
]);

// ============================================================================
// 6) VALIDATOR ($jsonSchema) áp dụng SAU khi đã có dữ liệu — collection
//    `subscriptions`. MongoDB không kiểm tra lại document cũ khi collMod thêm
//    validator, nên ~10% document "vi phạm" cố ý vẫn còn đó để test dry-run
//    "N valid / M invalid" của ValidationPanel mà không cần bắc cầu quanh nó.
// ============================================================================
db.subscriptions.drop();
const PLANS = ['free', 'pro', 'enterprise'];
const SUB_STATUSES = ['active', 'canceled', 'trialing', 'past_due'];
const subs = [];
for (let i = 0; i < 200; i++) {
  const valid = rng() > 0.1; // ~10% sẽ vi phạm schema áp dụng bên dưới
  const base = {
    _id: ObjectId(),
    userId: pick(userIds),
    plan: pick(PLANS),
    status: pick(SUB_STATUSES),
    startedAt: new Date(Date.now() - randInt(1, 900) * 86400000),
    amount: NumberDecimal(randFloat(9.99, 499.99).toFixed(2)),
    seats: randInt(1, 50),
  };
  if (!valid) {
    // Trộn vài kiểu vi phạm khác nhau để demo đa dạng lỗi.
    switch (randInt(0, 2)) {
      case 0:
        delete base.plan; // thiếu field bắt buộc
        break;
      case 1:
        base.amount = randFloat(9.99, 499.99); // sai kiểu: double thay vì Decimal128
        break;
      default:
        base.seats = 0; // vi phạm minimum
    }
  }
  subs.push(base);
}
db.subscriptions.insertMany(subs);
db.runCommand({
  collMod: 'subscriptions',
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['userId', 'plan', 'status', 'startedAt', 'amount', 'seats'],
      properties: {
        plan: { enum: PLANS },
        status: { enum: SUB_STATUSES },
        amount: { bsonType: 'decimal' },
        seats: { bsonType: 'int', minimum: 1 },
      },
    },
  },
  // "moderate": chỉ áp cho document mới/được sửa — không chạm vào các document cũ
  // (vốn đã cố ý có ~10% vi phạm ở trên) nên chúng không bị kẹt lại.
  validationLevel: 'moderate',
  validationAction: 'warn',
});

// ============================================================================
// 7) CAPPED COLLECTION — `activity_ring_buffer`. Chèn nhiều hơn `max` để chứng
//    minh hành vi ghi đè tài liệu cũ nhất (ring buffer thật, không chỉ set cờ).
// ============================================================================
db.activity_ring_buffer.drop();
db.createCollection('activity_ring_buffer', { capped: true, size: 5 * 1024 * 1024, max: 300 });
const ACTIONS = ['login', 'logout', 'search', 'add_to_cart', 'checkout', 'password_reset'];
const activityDocs = [];
for (let i = 0; i < 400; i++) {
  activityDocs.push({
    at: new Date(Date.now() - (400 - i) * 60000),
    actorUserId: pick(userIds),
    action: pick(ACTIONS),
    meta: { ip: `10.0.${randInt(0, 255)}.${randInt(0, 255)}` },
  });
}
db.activity_ring_buffer.insertMany(activityDocs);

// ============================================================================
// 8) TIME-SERIES COLLECTION — `sensor_readings` (nhiệt độ theo kho, 3 ngày, mỗi
//    10 phút). Có schema drift cố ý: field `unit` chỉ xuất hiện ở dữ liệu gần đây
//    (thêm sau), và ~1% document có `value` bị lưu nhầm thành string — để Shape
//    Lens có cả nhóm "added field" lẫn "retyped field" để phát hiện.
// ============================================================================
db.sensor_readings.drop();
db.createCollection('sensor_readings', {
  timeseries: { timeField: 'ts', metaField: 'meta', granularity: 'minutes' },
});
const START = Date.now() - 3 * 86400000;
const STEP_MS = 10 * 60000;
const POINTS_PER_SENSOR = Math.floor((3 * 86400000) / STEP_MS);
const UNIT_INTRODUCED_AT_POINT = Math.floor(POINTS_PER_SENSOR * 0.8); // 20% gần nhất mới có `unit`
const readings = [];
for (const wh of warehouseDocs) {
  let value = randFloat(18, 24);
  for (let p = 0; p < POINTS_PER_SENSOR; p++) {
    value = Math.max(15, Math.min(30, value + randFloat(-0.6, 0.6)));
    const doc = {
      ts: new Date(START + p * STEP_MS),
      meta: { warehouseId: wh._id, sensor: `${wh.city}-temp` },
      value: rng() < 0.01 ? value.toFixed(1) : Number(value.toFixed(1)), // ~1% retype drift
    };
    if (p >= UNIT_INTRODUCED_AT_POINT) doc.unit = 'C'; // field thêm sau — drift kiểu "added"
    readings.push(doc);
  }
}
// insertMany theo lô để tránh một batch quá lớn.
for (let i = 0; i < readings.length; i += 1000) {
  db.sensor_readings.insertMany(readings.slice(i, i + 1000));
}

// ============================================================================
// 9) VIEWS — kind "view" (db.createView không có UI tương ứng trong JiveDB nên
//    phải seed sẵn). Đặt tên theo phong cách v_* giống các view SQL song song.
// ============================================================================
db.v_order_summary.drop();
db.createView('v_order_summary', 'orders', [
  { $lookup: { from: 'users', localField: 'user_id', foreignField: '_id', as: 'user' } },
  { $unwind: '$user' },
  { $project: { _id: 1, status: 1, total: 1, created_at: 1, customerEmail: '$user.email' } },
]);

db.v_category_tree.drop();
db.createView('v_category_tree', 'categories', [
  {
    $lookup: {
      from: 'categories',
      localField: 'parent_id',
      foreignField: '_id',
      as: 'parent',
    },
  },
  { $unwind: { path: '$parent', preserveNullAndEmptyArrays: true } },
  { $project: { _id: 1, name: 1, slug: 1, parentName: '$parent.name' } },
]);

// ============================================================================
// 10) BSON "KITCHEN SINK" — collection `bson_type_gallery`: mỗi document minh
//     hoạ một nhóm kiểu BSON mà BsonValueView/BsonValueEditor hỗ trợ, cộng thêm
//     2 document chuyên để kích hoạt cơ chế cắt bớt (clipping) — xem ghi chú
//     "NGƯỠNG CLIPPING" bên dưới.
//
//     Không seed: Symbol, DBPointer, Undefined — Undefined bị mongosh ghi thành
//     `null` (kiểm chứng bằng $type), còn Symbol/DBPointer đã deprecated và không
//     có cách dựng hợp lệ bằng shell. Đây là giới hạn của shell, KHÔNG phải
//     JiveDB thiếu hỗ trợ hiển thị. Ngược lại `Code(fn, scope)` CÓ tạo ra
//     javascriptWithScope thật (đã kiểm chứng bằng $type) nên có seed bên dưới.
//     DBRef không phải kiểu BSON (chỉ là quy ước tầng ứng dụng) nhưng vẫn seed
//     được qua DBRef(...).
// ============================================================================
db.bson_type_gallery.drop();
const sampleAuthorId = authors[0]._id;
db.bson_type_gallery.insertMany([
  {
    label: 'numeric types',
    aDouble: 3.14159,
    anInt32: NumberInt(42),
    aLong: NumberLong('9223372036854775807'),
    aDecimal: NumberDecimal('19999999999999999999.99'),
    aNaN: NaN,
    anInfinity: Infinity,
  },
  {
    label: 'text & identity',
    aString: 'hello, JiveDB',
    anObjectId: ObjectId(),
  },
  {
    label: 'temporal & logical (has explicit null)',
    aDate: ISODate('2026-01-15T10:00:00Z'),
    aTimestamp: Timestamp(1700000000, 1),
    aBool: true,
    aNullField: null,
    // Không có `anOmittedField` ở đây — so sánh với chip "missing" (field vắng mặt)
    // khác với chip "null" (field có mặt, giá trị null) khi xem trong BSON viewer.
  },
  {
    label: 'binary, regex, code, uuid',
    aBinaryGeneric: BinData(0, Buffer.from('Hello JiveDB').toString('base64')),
    aUUID: UUID(),
    aRegex: /^prod-\d+$/i,
    aCode: Code('function(x) { return x * 2; }'),
    // Code 2 tham số → BSON javascriptWithScope (0x0F), khác với aCode ở trên
    // (javascript 0x0D). Cả backend (bsonTypeName) lẫn BsonValueView đều có nhánh
    // riêng cho kiểu này.
    aCodeWithScope: Code('function(x) { return x * multiplier; }', { multiplier: 2 }),
  },
  {
    label: 'structural',
    anArray: [1, 'two', 3.0, { four: 4 }],
    anObject: { nested: { deeper: { value: '3 levels' } } },
    arrayOfObjectIds: [ObjectId(), ObjectId(), ObjectId()],
  },
  {
    label: 'bounds & DBRef',
    aMinKey: MinKey(),
    aMaxKey: MaxKey(),
    aDbRef: DBRef('authors', sampleAuthorId),
  },
]);

// ── NGƯỠNG CLIPPING (driver/ejson.go) ────────────────────────────────────────
// documentToEJSON kiểm tra kích thước EJSON của TOÀN document trước:
//     if len(full) <= maxDocEJSONBytes { return full, false, nil }   // 2 MiB
// Chỉ khi vượt 2 MiB nó mới cắt từng field vượt clipFieldBytes (256 KiB) thành
// marker {"$jdbClipped":{...}}. Nghĩa là một document ~300 KiB (dù có field to
// hơn 256 KiB) KHÔNG BAO GIỜ bị cắt — phải vượt ngưỡng ngoài 2 MiB trước.
// Vì vậy cần 2 document riêng để phủ cả hai pass của thuật toán:
const MIB = 1024 * 1024;

// Pass 1 — "một field khổng lồ": tổng > 2 MiB và bản thân field > 256 KiB nên bị
// thay bằng marker ngay ở lượt quét đầu.
db.bson_type_gallery.insertOne({
  label: 'clipping pass 1 — single huge field (~2.4 MiB)',
  note: 'Field bigBlob vượt cả 2 ngưỡng → bị thay bằng $jdbClipped ngay pass đầu.',
  bigBlob: 'x'.repeat(Math.floor(2.4 * MIB)),
});

// Pass 2 — "nhiều field cỡ vừa": mỗi field ~200 KiB (DƯỚI ngưỡng 256 KiB nên pass
// 1 không đụng tới), nhưng 12 field cộng lại ~2.4 MiB > 2 MiB → pass 2 buộc phải
// cắt dần các field lớn nhất cho tới khi vừa. Đây là nhánh mà một document
// "một field to" không bao giờ chạm tới.
const midDoc = {
  label: 'clipping pass 2 — many mid-sized fields (12 x ~200 KiB)',
  note: 'Mỗi field dưới 256 KiB nên pass 1 bỏ qua; tổng vượt 2 MiB nên pass 2 cắt dần.',
};
for (let i = 1; i <= 12; i++) midDoc['chunk' + String(i).padStart(2, '0')] = 'y'.repeat(200 * 1024);
db.bson_type_gallery.insertOne(midDoc);

// ============================================================================
// 11) GRIDFS — bucket `attachments` với vài file nhỏ + metadata tuỳ biến.
//     mongosh không có API GridFSBucket cấp cao như driver Go/Node, nên ghi trực
//     tiếp theo đúng lược đồ chuẩn GridFS: "<bucket>.files" + "<bucket>.chunks".
// ============================================================================
const GRIDFS_CHUNK = 261120; // mặc định của GridFS (255 KiB)

// Ghi file theo đúng lược đồ GridFS, CHIA NHIỀU CHUNK khi cần — bản trước luôn
// ghi đúng 1 chunk nên nhánh ghép chunk trong DownloadToStream không bao giờ chạy.
function seedGridFSFile(bucket, filename, content, metadata, chunkSize) {
  const data = Buffer.isBuffer(content) ? content : Buffer.from(content, 'utf8');
  const cs = chunkSize || GRIDFS_CHUNK;
  const fileId = ObjectId();
  db.getCollection(bucket + '.files').insertOne({
    _id: fileId,
    length: data.length,
    chunkSize: cs,
    uploadDate: new Date(Date.now() - randInt(0, 400) * 86400000),
    filename,
    metadata: metadata || {},
  });
  const chunks = [];
  for (let n = 0, off = 0; off < data.length; n++, off += cs) {
    chunks.push({
      _id: ObjectId(),
      files_id: fileId,
      n,
      data: BinData(0, data.subarray(off, Math.min(off + cs, data.length)).toString('base64')),
    });
  }
  if (chunks.length) db.getCollection(bucket + '.chunks').insertMany(chunks);
  return chunks.length;
}

db.attachments.files.drop();
db.attachments.chunks.drop();
db.avatars.files.drop();
db.avatars.chunks.drop();

seedGridFSFile('attachments', 'welcome.txt', 'Welcome to the JiveDB MongoDB demo dataset.\n', { uploadedBy: pick(userIds), tag: 'readme' });
seedGridFSFile(
  'attachments',
  'store-locations.csv',
  'name,city\n' + db.stores.find({}, { name: 1, city: 1 }).toArray().map((s) => `${s.name},${s.city}`).join('\n') + '\n',
  { uploadedBy: pick(userIds), tag: 'export' },
);
seedGridFSFile(
  'attachments',
  'invoice-notes.md',
  '# Invoice notes\n\n- Net 30 terms for enterprise plans.\n- Refunds processed within 5 business days.\n',
  { uploadedBy: pick(userIds), tag: 'invoice' },
);

// File ĐA CHUNK (~1.4 MiB → 6 chunk). Hai tác dụng: (1) buộc DownloadToStream
// phải ghép nhiều chunk theo thứ tự `n`, (2) cột size trong GridFS Vault mới hiện
// đơn vị MB — trước đây mọi file đều vài trăm byte nên chỉ thấy "B".
const bigCsvRows = ['order_id,user_id,status,total'];
for (let i = 1; i <= 60000; i++) bigCsvRows.push(`${i},${randInt(1, 1500)},${pick(['paid', 'shipped', 'delivered'])},${randFloat(5, 900)}`);
const bigCsv = bigCsvRows.join('\n') + '\n';
const bigChunks = seedGridFSFile('attachments', 'orders-export-2026.csv', bigCsv, { uploadedBy: pick(userIds), tag: 'export', rows: 24000 });

// >50 file để lộ phân trang của GridFS Vault (PAGE_SIZE = 50 — dưới ngưỡng này
// thanh phân trang không render). Sinh bằng vòng lặp nên file seed không phình.
for (let i = 1; i <= 55; i++) {
  seedGridFSFile(
    'attachments',
    `receipts/receipt-${String(i).padStart(4, '0')}.txt`,
    `Receipt #${i}\nIssued: ${new Date(Date.now() - i * 86400000).toISOString()}\nAmount: ${randFloat(10, 999)} USD\n`,
    { uploadedBy: pick(userIds), tag: 'receipt', seq: i },
  );
}

// Bucket THỨ HAI — trước đây chỉ có `attachments` nên dropdown chọn bucket luôn
// có đúng 1 lựa chọn, không bấm được. Dùng PNG 1x1 thật để có file nhị phân
// (không phải text) trong kho.
const PNG_1X1 = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64');
seedGridFSFile('avatars', 'default.png', PNG_1X1, { contentType: 'image/png', tag: 'placeholder' });
seedGridFSFile('avatars', 'team-photo.png', Buffer.concat([PNG_1X1, Buffer.alloc(400 * 1024, 7)]), { contentType: 'image/png', tag: 'profile' });

db.attachments.files.createIndex({ filename: 1 });
db.attachments.chunks.createIndex({ files_id: 1, n: 1 }, { unique: true });
db.avatars.files.createIndex({ filename: 1 });
db.avatars.chunks.createIndex({ files_id: 1, n: 1 }, { unique: true });

// ============================================================================
// 12) SHAPE LENS SHOWCASE — collection `order_snapshots`.
//     Shape Lens là tính năng nhận diện của sản phẩm, nhưng trước đây chỉ được
//     demo GIÁN TIẾP (sensor_readings lệch ~1%, subscriptions thiếu field ~10%).
//     Collection này dựng CÓ CHỦ ĐÍCH 4 shape với tỉ lệ biết trước, mỗi shape
//     nhắm đúng một nhánh hiển thị của ShapeBar/ShapeDetail:
//
//       S1 ~70%  chuẩn          → shape trội (dominant), không có cờ
//       S2 ~20%  + coupon/discount → diff "+ added" (emerald)
//       S3  ~7%  total: Double   → RetypedVsTop ⇒ Drift=true BẤT KỂ coverage,
//                                  diff "~ retyped" (amber): decimal → double
//       S4  ~3%  bản legacy      → coverage < shapeDriftCoverage (0.1) ⇒ vòng
//                                  amber, và diff có cả "+ added" lẫn "− removed"
//
//     Chữ ký shape là tập cặp `path:type`, nên mỗi shape ở đây phải ĐỒNG NHẤT về
//     cả tên field lẫn kiểu — vì vậy `shippedAt` luôn là Date (không để null xen
//     kẽ), nếu không S1 sẽ tự tách đôi và làm hỏng tỉ lệ 70/20/7/3.
//     `total` xuất hiện dưới 2 kiểu (decimal + double) ⇒ cảnh báo polymorphic.
// ============================================================================
db.order_snapshots.drop();
const SNAP_STATUS = ['paid', 'shipped', 'delivered'];
const orderRefIds = db.orders.find({}, { _id: 1 }).limit(400).toArray().map((d) => d._id);
const snapItems = () => Array.from({ length: randInt(1, 4) }, () => ({
  sku: `V-${String(randInt(1, 2500)).padStart(7, '0')}`,
  qty: randInt(1, 5),
  unitPrice: NumberDecimal(randFloat(5, 400).toFixed(2)),
}));
const snapshots = [];
const snapBase = (i) => ({
  _id: ObjectId(),
  orderRef: pick(orderRefIds),
  total: NumberDecimal(randFloat(20, 2000).toFixed(2)),
  items: snapItems(),
  placedAt: new Date(Date.now() - randInt(1, 500) * 86400000),
  status: pick(SNAP_STATUS),
  shippedAt: new Date(Date.now() - randInt(0, 480) * 86400000),
});
for (let i = 0; i < 420; i++) snapshots.push(snapBase(i)); // S1 70%
for (let i = 0; i < 120; i++) {                            // S2 20%
  const d = snapBase(i);
  d.coupon = pick(['WELCOME10', 'FREESHIP', 'VIP20', 'BLACKFRIDAY']);
  d.discount = NumberDecimal(randFloat(1, 50).toFixed(2));
  snapshots.push(d);
}
for (let i = 0; i < 42; i++) {                             // S3 7% — retype drift
  const d = snapBase(i);
  d.total = randFloat(20, 2000); // Double thay vì Decimal128
  snapshots.push(d);
}
for (let i = 0; i < 18; i++) {                             // S4 3% — legacy
  snapshots.push({
    _id: ObjectId(),
    customerName: `${pick(['Ava', 'Kai', 'Mia', 'Noah', 'Zoe'])} ${pick(['Tran', 'Le', 'Pham', 'Vu'])}`,
    total: NumberDecimal(randFloat(20, 2000).toFixed(2)),
    placedAt: new Date(Date.now() - randInt(500, 900) * 86400000),
    status: pick(SNAP_STATUS),
  });
}
db.order_snapshots.insertMany(snapshots);

// ============================================================================
// 13) FIELD POLYMORPHIC MẠNH — collection `metric_samples`.
//     `sensor_readings.value` chỉ lệch sang string ở ~1% document: đủ để bật cờ
//     nhưng rất khó nhìn thấy. Ở đây `value` xoay vòng qua 6 kiểu BSON khác nhau
//     với tỉ lệ đều nhau, nên TypeMixBar của ShapeGrid hiện một dải nhiều màu rõ
//     rệt và ShapeDetail luôn cảnh báo polymorphic.
// ============================================================================
db.metric_samples.drop();
const metricNames = ['queue.depth', 'cache.hit', 'worker.state', 'batch.result', 'shard.tags', 'probe.missing'];
const metricSamples = [];
for (let i = 0; i < 180; i++) {
  const kind = i % 6;
  const value = kind === 0 ? `level-${randInt(1, 9)}`
    : kind === 1 ? NumberInt(randInt(0, 5000))
    : kind === 2 ? (rng() < 0.5)
    : kind === 3 ? { ok: rng() < 0.7, retries: NumberInt(randInt(0, 3)) }
    : kind === 4 ? [pick(['eu', 'us', 'apac']), pick(['hot', 'cold'])]
    : null;
  metricSamples.push({
    _id: ObjectId(),
    metric: metricNames[kind],
    at: new Date(Date.now() - randInt(0, 30) * 86400000),
    value,
  });
}
db.metric_samples.insertMany(metricSamples);

// ============================================================================
// 14) COLLECTION RỖNG — `archived_orders`. Có index và validator nhưng KHÔNG có
//     document nào, để kiểm tra các trạng thái rỗng: Find trả 0 dòng, Shape Lens
//     thoát sớm khi sampled == 0, doc count 0 ở Collection Overview, và pipeline
//     chạy trên đầu vào rỗng. Trước đây mọi collection đều có dữ liệu.
// ============================================================================
db.archived_orders.drop();
db.createCollection('archived_orders', {
  validator: { $jsonSchema: { bsonType: 'object', required: ['orderRef', 'archivedAt'] } },
});
db.archived_orders.createIndex({ archivedAt: -1 }, { name: 'archived_orders_archivedAt' });

// ============================================================================
// 15) _id KIỂU COMPOUND (embedded document) — `inventory_ledger`.
//     PLAN_mongodb.md nêu đây là câu hỏi mở cần xác nhận sớm: "_id types other
//     than ObjectId... string/int/compound... common". Seed đã có int (01-seed)
//     và string (feature_flags); đây là mảnh còn thiếu — buộc idFilter và ô _id
//     bị khoá trong DocEditorDialog phải xử lý _id KHÔNG phải giá trị vô hướng.
// ============================================================================
db.inventory_ledger.drop();
const ledger = [];
for (const wh of warehouseDocs) {
  for (let s = 1; s <= 8; s++) {
    ledger.push({
      _id: { sku: `P-${String(s).padStart(6, '0')}`, warehouse: wh.code || `WH-${wh._id}` },
      onHand: randInt(0, 500),
      reserved: randInt(0, 40),
      countedAt: new Date(Date.now() - randInt(0, 90) * 86400000),
    });
  }
}
db.inventory_ledger.insertMany(ledger);

// ============================================================================
// 16) VALIDATOR strict/error — `payment_methods`.
//     `subscriptions` (mục 6) demo cặp moderate/warn cùng ~10% document vi phạm
//     sẵn có. Ở đây là thái cực còn lại: validator gắn NGAY LÚC TẠO, mức strict +
//     hành động error, toàn bộ document đều hợp lệ. Khi mở ValidationPanel, các ô
//     select nạp đúng strict/error (không phải giá trị mặc định), và mọi insert
//     sai từ UI sẽ bị server TỪ CHỐI thật — chứ không chỉ ghi cảnh báo.
// ============================================================================
db.payment_methods.drop();
db.createCollection('payment_methods', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['userId', 'brand', 'last4', 'expiresAt'],
      properties: {
        brand: { enum: ['visa', 'mastercard', 'amex', 'jcb'] },
        last4: { bsonType: 'string', pattern: '^[0-9]{4}$' },
        isDefault: { bsonType: 'bool' },
      },
    },
  },
  validationLevel: 'strict',
  validationAction: 'error',
});
const methods = [];
for (let i = 0; i < 120; i++) {
  methods.push({
    _id: ObjectId(),
    userId: pick(userIds),
    brand: pick(['visa', 'mastercard', 'amex', 'jcb']),
    last4: String(randInt(1000, 9999)),
    expiresAt: new Date(Date.now() + randInt(30, 1400) * 86400000),
    isDefault: rng() < 0.3,
  });
}
db.payment_methods.insertMany(methods);

print(
  '02-features.js: done — stores, authors/articles/comments (+hidden index), user_sessions (+string ref), ' +
  'feature_flags, subscriptions, activity_ring_buffer, sensor_readings, v_order_summary, v_category_tree, ' +
  'bson_type_gallery (+2 clipping docs, +codeWithScope), attachments/avatars (GridFS, ' + bigChunks + '-chunk file), ' +
  'order_snapshots, metric_samples, archived_orders (empty), inventory_ledger (compound _id), payment_methods seeded.',
);
