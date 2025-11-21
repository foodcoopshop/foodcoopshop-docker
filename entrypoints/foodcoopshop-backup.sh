#!/bin/sh
set -e

# Set cronjobs via crontab command
cat <<EOF | crontab -
0 2 * * * /backup-script.sh daily >> /proc/1/fd/1 2>&1
0 3 * * 0 /backup-script.sh weekly >> /proc/1/fd/1 2>&1
0 4 1 * * /backup-script.sh monthly >> /proc/1/fd/1 2>&1
EOF

# Start cron in foreground and write to stdout (visible in docker logs)
exec cron -f -L 0
