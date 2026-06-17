-- Healthcare › clinical schema: patient care (5 tables + 1 view).
-- Idempotent: safe to re-run (uses IF NOT EXISTS / OR REPLACE).

CREATE SCHEMA IF NOT EXISTS clinical;
SET search_path = clinical;

-- 1. patients — patient master
CREATE TABLE IF NOT EXISTS patients (
    id          SERIAL PRIMARY KEY,
    mrn         VARCHAR(20) NOT NULL UNIQUE,
    first_name  VARCHAR(60) NOT NULL,
    last_name   VARCHAR(60) NOT NULL,
    dob         DATE NOT NULL,
    gender      VARCHAR(10) NOT NULL CHECK (gender IN ('male','female','other')),
    blood_type  VARCHAR(3) CHECK (blood_type IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    phone       VARCHAR(30),
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. encounters — hospital visits / admissions
CREATE TABLE IF NOT EXISTS encounters (
    id             SERIAL PRIMARY KEY,
    patient_id     INT NOT NULL REFERENCES patients(id),
    encounter_type VARCHAR(20) NOT NULL CHECK (encounter_type IN ('outpatient','inpatient','emergency','telehealth')),
    department     VARCHAR(60) NOT NULL,
    admitted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    discharged_at  TIMESTAMPTZ,
    status         VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open','discharged','transferred','cancelled')),
    created_at     TIMESTAMPTZ DEFAULT now()
);

-- 3. diagnoses — coded diagnoses per encounter
CREATE TABLE IF NOT EXISTS diagnoses (
    id            SERIAL PRIMARY KEY,
    encounter_id  INT NOT NULL REFERENCES encounters(id),
    icd10_code    VARCHAR(10) NOT NULL,
    description   VARCHAR(200) NOT NULL,
    severity      VARCHAR(10) NOT NULL DEFAULT 'mild' CHECK (severity IN ('mild','moderate','severe','critical')),
    diagnosed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 4. vitals — vital-sign measurements
CREATE TABLE IF NOT EXISTS vitals (
    id            SERIAL PRIMARY KEY,
    encounter_id  INT NOT NULL REFERENCES encounters(id),
    measured_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    heart_rate    INT CHECK (heart_rate BETWEEN 20 AND 250),
    systolic      INT CHECK (systolic BETWEEN 50 AND 260),
    diastolic     INT CHECK (diastolic BETWEEN 30 AND 200),
    temperature   NUMERIC(4,1) CHECK (temperature BETWEEN 30 AND 45),
    spo2          INT CHECK (spo2 BETWEEN 50 AND 100),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- 5. prescriptions — medication orders (drug lives in pharmacy schema; referenced by id/name)
CREATE TABLE IF NOT EXISTS prescriptions (
    id             SERIAL PRIMARY KEY,
    encounter_id   INT NOT NULL REFERENCES encounters(id),
    drug_id        INT NOT NULL,
    drug_name      VARCHAR(150) NOT NULL,
    dosage         VARCHAR(40) NOT NULL,
    frequency      VARCHAR(40) NOT NULL,
    duration_days  INT NOT NULL CHECK (duration_days > 0),
    prescribed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cln_enc_patient   ON encounters(patient_id);
CREATE INDEX IF NOT EXISTS idx_cln_enc_status    ON encounters(status);
CREATE INDEX IF NOT EXISTS idx_cln_diag_enc      ON diagnoses(encounter_id);
CREATE INDEX IF NOT EXISTS idx_cln_vitals_enc    ON vitals(encounter_id);
CREATE INDEX IF NOT EXISTS idx_cln_rx_enc        ON prescriptions(encounter_id);

CREATE OR REPLACE VIEW v_encounter_load AS
SELECT
    e.department,
    e.encounter_type,
    COUNT(*)                                           AS encounters,
    COUNT(*) FILTER (WHERE e.status = 'open')          AS open_now,
    COUNT(DISTINCT e.patient_id)                       AS unique_patients
FROM encounters e
GROUP BY e.department, e.encounter_type
ORDER BY encounters DESC;
