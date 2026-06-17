#!/usr/bin/env node
/**
 * generate.mjs — Streaming multi-database seed generator (domain edition).
 *
 * Produces compressed CSV for fast PostgreSQL COPY loading of THREE distinct
 * domain databases, each with its own schemas & tables:
 *
 *   ecommerce  → catalog, orders, marketing
 *   healthcare → clinical, pharmacy, billing
 *   banking    → accounts, lending, cards
 *
 * Output: data/<domain>/<schema>/<table>.csv.gz   (consumed by init.sh)
 *
 * Usage:
 *   node db/seeds/multidb-postgres/generate.mjs                 # full scale
 *   node db/seeds/multidb-postgres/generate.mjs --scale 0.01    # 1% rows (quick test)
 *   node db/seeds/multidb-postgres/generate.mjs --domain banking
 *   node db/seeds/multidb-postgres/generate.mjs --dry-run
 *
 * Deterministic: every value is derived from the row index, so the output and
 * its FK / CHECK / UNIQUE consistency match the SQL seed in databases/.
 * Column order below MUST match each table's column order (COPY is positional).
 */

import { createWriteStream, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createGzip } from 'node:zlib';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DATA_DIR = join(__dirname, 'data');

// ── CLI ──────────────────────────────────────────────────────────────────────
const ARGS = process.argv.slice(2);
const flag = (n, d) => { const i = ARGS.indexOf(`--${n}`); return i >= 0 && ARGS[i + 1] && !ARGS[i + 1].startsWith('--') ? ARGS[i + 1] : d; };
const has  = (n) => ARGS.includes(`--${n}`);
const SCALE   = parseFloat(flag('scale', '1.0'));
const ONLY    = flag('domain', null);
const DRY_RUN = has('dry-run');

// ── Helpers (all deterministic in g = 1-based row index) ─────────────────────
const DAY = 86400000;
const A = (arr, i) => arr[((i % arr.length) + arr.length) % arr.length];
const pad = (n, w) => String(n).padStart(w, '0');
const money = (cents) => (cents / 100).toFixed(2);          // integer cents → "x.xx"
const fdate = (baseISO, days) => new Date(Date.parse(baseISO + 'T00:00:00Z') + days * DAY).toISOString().slice(0, 10);
const fts   = (baseISO, days) => new Date(Date.parse(baseISO + 'T08:00:00Z') + days * DAY).toISOString().slice(0, 19).replace('T', ' ');
const bool  = (b) => (b ? 't' : 'f');

// ── Pools ────────────────────────────────────────────────────────────────────
const FIRST = ['Alice','Bob','Carol','Dave','Eve','Frank','Grace','Hank','Iris','Jack','Kate','Leo','Mia','Nick','Olivia','Paul','Quinn','Rose','Sam','Tina'];
const LAST  = ['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Nguyen','Tran','Lee','Walker','Young','King','Scott','Green','Adams','Baker','Nelson','Carter'];
const VN_FIRST = ['An','Binh','Chi','Dung','Em','Phuc','Giang','Ha','Khanh','Linh','Minh','Nam','Oanh','Phong','Quang','Son','Thu','Uyen','Viet','Yen'];
const VN_LAST  = ['Nguyen','Tran','Le','Pham','Hoang','Vu','Dang','Bui','Do','Ho','Ngo','Duong','Ly','Vo','Phan','Truong','Dinh','Mai','Cao','Ta'];

// fk/ext reference: deterministic valid id in [1, rows(name)]
const ref = (rows, name, g) => ((g - 1) % rows.get(name)) + 1;

