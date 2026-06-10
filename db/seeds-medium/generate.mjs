#!/usr/bin/env node
// Sinh BỘ DỮ LIỆU TẦM TRUNG (tách biệt với db/seeds/ — KHÔNG đụng dữ liệu mẫu cũ).
//   node db/seeds-medium/generate.mjs
//
// - 100 bảng có quan hệ (FK) cho PostgreSQL / MySQL / SQLite → mỗi loại 2 file: schema + data.
// - Redis ~5000 key đa kiểu (string/hash/list/set/zset).
// Dữ liệu tổng hợp, tất định (RNG có seed) → chạy lại cho kết quả giống nhau.
import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = dirname(fileURLToPath(import.meta.url))

// ── RNG tất định (mulberry32) ─────────────────────────────────────────────────────
let _s = 0x1234abcd
function rnd() {
  _s |= 0
  _s = (_s + 0x6d2b79f5) | 0
  let t = Math.imul(_s ^ (_s >>> 15), 1 | _s)
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}
const int = (a, b) => a + Math.floor(rnd() * (b - a + 1))
const pick = (arr) => arr[Math.floor(rnd() * arr.length)]
const pad = (n, w = 4) => String(n).padStart(w, '0')
const money = (a, b) => Number((a + rnd() * (b - a)).toFixed(2))

// ── Pools ─────────────────────────────────────────────────────────────────────────
const PREFIX = ['core', 'app', 'crm', 'hr', 'fin', 'ops', 'log', 'ref', 'cfg', 'geo', 'sales', 'inv']
const ENTITY = ['user', 'order', 'item', 'event', 'tag', 'note', 'role', 'team', 'site', 'plan', 'task', 'file', 'rule', 'zone', 'unit', 'asset', 'lead', 'deal', 'ticket', 'invoice']
const ADJ = ['Compact', 'Wireless', 'Matte', 'Rugged', 'Slim', 'Ultra', 'Eco', 'Smart', 'Pro', 'Mini', 'Vivid', 'Quiet', 'Rapid', 'Solar', 'Nordic']
const NOUN = ['Keyboard', 'Mouse', 'Hub', 'Cable', 'Lamp', 'Stand', 'Mat', 'Charger', 'Webcam', 'Speaker', 'Bottle', 'Backpack', 'Monitor', 'Dock', 'Pen']
const FIRST = ['Ava', 'Liam', 'Noah', 'Mia', 'Zoe', 'Leo', 'Ivy', 'Eli', 'Nora', 'Kai', 'Luna', 'Max', 'Ada', 'Finn', 'Ela', 'Theo', 'Ren', 'Mai', 'Bao', 'Linh']
const LAST = ['Tran', 'Nguyen', 'Le', 'Pham', 'Stone', 'Reed', 'Fox', 'Hale', 'Vu', 'Do', 'Bui', 'Cole', 'Lane', 'Ray', 'Wells', 'Kim', 'Shaw', 'Ford']
const CITY = ['Hanoi', 'Saigon', 'Da Nang', 'Berlin', 'Lyon', 'Osaka', 'Austin', 'Porto', 'Leeds', 'Turin']
const COUNTRY = ['VN', 'DE', 'FR', 'JP', 'US', 'PT', 'GB', 'IT', 'BE', 'PH']
const STATUS = ['active', 'pending', 'paid', 'closed', 'draft', 'archived']
const WORDS = ['great value', 'works as described', 'fast shipping', 'solid build', 'a bit pricey', 'exceeded expectations', 'minor issues', 'highly recommended', 'does the job', 'arrived early']
const CODES = ['SKU', 'REF', 'ORD', 'TKT', 'INV', 'LOT', 'BIN']

// ── Quy mô ─────────────────────────────────────────────────────────────────────────
const TABLE_COUNT = 100
const ROWS_MIN = 20
const ROWS_MAX = 150
const REDIS_KEYS = 5000

// ── Quote/escape ───────────────────────────────────────────────────────────────────
const q = (s) => `'${String(s).replace(/'/g, "''")}'`

// Ngày ISO ngẫu nhiên trong ~2 năm gần đây.
function isoDate() {
  const base = Date.UTC(2024, 0, 1)
  const ms = base + int(0, 720) * 86400000 + int(0, 86399) * 1000
  return new Date(ms).toISOString().slice(0, 19) // YYYY-MM-DDTHH:MM:SS
}
const dt = {
  pg: () => q(isoDate().replace('T', ' ') + '+00'),
  my: () => q(isoDate().replace('T', ' ')),
  lite: () => q(isoDate().replace('T', ' ')),
}
const boolVal = { pg: (b) => (b ? 'TRUE' : 'FALSE'), my: (b) => (b ? '1' : '0'), lite: (b) => (b ? '1' : '0') }

