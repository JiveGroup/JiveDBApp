#!/bin/bash
# Multi-database seed orchestrator for the MySQL Docker entrypoint.
# Mounted to /docker-entrypoint-initdb.d/00-init-multi.sh — runs once when the
# data volume is first initialized (root password & MYSQL_USER already exist).
#
# Creates 3 DISTINCT domain databases on the single `jdb` account:
#   jdb_ecommerce   → catalog_*, orders_*, marketing_*
#   jdb_healthcare  → clinical_*, pharmacy_*, billing_*
#   jdb_banking     → accounts_*, lending_*, cards_*
#
# (MySQL has no schemas-within-a-database, so each domain's 3 areas are kept as
#  table-name prefixes.)
set -e

DOMAINS="ecommerce healthcare banking"
SEED=/seed/databases
export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"           # avoids password-on-CLI warning
my() { mysql --protocol=socket -uroot "$@"; }

log() { echo "[multi-init] $(date +%H:%M:%S) $*"; }

for domain in $DOMAINS; do
    DB="jdb_${domain}"
    log "=== Database: $DB ==="
    my -e "CREATE DATABASE IF NOT EXISTS \`$DB\` CHARACTER SET utf8mb4;"
    # Make the application account ($MYSQL_USER) able to see/use this database.
    my -e "GRANT ALL PRIVILEGES ON \`$DB\`.* TO '${MYSQL_USER}'@'%';"

    if [ -f "$SEED/$domain/schema.sql" ]; then
        my "$DB" < "$SEED/$domain/schema.sql"
        log "  DDL applied."
    fi
    if [ -f "$SEED/$domain/data.sql" ]; then
        my "$DB" < "$SEED/$domain/data.sql"
        log "  Data loaded."
    fi
done

my -e "FLUSH PRIVILEGES;"
log "Done. 3 domain databases ready: jdb_ecommerce, jdb_healthcare, jdb_banking."
