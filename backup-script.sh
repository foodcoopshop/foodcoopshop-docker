#!/bin/sh
set -eu

# Call this script manually as follows:
# docker exec -it foodcoopshop-backup sh /backup-script.sh
#
# Check results in the logs:
# docker logs -f foodcoopshop-backup

# Method for logging timestamp + message
log() {
  echo "[INFO] $(date +%F_%T) - $1" > /proc/1/fd/1
}

if [ $# -ge 1 ]; then
  TYPE="$1"
else
  TYPE="manual"
fi
TS=$(date +%F_%H-%M)
TARGET_DIR="/backups/$TYPE"

# DB connection (provided via docker-compose environment; defaults as fallback)
DB_HOST="${DB_HOST:-foodcoopshop-db}"
DB_USER="${DB_USER:-foodcoop}"
DB_NAME="${DB_NAME:-foodcoopshop}"

mkdir -p "$TARGET_DIR"
log "Starting ${TYPE} backup run..."

# DB dump with fast and efficient compression (zstd).
# Dump to a temporary file first and only compress on success: piping mysqldump
# straight into zstd would hide mysqldump's exit status behind zstd (dash has no
# pipefail) and leave a bogus, near-empty "successful" archive - and the rotation
# below would then happily delete older, good backups.
# --ssl-verify-server-cert=0 keeps the connection encrypted but skips verifying
# the server's certificate: newer mariadb-client (>= 11.x) verifies by default
# and otherwise fails against mysql's auto-generated self-signed certificate
# ("TLS/SSL error: self-signed certificate in certificate chain").
DB_FILE="${TARGET_DIR}/db_${TS}.sql.zst"
DUMP_TMP="${TARGET_DIR}/.db_${TS}.sql.part"
trap 'rm -f "$DUMP_TMP"' EXIT
mysqldump --no-tablespaces --ssl-verify-server-cert=0 -h "$DB_HOST" -u "$DB_USER" \
  -p"$(cat /run/secrets/mysql_fcsdbpass)" "$DB_NAME" > "$DUMP_TMP"
zstd -19 -T0 -o "$DB_FILE" "$DUMP_TMP"
rm -f "$DUMP_TMP"
trap - EXIT
log "Database dump completed: $DB_FILE"

# Make archive of directories webroot/files and files_private
FILES_FILE="${TARGET_DIR}/files_${TS}.tar.zst"
tar -I 'zstd -19 -T0' -cf "$FILES_FILE" -C /app webroot/files files_private
log "File archive completed: $FILES_FILE"

# Rotation by type (essentially cleanup based on grandfather/father/son principle)
case "$TYPE" in
  daily)
    # List one file per line (newest first)
    # Show entries starting with
    ## 8th (first 7 stay - daily routine),
    ## 5th (first 4 stay -> weekly routine),
    ## 13th (first 12 stay -> monthly routine)
    # Delete those entries
    ls -1t "$TARGET_DIR"/db_*.sql.zst    2>/dev/null | tail -n +8  | xargs -r rm -- || true
    ls -1t "$TARGET_DIR"/files_*.tar.zst 2>/dev/null | tail -n +8  | xargs -r rm -- || true
    LABEL="Daily"
    ;;
  weekly)
    ls -1t "$TARGET_DIR"/db_*.sql.zst    2>/dev/null | tail -n +5  | xargs -r rm -- || true
    ls -1t "$TARGET_DIR"/files_*.tar.zst 2>/dev/null | tail -n +5  | xargs -r rm -- || true
    LABEL="Weekly"
    ;;
  monthly)
    ls -1t "$TARGET_DIR"/db_*.sql.zst    2>/dev/null | tail -n +13 | xargs -r rm -- || true
    ls -1t "$TARGET_DIR"/files_*.tar.zst 2>/dev/null | tail -n +13 | xargs -r rm -- || true
    LABEL="Monthly"
    ;;
  *)
    LABEL="manual"
    # no rotation for manual backups
    ;;
esac

log "Rotation and backup for $LABEL backups done."
