-- Healthcare › clinical data. Full-scale via generate_series (deterministic).
-- patients 80,000 · encounters 200,000 · diagnoses 200,000 · vitals 200,000 · prescriptions 150,000
SET search_path = clinical;
BEGIN;

-- patients → 80,000
INSERT INTO patients (id, mrn, first_name, last_name, dob, gender, blood_type, phone)
SELECT g,
       'MRN-' || lpad(g::text, 9, '0'),
       (ARRAY['An','Binh','Chi','Dung','Em','Phuc','Giang','Ha','Khanh','Linh','Minh','Nam','Oanh','Phong','Quang','Son','Thu','Uyen','Viet','Yen'])[1 + (g % 20)],
       (ARRAY['Nguyen','Tran','Le','Pham','Hoang','Vu','Dang','Bui','Do','Ho','Ngo','Duong','Ly','Vo','Phan','Truong','Dinh','Mai','Cao','Ta'])[1 + ((g / 20) % 20)],
       DATE '1950-01-01' + ((g * 97) % 26000),
       (ARRAY['male','female','other'])[1 + (g % 3)],
       (ARRAY['A+','A-','B+','B-','AB+','AB-','O+','O-'])[1 + (g % 8)],
       '+8490' || lpad((1000000 + g)::text, 7, '0')
FROM generate_series(1, 80000) AS g;

-- encounters → 200,000
INSERT INTO encounters (id, patient_id, encounter_type, department, admitted_at, discharged_at, status)
SELECT g,
       ((g - 1) % 80000) + 1,
       (ARRAY['outpatient','outpatient','inpatient','emergency','telehealth'])[1 + (g % 5)],
       (ARRAY['Cardiology','Neurology','Pediatrics','Orthopedics','Oncology','Emergency','Internal Medicine','Dermatology'])[1 + (g % 8)],
       TIMESTAMPTZ '2024-06-01 08:00:00' + ((g % 700) || ' days')::interval,
       CASE WHEN g % 4 = 0 THEN NULL ELSE TIMESTAMPTZ '2024-06-03 08:00:00' + ((g % 700) || ' days')::interval END,
       (ARRAY['open','discharged','discharged','transferred','cancelled'])[1 + (g % 5)]
FROM generate_series(1, 200000) AS g;

-- diagnoses → 200,000
INSERT INTO diagnoses (id, encounter_id, icd10_code, description, severity, diagnosed_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       (ARRAY['I10','E11','J45','K21','M54','F41','N39','R51'])[1 + (g % 8)] || '.' || (g % 10),
       (ARRAY['Hypertension','Type 2 diabetes','Asthma','Reflux disease','Low back pain','Anxiety disorder','Urinary infection','Headache'])[1 + (g % 8)],
       (ARRAY['mild','mild','moderate','severe','critical'])[1 + (g % 5)],
       TIMESTAMPTZ '2024-06-01 09:00:00' + ((g % 700) || ' days')::interval
FROM generate_series(1, 200000) AS g;

-- vitals → 200,000
INSERT INTO vitals (id, encounter_id, measured_at, heart_rate, systolic, diastolic, temperature, spo2)
SELECT g,
       ((g - 1) % 200000) + 1,
       TIMESTAMPTZ '2024-06-01 10:00:00' + ((g % 700) || ' days')::interval,
       55 + (g % 80),
       95 + (g % 70),
       60 + (g % 40),
       round((36.0 + (g % 30) / 10.0)::numeric, 1),
       90 + (g % 11)
FROM generate_series(1, 200000) AS g;

-- prescriptions → 150,000 (drug_id references pharmacy.drugs externally, 1..50000)
INSERT INTO prescriptions (id, encounter_id, drug_id, drug_name, dosage, frequency, duration_days, prescribed_at)
SELECT g,
       ((g - 1) % 200000) + 1,
       ((g - 1) % 50000) + 1,
       (ARRAY['Amoxicillin','Metformin','Atorvastatin','Omeprazole','Amlodipine','Salbutamol','Ibuprofen','Paracetamol'])[1 + (g % 8)],
       (ARRAY['250mg','500mg','5mg','10mg','20mg','1 puff'])[1 + (g % 6)],
       (ARRAY['once daily','twice daily','three times daily','as needed'])[1 + (g % 4)],
       1 + (g % 90),
       TIMESTAMPTZ '2024-06-01 11:00:00' + ((g % 700) || ' days')::interval
FROM generate_series(1, 150000) AS g;

COMMIT;

-- Reset sequences for this schema
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT table_name FROM information_schema.columns
           WHERE table_schema = 'clinical' AND column_name = 'id' AND column_default LIKE 'nextval%'
  LOOP
    EXECUTE format('SELECT setval(pg_get_serial_sequence(''clinical.%I'', ''id''), COALESCE((SELECT MAX(id) FROM clinical.%I), 1))', r.table_name, r.table_name);
  END LOOP;
END $$;
