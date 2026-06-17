-- jdb_banking — Banking domain (15 tables, area-prefixed: accounts_/lending_/cards_).
SET FOREIGN_KEY_CHECKS = 0;

-- ── accounts ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS accounts_branches (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(12) NOT NULL UNIQUE,
  name       VARCHAR(120) NOT NULL,
  city       VARCHAR(60),
  country    VARCHAR(40),
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS accounts_customers (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  full_name   VARCHAR(120) NOT NULL,
  national_id VARCHAR(20) NOT NULL UNIQUE,
  email       VARCHAR(255),
  phone       VARCHAR(30),
  kyc_status  ENUM('pending','verified','rejected','review') NOT NULL DEFAULT 'pending',
  created_at  DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS accounts_accounts (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  customer_id    BIGINT NOT NULL,
  branch_id      BIGINT NOT NULL,
  account_number VARCHAR(24) NOT NULL UNIQUE,
  account_type   ENUM('checking','savings','term_deposit','credit') NOT NULL,
  currency       CHAR(3) NOT NULL DEFAULT 'USD',
  balance        DECIMAL(16,2) NOT NULL DEFAULT 0,
  status         ENUM('active','dormant','frozen','closed') NOT NULL DEFAULT 'active',
  opened_at      DATE NOT NULL,
  created_at     DATETIME NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES accounts_customers(id),
  FOREIGN KEY (branch_id)   REFERENCES accounts_branches(id),
  KEY idx_accounts_customer (customer_id),
  KEY idx_accounts_branch (branch_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS accounts_transactions (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id    BIGINT NOT NULL,
  txn_type      ENUM('deposit','withdrawal','transfer','fee','interest') NOT NULL,
  amount        DECIMAL(16,2) NOT NULL,
  balance_after DECIMAL(16,2) NOT NULL,
  description   VARCHAR(200),
  txn_at        DATETIME NOT NULL,
  created_at    DATETIME NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts_accounts(id),
  KEY idx_txn_account (account_id),
  KEY idx_txn_type (txn_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS accounts_beneficiaries (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id     BIGINT NOT NULL,
  name           VARCHAR(120) NOT NULL,
  bank_name      VARCHAR(120),
  account_number VARCHAR(24) NOT NULL,
  created_at     DATETIME NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts_accounts(id),
  KEY idx_benef_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── lending ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lending_applications (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT NOT NULL,
  product     ENUM('personal','mortgage','auto','business','student') NOT NULL,
  amount      DECIMAL(16,2) NOT NULL,
  status      ENUM('submitted','under_review','approved','rejected','withdrawn') NOT NULL DEFAULT 'submitted',
  applied_at  DATETIME NOT NULL,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES accounts_customers(id),
  KEY idx_app_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lending_loans (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  application_id BIGINT NOT NULL,
  loan_number    VARCHAR(24) NOT NULL UNIQUE,
  principal      DECIMAL(16,2) NOT NULL,
  interest_rate  DECIMAL(5,2) NOT NULL,
  term_months    INT UNSIGNED NOT NULL,
  status         ENUM('active','paid_off','delinquent','defaulted','restructured') NOT NULL DEFAULT 'active',
  disbursed_at   DATE NOT NULL,
  created_at     DATETIME NOT NULL,
  FOREIGN KEY (application_id) REFERENCES lending_applications(id),
  KEY idx_loans_app (application_id),
  KEY idx_loans_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lending_collaterals (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  loan_id     BIGINT NOT NULL,
  kind        ENUM('property','vehicle','deposit','equipment','securities') NOT NULL,
  description VARCHAR(200),
  value       DECIMAL(16,2) NOT NULL,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (loan_id) REFERENCES lending_loans(id),
  KEY idx_collat_loan (loan_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lending_repayments (
  id             BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  loan_id        BIGINT NOT NULL,
  amount         DECIMAL(14,2) NOT NULL,
  principal_part DECIMAL(14,2) NOT NULL DEFAULT 0,
  interest_part  DECIMAL(14,2) NOT NULL DEFAULT 0,
  paid_at        DATETIME NOT NULL,
  created_at     DATETIME NOT NULL,
  FOREIGN KEY (loan_id) REFERENCES lending_loans(id),
  KEY idx_repay_loan (loan_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lending_schedules (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  loan_id     BIGINT NOT NULL,
  due_date    DATE NOT NULL,
  installment DECIMAL(14,2) NOT NULL,
  is_paid     TINYINT(1) NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (loan_id) REFERENCES lending_loans(id),
  KEY idx_sched_loan (loan_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── cards ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cards_merchants (
  id         BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  category   VARCHAR(60) NOT NULL,
  mcc        CHAR(4) NOT NULL,
  country    VARCHAR(40),
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cards_cards (
  id          BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  account_id  BIGINT NOT NULL,
  card_masked VARCHAR(19) NOT NULL UNIQUE,
  brand       ENUM('visa','mastercard','amex','jcb','unionpay') NOT NULL,
  status      ENUM('active','blocked','expired','lost','stolen') NOT NULL DEFAULT 'active',
  expires_on  DATE NOT NULL,
  created_at  DATETIME NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts_accounts(id),
  KEY idx_cards_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cards_authorizations (
  id            BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  card_id       BIGINT NOT NULL,
  merchant_id   BIGINT NOT NULL,
  amount        DECIMAL(14,2) NOT NULL,
  currency      CHAR(3) NOT NULL DEFAULT 'USD',
  status        ENUM('approved','declined','reversed','expired') NOT NULL DEFAULT 'approved',
  authorized_at DATETIME NOT NULL,
  created_at    DATETIME NOT NULL,
  FOREIGN KEY (card_id)     REFERENCES cards_cards(id),
  FOREIGN KEY (merchant_id) REFERENCES cards_merchants(id),
  KEY idx_auth_card (card_id),
  KEY idx_auth_merchant (merchant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cards_settlements (
  id               BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  authorization_id BIGINT NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,
  status           ENUM('settled','pending','failed') NOT NULL DEFAULT 'settled',
  settled_at       DATETIME NULL,
  created_at       DATETIME NOT NULL,
  FOREIGN KEY (authorization_id) REFERENCES cards_authorizations(id),
  KEY idx_settle_auth (authorization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cards_disputes (
  id               BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  authorization_id BIGINT NOT NULL,
  reason           VARCHAR(120) NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,
  status           ENUM('open','under_review','won','lost','withdrawn') NOT NULL DEFAULT 'open',
  opened_at        DATETIME NOT NULL,
  resolved_at      DATETIME NULL,
  created_at       DATETIME NOT NULL,
  FOREIGN KEY (authorization_id) REFERENCES cards_authorizations(id),
  KEY idx_disputes_auth (authorization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
