# JiveDB — a lightweight, modern database management tool

> A desktop app to **connect, query, edit and analyze** your data across many database engines — fast, secure and pleasant for everyday use.

---

## 1. What is JiveDB?

JiveDB is a **native** desktop application that lets you work with databases without juggling a pile of separate tools. The whole app ships as **a single executable**, starts fast and needs no complicated setup.

What sets JiveDB apart is balance: powerful enough for real work, yet still **light, clean and intuitive**. You can open a table, filter data, edit a few rows, view the relationship diagram or export a file in just a few clicks.

---

## 2. Why choose JiveDB?

- **One tool for many databases** — no more switching back and forth between different programs.
- **A data grid as powerful as a spreadsheet** — range selection, operator-based filtering, multi-column sorting, multi-cell paste, conditional formatting and more.
- **A smart SQL editor** — run exactly the statement at the cursor, format, save favorites, query history.
- **Entity-Relationship Diagram (ERD)** that is visual, safely read-only, with quick DDL preview for each table.
- **Secure by default** — connection passwords are encrypted when stored on your machine.
- **Light and fast** — a single executable, a compact UI, light/dark theme support.
- **Bilingual** — supports Vietnamese and English.

---

## 3. Supported databases

JiveDB works with popular engines in one unified interface:

| Database | Notes |
|---|---|
| **PostgreSQL** | Multiple schemas, fast schema switching, view object definitions (DDL). |
| **MySQL** | Manage tables/views/indexes/procedures per database. |
| **SQLite** | Open local files, lightweight, no server required. |
| **Redis** | Key/value browser for quick operations. |

---

## 4. Highlight features

### 4.1. The Data Grid — JiveDB's standout

This is where you spend most of your time, and JiveDB invests heavily to make it genuinely convenient:

- **Cell range selection** like Excel, with a quick summary bar (count, sum, average, min, max).
- **Flexible copy**: cell, row, selection or a whole column, in multiple formats (TSV, CSV, JSON, INSERT, UPDATE).
- **Operator-based filtering** per column: `= ≠ > < ≥ ≤`, contains (LIKE), empty/not empty, and **IN / NOT IN**, with easy-to-read symbol hints.
- **Multi-column sorting** by priority order; **freeze (pin) columns** to keep them in view while scrolling horizontally.
- **Safe in-place editing**: change tracking, preview before saving; **per-cell undo**; multi-cell paste, fill down, bulk set NULL.
- **Quick analysis**: column statistics and common value distribution right inside the grid.
- **Find & Replace**, **conditional formatting** (color by rules), **auto-fit column width**, flexible **row height**.
- **CSV import** and **Excel (.xlsx) export**, CSV, JSON — for the whole table or just the selection.
- **Foreign-key navigation**: jump to the referenced row with a single click.

### 4.2. SQL Editor

- **Smart run**: just place the cursor inside a statement and run — JiveDB picks the right statement to execute.
- Supports **multiple statements**, **formatting**, syntax highlighting, suggestions.
- **Query history** and **favorite statements** for quick reuse.
- For PostgreSQL: **pick a schema** right on the toolbar and query against the selected schema.

### 4.3. Entity-Relationship Diagram (ERD)

- Automatically builds a diagram **of tables only** and the foreign-key relationships between them.
- **Safely read-only**: no operations that modify the database.
- **Double-click** a table to expand it just enough to show long column names in full.
- Toggle the **Info panel** to quickly view the **DDL** of the selected table and copy it with one button.
- Colors **stay in sync with the app's light/dark theme**.

### 4.4. Explore structure & information

- A full object tree: tables, views, indexes, functions/procedures, sequences, data types…
- **View the definition (DDL)** of an object in read-only mode, with syntax highlighting.
- The **Info** tab aggregates metadata by group (Tables, Views, Indexes, Procedures) for a quick overview.

---

## 5. Security and privacy

- **Encrypted at rest**: sensitive connection details are encrypted before being written to your machine.
- **Your data stays on your machine**: JiveDB is a desktop app and does not require sending your data to any external service to work.
- **Safe by default**: potentially destructive operations are clearly confirmed; many screens prefer **read-only** mode when no editing is needed.

---

## 6. Cross-platform and performance

- Packaged as **a single executable**, starts fast.
- A **compact, modern** UI with **light/dark theme** and accent-color support.
- The data grid is **virtualized** to stay smooth with large row counts.

---

## 7. Who is it for?

- **Developers** who need a fast tool to query and edit data while building.
- **Data / analytics people** who want to filter, aggregate and export data without writing much SQL.
- **Database administrators** who need to view structure, relationships and object definitions visually.
- Anyone who wants **a single, lightweight tool** instead of many separate programs.