// ── Kiểu cột: type theo dialect + hàm sinh giá trị ─────────────────────────────────
const COLTYPES = {
  name: { pg: 'varchar(80)', my: 'varchar(80)', lite: 'TEXT', gen: () => q(`${pick(ADJ)} ${pick(NOUN)}`) },
  full_name: { pg: 'varchar(80)', my: 'varchar(80)', lite: 'TEXT', gen: () => q(`${pick(FIRST)} ${pick(LAST)}`) },
  code: { pg: 'varchar(24)', my: 'varchar(24)', lite: 'TEXT', gen: () => q(`${pick(CODES)}-${pad(int(1, 99999), 5)}`) },
  email: { pg: 'varchar(120)', my: 'varchar(120)', lite: 'TEXT', gen: () => q(`${pick(FIRST).toLowerCase()}.${int(1, 9999)}@example.com`) },
  city: { pg: 'varchar(60)', my: 'varchar(60)', lite: 'TEXT', gen: () => q(pick(CITY)) },
  country: { pg: 'varchar(2)', my: 'varchar(2)', lite: 'TEXT', gen: () => q(pick(COUNTRY)) },
  status: { pg: 'varchar(16)', my: 'varchar(16)', lite: 'TEXT', gen: () => q(pick(STATUS)) },
  note: { pg: 'text', my: 'text', lite: 'TEXT', gen: () => q(pick(WORDS)) },
  qty: { pg: 'integer', my: 'int', lite: 'INTEGER', gen: () => String(int(0, 500)) },
  score: { pg: 'integer', my: 'int', lite: 'INTEGER', gen: () => String(int(0, 100)) },
  amount: { pg: 'numeric(12,2)', my: 'decimal(12,2)', lite: 'REAL', gen: () => money(1, 9999).toFixed(2) },
  rate: { pg: 'numeric(5,2)', my: 'decimal(5,2)', lite: 'REAL', gen: () => money(0, 100).toFixed(2) },
  active: { pg: 'boolean', my: 'tinyint(1)', lite: 'INTEGER', gen: (d) => boolVal[d](rnd() < 0.7) },
}
const VALUE_COLS = Object.keys(COLTYPES)

// ── Sinh đặc tả 100 bảng (tất định) ─────────────────────────────────────────────────
function buildTables() {
  const names = []
  for (const p of PREFIX) for (const e of ENTITY) names.push(`${p}_${e}`)
  // names có 12*20 = 240 → lấy 100 đầu (đã có thứ tự ổn định)
  const chosen = names.slice(0, TABLE_COUNT)

  const tables = []
  chosen.forEach((name, i) => {
    // 3–6 cột giá trị ngẫu nhiên (luôn có created_at)
    const nCols = int(3, 6)
    const cols = []
    const used = new Set()
    for (let c = 0; c < nCols; c++) {
      let key = pick(VALUE_COLS)
      let col = key
      let n = 1
      while (used.has(col)) col = `${key}_${++n}` // tránh trùng tên cột
      used.add(col)
      cols.push({ col, type: key })
    }
    // FK tới một bảng đã định nghĩa trước (≈55% bảng, trừ bảng đầu)
    let fk = null
    if (i > 0 && rnd() < 0.55) {
      const parent = tables[int(0, i - 1)]
      fk = { col: `${parent.name}_id`, refTable: parent.name, refRows: parent.rows }
    }
    tables.push({ name, cols, fk, rows: int(ROWS_MIN, ROWS_MAX) })
  })
  return tables
}

// ── Emit SCHEMA theo dialect ────────────────────────────────────────────────────────
function emitSchema(tables, d) {
  const pkType = d === 'pg' ? 'bigserial PRIMARY KEY' : d === 'my' ? 'bigint AUTO_INCREMENT PRIMARY KEY' : 'INTEGER PRIMARY KEY AUTOINCREMENT'
  const tsType = d === 'pg' ? 'timestamptz' : d === 'my' ? 'datetime' : 'TEXT'
  const out = [`-- ${d.toUpperCase()} — bộ TẦM TRUNG: ${tables.length} bảng (schema)`]
  if (d === 'my') out.push('SET FOREIGN_KEY_CHECKS = 0;')
  for (const t of tables) {
    const lines = [`  id ${pkType}`]
    for (const c of t.cols) lines.push(`  ${c.col} ${COLTYPES[c.type][d]}`)
    lines.push(`  created_at ${tsType} NOT NULL`)
    if (t.fk) {
      lines.push(`  ${t.fk.col} bigint`)
      lines.push(`  FOREIGN KEY (${t.fk.col}) REFERENCES ${t.fk.refTable}(id)`)
    }
    out.push(`CREATE TABLE ${t.name} (\n${lines.join(',\n')}\n);`)
  }
  if (d === 'my') out.push('SET FOREIGN_KEY_CHECKS = 1;')
  return out.join('\n') + '\n'
}

