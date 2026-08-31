// MongoDB — kiểm tra các BẤT BIẾN của bộ seed. In PASS/FAIL từng mục và
// thoát với mã khác 0 nếu có mục hỏng (dùng được trong CI / `make verify-mongo`).
//
// VÌ SAO CẦN FILE NÀY: phần lớn giá trị của bộ seed nằm ở chỗ dữ liệu được canh
// đúng NGƯỠNG của ứng dụng — ví dụ document phải vượt 2 MiB thì cơ chế clipping
// mới chạy, hay phải có đúng 2 index không được dùng thì cờ "unused" mới có ý
// nghĩa tương phản. Những thứ đó KHÔNG hỏng ồn ào: seed vẫn nạp xong, không lỗi
// gì, chỉ là tính năng lặng lẽ không kích hoạt. Trước đây bộ seed từng có đúng
// một lỗi như vậy suốt một thời gian (field 300 KiB tưởng là kích hoạt clipping,
// thực ra không). Mỗi assert dưới đây là một cái bẫy cho loại lỗi đó.
//
// Dùng:
//   mongosh "mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin" db/seeds/mongodb/verify.js
//   make verify-mongo
db = db.getSiblingDB('jdb_dev');

const MIB = 1024 * 1024;
const MAX_DOC_EJSON = 2 * MIB;   // driver/ejson.go: maxDocEJSONBytes
const CLIP_FIELD = 256 * 1024;   // driver/ejson.go: clipFieldBytes
const GRIDFS_CHUNK = 261120;
const SHAPE_DRIFT_COVERAGE = 0.1; // driver/mongoschema.go
const REF_MIN_CONFIDENCE = 0.6;   // driver/mongorefs.go
const REF_KEEP_THRESHOLD = 0.25;

let pass = 0, fail = 0, skip = 0;
const failures = [];

function check(name, fn) {
  let ok, detail;
  try { const r = fn(); ok = r === true || (r && r.ok); detail = (r && r.detail) || ''; }
  catch (e) { ok = false; detail = 'lỗi: ' + e.message.slice(0, 120); }
  if (ok) { pass++; print('  PASS  ' + name + (detail ? '  — ' + detail : '')); }
  else { fail++; failures.push(name + (detail ? ' — ' + detail : '')); print('  FAIL  ' + name + (detail ? '  — ' + detail : '')); }
}
function skipped(name, why) { skip++; print('  SKIP  ' + name + '  — ' + why); }
function section(t) { print(''); print('── ' + t + ' ' + '─'.repeat(Math.max(0, 62 - t.length))); }

const isReplicaSet = !!db.hello().setName;
print('MongoDB ' + db.version() + '  ·  topology: ' + (isReplicaSet ? 'replicaSet (' + db.hello().setName + ')' : 'standalone'));

// ============================================================================
section('01-seed.js — nền dữ liệu quan hệ');
// ============================================================================
const BASE = { users: 1500, addresses: 2000, categories: 30, suppliers: 60, warehouses: 6,
  products: 1000, product_variants: 2500, carts: 1200, orders: 4000, reviews: 2500, events: 8000 };
check('16 collection thương mại điện tử có đủ số dòng', () => {
  const bad = Object.entries(BASE).filter(([c, n]) => db[c].countDocuments() !== n)
    .map(([c, n]) => c + '=' + db[c].countDocuments() + '≠' + n);
  return { ok: bad.length === 0, detail: bad.length ? bad.join(', ') : Object.keys(BASE).length + ' collection khớp' };
});
check('events.payload là object lồng nhau (không phải chuỗi JSON)', () => {
  const t = db.events.aggregate([{ $limit: 1 }, { $project: { t: { $type: '$payload' } } }]).toArray()[0].t;
  return { ok: t === 'object', detail: 'type=' + t };
});