---

## 8. Quick start

1. Open JiveDB and **create a connection** to PostgreSQL, MySQL, SQLite or Redis.
2. Browse the object tree in the sidebar, **open a table** to view its data.
3. Use the **data grid** to filter, sort, edit or export.
4. Open the **SQL Editor** to run queries, or view the **ERD** to understand the relationships between tables.

---

## 9. Download and install

Get the latest build for your platform from the **[Releases](../../releases/latest)** page.

| Platform | File |
|---|---|
| macOS (Intel & Apple Silicon) | `JiveDB.dmg` |
| Windows x64 | `JiveDB-windows-amd64.exe` |
| Windows ARM64 | `JiveDB-windows-arm64.exe` |
| Linux x64 | `JiveDB-linux-amd64.tar.gz` |
| Linux ARM64 | `JiveDB-linux-arm64.tar.gz` |

**macOS** — open `JiveDB.dmg`, drag **JiveDB** into the **Applications** folder, then launch it. (Developer ID signed + notarized.)

**Windows** — run `JiveDB-windows-amd64.exe` (or the `-arm64` build). If a SmartScreen warning appears, click **More info → Run anyway** (the current build is not yet code-signed).

> **Requires the WebView2 Runtime.** JiveDB uses **Microsoft Edge WebView2** to render its UI. Windows 11 (and most updated Windows 10 machines) already include this runtime. If the app won't open or shows a blank screen, download and install the **Evergreen WebView2 Runtime** (free) from Microsoft:
>
> - Download page: https://developer.microsoft.com/en-us/microsoft-edge/webview2
> - Choose the **Evergreen Bootstrapper** → download and run `MicrosoftEdgeWebview2Setup.exe`, then follow the prompts.
> - Once installed, relaunch JiveDB.

**Linux** — extract the archive and run `install.sh` (adds a launcher with icon to the app menu, no sudo needed):

```bash
tar -xzf JiveDB-linux-amd64.tar.gz
cd JiveDB-amd64 && ./install.sh
# Install the WebKitGTK runtime if needed (Debian/Ubuntu):
# sudo apt install libwebkit2gtk-4.1-0 libgtk-3-0
```

Then open **JiveDB** from the app menu. (Uninstall: `./uninstall.sh`.)

---

## 10. Create test data with Docker

The repo ships with a `docker-compose.yml` and sample datasets under `db/` so you can quickly spin up PostgreSQL, MySQL and Redis with data — for trying out JiveDB without installing servers yourself. The data is **synthetic** (deterministically generated), not real data, and is **for local testing only**.

> Requirements: **Docker** and **Docker Compose** (the `docker compose` command) installed.

### 10.1. Start it up

From the root of the repo:

```bash
docker compose up -d
```

The sample data **loads automatically when the containers are first initialized**:

- **PostgreSQL / MySQL**: run the `*.sql` files in `db/<set>/<db>/` via `/docker-entrypoint-initdb.d`.
- **Redis**: the `redis-seed` service loads `db/<set>/redis/seed.redis` right after Redis is ready, then exits.

### 10.2. Login credentials (for testing only)

Use the settings below to **create a connection in JiveDB** to the sample data you just spun up. These are local test credentials, **not for production use**.

| Database | Host | Port | User | Password | Database |
|---|---|---|---|---|---|
| PostgreSQL 16 | `localhost` | `5432` | `jdb` | `jdbtest` | `jdb_dev` |
| PostgreSQL 18 | `localhost` | `5433` | `jdb` | `jdbtest` | `jdb_dev` |
| MySQL 8 | `localhost` | `3306` | `jdb` | `jdbtest` | `jdb_dev` |
| Redis 7 | `localhost` | `6379` | — | — | `db0` (no password) |
| SQLite | — | — | — | — | open the `.sqlite` file directly (see below) |

Per-database notes:

- **PostgreSQL** — two versions run side by side: **16** on port `5432` and **18** on port `5433`, both with account `jdb` / `jdbtest` and database `jdb_dev`.
- **MySQL** — besides the `jdb` / `jdbtest` account, there is also an admin **`root`** account with password `jdbtest` if needed.
- **Redis** — authentication is disabled; the sample data lives in DB index `0`.
- **SQLite** — no Docker needed, open the file directly in JiveDB:
  - Small set: `db/seeds/sqlite/jdb.sqlite`
  - Medium set: `db/seeds-medium/sqlite/jdb_medium.sqlite`

> Tip: with `make` (see `Makefile`), you can quickly open a shell into a DB — `make psql`, `make mysql`, `make redis-cli`.

