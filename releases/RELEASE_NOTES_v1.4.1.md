# JiveDB 1.4.1

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- Auto-arrange for ERD diagrams — a toolbar button cycles through several layouts (balanced grid, wide, tall, and grouping by relationship clusters) using each entity's real size so nothing overlaps; click until you find the layout you like. Positions are saved per diagram.
- Zone colors — the ERD zone palette now offers 20 colors with an in-canvas color picker (click the color dot on a zone header to open the swatch grid).
- MySQL database picker — the SQL editor toolbar now lets a single MySQL connection switch between its databases, defaulting to the one you are working in.

## Improvements
- Schema-aware SQL autocomplete — table and column suggestions now match the selected PostgreSQL database and schema instead of always falling back to `public`; switching the `database > schema` picker reloads suggestions for that schema.
- PostgreSQL connections with many databases/schemas — the Query tab's `database > schema` picker loads every database and its schemas (in parallel, tolerant of databases you cannot access) and inherits the database/schema you were last working in.
- ERD entities are expanded by default so long column names and types no longer spill outside the box; in collapse mode, long names, types, and titles are shortened with an ellipsis and the full value is shown on hover.
- ERD interaction — drag an entity by its header only (clicking the body selects it without moving it), and double-click an entity's header to expand or collapse just that entity.
- ERD toolbar is now responsive — it collapses to icons only on narrow widths (under 1200px) or when the DDL info panel is open, and every button has a tooltip.
- New zones are placed at the center of the current view instead of a fixed corner.
- ERD focus mode (View ERD for a specific table) keeps the focused table as the diagram's root — it can no longer be removed from the canvas.
- Removing an entity from a diagram now asks for confirmation.
- The DDL info panel no longer flickers when switching between entities — the previous content stays until the new definition loads.

## Bug Fixes
- SQLite data safety — fixed an issue where a SQLite file could become corrupted or truncated to zero bytes over time (especially after abrupt shutdowns). Access to the file is now serialized, the connection uses safer write settings (WAL journaling), and connections are closed cleanly on exit so the database is finalized correctly.
- ERD entity selection — fixed clicks on an entity sometimes not registering, so opening an entity's DDL now works reliably.
- Removed the outdated "Double-click a table to edit" hint from the ERD view.
