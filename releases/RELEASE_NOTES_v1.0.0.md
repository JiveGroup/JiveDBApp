# JiveDB 1.0.0

A desktop client to manage **PostgreSQL · MySQL · SQLite · Redis**.

## Downloads

| Platform | File |
|---|---|
| macOS (Intel & Apple Silicon) | `JiveDB.dmg` |
| Windows x64 | `JiveDB-windows-amd64.exe` |
| Windows ARM64 | `JiveDB-windows-arm64.exe` |
| Linux x64 | `JiveDB-linux-amd64.tar.gz` |
| Linux ARM64 | `JiveDB-linux-arm64.tar.gz` |

## Install

**macOS**
1. Download **`JiveDB.dmg`**.
2. Open it and drag **JiveDB** into **Applications**.
3. Launch from Launchpad / Applications. (Signed with Developer ID + notarized.)

**Windows**
1. Download **`JiveDB-windows-amd64.exe`** (or `-arm64` for ARM devices).
2. Run it. If SmartScreen appears, click **More info → Run anyway** (the build is not code‑signed yet).

**Linux**
1. Download **`JiveDB-linux-amd64.tar.gz`** (or `-arm64`).
2. Extract and install (adds an app-menu launcher + icon, no sudo):
   ```bash
   tar -xzf JiveDB-linux-amd64.tar.gz
   cd JiveDB-amd64 && ./install.sh
   ```
3. Open **JiveDB** from the application menu. (Remove with `./uninstall.sh`.)
4. Requires WebKitGTK runtime, e.g. on Debian/Ubuntu:
   ```bash
   sudo apt install libwebkit2gtk-4.1-0 libgtk-3-0
   ```

## What's in this release
- Multi-database connection management + schema tree (tables/views/routines/sequences/object types).
- SQL editor: schema-aware autocomplete, query history, run selected statement (⌘/Ctrl+R).
- Data grid: server-side filter/sort, add rows via a validated form, export CSV/JSON.
- Table structure editor + entity-relationship diagram (ERD).
- Multi-provider AI assistant (OpenAI/Anthropic/DeepSeek/Gemini/Ollama…): generate/explain/optimize SQL, ask your data.
- Theme accent colors, light/dark, multi-language (English/Vietnamese).

## Verify (optional)
Checksums are provided in `SHA256SUMS.txt`:
```bash
shasum -a 256 -c SHA256SUMS.txt
```

---
*Tip when creating the Release: tag `v1.0.0`, title `JiveDB 1.0.0`, paste these notes, and attach all platform binaries to Assets.*
