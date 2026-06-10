-- PG — bộ TẦM TRUNG: 100 bảng (schema)
CREATE TABLE core_user (
  id bigserial PRIMARY KEY,
  status varchar(16),
  full_name varchar(80),
  qty integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE core_order (
  id bigserial PRIMARY KEY,
  status varchar(16),
  city varchar(60),
  country varchar(2),
  created_at timestamptz NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE core_item (
  id bigserial PRIMARY KEY,
  country varchar(2),
  full_name varchar(80),
  rate numeric(5,2),
  status varchar(16),
  email varchar(120),
  status_2 varchar(16),
  created_at timestamptz NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE core_event (
  id bigserial PRIMARY KEY,
  name varchar(80),
  rate numeric(5,2),
  score integer,
  amount numeric(12,2),
  created_at timestamptz NOT NULL,
  core_item_id bigint,
  FOREIGN KEY (core_item_id) REFERENCES core_item(id)
);
CREATE TABLE core_tag (
  id bigserial PRIMARY KEY,
  active boolean,
  score integer,
  active_2 boolean,
  country varchar(2),
  qty integer,
  qty_2 integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE core_note (
  id bigserial PRIMARY KEY,
  full_name varchar(80),
  score integer,
  amount numeric(12,2),
  active boolean,
  active_2 boolean,
  country varchar(2),
  created_at timestamptz NOT NULL,
  core_tag_id bigint,
  FOREIGN KEY (core_tag_id) REFERENCES core_tag(id)
);
CREATE TABLE core_role (
  id bigserial PRIMARY KEY,
  qty integer,
  email varchar(120),
  qty_2 integer,
  note text,
  score integer,
  email_2 varchar(120),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_team (
  id bigserial PRIMARY KEY,
  code varchar(24),
  qty integer,
  code_2 varchar(24),
  code_3 varchar(24),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_site (
  id bigserial PRIMARY KEY,
  name varchar(80),
  country varchar(2),
  active boolean,
  status varchar(16),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_plan (
  id bigserial PRIMARY KEY,
  email varchar(120),
  amount numeric(12,2),
  city varchar(60),
  name varchar(80),
  name_2 varchar(80),
  rate numeric(5,2),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_task (
  id bigserial PRIMARY KEY,
  qty integer,
  country varchar(2),
  score integer,
  status varchar(16),
  amount numeric(12,2),
  created_at timestamptz NOT NULL,
  core_site_id bigint,
  FOREIGN KEY (core_site_id) REFERENCES core_site(id)
);
CREATE TABLE core_file (
  id bigserial PRIMARY KEY,
  city varchar(60),
  score integer,
  note text,
  note_2 text,
  name varchar(80),
  city_2 varchar(60),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_rule (
  id bigserial PRIMARY KEY,
  active boolean,
  email varchar(120),
  code varchar(24),
  full_name varchar(80),
  created_at timestamptz NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE core_zone (
  id bigserial PRIMARY KEY,
  email varchar(120),
  code varchar(24),
  country varchar(2),
  amount numeric(12,2),
  score integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE core_unit (
  id bigserial PRIMARY KEY,
  name varchar(80),
  name_2 varchar(80),
  qty integer,
  name_3 varchar(80),
  full_name varchar(80),
  amount numeric(12,2),
  created_at timestamptz NOT NULL,
  core_team_id bigint,
  FOREIGN KEY (core_team_id) REFERENCES core_team(id)
);
CREATE TABLE core_asset (
  id bigserial PRIMARY KEY,
  amount numeric(12,2),
  country varchar(2),
  email varchar(120),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_lead (
  id bigserial PRIMARY KEY,
  email varchar(120),
  qty integer,
  status varchar(16),
  active boolean,
  active_2 boolean,
  created_at timestamptz NOT NULL
);
CREATE TABLE core_deal (
  id bigserial PRIMARY KEY,
  code varchar(24),
  amount numeric(12,2),
  score integer,
  city varchar(60),
  created_at timestamptz NOT NULL
);
CREATE TABLE core_ticket (
  id bigserial PRIMARY KEY,
  note text,
  city varchar(60),
  country varchar(2),
  qty integer,
  created_at timestamptz NOT NULL,
  core_role_id bigint,
  FOREIGN KEY (core_role_id) REFERENCES core_role(id)
);
CREATE TABLE core_invoice (
  id bigserial PRIMARY KEY,
  country varchar(2),
  qty integer,
  country_2 varchar(2),
  created_at timestamptz NOT NULL
);
CREATE TABLE app_user (
  id bigserial PRIMARY KEY,
  country varchar(2),
  full_name varchar(80),
  note text,
  country_2 varchar(2),
  score integer,
  created_at timestamptz NOT NULL,
  core_asset_id bigint,
  FOREIGN KEY (core_asset_id) REFERENCES core_asset(id)
);
CREATE TABLE app_order (
  id bigserial PRIMARY KEY,
  full_name varchar(80),
  amount numeric(12,2),
  status varchar(16),
  amount_2 numeric(12,2),
  created_at timestamptz NOT NULL,
  core_invoice_id bigint,
  FOREIGN KEY (core_invoice_id) REFERENCES core_invoice(id)
);
CREATE TABLE app_item (
  id bigserial PRIMARY KEY,
  rate numeric(5,2),
  qty integer,
  amount numeric(12,2),
  note text,
  status varchar(16),
  active boolean,
  created_at timestamptz NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE app_event (
  id bigserial PRIMARY KEY,
  score integer,
  amount numeric(12,2),
  status varchar(16),
  status_2 varchar(16),
  rate numeric(5,2),
  amount_2 numeric(12,2),
  created_at timestamptz NOT NULL
);
CREATE TABLE app_tag (
  id bigserial PRIMARY KEY,
  status varchar(16),
  rate numeric(5,2),
  city varchar(60),
  created_at timestamptz NOT NULL,
  core_zone_id bigint,
  FOREIGN KEY (core_zone_id) REFERENCES core_zone(id)
);
CREATE TABLE app_note (
  id bigserial PRIMARY KEY,
  city varchar(60),
  status varchar(16),
  code varchar(24),
  city_2 varchar(60),
  score integer,
  note text,
  created_at timestamptz NOT NULL
);
CREATE TABLE app_role (
  id bigserial PRIMARY KEY,
  note text,
  score integer,
  name varchar(80),
  note_2 text,
  created_at timestamptz NOT NULL,
  core_item_id bigint,
  FOREIGN KEY (core_item_id) REFERENCES core_item(id)
);
CREATE TABLE app_team (
  id bigserial PRIMARY KEY,
  name varchar(80),
  city varchar(60),
  code varchar(24),
  country varchar(2),
  rate numeric(5,2),
  created_at timestamptz NOT NULL,
  app_item_id bigint,
  FOREIGN KEY (app_item_id) REFERENCES app_item(id)
);
CREATE TABLE app_site (
  id bigserial PRIMARY KEY,
  qty integer,
  country varchar(2),
  score integer,
  active boolean,
  created_at timestamptz NOT NULL,
  core_event_id bigint,
  FOREIGN KEY (core_event_id) REFERENCES core_event(id)
);
CREATE TABLE app_plan (
  id bigserial PRIMARY KEY,
  name varchar(80),
  active boolean,
  score integer,
  score_2 integer,
  status varchar(16),
  note text,
  created_at timestamptz NOT NULL,
  app_order_id bigint,
  FOREIGN KEY (app_order_id) REFERENCES app_order(id)
);
CREATE TABLE app_task (
  id bigserial PRIMARY KEY,
  active boolean,
  code varchar(24),
  score integer,
  city varchar(60),
  amount numeric(12,2),
  name varchar(80),
  created_at timestamptz NOT NULL,
  core_task_id bigint,
  FOREIGN KEY (core_task_id) REFERENCES core_task(id)
);
CREATE TABLE app_file (
  id bigserial PRIMARY KEY,
  status varchar(16),
  status_2 varchar(16),
  status_3 varchar(16),
  qty integer,
  created_at timestamptz NOT NULL,
  core_unit_id bigint,
  FOREIGN KEY (core_unit_id) REFERENCES core_unit(id)
);
CREATE TABLE app_rule (
  id bigserial PRIMARY KEY,
  score integer,
  status varchar(16),
  full_name varchar(80),
  active boolean,
  created_at timestamptz NOT NULL,
  core_order_id bigint,
  FOREIGN KEY (core_order_id) REFERENCES core_order(id)
);
CREATE TABLE app_zone (
  id bigserial PRIMARY KEY,
  note text,
  amount numeric(12,2),
  amount_2 numeric(12,2),
  city varchar(60),
  created_at timestamptz NOT NULL,
  core_user_id bigint,
  FOREIGN KEY (core_user_id) REFERENCES core_user(id)
);
CREATE TABLE app_unit (
  id bigserial PRIMARY KEY,
  qty integer,
  active boolean,
  active_2 boolean,
  city varchar(60),
  created_at timestamptz NOT NULL
);
CREATE TABLE app_asset (
  id bigserial PRIMARY KEY,
  name varchar(80),
  qty integer,
  active boolean,
  name_2 varchar(80),
  qty_2 integer,
  country varchar(2),
  created_at timestamptz NOT NULL
);
CREATE TABLE app_lead (
  id bigserial PRIMARY KEY,
  name varchar(80),
  status varchar(16),
  code varchar(24),
  status_2 varchar(16),
  rate numeric(5,2),
  status_3 varchar(16),
  created_at timestamptz NOT NULL
);
CREATE TABLE app_deal (
  id bigserial PRIMARY KEY,
  city varchar(60),
  full_name varchar(80),
  name varchar(80),
  name_2 varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE app_ticket (
  id bigserial PRIMARY KEY,
  status varchar(16),
  name varchar(80),
  rate numeric(5,2),
  qty integer,
  city varchar(60),
  created_at timestamptz NOT NULL,
  core_ticket_id bigint,
  FOREIGN KEY (core_ticket_id) REFERENCES core_ticket(id)
);
CREATE TABLE app_invoice (
  id bigserial PRIMARY KEY,
  city varchar(60),
  qty integer,
  amount numeric(12,2),
  city_2 varchar(60),
  score integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_user (
  id bigserial PRIMARY KEY,
  qty integer,
  qty_2 integer,
  full_name varchar(80),
  created_at timestamptz NOT NULL,
  core_zone_id bigint,
  FOREIGN KEY (core_zone_id) REFERENCES core_zone(id)
);
CREATE TABLE crm_order (
  id bigserial PRIMARY KEY,
  email varchar(120),
  status varchar(16),
  country varchar(2),
  name varchar(80),
  qty integer,
  note text,
  created_at timestamptz NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE crm_item (
  id bigserial PRIMARY KEY,
  qty integer,
  qty_2 integer,
  amount numeric(12,2),
  rate numeric(5,2),
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_event (
  id bigserial PRIMARY KEY,
  status varchar(16),
  full_name varchar(80),
  full_name_2 varchar(80),
  amount numeric(12,2),
  country varchar(2),
  created_at timestamptz NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE crm_tag (
  id bigserial PRIMARY KEY,
  active boolean,
  full_name varchar(80),
  code varchar(24),
  active_2 boolean,
  score integer,
  full_name_2 varchar(80),
  created_at timestamptz NOT NULL,
  core_asset_id bigint,
  FOREIGN KEY (core_asset_id) REFERENCES core_asset(id)
);
CREATE TABLE crm_note (
  id bigserial PRIMARY KEY,
  status varchar(16),
  qty integer,
  country varchar(2),
  qty_2 integer,
  note text,
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_role (
  id bigserial PRIMARY KEY,
  score integer,
  rate numeric(5,2),
  amount numeric(12,2),
  note text,
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_team (
  id bigserial PRIMARY KEY,
  note text,
  score integer,
  status varchar(16),
  full_name varchar(80),
  email varchar(120),
  email_2 varchar(120),
  created_at timestamptz NOT NULL,
  crm_tag_id bigint,
  FOREIGN KEY (crm_tag_id) REFERENCES crm_tag(id)
);
CREATE TABLE crm_site (
  id bigserial PRIMARY KEY,
  status varchar(16),
  score integer,
  amount numeric(12,2),
  name varchar(80),
  name_2 varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_plan (
  id bigserial PRIMARY KEY,
  note text,
  score integer,
  active boolean,
  created_at timestamptz NOT NULL,
  app_deal_id bigint,
  FOREIGN KEY (app_deal_id) REFERENCES app_deal(id)
);
CREATE TABLE crm_task (
  id bigserial PRIMARY KEY,
  name varchar(80),
  country varchar(2),
  amount numeric(12,2),
  rate numeric(5,2),
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_file (
  id bigserial PRIMARY KEY,
  qty integer,
  code varchar(24),
  qty_2 integer,
  name varchar(80),
  note text,
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_rule (
  id bigserial PRIMARY KEY,
  active boolean,
  city varchar(60),
  full_name varchar(80),
  full_name_2 varchar(80),
  note text,
  score integer,
  created_at timestamptz NOT NULL,
  core_plan_id bigint,
  FOREIGN KEY (core_plan_id) REFERENCES core_plan(id)
);
CREATE TABLE crm_zone (
  id bigserial PRIMARY KEY,
  email varchar(120),
  city varchar(60),
  note text,
  amount numeric(12,2),
  qty integer,
  name varchar(80),
  created_at timestamptz NOT NULL,
  core_role_id bigint,
  FOREIGN KEY (core_role_id) REFERENCES core_role(id)
);
CREATE TABLE crm_unit (
  id bigserial PRIMARY KEY,
  country varchar(2),
  rate numeric(5,2),
  code varchar(24),
  country_2 varchar(2),
  note text,
  full_name varchar(80),
  created_at timestamptz NOT NULL,
  crm_event_id bigint,
  FOREIGN KEY (crm_event_id) REFERENCES crm_event(id)
);
CREATE TABLE crm_asset (
  id bigserial PRIMARY KEY,
  country varchar(2),
  code varchar(24),
  full_name varchar(80),
  score integer,
  qty integer,
  created_at timestamptz NOT NULL,
  app_asset_id bigint,
  FOREIGN KEY (app_asset_id) REFERENCES app_asset(id)
);
CREATE TABLE crm_lead (
  id bigserial PRIMARY KEY,
  code varchar(24),
  full_name varchar(80),
  amount numeric(12,2),
  note text,
  created_at timestamptz NOT NULL,
  core_ticket_id bigint,
  FOREIGN KEY (core_ticket_id) REFERENCES core_ticket(id)
);
CREATE TABLE crm_deal (
  id bigserial PRIMARY KEY,
  code varchar(24),
  name varchar(80),
  rate numeric(5,2),
  full_name varchar(80),
  score integer,
  code_2 varchar(24),
  created_at timestamptz NOT NULL,
  core_deal_id bigint,
  FOREIGN KEY (core_deal_id) REFERENCES core_deal(id)
);
CREATE TABLE crm_ticket (
  id bigserial PRIMARY KEY,
  note text,
  qty integer,
  note_2 text,
  status varchar(16),
  qty_2 integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE crm_invoice (
  id bigserial PRIMARY KEY,
  amount numeric(12,2),
  score integer,
  rate numeric(5,2),
  status varchar(16),
  code varchar(24),
  score_2 integer,
  created_at timestamptz NOT NULL,
  app_asset_id bigint,
  FOREIGN KEY (app_asset_id) REFERENCES app_asset(id)
);
CREATE TABLE hr_user (
  id bigserial PRIMARY KEY,
  score integer,
  country varchar(2),
  amount numeric(12,2),
  country_2 varchar(2),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_order (
  id bigserial PRIMARY KEY,
  city varchar(60),
  active boolean,
  email varchar(120),
  qty integer,
  full_name varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_item (
  id bigserial PRIMARY KEY,
  score integer,
  code varchar(24),
  active boolean,
  amount numeric(12,2),
  city varchar(60),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_event (
  id bigserial PRIMARY KEY,
  rate numeric(5,2),
  qty integer,
  rate_2 numeric(5,2),
  created_at timestamptz NOT NULL,
  hr_user_id bigint,
  FOREIGN KEY (hr_user_id) REFERENCES hr_user(id)
);
CREATE TABLE hr_tag (
  id bigserial PRIMARY KEY,
  score integer,
  note text,
  note_2 text,
  rate numeric(5,2),
  full_name varchar(80),
  score_2 integer,
  created_at timestamptz NOT NULL,
  core_note_id bigint,
  FOREIGN KEY (core_note_id) REFERENCES core_note(id)
);
CREATE TABLE hr_note (
  id bigserial PRIMARY KEY,
  score integer,
  note text,
  email varchar(120),
  status varchar(16),
  amount numeric(12,2),
  full_name varchar(80),
  created_at timestamptz NOT NULL,
  crm_file_id bigint,
  FOREIGN KEY (crm_file_id) REFERENCES crm_file(id)
);
CREATE TABLE hr_role (
  id bigserial PRIMARY KEY,
  country varchar(2),
  qty integer,
  amount numeric(12,2),
  created_at timestamptz NOT NULL,
  crm_invoice_id bigint,
  FOREIGN KEY (crm_invoice_id) REFERENCES crm_invoice(id)
);
CREATE TABLE hr_team (
  id bigserial PRIMARY KEY,
  code varchar(24),
  full_name varchar(80),
  active boolean,
  rate numeric(5,2),
  city varchar(60),
  name varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_site (
  id bigserial PRIMARY KEY,
  qty integer,
  note text,
  full_name varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_plan (
  id bigserial PRIMARY KEY,
  status varchar(16),
  qty integer,
  amount numeric(12,2),
  email varchar(120),
  code varchar(24),
  status_2 varchar(16),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_task (
  id bigserial PRIMARY KEY,
  note text,
  status varchar(16),
  note_2 text,
  rate numeric(5,2),
  active boolean,
  created_at timestamptz NOT NULL,
  app_item_id bigint,
  FOREIGN KEY (app_item_id) REFERENCES app_item(id)
);
CREATE TABLE hr_file (
  id bigserial PRIMARY KEY,
  note text,
  country varchar(2),
  full_name varchar(80),
  email varchar(120),
  amount numeric(12,2),
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_rule (
  id bigserial PRIMARY KEY,
  amount numeric(12,2),
  amount_2 numeric(12,2),
  qty integer,
  status varchar(16),
  full_name varchar(80),
  created_at timestamptz NOT NULL,
  hr_note_id bigint,
  FOREIGN KEY (hr_note_id) REFERENCES hr_note(id)
);
CREATE TABLE hr_zone (
  id bigserial PRIMARY KEY,
  full_name varchar(80),
  qty integer,
  name varchar(80),
  status varchar(16),
  code varchar(24),
  qty_2 integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_unit (
  id bigserial PRIMARY KEY,
  score integer,
  country varchar(2),
  full_name varchar(80),
  score_2 integer,
  created_at timestamptz NOT NULL
);
CREATE TABLE hr_asset (
  id bigserial PRIMARY KEY,
  code varchar(24),
  note text,
  city varchar(60),
  amount numeric(12,2),
  created_at timestamptz NOT NULL,
  crm_unit_id bigint,
  FOREIGN KEY (crm_unit_id) REFERENCES crm_unit(id)
);
CREATE TABLE hr_lead (
  id bigserial PRIMARY KEY,
  active boolean,
  rate numeric(5,2),
  status varchar(16),
  email varchar(120),
  score integer,
  created_at timestamptz NOT NULL,
  hr_asset_id bigint,
  FOREIGN KEY (hr_asset_id) REFERENCES hr_asset(id)
);
CREATE TABLE hr_deal (
  id bigserial PRIMARY KEY,
  city varchar(60),
  active boolean,
  status varchar(16),
  created_at timestamptz NOT NULL,
  crm_note_id bigint,
  FOREIGN KEY (crm_note_id) REFERENCES crm_note(id)
);
CREATE TABLE hr_ticket (
  id bigserial PRIMARY KEY,
  note text,
  qty integer,
  note_2 text,
  status varchar(16),
  amount numeric(12,2),
  created_at timestamptz NOT NULL,
  hr_file_id bigint,
  FOREIGN KEY (hr_file_id) REFERENCES hr_file(id)
);
CREATE TABLE hr_invoice (
  id bigserial PRIMARY KEY,
  status varchar(16),
  active boolean,
  rate numeric(5,2),
  note text,
  status_2 varchar(16),
  created_at timestamptz NOT NULL,
  hr_user_id bigint,
  FOREIGN KEY (hr_user_id) REFERENCES hr_user(id)
);
CREATE TABLE fin_user (
  id bigserial PRIMARY KEY,
  amount numeric(12,2),
  code varchar(24),
  code_2 varchar(24),
  status varchar(16),
  amount_2 numeric(12,2),
  created_at timestamptz NOT NULL,
  crm_event_id bigint,
  FOREIGN KEY (crm_event_id) REFERENCES crm_event(id)
);
CREATE TABLE fin_order (
  id bigserial PRIMARY KEY,
  email varchar(120),
  country varchar(2),
  status varchar(16),
  note text,
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_item (
  id bigserial PRIMARY KEY,
  city varchar(60),
  status varchar(16),
  city_2 varchar(60),
  email varchar(120),
  created_at timestamptz NOT NULL,
  hr_plan_id bigint,
  FOREIGN KEY (hr_plan_id) REFERENCES hr_plan(id)
);
CREATE TABLE fin_event (
  id bigserial PRIMARY KEY,
  active boolean,
  active_2 boolean,
  qty integer,
  country varchar(2),
  created_at timestamptz NOT NULL,
  app_invoice_id bigint,
  FOREIGN KEY (app_invoice_id) REFERENCES app_invoice(id)
);
CREATE TABLE fin_tag (
  id bigserial PRIMARY KEY,
  qty integer,
  code varchar(24),
  code_2 varchar(24),
  name varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_note (
  id bigserial PRIMARY KEY,
  email varchar(120),
  status varchar(16),
  country varchar(2),
  amount numeric(12,2),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_role (
  id bigserial PRIMARY KEY,
  city varchar(60),
  note text,
  city_2 varchar(60),
  email varchar(120),
  status varchar(16),
  email_2 varchar(120),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_team (
  id bigserial PRIMARY KEY,
  code varchar(24),
  status varchar(16),
  name varchar(80),
  city varchar(60),
  status_2 varchar(16),
  country varchar(2),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_site (
  id bigserial PRIMARY KEY,
  note text,
  active boolean,
  rate numeric(5,2),
  amount numeric(12,2),
  code varchar(24),
  name varchar(80),
  created_at timestamptz NOT NULL,
  core_order_id bigint,
  FOREIGN KEY (core_order_id) REFERENCES core_order(id)
);
CREATE TABLE fin_plan (
  id bigserial PRIMARY KEY,
  qty integer,
  amount numeric(12,2),
  score integer,
  rate numeric(5,2),
  rate_2 numeric(5,2),
  name varchar(80),
  created_at timestamptz NOT NULL,
  app_zone_id bigint,
  FOREIGN KEY (app_zone_id) REFERENCES app_zone(id)
);
CREATE TABLE fin_task (
  id bigserial PRIMARY KEY,
  code varchar(24),
  active boolean,
  rate numeric(5,2),
  status varchar(16),
  qty integer,
  email varchar(120),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_file (
  id bigserial PRIMARY KEY,
  status varchar(16),
  name varchar(80),
  country varchar(2),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_rule (
  id bigserial PRIMARY KEY,
  name varchar(80),
  active boolean,
  amount numeric(12,2),
  full_name varchar(80),
  email varchar(120),
  score integer,
  created_at timestamptz NOT NULL,
  app_team_id bigint,
  FOREIGN KEY (app_team_id) REFERENCES app_team(id)
);
CREATE TABLE fin_zone (
  id bigserial PRIMARY KEY,
  code varchar(24),
  name varchar(80),
  status varchar(16),
  name_2 varchar(80),
  rate numeric(5,2),
  created_at timestamptz NOT NULL,
  core_task_id bigint,
  FOREIGN KEY (core_task_id) REFERENCES core_task(id)
);
CREATE TABLE fin_unit (
  id bigserial PRIMARY KEY,
  country varchar(2),
  score integer,
  email varchar(120),
  full_name varchar(80),
  full_name_2 varchar(80),
  note text,
  created_at timestamptz NOT NULL,
  crm_ticket_id bigint,
  FOREIGN KEY (crm_ticket_id) REFERENCES crm_ticket(id)
);
CREATE TABLE fin_asset (
  id bigserial PRIMARY KEY,
  rate numeric(5,2),
  active boolean,
  name varchar(80),
  full_name varchar(80),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_lead (
  id bigserial PRIMARY KEY,
  name varchar(80),
  city varchar(60),
  note text,
  email varchar(120),
  email_2 varchar(120),
  email_3 varchar(120),
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_deal (
  id bigserial PRIMARY KEY,
  status varchar(16),
  amount numeric(12,2),
  score integer,
  email varchar(120),
  active boolean,
  created_at timestamptz NOT NULL
);
CREATE TABLE fin_ticket (
  id bigserial PRIMARY KEY,
  city varchar(60),
  name varchar(80),
  qty integer,
  created_at timestamptz NOT NULL,
  hr_role_id bigint,
  FOREIGN KEY (hr_role_id) REFERENCES hr_role(id)
);
CREATE TABLE fin_invoice (
  id bigserial PRIMARY KEY,
  qty integer,
  country varchar(2),
  rate numeric(5,2),
  created_at timestamptz NOT NULL
);
