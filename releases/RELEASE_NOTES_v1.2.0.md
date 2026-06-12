# JiveDB 1.2.0

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- Full PostgreSQL object tree: Materialized Views, Foreign Tables, Domains, Collations, Aggregates, Operators (+ Classes/Families), Full-Text Search; separate Functions / Procedures / Trigger Functions.
- Quick View (DDL) for routines, views, sequences, triggers, domains, aggregates, operators, collations, and FTS; with Copy and Copy-as-call.
- Context menus to Create / Alter objects (generating SQL templates); a Create table modal; create column/index/key/trigger opens straight into Edit Structure.
- Smart SQL run: executes the statement at the cursor; multi-statement runs go in sequence, stop on error, and keep prior results.
- Statement splitter understands dollar-quoting ($$…$$) so CREATE FUNCTION/PROCEDURE runs as one statement.
- Consistent tree refresh: changes reload exactly the containing group and the ERD.
- Per-type icons and colors; PostgreSQL schema icon set to Layers.
- App Logs refined with broader coverage and click-to-copy.

## Bug Fixes
- Fixed PostgreSQL schema load error when routine_type is NULL.
- Show the correct PostgreSQL error in the SQL Editor instead of "Unknown error".
- New objects (e.g. CREATE VIEW) now appear automatically in the sidebar.
- Heavy DDL (CREATE MATERIALIZED VIEW, CREATE INDEX…) is no longer cut off at 30s.
- Removed the Compact | Comfortable option from structure editing for a consistent UI.