### 10.3. Choose a dataset

By default the **small** set (`seeds`) is loaded. Switch sets via the `JDB_SEED` environment variable:

```bash
JDB_SEED=seeds        docker compose up -d   # small set (default)
JDB_SEED=seeds-medium docker compose up -d   # medium set (more tables)
```

### 10.4. Reload from scratch

The init scripts **only run while the volume is still empty**. To wipe the old data and re-seed:

```bash
docker compose down -v && docker compose up -d
```

### 10.5. Stop and clean up

```bash
docker compose down       # stop, keep the data in the volume
docker compose down -v    # stop and delete the data (volume) too
```

### 10.6. Create the full set of PostgreSQL schema objects

The `db/postgres_schema_objects_sample.sql` file creates **one of every kind of PostgreSQL schema object** so you can see how they appear in JiveDB's sidebar tree: **Tables, Views, Materialized Views, Foreign Tables, Sequences, Types** (enum/composite/range), **Domains, Collations, Functions, Procedures, Trigger Functions, Aggregates, Operators** and **Full-Text Search** (Parser → Template → Dictionary → Configuration).

- **Safe**: everything lives in a dedicated **`demo_objects`** schema and does not touch your existing data. The top of the file already does `DROP SCHEMA ... CASCADE`, so it is **safe to run repeatedly**.
- **Requirements**: PostgreSQL **14+**, with **ICU** and **postgres_fdw** — the `postgres:16`/`postgres:18` images in `docker-compose.yml` already include these, and the `jdb` account is a superuser so it can create EXTENSION / SERVER / FTS objects.

Load the file into the running PostgreSQL (Postgres 16, port 5432):

```bash
docker exec -i jdbapp-postgres-1 psql -U jdb -d jdb_dev < db/postgres_schema_objects_sample.sql
# or, more quickly:
make pg-objects
```

Or open the file, **copy its entire contents into JiveDB's SQL Editor** and run it (note: the function/procedure blocks use dollar-quoting `$$ ... $$` and must be run as whole blocks — don't split on the inner `;`).

Then **Refresh the sidebar** and open the `demo_objects` schema to see all the objects. Clean up when done:

```sql
DROP SCHEMA demo_objects CASCADE;
DROP SERVER  demo_remote  CASCADE;   -- the FDW server is global, not part of a schema
```

> Details about the schema, table/row counts and the DEMO queries are available in `db/seeds/README.md` and the READMEs in each subdirectory.

### 10.7. Test secure connections (TLS/SSL + SSH Tunnel)

The stack also ships **security-enabled databases** for trying the **TLS/SSL** and **SSH Tunnel** tabs:

```bash
make secure-gen   # generate TLS CA/cert/key + SSH key into secure/ (run once)
make up           # also brings up postgres-tls / mysql-tls / redis-tls / bastion
```

| Purpose | Host | Port | Notes |
|---|---|---|---|
| PostgreSQL TLS | `localhost` | `5434` | encryption required (plaintext rejected), client cert optional, CA = `secure/tls/ca.crt` |
| PostgreSQL mTLS | `localhost` | `5435` | client cert **required** (`client.crt`+`client.key`) |
| MySQL TLS | `127.0.0.1` | `3307` | TLS required (plaintext connections rejected) |
| Redis TLS | `localhost` | `6380` | — |
| SSH bastion | `localhost` | `2222` | user `jdb`, password `jdbtest` or key `secure/ssh/id_ed25519` |
| Internal DB via tunnel | `internal-postgres` | `5432` | only reachable after SSH into the bastion |

> Full parameter table for the app's connection dialog: see **`secure/README.md`**.

---

## 11. Verify release files (checksum & size)

After downloading the release artifacts (or when building a new version), you can verify their integrity and size with two `make` commands. By default they operate on `releases/<VERSION>` (where `VERSION` defaults to the current release); override with `VERSION=...` or `RELEASE_DIR=...`.

**`make checksums`** — generates a SHA-256 hash for each file and writes them to `SHA256SUMS`:

```bash
make checksums                       # default version
make checksums VERSION=1.3.0         # a specific version
make checksums RELEASE_DIR=/path/to/dir
```

**`make verify-checksums`** — reads `SHA256SUMS` and prints `OK` for each file that matches:

```bash
make verify-checksums
```

**`make sizes`** — shows the human-readable size of each file:

```bash
make sizes
make sizes VERSION=1.3.0
```

> Both commands skip the `SHA256SUMS` file itself.

---

> **JiveDB** — powerful enough for real work, light enough to use every day.
