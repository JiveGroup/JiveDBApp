-- jdb_healthcare — Healthcare domain (15 tables, area-prefixed: clinical_/pharmacy_/billing_).
SET FOREIGN_KEY_CHECKS = 0;

-- ── clinical ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clinical_patients (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  mrn        VARCHAR(20) NOT NULL UNIQUE,
  first_name VARCHAR(60) NOT NULL,
  last_name  VARCHAR(60) NOT NULL,
  dob        DATE NOT NULL,
  gender     ENUM('male','female','other') NOT NULL,
  blood_type ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-'),
  phone      VARCHAR(30),
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS clinical_encounters (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  patient_id     BIGINT NOT NULL,
  encounter_type ENUM('outpatient','inpatient','emergency','telehealth') NOT NULL,
  department     VARCHAR(60) NOT NULL,
  admitted_at    DATETIME NOT NULL,
  discharged_at  DATETIME NULL,
  status         ENUM('open','discharged','transferred','cancelled') NOT NULL DEFAULT 'open',
  created_at     DATETIME NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES clinical_patients(id),
  KEY idx_enc_patient (patient_id),
  KEY idx_enc_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS clinical_diagnoses (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  encounter_id BIGINT NOT NULL,
  icd10_code   VARCHAR(10) NOT NULL,
  description  VARCHAR(200) NOT NULL,
  severity     ENUM('mild','moderate','severe','critical') NOT NULL DEFAULT 'mild',
  diagnosed_at DATETIME NOT NULL,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES clinical_encounters(id),
  KEY idx_diag_enc (encounter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS clinical_vitals (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  encounter_id BIGINT NOT NULL,
  measured_at  DATETIME NOT NULL,
  heart_rate   SMALLINT,
  systolic     SMALLINT,
  diastolic    SMALLINT,
  temperature  DECIMAL(4,1),
  spo2         SMALLINT,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES clinical_encounters(id),
  KEY idx_vitals_enc (encounter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS clinical_prescriptions (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  encounter_id  BIGINT NOT NULL,
  drug_id       BIGINT NOT NULL,
  drug_name     VARCHAR(150) NOT NULL,
  dosage        VARCHAR(40) NOT NULL,
  frequency     VARCHAR(40) NOT NULL,
  duration_days INT UNSIGNED NOT NULL,
  prescribed_at DATETIME NOT NULL,
  created_at    DATETIME NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES clinical_encounters(id),
  FOREIGN KEY (drug_id)      REFERENCES pharmacy_drugs(id),
  KEY idx_rx_enc (encounter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── pharmacy ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pharmacy_suppliers (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(120) NOT NULL,
  country       VARCHAR(40),
  contact_email VARCHAR(255),
  status        ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
  created_at    DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pharmacy_drugs (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(150) NOT NULL,
  generic_name  VARCHAR(150),
  atc_code      VARCHAR(10) NOT NULL,
  form          ENUM('tablet','capsule','syrup','injection','inhaler','cream') NOT NULL,
  strength      VARCHAR(40),
  unit_price    DECIMAL(10,2) NOT NULL,
  is_controlled TINYINT(1) NOT NULL DEFAULT 0,
  created_at    DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pharmacy_drug_inventory (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  drug_id     BIGINT NOT NULL,
  batch_no    VARCHAR(40) NOT NULL UNIQUE,
  quantity    INT UNSIGNED NOT NULL DEFAULT 0,
  expiry_date DATE NULL,
  received_at DATETIME NOT NULL,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (drug_id) REFERENCES pharmacy_drugs(id),
  KEY idx_inv_drug (drug_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pharmacy_dispenses (
  id              BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  drug_id         BIGINT NOT NULL,
  prescription_id BIGINT NOT NULL,
  quantity        INT UNSIGNED NOT NULL,
  pharmacist      VARCHAR(120) NOT NULL,
  dispensed_at    DATETIME NOT NULL,
  created_at      DATETIME NOT NULL,
  FOREIGN KEY (drug_id)         REFERENCES pharmacy_drugs(id),
  FOREIGN KEY (prescription_id) REFERENCES clinical_prescriptions(id),
  KEY idx_disp_drug (drug_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pharmacy_stock_moves (
  id        BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  drug_id   BIGINT NOT NULL,
  move_type ENUM('receipt','dispense','adjustment','return','expiry_writeoff') NOT NULL,
  quantity  INT NOT NULL,
  reason    VARCHAR(120),
  moved_at  DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (drug_id) REFERENCES pharmacy_drugs(id),
  KEY idx_moves_drug (drug_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── billing ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS billing_insurers (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(120) NOT NULL,
  country       VARCHAR(40),
  plan_type     ENUM('public','private','employer','supplemental') NOT NULL,
  contact_email VARCHAR(255),
  created_at    DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS billing_services (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(20) NOT NULL UNIQUE,
  name       VARCHAR(150) NOT NULL,
  category   VARCHAR(60) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS billing_invoices (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  patient_id     BIGINT NOT NULL,
  insurer_id     BIGINT NULL,
  invoice_number VARCHAR(30) NOT NULL UNIQUE,
  amount         DECIMAL(14,2) NOT NULL,
  status         ENUM('open','sent','paid','partially_paid','overdue','written_off') NOT NULL DEFAULT 'open',
  issued_at      DATETIME NOT NULL,
  due_date       DATE NOT NULL,
  created_at     DATETIME NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES clinical_patients(id),
  FOREIGN KEY (insurer_id) REFERENCES billing_insurers(id),
  KEY idx_inv_insurer (insurer_id),
  KEY idx_inv_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS billing_claims (
  id           BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  invoice_id   BIGINT NOT NULL,
  insurer_id   BIGINT NOT NULL,
  claim_number VARCHAR(30) NOT NULL UNIQUE,
  amount       DECIMAL(14,2) NOT NULL,
  status       ENUM('submitted','in_review','approved','partially_approved','denied','paid') NOT NULL DEFAULT 'submitted',
  submitted_at DATETIME NOT NULL,
  resolved_at  DATETIME NULL,
  created_at   DATETIME NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES billing_invoices(id),
  FOREIGN KEY (insurer_id) REFERENCES billing_insurers(id),
  KEY idx_claims_inv (invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS billing_payments (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  invoice_id BIGINT NOT NULL,
  method     ENUM('cash','card','insurance','bank_transfer') NOT NULL,
  amount     DECIMAL(14,2) NOT NULL,
  paid_at    DATETIME NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES billing_invoices(id),
  KEY idx_pay_inv (invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
