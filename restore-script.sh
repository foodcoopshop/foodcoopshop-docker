#!/bin/sh
set -e

# Call this script manually as follows:
# docker exec -it foodcoopshop-backup sh /backup/restore-script.sh \
#  [--dry-run] /backups/daily/db_2025-10-03_02-00.sql.zst \
#              /backups/daily/files_2025-10-03_02-00.tar.zst

DRYRUN=0
if [ "$1" = "--dry-run" ]; then
  DRYRUN=1
  shift
fi

DB_DUMP=$1
FILES_ARCHIVE=$2

if [ -z "$DB_DUMP" ] || [ -z "$FILES_ARCHIVE" ]; then
  echo "Usage: $0 [--dry-run] <db_dump.sql.zst> <files_archive.tar.zst>"
  exit 1
fi

# Safety check: confirm backup is created
echo "Did you create a backup before? (yes/no)"
read CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Stopped restore - create a backup first!"
  exit 1
fi

echo "--- Starting restore ---"
if [ $DRYRUN -eq 1 ]; then
  echo "[DRY-RUN] nothing will be changed!"
fi

# 1. restore database
echo "Restoring database from: $DB_DUMP"
if [ $DRYRUN -eq 0 ]; then
  zstd -dc "$DB_DUMP" | mysql -h YOURDBHOST -u YOURDBUSER \
    -p"$(cat /run/secrets/mysql_fcsdbpass)" YOURDB
else
  echo "[DRY-RUN] -> would be imported with mysql"
fi

# 2. restore files
echo "Restoring files from: $FILES_ARCHIVE"
if [ $DRYRUN -eq 0 ]; then
  # Only extract relevant dirs
  tar -I zstd -xf "$FILES_ARCHIVE" -C /app webroot/files files_private

  # Set ownership und permissions
  echo "Fixing ownership and permissions for user files"
  chown -R 1000:1000 /app/webroot/files /app/files_private
  chmod -R 775 /app/webroot/files /app/files_private
else
  echo "[DRY-RUN] -> would be decompressed/unpacked to /app, /app/webroot/files and /app/files_private"
  echo "[DRY-RUN] -> would also fix ownership and permissions for application user"
fi

echo "--- Finished restore ---"
echo "--- Consider restarting the foodcoopshop-app container ---"