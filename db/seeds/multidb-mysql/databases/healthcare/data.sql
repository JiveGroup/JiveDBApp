-- jdb_healthcare data — full-scale, deterministic (derived from row number `g`).
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

DROP TEMPORARY TABLE IF EXISTS seq;
CREATE TEMPORARY TABLE seq (g INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO seq (g)
SELECT g FROM (
  SELECT 1 + d0.i + d1.i*10 + d2.i*100 + d3.i*1000 + d4.i*10000 + d5.i*100000 AS g
  FROM       (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4
  CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d5
) t WHERE g <= 200000;

-- clinical_patients → 80000
INSERT INTO clinical_patients (id, mrn, first_name, last_name, dob, gender, blood_type, phone, created_at)
SELECT g,
       CONCAT('MRN-', LPAD(g, 9, '0')),
       ELT((g % 20) + 1,'An','Binh','Chi','Dung','Em','Phuc','Giang','Ha','Khanh','Linh','Minh','Nam','Oanh','Phong','Quang','Son','Thu','Uyen','Viet','Yen'),
       ELT((FLOOR(g / 20) % 20) + 1,'Nguyen','Tran','Le','Pham','Hoang','Vu','Dang','Bui','Do','Ho','Ngo','Duong','Ly','Vo','Phan','Truong','Dinh','Mai','Cao','Ta'),
       DATE_ADD('1950-01-01', INTERVAL (g * 97) % 26000 DAY),
       ELT((g % 3) + 1,'male','female','other'),
       ELT((g % 8) + 1,'A+','A-','B+','B-','AB+','AB-','O+','O-'),
       CONCAT('+8490', LPAD(1000000 + g, 7, '0')),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 80000;

-- clinical_encounters → 200000
INSERT INTO clinical_encounters (id, patient_id, encounter_type, department, admitted_at, discharged_at, status, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       ELT((g % 5) + 1,'outpatient','outpatient','inpatient','emergency','telehealth'),
       ELT((g % 8) + 1,'Cardiology','Neurology','Pediatrics','Orthopedics','Oncology','Emergency','Internal Medicine','Dermatology'),
       DATE_ADD('2024-06-01 08:00:00', INTERVAL (g % 700) DAY),
       IF(g % 4 = 0, NULL, DATE_ADD('2024-06-03 08:00:00', INTERVAL (g % 700) DAY)),
       ELT((g % 5) + 1,'open','discharged','discharged','transferred','cancelled'),
       DATE_ADD('2024-06-01 08:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 200000;

-- clinical_diagnoses → 200000
INSERT INTO clinical_diagnoses (id, encounter_id, icd10_code, description, severity, diagnosed_at, created_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       CONCAT(ELT((g % 8) + 1,'I10','E11','J45','K21','M54','F41','N39','R51'), '.', (g % 10)),
       ELT((g % 8) + 1,'Hypertension','Type 2 diabetes','Asthma','Reflux disease','Low back pain','Anxiety disorder','Urinary infection','Headache'),
       ELT((g % 5) + 1,'mild','mild','moderate','severe','critical'),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 700) DAY),
       DATE_ADD('2024-06-01 09:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 200000;

-- clinical_vitals → 200000
INSERT INTO clinical_vitals (id, encounter_id, measured_at, heart_rate, systolic, diastolic, temperature, spo2, created_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       DATE_ADD('2024-06-01 10:00:00', INTERVAL (g % 700) DAY),
       55 + (g % 80),
       95 + (g % 70),
       60 + (g % 40),
       ROUND(36.0 + (g % 30) / 10, 1),
       90 + (g % 11),
       DATE_ADD('2024-06-01 10:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 200000;

-- clinical_prescriptions → 150000
INSERT INTO clinical_prescriptions (id, encounter_id, drug_id, drug_name, dosage, frequency, duration_days, prescribed_at, created_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       ((g - 1) % 50000) + 1,
       ELT((g % 8) + 1,'Amoxicillin','Metformin','Atorvastatin','Omeprazole','Amlodipine','Salbutamol','Ibuprofen','Paracetamol'),
       ELT((g % 6) + 1,'250mg','500mg','5mg','10mg','20mg','1 puff'),
       ELT((g % 4) + 1,'once daily','twice daily','three times daily','as needed'),
       1 + (g % 90),
       DATE_ADD('2024-06-01 11:00:00', INTERVAL (g % 700) DAY),
       DATE_ADD('2024-06-01 11:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 150000;

-- pharmacy_suppliers → 3000
INSERT INTO pharmacy_suppliers (id, name, country, contact_email, status, created_at)
SELECT g,
       CONCAT('Pharma Supplier ', g),
       ELT((g % 10) + 1,'IN','CN','DE','CH','US','VN','FR','GB','JP','KR'),
       CONCAT('supplier', g, '@pharma.example.com'),
       ELT((g % 5) + 1,'active','active','active','inactive','suspended'),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 3000;

-- pharmacy_drugs → 50000
INSERT INTO pharmacy_drugs (id, name, generic_name, atc_code, form, strength, unit_price, is_controlled, created_at)
SELECT g,
       CONCAT(ELT((g % 10) + 1,'Amoxil','Glucophage','Lipitor','Losec','Norvasc','Ventolin','Brufen','Panadol','Augmentin','Zithromax'), ' ', g),
       ELT((g % 10) + 1,'Amoxicillin','Metformin','Atorvastatin','Omeprazole','Amlodipine','Salbutamol','Ibuprofen','Paracetamol','Co-amoxiclav','Azithromycin'),
       CONCAT(ELT((g % 8) + 1,'J01','A10','C10','A02','C08','R03','M01','N02'), LPAD(g % 100, 2, '0')),
       ELT((g % 6) + 1,'tablet','capsule','syrup','injection','inhaler','cream'),
       ELT((g % 6) + 1,'250mg','500mg','5mg','10mg','20mg','100ml'),
       ROUND((50 + (g * 23) % 50000) / 100, 2),
       (g % 11 = 0),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 50000;

-- pharmacy_drug_inventory → 100000
INSERT INTO pharmacy_drug_inventory (id, drug_id, batch_no, quantity, expiry_date, received_at, created_at)
SELECT g,
       ((g - 1) % 50000) + 1,
       CONCAT('BATCH-', LPAD(g, 9, '0')),
       g % 10000,
       DATE_ADD('2026-01-01', INTERVAL (g % 1000) DAY),
       DATE_ADD('2024-06-01 08:00:00', INTERVAL (g % 600) DAY),
       DATE_ADD('2024-06-01 08:00:00', INTERVAL (g % 600) DAY)
FROM seq WHERE g <= 100000;

-- pharmacy_dispenses → 200000
INSERT INTO pharmacy_dispenses (id, drug_id, prescription_id, quantity, pharmacist, dispensed_at, created_at)
SELECT g,
       ((g - 1) % 50000) + 1,
       ((g - 1) % 150000) + 1,
       1 + (g % 60),
       CONCAT('Pharmacist ', g % 200),
       DATE_ADD('2024-06-02 09:00:00', INTERVAL (g % 600) DAY),
       DATE_ADD('2024-06-02 09:00:00', INTERVAL (g % 600) DAY)
FROM seq WHERE g <= 200000;

-- pharmacy_stock_moves → 200000 (quantity <> 0)
INSERT INTO pharmacy_stock_moves (id, drug_id, move_type, quantity, reason, moved_at, created_at)
SELECT g,
       ((g - 1) % 50000) + 1,
       ELT((g % 5) + 1,'receipt','dispense','adjustment','return','expiry_writeoff'),
       IF(g % 2 = 0, 1 + (g % 500), -(1 + (g % 500))),
       ELT((g % 5) + 1,'Routine receipt','Patient dispense','Cycle count','Customer return','Expired stock'),
       DATE_ADD('2024-06-01 12:00:00', INTERVAL (g % 600) DAY),
       DATE_ADD('2024-06-01 12:00:00', INTERVAL (g % 600) DAY)
FROM seq WHERE g <= 200000;

-- billing_insurers → 2000
INSERT INTO billing_insurers (id, name, country, plan_type, contact_email, created_at)
SELECT g,
       CONCAT(ELT((g % 8) + 1,'BlueCross','Aetna','Cigna','Humana','Bao Viet','PVI','UnitedHealth','Allianz'), ' ', g),
       ELT((g % 8) + 1,'US','US','VN','DE','GB','FR','JP','SG'),
       ELT((g % 4) + 1,'public','private','employer','supplemental'),
       CONCAT('claims', g, '@insurer.example.com'),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 2000;

-- billing_services → 5000
INSERT INTO billing_services (id, code, name, category, unit_price, created_at)
SELECT g,
       CONCAT('SVC-', LPAD(g, 6, '0')),
       CONCAT(ELT((g % 8) + 1,'Consultation','X-Ray','MRI Scan','Blood Test','Surgery','Physiotherapy','Vaccination','ECG'), ' ', g),
       ELT((g % 6) + 1,'Consultation','Imaging','Laboratory','Surgical','Therapy','Preventive'),
       ROUND((1000 + (g * 31) % 500000) / 100, 2),
       DATE_ADD('2024-01-01 09:00:00', INTERVAL (g % 400) DAY)
FROM seq WHERE g <= 5000;

-- billing_invoices → 150000
INSERT INTO billing_invoices (id, patient_id, insurer_id, invoice_number, amount, status, issued_at, due_date, created_at)
SELECT g,
       ((g - 1) % 80000) + 1,
       IF(g % 5 = 0, NULL, ((g - 1) % 2000) + 1),
       CONCAT('INV-', LPAD(g, 9, '0')),
       ROUND((2000 + (g * 43) % 2000000) / 100, 2),
       ELT((g % 6) + 1,'open','sent','paid','partially_paid','overdue','written_off'),
       DATE_ADD('2024-06-01 08:00:00', INTERVAL (g % 700) DAY),
       DATE_ADD('2024-07-01', INTERVAL (g % 700) DAY),
       DATE_ADD('2024-06-01 08:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 150000;

-- billing_claims → 120000
INSERT INTO billing_claims (id, invoice_id, insurer_id, claim_number, amount, status, submitted_at, resolved_at, created_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       ((g - 1) % 2000) + 1,
       CONCAT('CLM-', LPAD(g, 9, '0')),
       ROUND((2000 + (g * 37) % 1500000) / 100, 2),
       ELT((g % 6) + 1,'submitted','in_review','approved','partially_approved','denied','paid'),
       DATE_ADD('2024-06-05 08:00:00', INTERVAL (g % 700) DAY),
       IF(g % 3 = 0, NULL, DATE_ADD('2024-06-20 08:00:00', INTERVAL (g % 700) DAY)),
       DATE_ADD('2024-06-05 08:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 120000;

-- billing_payments → 150000
INSERT INTO billing_payments (id, invoice_id, method, amount, paid_at, created_at)
SELECT g,
       ((g - 1) % 150000) + 1,
       ELT((g % 4) + 1,'cash','card','insurance','bank_transfer'),
       ROUND((1000 + (g * 29) % 1000000) / 100, 2),
       IF(g % 6 = 0, NULL, DATE_ADD('2024-06-10 08:00:00', INTERVAL (g % 700) DAY)),
       DATE_ADD('2024-06-10 08:00:00', INTERVAL (g % 700) DAY)
FROM seq WHERE g <= 150000;

DROP TEMPORARY TABLE IF EXISTS seq;
SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;
