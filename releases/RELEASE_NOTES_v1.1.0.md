# JiveDB 1.1.0

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- App Logs panel: floating button, color-coded entries (SQL / AI / error / warning / info), click a line to copy.
- Hardened encryption: AES-256-GCM keys derived via HKDF-SHA256 from a local random key, an embedded app pepper, and machine + OS-account binding; backward compatible with old data.
- ERD renders without errors for databases with up to 500 tables.
- Improved table-related icon system, with key icons for primary / foreign / unique columns.
- Row counts shown next to each table (quick estimate first, then an exact count in the background).
- Drag-and-drop column reordering in the data grid.
- Copy rows as SQL: Copy Row (INSERT), Copy Row (UPDATE).
- Form View to see a single row/cell as a form; quick Table Detail.
- Close multiple tabs: others, to the right, all; reopen the last closed tab.
- Redis: context menus, multi-select keys for bulk copy/delete, quick open DB by index, query toolbar.
- Language flags switched to SVG for consistent rendering across Windows / macOS / Linux.

## Bug Fixes
- SQL history now appends instead of overwriting previous entries.
- Right-click cell menu opens at the correct cursor position.
- Normalized multi-language strings (vi/en) and removed unused i18n keys.