// ═══════════════════════════════════════════════════════════════════════════
// SCHEMA DEFINITIONS  —  defs[domain] = { dbName, schemas: { schema: [tables] } }
// Each table: [name, baseRows, [[colName, (g, rows) => value], ...]]
// ═══════════════════════════════════════════════════════════════════════════
const DEFS = {
  ecommerce: {
    dbName: 'jdb_ecommerce',
    schemas: {
      catalog: [
        ['categories', 500, [
          ['id', g => g],
          ['name', g => A(['Electronics','Fashion','Home','Beauty','Sports','Toys','Grocery','Automotive','Books','Garden','Office','Pets','Health','Music','Jewelry','Shoes','Baby','Tools','Outdoor','Gaming'], g) + ' / Sub ' + g],
          ['slug', g => 'cat-' + pad(g, 5)],
          ['parent_id', g => (g <= 20 ? null : (g % 20) + 1)],
          ['is_active', g => bool(g % 17 !== 0)],
          ['created_at', g => fts('2025-01-01', g % 300)],
        ]],
        ['brands', 2000, [
          ['id', g => g],
          ['name', g => A(['Acme','Globex','Initech','Umbra','Cyber','Stark','Wayne','Oscorp','Lex','Nakatomi','Tyrell','Aperture','Nova','Helios','Sombra'], g) + ' ' + g],
          ['country', g => A(['US','UK','JP','FR','DE','CN','KR','IT','SE','VN'], g)],
          ['website', g => 'https://brand' + g + '.example.com'],
          ['rating', g => ((10 + (g % 40)) / 10).toFixed(2)],
          ['created_at', g => fts('2024-06-01', g % 300)],
        ]],
        ['suppliers', 5000, [
          ['id', g => g],
          ['name', g => 'Supplier ' + g],
          ['country', g => A(['CN','VN','IN','US','DE','MX','TR','TH','ID','BD'], g)],
          ['contact_email', g => 'supplier' + g + '@vendor.example.com'],
          ['lead_time_days', g => 1 + (g % 60)],
          ['status', g => A(['active','active','active','inactive','suspended'], g)],
          ['created_at', g => fts('2024-01-01', g % 400)],
        ]],
        ['products', 100000, [
          ['id', g => g],
          ['category_id', (g, r) => ref(r, 'categories', g)],
          ['brand_id', (g, r) => ref(r, 'brands', g)],
          ['supplier_id', (g, r) => ref(r, 'suppliers', g)],
          ['name', g => A(['Pro','Max','Ultra','Lite','Eco','Prime','Smart','Mega','Nano','Turbo'], g) + ' ' + A(['Widget','Gadget','Speaker','Charger','Backpack','Bottle','Lamp','Keyboard','Mouse','Camera'], Math.floor(g / 10)) + ' ' + g],
          ['sku', g => 'SKU-' + pad(g, 8)],
          ['description', g => 'Auto-generated product description ' + g],
          ['price', g => money(500 + (g * 37) % 200000)],
          ['cost', g => money(200 + (g * 19) % 100000)],
          ['status', g => A(['active','active','active','active','draft','discontinued','archived'], g)],
          ['created_at', g => fts('2024-06-01', g % 400)],
          ['updated_at', () => '2025-12-01 09:00:00'],
        ]],
        ['product_variants', 200000, [
          ['id', g => g],
          ['product_id', (g, r) => ref(r, 'products', g)],
          ['sku', g => 'VAR-' + pad(g, 9)],
          ['variant_name', g => 'Variant ' + g],
          ['color', g => A(['Black','White','Red','Blue','Green','Silver','Gold','Gray'], g)],
          ['size', g => A(['XS','S','M','L','XL','One Size'], g)],
          ['price', g => money(500 + (g * 41) % 250000)],
          ['stock_qty', g => g % 5000],
          ['weight_g', g => 50 + (g % 4000)],
          ['created_at', g => fts('2024-06-01', g % 400)],
        ]],
      ],
      orders: [
        ['customers', 80000, [
          ['id', g => g],
          ['first_name', g => A(FIRST, g)],
          ['last_name', g => A(LAST, Math.floor(g / 20))],
          ['email', g => 'shopper' + g + '@mail.example.com'],
          ['phone', g => '+1555' + pad(1000000 + g, 8)],
          ['country', g => A(['US','UK','VN','JP','FR','DE','AU','CA','IN','SG'], g)],
          ['city', g => A(['New York','London','Hanoi','Tokyo','Paris','Berlin','Sydney','Toronto','Mumbai','Singapore'], g)],
          ['loyalty_tier', g => A(['bronze','bronze','bronze','silver','silver','gold','platinum'], g)],
          ['created_at', g => fts('2024-01-01', g % 500)],
        ]],
        ['orders', 150000, [
          ['id', g => g],
          ['customer_id', (g, r) => ref(r, 'customers', g)],
          ['order_number', g => 'ORD-' + pad(g, 9)],
          ['status', g => A(['pending','paid','paid','shipped','delivered','delivered','cancelled','refunded'], g)],
          ['subtotal', g => money(10000 + (g * 53) % 500000)],
          ['discount', g => money((g % 50) * 100)],
          ['shipping_fee', g => money((g % 30) * 100)],
          ['total', g => money(10000 + (g * 53) % 500000 + (g % 30) * 100 - (g % 50) * 100)],
          ['placed_at', g => fts('2025-01-01', g % 350)],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
        ['order_items', 200000, [
          ['id', g => g],
          ['order_id', (g, r) => ref(r, 'orders', g)],
          ['variant_sku', g => 'VAR-' + pad(((g - 1) % 200000) + 1, 9)],
          ['product_name', g => A(['Pro Widget','Max Gadget','Ultra Speaker','Lite Charger','Eco Backpack','Smart Lamp','Nano Mouse','Turbo Camera'], g)],
          ['quantity', g => 1 + (g % 10)],
          ['unit_price', g => money(500 + (g * 29) % 100000)],
          ['line_total', g => money((1 + (g % 10)) * (500 + (g * 29) % 100000))],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
        ['payments', 100000, [
          ['id', g => g],
          ['order_id', (g, r) => ref(r, 'orders', g)],
          ['method', g => A(['card','card','paypal','bank_transfer','cod','wallet'], g)],
          ['amount', g => money(1000 + (g * 47) % 500000)],
          ['status', g => A(['pending','authorized','captured','captured','failed','refunded'], g)],
          ['paid_at', g => (g % 4 === 0 ? null : fts('2025-01-01', g % 350))],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
        ['shipments', 120000, [
          ['id', g => g],
          ['order_id', (g, r) => ref(r, 'orders', g)],
          ['carrier', g => A(['DHL','FedEx','UPS','USPS','GHN','VNPost','Aramex'], g)],
          ['tracking_no', g => 'TRK-' + pad(g, 12)],
          ['status', g => A(['label_created','in_transit','out_for_delivery','delivered','delivered','returned'], g)],
          ['shipped_at', g => fts('2025-01-02', g % 350)],
          ['delivered_at', g => (g % 3 === 0 ? null : fts('2025-01-05', g % 350))],
          ['created_at', g => fts('2025-01-02', g % 350)],
        ]],
      ],
      marketing: [
        ['campaigns', 2000, [
          ['id', g => g],
          ['name', g => A(['Summer Sale','Black Friday','New Arrivals','Flash Deal','Loyalty Boost','Back to School','Holiday Push','Clearance'], g) + ' #' + g],
          ['channel', g => A(['email','social','search','display','affiliate','influencer'], g)],
          ['budget', g => money((1000 + (g % 50000)) * 100)],
          ['start_date', g => fdate('2025-01-01', g % 300)],
          ['end_date', g => fdate('2025-02-01', g % 300)],
          ['status', g => A(['planned','active','active','paused','completed'], g)],
          ['created_at', g => fts('2025-01-01', g % 300)],
        ]],
        ['coupons', 50000, [
          ['id', g => g],
          ['code', g => 'SAVE-' + pad(g, 7)],
          ['discount_type', g => A(['percent','fixed'], g)],
          ['discount_val', g => money((1 + (g % 50)) * 100)],
          ['max_uses', g => 100 + (g % 900)],
          ['used_count', g => g % 100],
          ['expires_at', g => fdate('2025-06-01', g % 365)],
          ['created_at', g => fts('2025-01-01', g % 300)],
        ]],
        ['reviews', 150000, [
          ['id', g => g],
          ['product_id', (g, r) => ref(r, 'products', g)],
          ['customer_id', (g, r) => ref(r, 'customers', g)],
          ['rating', g => 1 + (g % 5)],
          ['title', g => A(['Great product','Not bad','Disappointed','Excellent','Average','Would buy again'], g)],
          ['body', g => 'Auto-generated review body ' + g],
          ['is_verified', g => bool(g % 3 === 0)],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
        ['wishlists', 120000, [
          ['id', g => g],
          ['customer_id', (g, r) => ref(r, 'customers', g)],
          ['variant_sku', g => 'VAR-' + pad(((g - 1) % 200000) + 1, 9)],
          ['added_at', g => fts('2025-01-01', g % 350)],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
        ['ad_spend', 80000, [
          ['id', g => g],
          ['campaign_id', (g, r) => ref(r, 'campaigns', g)],
          ['spend_date', g => fdate('2025-01-01', g % 350)],
          ['impressions', g => 1000 + (g % 100000)],
          ['clicks', g => 10 + (g % 5000)],
          ['conversions', g => g % 500],
          ['cost', g => money((50 + (g % 10000)) * 100)],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
      ],
    },
  },

  healthcare: {
    dbName: 'jdb_healthcare',
    schemas: {
      clinical: [
        ['patients', 80000, [
          ['id', g => g],
          ['mrn', g => 'MRN-' + pad(g, 9)],
          ['first_name', g => A(VN_FIRST, g)],
          ['last_name', g => A(VN_LAST, Math.floor(g / 20))],
          ['dob', g => fdate('1950-01-01', (g * 97) % 26000)],
          ['gender', g => A(['male','female','other'], g)],
          ['blood_type', g => A(['A+','A-','B+','B-','AB+','AB-','O+','O-'], g)],
          ['phone', g => '+8490' + pad(1000000 + g, 7)],
          ['created_at', g => fts('2024-06-01', g % 700)],
        ]],
        ['encounters', 200000, [
          ['id', g => g],
          ['patient_id', (g, r) => ref(r, 'patients', g)],
          ['encounter_type', g => A(['outpatient','outpatient','inpatient','emergency','telehealth'], g)],
          ['department', g => A(['Cardiology','Neurology','Pediatrics','Orthopedics','Oncology','Emergency','Internal Medicine','Dermatology'], g)],
          ['admitted_at', g => fts('2024-06-01', g % 700)],
          ['discharged_at', g => (g % 4 === 0 ? null : fts('2024-06-03', g % 700))],
          ['status', g => A(['open','discharged','discharged','transferred','cancelled'], g)],
          ['created_at', g => fts('2024-06-01', g % 700)],
        ]],
        ['diagnoses', 200000, [
          ['id', g => g],
          ['encounter_id', (g, r) => ref(r, 'encounters', g)],
          ['icd10_code', g => A(['I10','E11','J45','K21','M54','F41','N39','R51'], g) + '.' + (g % 10)],
          ['description', g => A(['Hypertension','Type 2 diabetes','Asthma','Reflux disease','Low back pain','Anxiety disorder','Urinary infection','Headache'], g)],
          ['severity', g => A(['mild','mild','moderate','severe','critical'], g)],
          ['diagnosed_at', g => fts('2024-06-01', g % 700)],
          ['created_at', g => fts('2024-06-01', g % 700)],
        ]],
        ['vitals', 200000, [
          ['id', g => g],
          ['encounter_id', (g, r) => ref(r, 'encounters', g)],
          ['measured_at', g => fts('2024-06-01', g % 700)],
          ['heart_rate', g => 55 + (g % 80)],
          ['systolic', g => 95 + (g % 70)],
          ['diastolic', g => 60 + (g % 40)],
          ['temperature', g => (36.0 + (g % 30) / 10).toFixed(1)],
          ['spo2', g => 90 + (g % 11)],
          ['created_at', g => fts('2024-06-01', g % 700)],
        ]],
        ['prescriptions', 150000, [
          ['id', g => g],
          ['encounter_id', (g, r) => ref(r, 'encounters', g)],
          ['drug_id', (g, r) => ref(r, 'drugs', g)],   // ext (pharmacy.drugs)
          ['drug_name', g => A(['Amoxicillin','Metformin','Atorvastatin','Omeprazole','Amlodipine','Salbutamol','Ibuprofen','Paracetamol'], g)],
          ['dosage', g => A(['250mg','500mg','5mg','10mg','20mg','1 puff'], g)],
          ['frequency', g => A(['once daily','twice daily','three times daily','as needed'], g)],
          ['duration_days', g => 1 + (g % 90)],
          ['prescribed_at', g => fts('2024-06-01', g % 700)],
          ['created_at', g => fts('2024-06-01', g % 700)],
        ]],
      ],
      pharmacy: [
        ['suppliers', 3000, [
          ['id', g => g],
          ['name', g => 'Pharma Supplier ' + g],
          ['country', g => A(['IN','CN','DE','CH','US','VN','FR','GB','JP','KR'], g)],
          ['contact_email', g => 'supplier' + g + '@pharma.example.com'],
          ['status', g => A(['active','active','active','inactive','suspended'], g)],
          ['created_at', g => fts('2024-01-01', g % 400)],
        ]],
        ['drugs', 50000, [
          ['id', g => g],
          ['name', g => A(['Amoxil','Glucophage','Lipitor','Losec','Norvasc','Ventolin','Brufen','Panadol','Augmentin','Zithromax'], g) + ' ' + g],
          ['generic_name', g => A(['Amoxicillin','Metformin','Atorvastatin','Omeprazole','Amlodipine','Salbutamol','Ibuprofen','Paracetamol','Co-amoxiclav','Azithromycin'], g)],
          ['atc_code', g => A(['J01','A10','C10','A02','C08','R03','M01','N02'], g) + pad(g % 100, 2)],
          ['form', g => A(['tablet','capsule','syrup','injection','inhaler','cream'], g)],
          ['strength', g => A(['250mg','500mg','5mg','10mg','20mg','100ml'], g)],
          ['unit_price', g => money(50 + (g * 23) % 50000)],
          ['is_controlled', g => bool(g % 11 === 0)],
          ['created_at', g => fts('2024-01-01', g % 400)],
        ]],
        ['drug_inventory', 100000, [
          ['id', g => g],
          ['drug_id', (g, r) => ref(r, 'drugs', g)],
          ['batch_no', g => 'BATCH-' + pad(g, 9)],
          ['quantity', g => g % 10000],
          ['expiry_date', g => fdate('2026-01-01', g % 1000)],
          ['received_at', g => fts('2024-06-01', g % 600)],
          ['created_at', g => fts('2024-06-01', g % 600)],
        ]],
        ['dispenses', 200000, [
          ['id', g => g],
          ['drug_id', (g, r) => ref(r, 'drugs', g)],
          ['prescription_id', (g, r) => ref(r, 'prescriptions', g)],  // ext (clinical.prescriptions)
          ['quantity', g => 1 + (g % 60)],
          ['pharmacist', g => 'Pharmacist ' + (g % 200)],
          ['dispensed_at', g => fts('2024-06-02', g % 600)],
          ['created_at', g => fts('2024-06-02', g % 600)],
        ]],
        ['stock_moves', 200000, [
          ['id', g => g],
          ['drug_id', (g, r) => ref(r, 'drugs', g)],
          ['move_type', g => A(['receipt','dispense','adjustment','return','expiry_writeoff'], g)],
          ['quantity', g => (g % 2 === 0 ? 1 + (g % 500) : -(1 + (g % 500)))],
          ['reason', g => A(['Routine receipt','Patient dispense','Cycle count','Customer return','Expired stock'], g)],
          ['moved_at', g => fts('2024-06-01', g % 600)],
          ['created_at', g => fts('2024-06-01', g % 600)],
        ]],
      ],
      billing: [
        ['insurers', 2000, [
          ['id', g => g],
          ['name', g => A(['BlueCross','Aetna','Cigna','Humana','Bao Viet','PVI','UnitedHealth','Allianz'], g) + ' ' + g],
          ['country', g => A(['US','US','VN','DE','GB','FR','JP','SG'], g)],
          ['plan_type', g => A(['public','private','employer','supplemental'], g)],
          ['contact_email', g => 'claims' + g + '@insurer.example.com'],
          ['created_at', g => fts('2024-01-01', g % 400)],
        ]],
        ['services', 5000, [
          ['id', g => g],
          ['code', g => 'SVC-' + pad(g, 6)],
          ['name', g => A(['Consultation','X-Ray','MRI Scan','Blood Test','Surgery','Physiotherapy','Vaccination','ECG'], g) + ' ' + g],
          ['category', g => A(['Consultation','Imaging','Laboratory','Surgical','Therapy','Preventive'], g)],
          ['unit_price', g => money(1000 + (g * 31) % 500000)],
          ['created_at', g => fts('2024-01-01', g % 400)],
        ]],
        ['invoices', 150000, [
          ['id', g => g],
          ['patient_id', (g, r) => ref(r, 'patients', g)],   // ext (clinical.patients)
          ['insurer_id', (g, r) => (g % 5 === 0 ? null : ref(r, 'insurers', g))],
          ['invoice_number', g => 'INV-' + pad(g, 9)],
          ['amount', g => money(2000 + (g * 43) % 2000000)],
          ['status', g => A(['open','sent','paid','partially_paid','overdue','written_off'], g)],
          ['issued_at', g => fts('2024-06-01', g % 700)],
          ['due_date', g => fdate('2024-07-01', g % 700)],
          ['created_at', g => fts('2024-06-01', g % 700)],
        ]],
        ['claims', 120000, [
          ['id', g => g],
          ['invoice_id', (g, r) => ref(r, 'invoices', g)],
          ['insurer_id', (g, r) => ref(r, 'insurers', g)],
          ['claim_number', g => 'CLM-' + pad(g, 9)],
          ['amount', g => money(2000 + (g * 37) % 1500000)],
          ['status', g => A(['submitted','in_review','approved','partially_approved','denied','paid'], g)],
          ['submitted_at', g => fts('2024-06-05', g % 700)],
          ['resolved_at', g => (g % 3 === 0 ? null : fts('2024-06-20', g % 700))],
          ['created_at', g => fts('2024-06-05', g % 700)],
        ]],
        ['payments', 150000, [
          ['id', g => g],
          ['invoice_id', (g, r) => ref(r, 'invoices', g)],
          ['method', g => A(['cash','card','insurance','bank_transfer'], g)],
          ['amount', g => money(1000 + (g * 29) % 1000000)],
          ['paid_at', g => (g % 6 === 0 ? null : fts('2024-06-10', g % 700))],
          ['created_at', g => fts('2024-06-10', g % 700)],
        ]],
      ],
    },
  },

  banking: {
    dbName: 'jdb_banking',
    schemas: {
      accounts: [
        ['branches', 2000, [
          ['id', g => g],
          ['code', g => 'BR-' + pad(g, 6)],
          ['name', g => A(['Downtown','Uptown','Harbor','Central','Westside','Airport','Old Town','Riverside'], g) + ' Branch ' + g],
          ['city', g => A(['New York','London','Hanoi','Tokyo','Paris','Berlin','Sydney','Singapore'], g)],
          ['country', g => A(['US','UK','VN','JP','FR','DE','AU','SG'], g)],
          ['created_at', g => fts('2018-01-01', g % 400)],
        ]],
        ['customers', 80000, [
          ['id', g => g],
          ['full_name', g => A(FIRST, g) + ' ' + A(LAST, Math.floor(g / 8))],
          ['national_id', g => 'NID' + pad(g, 11)],
          ['email', g => 'cust' + g + '@bank.example.com'],
          ['phone', g => '+1555' + pad(2000000 + g, 8)],
          ['kyc_status', g => A(['pending','verified','verified','verified','rejected','review'], g)],
          ['created_at', g => fts('2018-01-01', g % 2800)],
        ]],
        ['accounts', 120000, [
          ['id', g => g],
          ['customer_id', (g, r) => ref(r, 'customers', g)],
          ['branch_id', (g, r) => ref(r, 'branches', g)],
          ['account_number', g => 'ACC' + pad(g, 12)],
          ['account_type', g => A(['checking','savings','term_deposit','credit'], g)],
          ['currency', g => A(['USD','EUR','VND','JPY','GBP'], g)],
          ['balance', g => money((g * 911) % 100000000)],
          ['status', g => A(['active','active','active','dormant','frozen','closed'], g)],
          ['opened_at', g => fdate('2018-01-01', g % 2800)],
          ['created_at', g => fts('2018-01-01', g % 2800)],
        ]],
        ['transactions', 200000, [
          ['id', g => g],
          ['account_id', (g, r) => ref(r, 'accounts', g)],
          ['txn_type', g => A(['deposit','withdrawal','transfer','fee','interest'], g)],
          ['amount', g => money(100 + (g * 53) % 5000000)],
          ['balance_after', g => money((g * 911) % 100000000)],
          ['description', g => A(['ATM','POS purchase','Online transfer','Salary credit','Service fee','Interest posting'], g)],
          ['txn_at', g => fts('2024-01-01', g % 700)],
          ['created_at', g => fts('2024-01-01', g % 700)],
        ]],
        ['beneficiaries', 100000, [
          ['id', g => g],
          ['account_id', (g, r) => ref(r, 'accounts', g)],
          ['name', g => 'Payee ' + g],
          ['bank_name', g => A(['Chase','HSBC','Vietcombank','MUFG','BNP Paribas','Deutsche Bank','ANZ','DBS'], g)],
          ['account_number', g => 'EXT' + pad(g, 12)],
          ['created_at', g => fts('2024-01-01', g % 700)],
        ]],
      ],
      lending: [
        ['applications', 100000, [
          ['id', g => g],
          ['customer_id', (g, r) => ref(r, 'customers', g)],   // ext (accounts.customers)
          ['product', g => A(['personal','mortgage','auto','business','student'], g)],
          ['amount', g => money(100000 + (g * 71) % 50000000)],
          ['status', g => A(['submitted','under_review','approved','approved','rejected','withdrawn'], g)],
          ['applied_at', g => fts('2023-01-01', g % 900)],
          ['created_at', g => fts('2023-01-01', g % 900)],
        ]],
        ['loans', 80000, [
          ['id', g => g],
          ['application_id', (g, r) => ref(r, 'applications', g)],
          ['loan_number', g => 'LN-' + pad(g, 10)],
          ['principal', g => money(100000 + (g * 67) % 40000000)],
          ['interest_rate', g => (2 + (g % 1800) / 100).toFixed(2)],
          ['term_months', g => A([12, 24, 36, 48, 60, 120, 240, 360], g)],
          ['status', g => A(['active','active','active','paid_off','delinquent','defaulted','restructured'], g)],
          ['disbursed_at', g => fdate('2023-01-01', g % 900)],
          ['created_at', g => fts('2023-01-01', g % 900)],
        ]],
        ['collaterals', 60000, [
          ['id', g => g],
          ['loan_id', (g, r) => ref(r, 'loans', g)],
          ['kind', g => A(['property','vehicle','deposit','equipment','securities'], g)],
          ['description', g => A(['Residential property','Passenger vehicle','Fixed deposit','Industrial equipment','Listed securities'], g) + ' #' + g],
          ['value', g => money(500000 + (g * 89) % 100000000)],
          ['created_at', g => fts('2023-01-01', g % 900)],
        ]],
        ['repayments', 200000, [
          ['id', g => g],
          ['loan_id', (g, r) => ref(r, 'loans', g)],
          ['amount', g => money(5000 + (g * 41) % 1000000)],
          ['principal_part', g => money(4000 + (g * 41) % 800000)],
          ['interest_part', g => money(1000 + (g * 41) % 200000)],
          ['paid_at', g => fts('2023-06-01', g % 900)],
          ['created_at', g => fts('2023-06-01', g % 900)],
        ]],
        ['schedules', 200000, [
          ['id', g => g],
          ['loan_id', (g, r) => ref(r, 'loans', g)],
          ['due_date', g => fdate('2023-06-01', g % 1200)],
          ['installment', g => money(5000 + (g * 43) % 1000000)],
          ['is_paid', g => bool(g % 3 !== 0)],
          ['created_at', g => fts('2023-06-01', g % 1200)],
        ]],
      ],
      cards: [
        ['merchants', 20000, [
          ['id', g => g],
          ['name', g => A(['Amazon','Walmart','Starbucks','Shell','Netflix','Apple','Grab','Shopee'], g) + ' #' + g],
          ['category', g => A(['Retail','Grocery','Dining','Fuel','Streaming','Electronics','Transport','Marketplace'], g)],
          ['mcc', g => A(['5411','5812','5541','5732','4899','5732','4121','5999'], g)],
          ['country', g => A(['US','UK','VN','JP','FR','DE','SG','AU'], g)],
          ['created_at', g => fts('2024-01-01', g % 400)],
        ]],
        ['cards', 100000, [
          ['id', g => g],
          ['account_id', (g, r) => ref(r, 'accounts', g)],   // ext (accounts.accounts, 120000)
          ['card_masked', g => '4XXX-XXXX-' + pad(Math.floor(g / 10000) % 10000, 4) + '-' + pad(g % 10000, 4)],
          ['brand', g => A(['visa','mastercard','amex','jcb','unionpay'], g)],
          ['status', g => A(['active','active','active','blocked','expired','lost','stolen'], g)],
          ['expires_on', g => fdate('2026-01-01', g % 1500)],
          ['created_at', g => fts('2024-06-01', g % 350)],
        ]],
        ['authorizations', 200000, [
          ['id', g => g],
          ['card_id', (g, r) => ref(r, 'cards', g)],
          ['merchant_id', (g, r) => ref(r, 'merchants', g)],
          ['amount', g => money(100 + (g * 53) % 2000000)],
          ['currency', g => A(['USD','EUR','VND','JPY','GBP'], g)],
          ['status', g => A(['approved','approved','approved','declined','reversed','expired'], g)],
          ['authorized_at', g => fts('2025-01-01', g % 350)],
          ['created_at', g => fts('2025-01-01', g % 350)],
        ]],
        ['settlements', 150000, [
          ['id', g => g],
          ['authorization_id', (g, r) => ref(r, 'authorizations', g)],
          ['amount', g => money(100 + (g * 53) % 2000000)],
          ['status', g => A(['settled','settled','settled','pending','failed'], g)],
          ['settled_at', g => (g % 5 === 0 ? null : fts('2025-01-03', g % 350))],
          ['created_at', g => fts('2025-01-03', g % 350)],
        ]],
        ['disputes', 50000, [
          ['id', g => g],
          ['authorization_id', (g, r) => ref(r, 'authorizations', g)],
          ['reason', g => A(['Unauthorized charge','Item not received','Duplicate charge','Wrong amount','Cancelled service'], g)],
          ['amount', g => money(100 + (g * 47) % 1500000)],
          ['status', g => A(['open','under_review','won','lost','withdrawn'], g)],
          ['opened_at', g => fts('2025-02-01', g % 300)],
          ['resolved_at', g => (g % 2 === 0 ? null : fts('2025-02-20', g % 300))],
          ['created_at', g => fts('2025-02-01', g % 300)],
        ]],
      ],
    },
  },
};

// ── CSV ──────────────────────────────────────────────────────────────────────
function csvEscape(v) {
  if (v === null || v === undefined) return '\\N';
  const s = String(v);
  return /[",\n\r]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}

function fmtRows(n) { return n < 1000 ? String(n) : n < 1e6 ? (n / 1e3).toFixed(0) + 'K' : (n / 1e6).toFixed(1) + 'M'; }

async function generateTable(domain, schema, table, rows, outDir) {
  const [name, , cols] = table;
  const n = rows.get(name);
  const filePath = join(outDir, `${name}.csv.gz`);
  mkdirSync(dirname(filePath), { recursive: true });

  const gzip = createGzip({ level: 6 });
  const ws = createWriteStream(filePath);
  gzip.pipe(ws);
  gzip.write(cols.map(c => `"${c[0]}"`).join(',') + '\n');   // header (skipped by COPY)

  const BATCH = 10000;
  for (let off = 0; off < n; off += BATCH) {
    const end = Math.min(off + BATCH, n);
    let chunk = '';
    for (let g = off + 1; g <= end; g++) {
      chunk += cols.map(c => csvEscape(c[1](g, rows))).join(',') + '\n';
    }
    if (!gzip.write(chunk)) await new Promise(r => gzip.once('drain', r));
  }
  gzip.end();
  await new Promise((res, rej) => { ws.on('finish', res); ws.on('error', rej); });
  return n;
}

async function main() {
  console.log('Multi-DB Seed Generator (domain edition)');
  console.log(`  Scale:  ${SCALE}`);
  console.log(`  Output: ${DATA_DIR}`);
  if (ONLY) console.log(`  Domain: ${ONLY}`);
  console.log(`  Mode:   ${DRY_RUN ? 'DRY RUN' : 'GENERATE'}\n`);

  const start = Date.now();
  let grand = 0;

  for (const [domain, def] of Object.entries(DEFS)) {
    if (ONLY && domain !== ONLY) continue;
    console.log(`── ${def.dbName} (${domain}) ──`);

    // Per-domain scaled row counts (used by fk / cross-schema refs).
    const rows = new Map();
    for (const schema of Object.values(def.schemas))
      for (const [name, base] of schema) rows.set(name, Math.max(1, Math.floor(base * SCALE)));

    for (const [schema, tables] of Object.entries(def.schemas)) {
      console.log(`  ${schema}/`);
      for (const table of tables) {
        const name = table[0];
        const n = rows.get(name);
        if (DRY_RUN) { console.log(`    ${name.padEnd(20)} ${fmtRows(n).padStart(6)} rows`); grand += n; continue; }
        const outDir = join(DATA_DIR, domain, schema);
        await generateTable(domain, schema, table, rows, outDir);
        console.log(`    ${name.padEnd(20)} ${fmtRows(n).padStart(6)} rows`);
        grand += n;
      }
    }
    console.log();
  }

  console.log('── Summary ──');
  console.log(`  Total rows: ${fmtRows(grand)}`);
  console.log(`  Elapsed:    ${((Date.now() - start) / 1000).toFixed(1)}s`);
  if (!DRY_RUN) console.log(`\nFiles in: ${DATA_DIR}\nReady for: docker compose up -d`);
}

main().catch(err => { console.error(err); process.exit(1); });