// ── Emit DATA theo dialect ──────────────────────────────────────────────────────────
function emitData(tables, d) {
  const out = [`-- ${d.toUpperCase()} — bộ TẦM TRUNG: dữ liệu`]
  if (d === 'my') out.push('SET FOREIGN_KEY_CHECKS = 0;')
  if (d === 'pg' || d === 'lite') out.push('BEGIN;')
  for (const t of tables) {
    const colNames = ['created_at', ...t.cols.map((c) => c.col)]
    if (t.fk) colNames.push(t.fk.col)
    const rowsSql = []
    for (let r = 0; r < t.rows; r++) {
      const vals = [dt[d]()]
      for (const c of t.cols) vals.push(COLTYPES[c.type].gen(d))
      if (t.fk) vals.push(t.fk.refRows > 0 ? String(int(1, t.fk.refRows)) : 'NULL')
      rowsSql.push(`(${vals.join(', ')})`)
    }
    // chèn theo lô 200 dòng/câu
    for (let i = 0; i < rowsSql.length; i += 200) {
      const chunk = rowsSql.slice(i, i + 200)
      out.push(`INSERT INTO ${t.name} (${colNames.join(', ')}) VALUES\n${chunk.join(',\n')};`)
    }
  }
  if (d === 'pg' || d === 'lite') out.push('COMMIT;')
  if (d === 'my') out.push('SET FOREIGN_KEY_CHECKS = 1;')
  return out.join('\n') + '\n'
}

// ── Redis ~5000 key đa kiểu ────────────────────────────────────────────────────────
function emitRedis() {
  const out = [
    '# Redis — bộ TẦM TRUNG (~5000 key). Nạp vào DB riêng để không đụng dữ liệu cũ:',
    '#   redis-cli -n 1 < db/seeds-medium/redis/seed.redis',
    '# (FLUSHDB sẽ XOÁ sạch DB đang chọn trước khi nạp)',
    'FLUSHDB',
  ]
  const plan = [
    ['string', 2000],
    ['hash', 1200],
    ['list', 800],
    ['set', 600],
    ['zset', 400],
  ]
  for (const [kind, count] of plan) {
    for (let i = 1; i <= count; i++) {
      if (kind === 'string') out.push(`SET m:str:${i} ${q(`${pick(ADJ)} ${pick(NOUN)} ${int(1, 9999)}`)}`)
      else if (kind === 'hash') out.push(`HSET m:user:${i} name ${q(`${pick(FIRST)} ${pick(LAST)}`)} email ${q(`u${i}@example.com`)} city ${q(pick(CITY))} status ${q(pick(STATUS))}`)
      else if (kind === 'list') {
        const n = int(3, 8)
        const vals = Array.from({ length: n }, () => q(`evt:${pick(STATUS)}:${int(1, 999)}`)).join(' ')
        out.push(`RPUSH m:list:${i} ${vals}`)
      } else if (kind === 'set') {
        const n = int(3, 7)
        const vals = Array.from({ length: n }, () => q(`tag:${pick(NOUN).toLowerCase()}`)).join(' ')
        out.push(`SADD m:set:${i} ${vals}`)
      } else {
        const n = int(3, 8)
        const vals = Array.from({ length: n }, () => `${int(1, 1000)} ${q(`${pick(FIRST)}${int(1, 99)}`)}`).join(' ')
        out.push(`ZADD m:rank:${i} ${vals}`)
      }
    }
  }
  return out.join('\n') + '\n'
}

// ── Ghi file ────────────────────────────────────────────────────────────────────────
function write(rel, content) {
  const p = join(ROOT, rel)
  mkdirSync(dirname(p), { recursive: true })
  writeFileSync(p, content)
  console.log(`  ${rel}  (${(content.length / 1024).toFixed(0)} KB)`)
}

const tables = buildTables()
console.log(`Sinh ${tables.length} bảng + dữ liệu (3 dialect) + Redis ${REDIS_KEYS} key...`)
write('postgres/01-schema.sql', emitSchema(tables, 'pg'))
write('postgres/02-data.sql', emitData(tables, 'pg'))
write('mysql/01-schema.sql', emitSchema(tables, 'my'))
write('mysql/02-data.sql', emitData(tables, 'my'))
write('sqlite/schema.sql', emitSchema(tables, 'lite'))
write('sqlite/data.sql', emitData(tables, 'lite'))
write('redis/seed.redis', emitRedis())
const totalRows = tables.reduce((s, t) => s + t.rows, 0)
console.log(`Xong. Tổng ${totalRows} dòng/dialect; Redis ${REDIS_KEYS} key.`)
