// MongoDB — bộ sinh ghi liên tục để demo tab Live Ops → Change Tail.
//
// Change Tail đọc change stream: nó chỉ hiện sự kiện xảy ra TRONG LÚC stream đang
// mở. Không có seed tĩnh nào làm nó "có sẵn dữ liệu" được — phải có ai đó ghi vào
// DB trong lúc bạn đang xem. Script này làm đúng việc đó.
//
// Vòng lặp phát đủ 3 loại thao tác để thấy hết 3 màu của feed, và bản update dùng
// ĐỒNG THỜI $set lẫn $unset để hiện cả 2 danh sách field:
//   insert  → emerald
//   update  → amber, kèm `~field` (updatedFields) và `−field` (removedFields)
//   delete  → rose
//
// KHÔNG ghi vào `activity_ring_buffer`: đó là capped collection, mà MongoDB CẤM
// xoá document khỏi capped collection (và cấm update làm document phình ra) — nên
// nhánh delete sẽ lỗi. Script tự dùng collection thường `change_tail_demo` để
// không đụng vào dữ liệu seed.
//
// Dùng:
//   mongosh "mongodb://jdb:jdbtest@localhost:27017/jdb_dev?authSource=admin&replicaSet=rs0" db/seeds/mongodb/watch-demo.js
//   docker compose --profile mongo-writer up -d      # hoặc chạy nền bằng compose
// Dừng: Ctrl+C (hoặc docker compose stop mongodb-writer).
db = db.getSiblingDB('jdb_dev');

const COLL = 'change_tail_demo';
const DELAY_MS = Number(process.env.JDB_WATCH_DELAY_MS || 1500);
const MAX_ITER = Number(process.env.JDB_WATCH_ITERATIONS || 0); // 0 = chạy mãi

if (!db.getCollectionNames().includes(COLL)) db.createCollection(COLL);

const ACTIONS = ['checkout', 'search', 'add_to_cart', 'login', 'refund'];
const REGIONS = ['eu', 'us', 'apac'];
const pick = (a) => a[Math.floor(Math.random() * a.length)];

print('watch-demo.js: ghi vào jdb_dev.' + COLL + ' mỗi ' + DELAY_MS + 'ms. Ctrl+C để dừng.');
print('Mở JiveDB → Live Ops → Change Tail (scope: collection ' + COLL + ', hoặc whole-db) để xem.');

for (let i = 1; MAX_ITER === 0 || i <= MAX_ITER; i++) {
  // 1) insert → sự kiện màu emerald
  const doc = {
    _id: new ObjectId(),
    seq: i,
    action: pick(ACTIONS),
    region: pick(REGIONS),
    // `scratch` tồn tại để bước sau $unset nó đi, tạo ra `−scratch` trong feed.
    scratch: 'to-be-removed',
    at: new Date(),
  };
  db.getCollection(COLL).insertOne(doc);

  sleep(DELAY_MS);

  // 2) update có CẢ $set lẫn $unset → amber, feed hiện `~status`, `~updatedAt`
  //    (updatedFields) và `−scratch` (removedFields).
  db.getCollection(COLL).updateOne(
    { _id: doc._id },
    { $set: { status: 'processed', updatedAt: new Date() }, $unset: { scratch: '' } },
  );

  sleep(DELAY_MS);

  // 3) delete → rose. Xoá document CŨ (giữ lại vài bản gần nhất để nhìn được),
  //    nên collection không phình mãi mà feed vẫn luôn có sự kiện xoá.
  const old = db.getCollection(COLL).find({}, { _id: 1 }).sort({ seq: 1 }).limit(1).toArray();
  if (old.length && db.getCollection(COLL).countDocuments() > 5) {
    db.getCollection(COLL).deleteOne({ _id: old[0]._id });
  }

  if (i % 10 === 0) print('  ... ' + i + ' vòng, hiện có ' + db.getCollection(COLL).countDocuments() + ' document');
  sleep(DELAY_MS);
}

print('watch-demo.js: xong ' + MAX_ITER + ' vòng.');
