# FoodCoopShop production ready Docker config
This repo provides a starting point for your production ready FoodCoopShop via Docker Compose. It's providing five services:
- `foodcoopshop-nginx`: covering the webserver via original Nginx image based on Alpine Linux. It serves and caches static content and forwards PHP related requests to the subsequent listed app service.
- `foodcoopshop-app`: holding the main application FoodCoopShop via an Alpine based image providing PHP in latest version and FPM.
- `foodcoopshop-db`: covering the database based on the official LTS mysql image.
- `foodcoopshop-cron`: taking care of cron jobs by utilizing app service image and implementing FoodCoopShop [cronjob requirements](https://foodcoopshop.github.io/dev/cronjobs).
- `foodcoopshop-backup`: offering backup service as well as the option to restore from created backups.

All services run in the same Docker network `proxy`. And ideally you front this with a reverse proxy (e.g. caddy) which takes care of TLS certificates.

## ⚙️ Setup
To get your FoodCoopShop instance running follow these steps:
1) Create the docker network via `docker network create proxy`.
1) Overwrite the config files `credentials.php` and `custom_config.php` in folder `config` with your values, following [official docs](https://foodcoopshop.github.io/dev/installation-guide#configuration). All placeholders are written UPPERCASE.
1) Set or create the proper Docker secret values for the respective files in folder `secrets`. This includes the CakePHP cookie key and salt as well as database and mail credentials.
1) Build the `app` service via `docker compose -f docker-compose.yml build --build-arg FCS_VERSION=4.1.1 foodcoopshop-app` and start it via `docker compose -f docker-compose.yml up -d foodcoopshop-app`. The `db` service image is considered automatically as it is declared as a dependency.
1) Initialize your database (the `db` service), following [official docs](https://foodcoopshop.github.io/dev/installation-guide#database-setup) via: `docker compose -f docker-compose.yml exec -it foodcoopshop-app bash devtools/installation/init-database.sh de_DE` respectively `docker compose -f docker-compose.yml exec -it foodcoopshop-app bash ./bin/cake migrations seed --seed AddTaxesGermanySeed` (adopt to your demands accordingly).
1) Make the `cron` service entrypoint script executable (as it's the only one which is not covered via Dockerfiles) and initialize the service via `docker compose -f docker-compose.yml up -d foodcoopshop-cron`.
1) Build the `backup` service image and start the container via `docker compose -f docker-compose.yml build foodcoopshop-backup` and `docker compose -f docker-compose.yml up -d foodcoopshop-backup`.
1) Start the `nginx` service via `docker compose -f docker-compose.yml up -d foodcoopshop-nginx`.
1) Follow further [official docs](https://foodcoopshop.github.io/dev/installation-guide#setup-security-keys) (security keys, super admin).

## 💾 Backups
The `backup` service automatically follows a son/father/grandfather backup principle, backing up last 7 days, last four weeks (one backup at the end of each week) and last 12 months (one backup each month). It stores created archives under `/var/backups/foodcoopshop/` in respective subfolders. Besides automatic backups you can also trigger a manual one via `docker exec -it foodcoopshop-backup sh /backup-script.sh`

## 🔄 Restore
When you want to restore based on a given backup you first need to grant write permission to the volumes which provide access to bind-mounted directories `files_private` and `webroot/files` (as this is not required for backups it's not activated per default):
- Shutdown the service first: `docker compose -f docker-compose.yml down foodcoopshop-backup`.
- Comment out the according `:ro` suffixed volumes and remove comments from versions without the suffix.
- Start the service again: `docker compose -f docker-compose.yml up -d foodcoopshop-backup`.

Select the desired backups and copy them into the container via `docker cp <Database-BACKUP>.sql.zst foodcoopshop-backup:/tmp` and `docker cp <Files-BACKUP>.tar.zst foodcoopshop-backup:/tmp`. Afterwards execute the restore script via `docker exec -it foodcoopshop-backup sh restore-script.sh /tmp/<Database-BACKUP>.sql.zst /tmp/<Files-BACKUP>.tar.zst`. Check the logs and test if everything works. Finally remove the `:ro` suffix and restart the service again. 

## 🆕 Update of FoodCoopShop
When a new release of FoodCoopShop is published you can incorporate this via the build argument `FCS_VERSION` you pass to the docker compose build command of building the `app` service (see Setup section). Ideally you make use of the `--no-cache` flag as well to assure no obsolete cached data is baked in the new image. Subsequently comply to relevant migration steps from official docs.
