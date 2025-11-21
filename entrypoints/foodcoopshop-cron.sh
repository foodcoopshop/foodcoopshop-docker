#!/bin/sh
set -e

# Every 5 minutes: execute queue
echo "*/5 * * * * cd /app && bin/cake queue run >> /proc/1/fd/1 2>&1" > /etc/crontabs/root

# Every 10 minutes: call internal cron endpoint
echo "*/10 * * * * curl -s http://foodcoopshop-nginx/cron >> /proc/1/fd/1 2>&1" >> /etc/crontabs/root

# Start cron daemon in foreground (logs in stdout -> docker logs foodcoopshop-cron)
exec crond -f -L /dev/stdout
