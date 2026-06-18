# JiveDB 1.4.2

One client for all your databases — PostgreSQL, MySQL, SQLite, and Redis in a single lightweight native app.

## New Features
- Run multiple Redis commands at once — the Redis query editor can now execute a whole script with one command per line. Run the entire editor, or select a few lines and run just the selection. This makes bulk operations and data imports much easier.
- Redis import progress — when a large batch of commands is running, a progress bar appears beneath the key list and disappears automatically once it reaches 100%.

## Bug Fixes
- Editing a table's structure now updates an open Data tab immediately — after adding, removing, or changing columns in the Structure tab, the data grid shows the new columns right away instead of only after pressing Refresh.
