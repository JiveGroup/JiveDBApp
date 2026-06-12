# JiveDB 1.3.1

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- Automatic update check on launch against the release server, with a pulsing "new version" badge on the title bar that opens the About dialog.
- Select the entire table at once: ⌘/Ctrl+A, or click the top-left "#" corner.
- Data exports are named after the table (e.g. `users.csv`, `users-selection.xlsx`); query results fall back to `export.*`.
- Minimum window size so the layout no longer breaks when the window is shrunk.
- Feedback form preview (under development) — the UI is available, but sending is disabled for now.

## Bug Fixes
- Fixed ERD "Export SVG" producing a blank image when opened outside the app — colors are now embedded so the diagram renders in any viewer.
- ERD table headers are inset slightly so the card border wraps around them evenly.
- Light-theme ERD exports now use the correct background instead of a forced dark one.
