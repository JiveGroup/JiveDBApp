#!/bin/bash
# Multi-database seed orchestrator for PostgreSQL Docker entrypoint.
# Mounted to /docker-entrypoint-initdb.d/00-init-multi.sh — runs once
# when the data volume is first initialized.
#
# Creates 3 DISTINCT domain databases, each with its own schemas & tables:
#   jdb_ecommerce  → catalog, orders, marketing
#   jdb_healthcare → clinical, pharmacy, billing
#   jdb_banking    → accounts, lending, cards
#
# DDL:  /seed/databases/{domain}/{schema}/schema.sql
# Data: /seed/data/{domain}/{schema}/*.csv.gz   (COPY — full scale, generated)
#       /seed/databases/{domain}/{schema}/data.sql  (INSERT — generate_series, default)
set -e

# domain : "db_name schema1 schema2 schema3"
DOMAINS="ecommerce healthcare banking"
schemas_for() {
    case "$1" in
        ecommerce)  echo "catalog orders marketing" ;;
        healthcare) echo "clinical pharmacy billing" ;;
        banking)    echo "accounts lending cards" ;;
    esac
}
dbname_for() {
    case "$1" in
        ecommerce)  echo "jdb_ecommerce" ;;
        healthcare) echo "jdb_healthcare" ;;
        banking)    echo "jdb_banking" ;;
    esac
}

log()  { echo "[multi-init] $(date +%H:%M:%S) $*"; }
warn() { echo "[multi-init] WARNING: $*" >&2; }

for domain in $DOMAINS; do
    DB=$(dbname_for "$domain")
    log "=== Database: $DB ($domain) ==="
    createdb -U "$POSTGRES_USER" "$DB" 2>/dev/null || log "  (already exists)"

    # Pre-generated CSV for this domain?
    HAS_CSV=false
    if [ -d "/seed/data/$domain/" ] && [ "$(ls -A "/seed/data/$domain/" 2>/dev/null)" ]; then
        HAS_CSV=true
    fi

    for schema in $(schemas_for "$domain"); do
        log "  Schema: $schema"

        # 1. Apply DDL
        if [ -f "/seed/databases/$domain/$schema/schema.sql" ]; then
            psql -q -U "$POSTGRES_USER" -d "$DB" -f "/seed/databases/$domain/$schema/schema.sql"
            log "    DDL applied."
        fi

        # 2. Load data
        if $HAS_CSV; then
            # Full-scale: COPY from compressed CSV.
            # Files COPY in glob (alphabetical) order, which does NOT match FK
            # dependency order. Generated data is FK-consistent, so disable FK
            # trigger enforcement for the load via session_replication_role.
            # (PK/UNIQUE/CHECK stay enforced.)
            DATA_DIR="/seed/data/$domain/$schema"
            if [ -d "$DATA_DIR" ]; then
                loaded=0
                for csv_gz in "$DATA_DIR"/*.csv.gz; do
                    [ -e "$csv_gz" ] || continue
                    table=$(basename "$csv_gz" .csv.gz)
                    zcat "$csv_gz" | PGOPTIONS='-c session_replication_role=replica' \
                        psql -q -U "$POSTGRES_USER" -d "$DB" \
                        -c "COPY ${schema}.\"${table}\" FROM STDIN WITH (FORMAT csv, HEADER true, NULL '\\N')"
                    loaded=$((loaded + 1))
                done
                log "    Loaded $loaded tables via COPY."
            fi
        elif [ -f "/seed/databases/$domain/$schema/data.sql" ]; then
            # Default: full-scale data via generate_series (INSERT). Each data.sql
            # is self-contained (parents first, sequences reset at the end).
            psql -q -U "$POSTGRES_USER" -d "$DB" -f "/seed/databases/$domain/$schema/data.sql"
            log "    Loaded data via generate_series."
        else
            warn "    No data found — schema only."
        fi
    done
done

log "Done. 3 domain databases ready: jdb_ecommerce, jdb_healthcare, jdb_banking."
