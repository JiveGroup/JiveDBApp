-- LITE — bộ TẦM TRUNG: 100 bảng (schema)
CREATE TABLE core_user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  full_name TEXT,
  qty INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE core_order (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  city TEXT,
  country TEXT,
  created_at TEXT NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE core_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  full_name TEXT,
  rate REAL,
  status TEXT,
  email TEXT,
  status_2 TEXT,
  created_at TEXT NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE core_event (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  rate REAL,
  score INTEGER,
  amount REAL,
  created_at TEXT NOT NULL,
  core_item_id bigint,
  FOREIGN KEY (core_item_id) REFERENCES core_item(id)
);
CREATE TABLE core_tag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  score INTEGER,
  active_2 INTEGER,
  country TEXT,
  qty INTEGER,
  qty_2 INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE core_note (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name TEXT,
  score INTEGER,
  amount REAL,
  active INTEGER,
  active_2 INTEGER,
  country TEXT,
  created_at TEXT NOT NULL,
  core_tag_id bigint,
  FOREIGN KEY (core_tag_id) REFERENCES core_tag(id)
);
CREATE TABLE core_role (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  email TEXT,
  qty_2 INTEGER,
  note TEXT,
  score INTEGER,
  email_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE core_team (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  qty INTEGER,
  code_2 TEXT,
  code_3 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE core_site (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  country TEXT,
  active INTEGER,
  status TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE core_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  amount REAL,
  city TEXT,
  name TEXT,
  name_2 TEXT,
  rate REAL,
  created_at TEXT NOT NULL
);
CREATE TABLE core_task (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  country TEXT,
  score INTEGER,
  status TEXT,
  amount REAL,
  created_at TEXT NOT NULL,
  core_site_id bigint,
  FOREIGN KEY (core_site_id) REFERENCES core_site(id)
);
CREATE TABLE core_file (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  score INTEGER,
  note TEXT,
  note_2 TEXT,
  name TEXT,
  city_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE core_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  email TEXT,
  code TEXT,
  full_name TEXT,
  created_at TEXT NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE core_zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  code TEXT,
  country TEXT,
  amount REAL,
  score INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE core_unit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  name_2 TEXT,
  qty INTEGER,
  name_3 TEXT,
  full_name TEXT,
  amount REAL,
  created_at TEXT NOT NULL,
  core_team_id bigint,
  FOREIGN KEY (core_team_id) REFERENCES core_team(id)
);
CREATE TABLE core_asset (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL,
  country TEXT,
  email TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE core_lead (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  qty INTEGER,
  status TEXT,
  active INTEGER,
  active_2 INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE core_deal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  amount REAL,
  score INTEGER,
  city TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE core_ticket (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  city TEXT,
  country TEXT,
  qty INTEGER,
  created_at TEXT NOT NULL,
  core_role_id bigint,
  FOREIGN KEY (core_role_id) REFERENCES core_role(id)
);
CREATE TABLE core_invoice (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  qty INTEGER,
  country_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE app_user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  full_name TEXT,
  note TEXT,
  country_2 TEXT,
  score INTEGER,
  created_at TEXT NOT NULL,
  core_asset_id bigint,
  FOREIGN KEY (core_asset_id) REFERENCES core_asset(id)
);
CREATE TABLE app_order (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name TEXT,
  amount REAL,
  status TEXT,
  amount_2 REAL,
  created_at TEXT NOT NULL,
  core_invoice_id bigint,
  FOREIGN KEY (core_invoice_id) REFERENCES core_invoice(id)
);
CREATE TABLE app_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rate REAL,
  qty INTEGER,
  amount REAL,
  note TEXT,
  status TEXT,
  active INTEGER,
  created_at TEXT NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE app_event (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  amount REAL,
  status TEXT,
  status_2 TEXT,
  rate REAL,
  amount_2 REAL,
  created_at TEXT NOT NULL
);
CREATE TABLE app_tag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  rate REAL,
  city TEXT,
  created_at TEXT NOT NULL,
  core_zone_id bigint,
  FOREIGN KEY (core_zone_id) REFERENCES core_zone(id)
);
CREATE TABLE app_note (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  status TEXT,
  code TEXT,
  city_2 TEXT,
  score INTEGER,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE app_role (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  score INTEGER,
  name TEXT,
  note_2 TEXT,
  created_at TEXT NOT NULL,
  core_item_id bigint,
  FOREIGN KEY (core_item_id) REFERENCES core_item(id)
);
CREATE TABLE app_team (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  city TEXT,
  code TEXT,
  country TEXT,
  rate REAL,
  created_at TEXT NOT NULL,
  app_item_id bigint,
  FOREIGN KEY (app_item_id) REFERENCES app_item(id)
);
CREATE TABLE app_site (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  country TEXT,
  score INTEGER,
  active INTEGER,
  created_at TEXT NOT NULL,
  core_event_id bigint,
  FOREIGN KEY (core_event_id) REFERENCES core_event(id)
);
CREATE TABLE app_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  active INTEGER,
  score INTEGER,
  score_2 INTEGER,
  status TEXT,
  note TEXT,
  created_at TEXT NOT NULL,
  app_order_id bigint,
  FOREIGN KEY (app_order_id) REFERENCES app_order(id)
);
CREATE TABLE app_task (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  code TEXT,
  score INTEGER,
  city TEXT,
  amount REAL,
  name TEXT,
  created_at TEXT NOT NULL,
  core_task_id bigint,
  FOREIGN KEY (core_task_id) REFERENCES core_task(id)
);
CREATE TABLE app_file (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  status_2 TEXT,
  status_3 TEXT,
  qty INTEGER,
  created_at TEXT NOT NULL,
  core_unit_id bigint,
  FOREIGN KEY (core_unit_id) REFERENCES core_unit(id)
);
CREATE TABLE app_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  status TEXT,
  full_name TEXT,
  active INTEGER,
  created_at TEXT NOT NULL,
  core_order_id bigint,
  FOREIGN KEY (core_order_id) REFERENCES core_order(id)
);
CREATE TABLE app_zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  amount REAL,
  amount_2 REAL,
  city TEXT,
  created_at TEXT NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE app_unit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  active INTEGER,
  active_2 INTEGER,
  city TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE app_asset (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  qty INTEGER,
  active INTEGER,
  name_2 TEXT,
  qty_2 INTEGER,
  country TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE app_lead (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  status TEXT,
  code TEXT,
  status_2 TEXT,
  rate REAL,
  status_3 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE app_deal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  full_name TEXT,
  name TEXT,
  name_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE app_ticket (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  name TEXT,
  rate REAL,
  qty INTEGER,
  city TEXT,
  created_at TEXT NOT NULL,
  core_ticket_id bigint,
  FOREIGN KEY (core_ticket_id) REFERENCES core_ticket(id)
);
CREATE TABLE app_invoice (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  qty INTEGER,
  amount REAL,
  city_2 TEXT,
  score INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  qty_2 INTEGER,
  full_name TEXT,
  created_at TEXT NOT NULL,
  core_zone_id bigint,
  FOREIGN KEY (core_zone_id) REFERENCES core_zone(id)
);
CREATE TABLE crm_order (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  status TEXT,
  country TEXT,
  name TEXT,
  qty INTEGER,
  note TEXT,
  created_at TEXT NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE crm_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  qty_2 INTEGER,
  amount REAL,
  rate REAL,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_event (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  full_name TEXT,
  full_name_2 TEXT,
  amount REAL,
  country TEXT,
  created_at TEXT NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE crm_tag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  full_name TEXT,
  code TEXT,
  active_2 INTEGER,
  score INTEGER,
  full_name_2 TEXT,
  created_at TEXT NOT NULL,
  core_asset_id bigint,
  FOREIGN KEY (core_asset_id) REFERENCES core_asset(id)
);
CREATE TABLE crm_note (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  qty INTEGER,
  country TEXT,
  qty_2 INTEGER,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_role (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  rate REAL,
  amount REAL,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_team (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  score INTEGER,
  status TEXT,
  full_name TEXT,
  email TEXT,
  email_2 TEXT,
  created_at TEXT NOT NULL,
  crm_tag_id bigint,
  FOREIGN KEY (crm_tag_id) REFERENCES crm_tag(id)
);
CREATE TABLE crm_site (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  score INTEGER,
  amount REAL,
  name TEXT,
  name_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  score INTEGER,
  active INTEGER,
  created_at TEXT NOT NULL,
  app_deal_id bigint,
  FOREIGN KEY (app_deal_id) REFERENCES app_deal(id)
);
CREATE TABLE crm_task (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  country TEXT,
  amount REAL,
  rate REAL,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_file (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  code TEXT,
  qty_2 INTEGER,
  name TEXT,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  city TEXT,
  full_name TEXT,
  full_name_2 TEXT,
  note TEXT,
  score INTEGER,
  created_at TEXT NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE crm_zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  city TEXT,
  note TEXT,
  amount REAL,
  qty INTEGER,
  name TEXT,
  created_at TEXT NOT NULL,
  core_role_id bigint,
  FOREIGN KEY (core_role_id) REFERENCES core_role(id)
);
CREATE TABLE crm_unit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  rate REAL,
  code TEXT,
  country_2 TEXT,
  note TEXT,
  full_name TEXT,
  created_at TEXT NOT NULL,
  crm_event_id bigint,
  FOREIGN KEY (crm_event_id) REFERENCES crm_event(id)
);
CREATE TABLE crm_asset (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  code TEXT,
  full_name TEXT,
  score INTEGER,
  qty INTEGER,
  created_at TEXT NOT NULL,
  app_asset_id bigint,
  FOREIGN KEY (app_asset_id) REFERENCES app_asset(id)
);
CREATE TABLE crm_lead (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  full_name TEXT,
  amount REAL,
  note TEXT,
  created_at TEXT NOT NULL,
  core_ticket_id bigint,
  FOREIGN KEY (core_ticket_id) REFERENCES core_ticket(id)
);
CREATE TABLE crm_deal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  name TEXT,
  rate REAL,
  full_name TEXT,
  score INTEGER,
  code_2 TEXT,
  created_at TEXT NOT NULL,
  core_deal_id bigint,
  FOREIGN KEY (core_deal_id) REFERENCES core_deal(id)
);
CREATE TABLE crm_ticket (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  qty INTEGER,
  note_2 TEXT,
  status TEXT,
  qty_2 INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE crm_invoice (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL,
  score INTEGER,
  rate REAL,
  status TEXT,
  code TEXT,
  score_2 INTEGER,
  created_at TEXT NOT NULL,
  app_asset_id bigint,
  FOREIGN KEY (app_asset_id) REFERENCES app_asset(id)
);
CREATE TABLE hr_user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  country TEXT,
  amount REAL,
  country_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_order (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  active INTEGER,
  email TEXT,
  qty INTEGER,
  full_name TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  code TEXT,
  active INTEGER,
  amount REAL,
  city TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_event (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rate REAL,
  qty INTEGER,
  rate_2 REAL,
  created_at TEXT NOT NULL,
  hr_user_id bigint,
  FOREIGN KEY (hr_user_id) REFERENCES hr_user(id)
);
CREATE TABLE hr_tag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  note TEXT,
  note_2 TEXT,
  rate REAL,
  full_name TEXT,
  score_2 INTEGER,
  created_at TEXT NOT NULL,
  core_note_id bigint,
  FOREIGN KEY (core_note_id) REFERENCES core_note(id)
);
CREATE TABLE hr_note (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  note TEXT,
  email TEXT,
  status TEXT,
  amount REAL,
  full_name TEXT,
  created_at TEXT NOT NULL,
  crm_file_id bigint,
  FOREIGN KEY (crm_file_id) REFERENCES crm_file(id)
);
CREATE TABLE hr_role (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  qty INTEGER,
  amount REAL,
  created_at TEXT NOT NULL,
  crm_invoice_id bigint,
  FOREIGN KEY (crm_invoice_id) REFERENCES crm_invoice(id)
);
CREATE TABLE hr_team (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  full_name TEXT,
  active INTEGER,
  rate REAL,
  city TEXT,
  name TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_site (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  note TEXT,
  full_name TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  qty INTEGER,
  amount REAL,
  email TEXT,
  code TEXT,
  status_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_task (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  status TEXT,
  note_2 TEXT,
  rate REAL,
  active INTEGER,
  created_at TEXT NOT NULL,
  app_item_id bigint,
  FOREIGN KEY (app_item_id) REFERENCES app_item(id)
);
CREATE TABLE hr_file (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  country TEXT,
  full_name TEXT,
  email TEXT,
  amount REAL,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL,
  amount_2 REAL,
  qty INTEGER,
  status TEXT,
  full_name TEXT,
  created_at TEXT NOT NULL,
  hr_note_id bigint,
  FOREIGN KEY (hr_note_id) REFERENCES hr_note(id)
);
CREATE TABLE hr_zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name TEXT,
  qty INTEGER,
  name TEXT,
  status TEXT,
  code TEXT,
  qty_2 INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_unit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  score INTEGER,
  country TEXT,
  full_name TEXT,
  score_2 INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE hr_asset (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  note TEXT,
  city TEXT,
  amount REAL,
  created_at TEXT NOT NULL,
  crm_unit_id bigint,
  FOREIGN KEY (crm_unit_id) REFERENCES crm_unit(id)
);
CREATE TABLE hr_lead (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  rate REAL,
  status TEXT,
  email TEXT,
  score INTEGER,
  created_at TEXT NOT NULL,
  hr_asset_id bigint,
  FOREIGN KEY (hr_asset_id) REFERENCES hr_asset(id)
);
CREATE TABLE hr_deal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  active INTEGER,
  status TEXT,
  created_at TEXT NOT NULL,
  crm_note_id bigint,
  FOREIGN KEY (crm_note_id) REFERENCES crm_note(id)
);
CREATE TABLE hr_ticket (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  qty INTEGER,
  note_2 TEXT,
  status TEXT,
  amount REAL,
  created_at TEXT NOT NULL,
  hr_file_id bigint,
  FOREIGN KEY (hr_file_id) REFERENCES hr_file(id)
);
CREATE TABLE hr_invoice (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  active INTEGER,
  rate REAL,
  note TEXT,
  status_2 TEXT,
  created_at TEXT NOT NULL,
  hr_user_id bigint,
  FOREIGN KEY (hr_user_id) REFERENCES hr_user(id)
);
CREATE TABLE fin_user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL,
  code TEXT,
  code_2 TEXT,
  status TEXT,
  amount_2 REAL,
  created_at TEXT NOT NULL,
  crm_event_id bigint,
  FOREIGN KEY (crm_event_id) REFERENCES crm_event(id)
);
CREATE TABLE fin_order (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  country TEXT,
  status TEXT,
  note TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  status TEXT,
  city_2 TEXT,
  email TEXT,
  created_at TEXT NOT NULL,
  hr_plan_id bigint,
  FOREIGN KEY (hr_plan_id) REFERENCES hr_plan(id)
);
CREATE TABLE fin_event (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  active INTEGER,
  active_2 INTEGER,
  qty INTEGER,
  country TEXT,
  created_at TEXT NOT NULL,
  app_invoice_id bigint,
  FOREIGN KEY (app_invoice_id) REFERENCES app_invoice(id)
);
CREATE TABLE fin_tag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  code TEXT,
  code_2 TEXT,
  name TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_note (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT,
  status TEXT,
  country TEXT,
  amount REAL,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_role (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  note TEXT,
  city_2 TEXT,
  email TEXT,
  status TEXT,
  email_2 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_team (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  status TEXT,
  name TEXT,
  city TEXT,
  status_2 TEXT,
  country TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_site (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  note TEXT,
  active INTEGER,
  rate REAL,
  amount REAL,
  code TEXT,
  name TEXT,
  created_at TEXT NOT NULL,
  core_order_id bigint,
  FOREIGN KEY (core_order_id) REFERENCES core_order(id)
);
CREATE TABLE fin_plan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  amount REAL,
  score INTEGER,
  rate REAL,
  rate_2 REAL,
  name TEXT,
  created_at TEXT NOT NULL,
  app_zone_id bigint,
  FOREIGN KEY (app_zone_id) REFERENCES app_zone(id)
);
CREATE TABLE fin_task (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  active INTEGER,
  rate REAL,
  status TEXT,
  qty INTEGER,
  email TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_file (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  name TEXT,
  country TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  active INTEGER,
  amount REAL,
  full_name TEXT,
  email TEXT,
  score INTEGER,
  created_at TEXT NOT NULL,
  app_team_id bigint,
  FOREIGN KEY (app_team_id) REFERENCES app_team(id)
);
CREATE TABLE fin_zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT,
  name TEXT,
  status TEXT,
  name_2 TEXT,
  rate REAL,
  created_at TEXT NOT NULL,
  core_task_id bigint,
  FOREIGN KEY (core_task_id) REFERENCES core_task(id)
);
CREATE TABLE fin_unit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  country TEXT,
  score INTEGER,
  email TEXT,
  full_name TEXT,
  full_name_2 TEXT,
  note TEXT,
  created_at TEXT NOT NULL,
  crm_ticket_id bigint,
  FOREIGN KEY (crm_ticket_id) REFERENCES crm_ticket(id)
);
CREATE TABLE fin_asset (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rate REAL,
  active INTEGER,
  name TEXT,
  full_name TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_lead (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  city TEXT,
  note TEXT,
  email TEXT,
  email_2 TEXT,
  email_3 TEXT,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_deal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT,
  amount REAL,
  score INTEGER,
  email TEXT,
  active INTEGER,
  created_at TEXT NOT NULL
);
CREATE TABLE fin_ticket (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  city TEXT,
  name TEXT,
  qty INTEGER,
  created_at TEXT NOT NULL,
  hr_role_id bigint,
  FOREIGN KEY (hr_role_id) REFERENCES hr_role(id)
);
CREATE TABLE fin_invoice (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  qty INTEGER,
  country TEXT,
  rate REAL,
  created_at TEXT NOT NULL
);
