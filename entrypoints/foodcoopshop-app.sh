#!/bin/sh
set -e

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Release code
SRC_DIR="/usr/src/app"
# Copy of release code for access of Nginx service
DST_DIR="/app"
# Version file to check if copying is required
VERSION_FILE="$DST_DIR/.fcs_version"

# If volume is empty copy from SRC_DIR to DST_DIR
if [ ! -f "$VERSION_FILE" ] || [ "$(cat $VERSION_FILE)" != "$FCS_VERSION" ]; then
  log "[Update] Starting syncing release code into volume..."
  cp -R "$SRC_DIR"/* "$DST_DIR"/
  echo "$FCS_VERSION" > "$VERSION_FILE"
  chown -R application:application "$DST_DIR"
  log "[Update] Updated to release version $FCS_VERSION."
else
  log "[Init] Volume (/app) already contains data of version $FCS_VERSION - no update required."
fi

# Start PHP-FPM in foreground
#   Master process runs as root per default so that it can open ports and manage resources
#   Worker processes are started as application user (see www.conf)
exec php-fpm -F