// ============================================================================
section('Kiểu collection');
// ============================================================================
check('2 view tồn tại', () => {
  const v = db.getCollectionInfos({ type: 'view' }).map((c) => c.name).sort();
  return { ok: v.length === 2, detail: v.join(', ') };
});
check('capped ring buffer bị cắt đúng ở max', () => {
  const info = db.getCollectionInfos({ name: 'activity_ring_buffer' })[0];
  const n = db.activity_ring_buffer.countDocuments();
  // seed chèn 400 doc vào cap max=300 → phải còn đúng 300 (chứng minh ghi đè vòng)
  return { ok: info.options.capped === true && n === 300, detail: 'capped=' + info.options.capped + ' docs=' + n + ' (đã chèn 400)' };
});
check('time-series có timeField/metaField', () => {
  const o = db.getCollectionInfos({ name: 'sensor_readings' })[0].options.timeseries;
  return { ok: !!o && o.timeField === 'ts' && o.metaField === 'meta', detail: o ? o.timeField + '/' + o.metaField + '/' + o.granularity : 'không phải timeseries' };
});
check('collection RỖNG vẫn có index + validator', () => {
  const o = db.getCollectionInfos({ name: 'archived_orders' })[0].options;
  const n = db.archived_orders.countDocuments();
  return { ok: n === 0 && !!o.validator && db.archived_orders.getIndexes().length >= 2,
    detail: 'docs=' + n + ' validator=' + !!o.validator + ' indexes=' + db.archived_orders.getIndexes().length };
});

// ============================================================================
section('Clipping — ngưỡng của driver/ejson.go');
// ============================================================================
// documentToEJSON kiểm tra TOÀN document trước; chỉ khi > 2 MiB mới cắt field > 256 KiB.
function clipStats(labelRe) {
  const d = db.bson_type_gallery.findOne({ label: labelRe });
  if (!d) return null;
  const ejson = EJSON.stringify(d, null, 0, { relaxed: false }).length;
  const big = Object.keys(d).filter((k) => typeof d[k] === 'string' && d[k].length > 1000).map((k) => d[k].length);
  return { ejson, maxField: Math.max.apply(null, big), nFields: big.length };
}
check('pass 1 — 1 field khổng lồ: vượt CẢ 2 ngưỡng', () => {
  const s = clipStats(/^clipping pass 1/);
  return { ok: s && s.ejson > MAX_DOC_EJSON && s.maxField > CLIP_FIELD,
    detail: s ? 'doc=' + s.ejson + 'B>' + MAX_DOC_EJSON + ' · field=' + s.maxField + 'B>' + CLIP_FIELD : 'không tìm thấy document' };
});
check('pass 2 — nhiều field vừa: doc vượt 2 MiB NHƯNG mọi field DƯỚI 256 KiB', () => {
  const s = clipStats(/^clipping pass 2/);
  // Nếu maxField vượt 256 KiB thì pass 1 đã cắt xong và pass 2 không bao giờ chạy
  // → mất đúng nhánh mà document này sinh ra để kiểm thử.
  return { ok: s && s.ejson > MAX_DOC_EJSON && s.maxField < CLIP_FIELD && s.nFields >= 10,
    detail: s ? 'doc=' + s.ejson + 'B>' + MAX_DOC_EJSON + ' · field lớn nhất=' + s.maxField + 'B<' + CLIP_FIELD + ' · ' + s.nFields + ' field' : 'không tìm thấy document' };
});

// ============================================================================
section('Kiểu BSON');
// ============================================================================
check('javascript và javascriptWithScope là 2 kiểu khác nhau', () => {
  const r = db.bson_type_gallery.aggregate([{ $match: { label: /binary/ } },
    { $project: { _id: 0, c: { $type: '$aCode' }, cws: { $type: '$aCodeWithScope' } } }]).toArray()[0];
  return { ok: r && r.c === 'javascript' && r.cws === 'javascriptWithScope', detail: r ? r.c + ' / ' + r.cws : 'thiếu' };
});
check('có đủ nhóm kiểu BSON hiếm (decimal/binData/regex/minKey/maxKey/timestamp)', () => {
  const want = ['decimal', 'binData', 'regex', 'minKey', 'maxKey', 'timestamp'];
  const got = db.bson_type_gallery.aggregate([
    { $project: { kv: { $objectToArray: '$$ROOT' } } }, { $unwind: '$kv' },
    { $group: { _id: null, types: { $addToSet: { $type: '$kv.v' } } } }]).toArray()[0].types;
  const missing = want.filter((t) => got.indexOf(t) === -1);
  return { ok: missing.length === 0, detail: missing.length ? 'thiếu: ' + missing.join(', ') : want.length + ' kiểu có mặt' };
});
check('phân biệt null tường minh với field vắng mặt', () => {
  const d = db.bson_type_gallery.findOne({ label: /temporal/ });
  return { ok: d && d.aNullField === null && !('anOmittedField' in d), detail: 'aNullField=null, anOmittedField vắng mặt' };
});

