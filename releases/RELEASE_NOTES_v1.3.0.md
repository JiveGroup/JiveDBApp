# JiveDB 1.3.0

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- Multi-database connections: PostgreSQL, MySQL, SQLite, Redis; passwords encrypted at rest (AES-256-GCM).
- Metadata tree: databases, schemas, tables, views, routines, sequences, types.
- Powerful data grid: inline cell editing, add/delete rows, undo (⌘Z), filter & sort.
- Free-form WHERE / ORDER BY bar right on the data tab (power users).
- Pagination and jump-to-referenced-row via foreign keys (FK navigation).
- Data export: CSV, JSON, clipboard, and Excel (.xlsx).
- SQL editor (CodeMirror): run statements, format, column autocomplete, multi-statement.
- Query history and Command Palette (⌘K) for quick actions.
- ERD diagram (view-only) with a DDL panel and SVG export.
- Schema Info tab for an overview of schemas/tables.
- Redis operations: browse keys, view/edit values, run commands.
- Multi-provider AI: chat, SQL generation, dialect conversion, optimize/explain, data dictionary.
- Built-in AI provider & model editor in Settings.
- Light/dark themes with accent colors; bilingual Vietnamese / English.
- Customizable hotkeys; App Logs panel to track activity.
- Automatic update check on launch plus a notice in the title bar.

## Bug Fixes
- Cells are no longer marked "edited" when only selected/clicked without changing the value.
- Fixed the About dialog showing a blank screen due to a missing update binding.
- Standardized hotkeys (Command Palette ⌘K, Toggle Sidebar ⌘B, Format ⇧⌥F).
- Disabled all hotkeys when no connection exists to avoid accidental actions.
- Added a minimum window size to prevent the UI from breaking when shrunk.
- SQLite now reloads the correct data and closes related tabs after structure changes.
