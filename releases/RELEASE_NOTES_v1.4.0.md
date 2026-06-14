# JiveDB 1.4.0

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- Secure connections — TLS/SSL for PostgreSQL, MySQL, and Redis with all four modes (`disable` / `require` / `verify-ca` / `verify-full`), a private CA, and client-certificate auth (mTLS). `verify-ca` / `verify-full` require an explicit Server CA (no silent fallback to the system trust store).
- SSH tunnel (single-hop) for any connection — authenticate by password or private key (with passphrase); the tunnel automatically reconnects if the link drops. SSH passwords and key passphrases are encrypted at rest.
- Redesigned connection dialog with tabs — Connection / TLS/SSL / SSH Tunnel — showing only the fields relevant to the selected TLS mode, active badges on the TLS and SSH tabs, and validation for the CA / mTLS certificate pair.
- Partitioned tables for PostgreSQL and MySQL — parent tables are marked and their partitions (and sub-partitions) nest beneath them in the sidebar; open a single partition's data directly, with partition icons and a bound/range tooltip.
- ERD editing — add entities by picking tables not yet on the canvas; create, list, and delete virtual relations (virtual foreign keys, 1‑1 / 1‑many, with an optional note); and group entities into module zones. Positions, hidden/added entities, virtual relations, and zones are saved per diagram.
- JSON Viewer — right-click a row number to view selected rows as JSON, with recursive lazy-loading of foreign keys, node deletion, and Copy JSON. Structured types map to real JSON: `json`/`jsonb` → object/array, geometry → number arrays, arrays → JSON arrays, circle → `{x, y, r}`; precision-sensitive types (`bigint`, `numeric`, `decimal`, `money`) stay as strings.
- FK Peek — click the foreign-key icon on a cell to preview the referenced row inline (name/type + value), up to 10 columns.
- Type-aware Add/Edit forms — dedicated editors for arrays, enum/set, JSON, binary (view-only), circle, geometry (point/line/segment/box/path/polygon), and a date/time picker.
- Third-party licenses viewer in the About dialog (lazy-loaded).

## Improvements
- Row and Cell edit modes (default Row) — double-clicking a cell opens a focused single-field form; the old full-size edit modal is gone.
- Saves only the cells you changed (diffed against the original by primary key), with a modified-field indicator.
- Richer cell selection — adjacent cells (Shift+Click), whole rows and columns, and ⌘/Ctrl+A to select all cells.
- "Set value" action for a whole column (simple types), a rows-per-page popover (25–10,000), and a go-to-page popover.
- Column headers now show the data type beneath the column name, with a comment/type tooltip.
- Sidebar — highlights the default database (when there are more than three), flags databases that failed to open, and lets you hide/unhide databases (persisted) without reloading the tree.
- Deleting a connection now closes its live connection and clears its tabs and schema cache.
- Schema object types display readable names instead of raw PostgreSQL OIDs.
- Certificate and key file pickers now work on macOS.

## Bug Fixes
- A burst of notifications no longer covers the header — toasts are capped and the toaster height is bounded.
- The cell you're editing is now committed when you click another cell.
- Cell interaction polish — hover highlight and the correct default cursor on cells.