// ============================================================================
section('Shape Lens');
// ============================================================================
check('order_snapshots có đúng 4 shape với tỉ lệ 70/20/7/3', () => {
  const tot = db.order_snapshots.countDocuments();
  const g = db.order_snapshots.aggregate([
    { $group: { _id: { c: { $ne: [{ $type: '$coupon' }, 'missing'] }, t: { $type: '$total' },
      l: { $ne: [{ $type: '$customerName' }, 'missing'] } }, n: { $sum: 1 } } }]).toArray();
  const by = {};
  g.forEach((r) => { by[(r._id.l ? 'legacy' : r._id.t === 'double' ? 'retyped' : r._id.c ? 'coupon' : 'base')] = r.n; });
  const ok = tot === 600 && by.base === 420 && by.coupon === 120 && by.retyped === 42 && by.legacy === 18;
  return { ok, detail: 'base=' + by.base + ' coupon=' + by.coupon + ' retyped=' + by.retyped + ' legacy=' + by.legacy + ' /' + tot };
});
check('shape legacy dưới ngưỡng drift (' + SHAPE_DRIFT_COVERAGE * 100 + '%) → có vòng amber', () => {
  const cov = db.order_snapshots.countDocuments({ customerName: { $exists: true } }) / db.order_snapshots.countDocuments();
  return { ok: cov > 0 && cov < SHAPE_DRIFT_COVERAGE, detail: 'coverage=' + (cov * 100).toFixed(1) + '% < ' + SHAPE_DRIFT_COVERAGE * 100 + '%' };
});
check('total là field polymorphic (decimal + double)', () => {
  const t = db.order_snapshots.aggregate([{ $group: { _id: { $type: '$total' } } }]).toArray().map((r) => r._id).sort();
  return { ok: t.length === 2 && t.indexOf('decimal') >= 0 && t.indexOf('double') >= 0, detail: t.join(' + ') };
});
check('metric_samples.value trải đủ 6 kiểu BSON', () => {
  const t = db.metric_samples.aggregate([{ $group: { _id: { $type: '$value' } } }]).toArray().map((r) => r._id).sort();
  return { ok: t.length === 6, detail: t.join(', ') };
});
check('sensor_readings có drift kiểu "added field" + "retyped"', () => {
  const tot = db.sensor_readings.countDocuments();
  const withUnit = db.sensor_readings.countDocuments({ unit: { $exists: true } });
  const asString = db.sensor_readings.countDocuments({ value: { $type: 'string' } });
  return { ok: withUnit > 0 && withUnit < tot && asString > 0,
    detail: 'unit ở ' + (withUnit / tot * 100).toFixed(0) + '% doc · value kiểu string: ' + asString };
});

// ============================================================================
section('_id — đủ 4 kiểu');
// ============================================================================
check('int (01-seed), string (feature_flags), ObjectId (authors), compound (inventory_ledger)', () => {
  const kinds = {
    int: db.users.aggregate([{ $limit: 1 }, { $project: { t: { $type: '$_id' } } }]).toArray()[0].t,
    string: db.feature_flags.aggregate([{ $limit: 1 }, { $project: { t: { $type: '$_id' } } }]).toArray()[0].t,
    objectId: db.authors.aggregate([{ $limit: 1 }, { $project: { t: { $type: '$_id' } } }]).toArray()[0].t,
    compound: db.inventory_ledger.aggregate([{ $limit: 1 }, { $project: { t: { $type: '$_id' } } }]).toArray()[0].t,
  };
  const ok = kinds.int === 'int' && kinds.string === 'string' && kinds.objectId === 'objectId' && kinds.compound === 'object';
  return { ok, detail: Object.entries(kinds).map(([k, v]) => k + '→' + v).join(', ') };
});
check('_id compound trỏ tới mã kho CÓ THẬT trong warehouses', () => {
  const codes = db.warehouses.distinct('code');
  const used = db.inventory_ledger.distinct('_id.warehouse');
  const orphan = used.filter((w) => codes.indexOf(w) === -1);
  return { ok: orphan.length === 0, detail: orphan.length ? 'mã lạ: ' + orphan.join(',') : used.length + ' mã đều khớp' };
});

// ============================================================================
section('Reference Map');
// ============================================================================
check('cạnh ObjectId "verified" (articles.writer → authors) ≥ ' + REF_MIN_CONFIDENCE * 100 + '%', () => {
  const tot = db.articles.countDocuments();
  const hit = db.articles.aggregate([{ $lookup: { from: 'authors', localField: 'writer', foreignField: '_id', as: 'a' } },
    { $match: { 'a.0': { $exists: true } } }, { $count: 'n' }]).toArray()[0].n;
  return { ok: hit / tot >= REF_MIN_CONFIDENCE, detail: (hit / tot * 100).toFixed(0) + '% (' + hit + '/' + tot + ')' };
});
check('cạnh gãy một phần (comments.articleId) nằm trong [' + REF_KEEP_THRESHOLD + ', ' + REF_MIN_CONFIDENCE + ')', () => {
  const tot = db.comments.countDocuments();
  const hit = db.comments.aggregate([{ $lookup: { from: 'articles', localField: 'articleId', foreignField: '_id', as: 'a' } },
    { $match: { 'a.0': { $exists: true } } }, { $count: 'n' }]).toArray()[0].n;
  const c = hit / tot;
  // Phải nằm GIỮA 2 ngưỡng: dưới 0.25 thì cạnh bị loại hẳn, từ 0.6 trở lên thì
  // lại thành "Verified" — cả hai đều làm mất ý nghĩa tương phản với cạnh trên.
  return { ok: c >= REF_KEEP_THRESHOLD && c < REF_MIN_CONFIDENCE, detail: (c * 100).toFixed(0) + '% (' + hit + '/' + tot + ')' };
});
check('cạnh mảng ObjectId (articles.relatedArticleIds)', () => {
  const n = db.articles.countDocuments({ 'relatedArticleIds.0': { $exists: true } });
  return { ok: n > 0, detail: n + ' bài có mảng tham chiếu' };
});
check('cạnh tham chiếu bằng CHUỖI (user_sessions.feature_flag_id → feature_flags)', () => {
  const tot = db.user_sessions.countDocuments();
  const hit = db.user_sessions.aggregate([{ $lookup: { from: 'feature_flags', localField: 'feature_flag_id', foreignField: '_id', as: 'f' } },
    { $match: { 'f.0': { $exists: true } } }, { $count: 'n' }]).toArray()[0].n;
  return { ok: tot > 0 && hit === tot, detail: hit + '/' + tot + ' khớp' };
});

// ============================================================================
section('Index');
// ============================================================================
const wantIdx = {
  'reviews/reviews_body_text': (i) => i.key._fts === 'text' || i.textIndexVersion,
  'products/products_category_price': (i) => i.key.category_id === 1 && i.key.price === -1,
  'orders/orders_cancelled_total_partial': (i) => !!i.partialFilterExpression,
  'events/events_payload_wildcard': (i) => JSON.stringify(i.key).indexOf('$**') >= 0,
  'stores/stores_location_2dsphere': (i) => i.key.location === '2dsphere',
  'authors/authors_email_unique': (i) => i.unique === true,
  'authors/authors_deceasedAt_sparse': (i) => i.sparse === true,
  'user_sessions/user_sessions_ttl': (i) => i.expireAfterSeconds !== undefined,
  'user_sessions/user_sessions_userId_hashed': (i) => i.key.userId === 'hashed',
  'articles/articles_views_hidden': (i) => i.hidden === true,
};
check('đủ 10 loại index/cờ (text, compound, partial, wildcard, 2dsphere, unique, sparse, ttl, hashed, hidden)', () => {
  const bad = [];
  for (const [path, pred] of Object.entries(wantIdx)) {
    const [coll, name] = path.split('/');
    const ix = db[coll].getIndexes().find((i) => i.name === name);
    if (!ix) bad.push(name + ' (thiếu)');
    else if (!pred(ix)) bad.push(name + ' (sai thuộc tính)');
  }
  return { ok: bad.length === 0, detail: bad.length ? bad.join(', ') : '10/10' };
});

// ============================================================================
section('GridFS');
// ============================================================================
check('2 bucket', () => {
  const b = db.getCollectionNames().filter((n) => n.endsWith('.files')).map((n) => n.replace('.files', '')).sort();
  return { ok: b.length === 2, detail: b.join(', ') };
});
check('attachments > 50 file → lộ phân trang (PAGE_SIZE=50)', () => {
  const n = db.attachments.files.countDocuments();
  return { ok: n > 50, detail: n + ' file' };
});
check('có file ĐA CHUNK (buộc ghép chunk khi tải)', () => {
  const f = db.attachments.files.find().sort({ length: -1 }).limit(1).toArray()[0];
  const c = db.attachments.chunks.countDocuments({ files_id: f._id });
  return { ok: c > 1 && f.length > GRIDFS_CHUNK, detail: f.filename + ' ' + (f.length / MIB).toFixed(2) + ' MB → ' + c + ' chunk' };
});
check('chunk liên tục, không thiếu mảnh', () => {
  const bad = [];
  db.attachments.files.find({}, { _id: 1, length: 1, chunkSize: 1, filename: 1 }).forEach((f) => {
    const want = Math.ceil(f.length / f.chunkSize);
    const got = db.attachments.chunks.countDocuments({ files_id: f._id });
    if (got !== want) bad.push(f.filename + ' ' + got + '≠' + want);
  });
  return { ok: bad.length === 0, detail: bad.length ? bad.join(', ') : 'mọi file đủ chunk' };
});

// ============================================================================
section('Validator');
// ============================================================================
check('subscriptions: moderate/warn + CÓ document vi phạm sẵn', () => {
  const o = db.getCollectionInfos({ name: 'subscriptions' })[0].options;
  const schema = o.validator.$jsonSchema;
  const invalid = db.subscriptions.countDocuments({ $nor: [{ $jsonSchema: schema }] });
  // Phải còn document vi phạm thì nút "Test" của ValidationPanel mới có gì để đếm.
  return { ok: o.validationLevel === 'moderate' && o.validationAction === 'warn' && invalid > 0,
    detail: o.validationLevel + '/' + o.validationAction + ' · ' + invalid + '/' + db.subscriptions.countDocuments() + ' vi phạm' };
});
check('payment_methods: strict/error và TỪ CHỐI insert sai thật', () => {
  const o = db.getCollectionInfos({ name: 'payment_methods' })[0].options;
  let rejected = false;
  try { db.payment_methods.insertOne({ userId: 1, brand: 'diners', last4: 'xx', expiresAt: new Date() }); }
  catch (e) { rejected = true; }
  if (!rejected) db.payment_methods.deleteOne({ brand: 'diners' }); // dọn nếu lọt
  return { ok: o.validationLevel === 'strict' && o.validationAction === 'error' && rejected,
    detail: o.validationLevel + '/' + o.validationAction + ' · insert sai bị từ chối: ' + rejected };
});

// ============================================================================
section('Sau warmup (03-warmup.js)');
// ============================================================================
if (!isReplicaSet) {
  skipped('profiler + index usage', 'instance standalone cố ý không chạy 03-warmup.js');
} else {
  check('system.profile có dữ liệu cho tab Slow Queries', () => {
    const n = db.system.profile.countDocuments();
    return { ok: n > 0, detail: n + ' bản ghi (nếu 0: chạy `make mongo-warmup`)' };
  });
  check('đúng 2 index ops=0 → cờ "unused" có ý nghĩa tương phản', () => {
    // `archived_orders` bị loại vì collection rỗng thì index của nó không bao giờ
    // được đụng tới — đó là hệ quả của thiết kế, không phải index "bị bỏ quên".
    const IGNORE = ['archived_orders'];
    const zero = [];
    db.getCollectionInfos({ type: 'collection' }).forEach((c) => {
      if (c.name.startsWith('system.') || IGNORE.indexOf(c.name) >= 0) return;
      try {
        db[c.name].aggregate([{ $indexStats: {} }]).toArray().forEach((i) => {
          // accesses.ops là Long → `=== 0` luôn sai (so object với số nguyên thuỷ).
          if (i.name !== '_id_' && Number(i.accesses.ops) === 0) zero.push(c.name + '.' + i.name);
        });
      } catch (e) { /* view không hỗ trợ $indexStats */ }
    });
    const want = ['articles.articles_views_hidden', 'stores.stores_tags_unused'];
    const extra = zero.filter((z) => want.indexOf(z) < 0);
    const missing = want.filter((w) => zero.indexOf(w) < 0);
    const ok = extra.length === 0 && missing.length === 0;
    return { ok,
      detail: ok ? zero.sort().join(', ')
        : (missing.length ? 'đã bị dùng mất: ' + missing.join(', ') + '. ' : '') +
          (extra.length ? 'chưa hâm nóng: ' + extra.join(', ') : '') };
  });
}

// ============================================================================
print('');
print('═'.repeat(66));
print('  PASS ' + pass + '   FAIL ' + fail + '   SKIP ' + skip);
if (fail) {
  print('');
  print('  Hỏng:');
  failures.forEach((f) => print('    · ' + f));
  print('');
  print('  Gợi ý: seed sai thường do volume cũ chưa xoá — `make reset-mongo`.');
  quit(1);
}
print('  Bộ seed MongoDB đạt toàn bộ bất biến.');
quit(0);
