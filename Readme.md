# FoodCoopShop hosted with Docker Swarm

A Docker stack for FoodCoopShop which uses

- **MySql** as database
- An **Ubuntu** based container with **Apache** as webserver to host the [FoodCoopShop](https://www.foodcoopshop.com)  application
- **Nginx** as web-proxy and for SSL-termination

The project is currently intended for educational purposes and it's not recommended to run a live system with this approach. I use it for demo and testing purposes.

## Setup Instructions for Host
Tested with an Ubuntu 18.04 and Docker 19.03.

Start with a fresh Ubuntu host system and install Docker. For infos about installing Docker see for example https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04.

Change configs, names and placeholders in the different files according to your environment.

### 1. Setup some folders for SSL cert
    mkdir -p /var/lib/letsencrypt
    mkdir -p /etc/letsencrypt
    mkdir -p /usr/share/nginx/html

Copy necessary files on the host working dir, e.g. /home/foodcoopshop

    mkdir -p /home/foodcoopshop

Clone this repo and make your changes to the configs as far as possible at this point. Then copy via scp

    scp -r * root@HOST:/home/foodcoopshop

or do this directly on the server.

All commands later on are executed from the working dir _/home/foodcoopshop_.

### 2. Init Docker swarm
Run

    docker swarm init --advertise-addr IP

and use your hosts IP address.

### 3. Generate ssl certificate
Make sure you updated your DNS settings for your domain.

Run

    bash scripts/generate.sh

This executes a docker container with certbot (command see below) and stores the certificate for the given domain in the "/var/lib/letsencrypt" folder on the host. This folder will be used by Nginx.

    docker run --rm \
    -p 443:443 -p 80:80 --name letsencrypt \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    certbot/certbot certonly -n \
    -m "admin@fcsdemo1.com" \
    -d fcsdemo1.com -d www.fcsdemo1.com \
    --standalone --agree-tos

Obviously you have to change email and domains to your settings.

### 4. Pull images
    docker pull nginx:stable-alpine
    docker pull mysql:5.7
    docker pull mantenpanther/foodcoopshop:3.2.0

#### 4.1 Using your own FoocCoopShop image
Modify the Dockerfile in the _application_ folder to your liking and create a new image, for example

    docker build -t mantensteiner/myfoodcoopshop:latest .

### 5. Start Swarm stack
The command to run the full stack would be

    docker stack deploy -c docker-compose.yml fcsdemo1

But for the inital DB-Setup you can run the MySQL container in isolation to initialize the DB in beforehand and then start the full stack. So you at first you run the comand

    docker stack deploy -c docker-compose-init.yml fcsdemo1

Then you setup the DB (see 5.1) and after successful initialization destroy the stack with

    docker stack rm fcsdemo1

and make the configuration changes described in 5.2 and 5.3.

Finally run the command above for the **full** stack and make the necessary file changes to configure the system on the way:

- Navigate to the site and copy the Salt to your custom_config.php and eventually restart the application container

        docker restart CONTAINER_ID

- Navigate to the site and create a Superadmin account (see guide)
  - Update the account configuration directly in MySql

        # After account creation
        mysql -uroot -pmysecret foodcoopshop_db -e "UPDATE fcs_customer SET id_default_group = 5 WHERE id_customer=1;"
        mysql -uroot -pmysecret foodcoopshop_db -e "UPDATE fcs_customer SET active = 1 WHERE id_customer=1;"

  - Add the password to the credentials.php


#### 5.1 MySQL Initialization
The Database must be initialized manually and also updated manually after the Superadmin account creation.

- Deploy a new Swarm stack by using the "init" compose file, e.g. _docker stack deploy -c docker-compose-init.yml fcsdemo1_ as described above.

  Alternatively start the container via _docker_-command (also create a network first) should also work

        docker network create -d bridge fcs-testnet

        docker run --name fcs-mysql \
        -v /home/foodcoopshop/mysql/setup:/home/setup \
        -v /home/foodcoopshop/mysql/sql:/home/sql \
        -v /home/foodcoopshop/data/mysql:/var/lib/mysql \
        -e MYSQL_ROOT_PASSWORD=mysecret \
        --network=fcs-testnet \
        -d mysql:5.7

- Execute a bash in the running container via

        docker exec -it CONTAINER_ID /bin/bash

- Inside the container run following command

        bash /home/setup/setup.sh

  This initializes the DB by creating users, schemas and initial data. Use the right file for your language, in this case it's german by using _clean-db-data-de_DE.sql_.

Because of the manual steps required this procedure (connecting into the container and executing setup-files) has room for improvement, but it does not depend on other tools.

You could also setup containers for Admin-tools like Adminer or PhpMyAdmin and setup your DB this way, but you would need to open the DB-port on the host.

#### 5.2 Nginx, Letsencrypt
Instead of using Apache directly, this stack uses Nginx a front facing web-proxy and Let's Encrypt for SSL certificates. The FoodCoopShop application runs on Apache and port 80 internally, all incoming  traffic is routed to the application through Nginx.

Update the _config/nginx/nginx.conf_ settings to your environment.

Create a cron-job on the host for certificate renewal

    bash scripts/add_renew_cron.sh

#### 5.3 FoodCoopShop
The application relies on a few manual file-changes during setup. To keep the container unchanged (avoiding creating new images) the changes are made on the host and the files are projected into the container via volume-mappings. Here is an example on how to start the container for debugging purposes (without volume mappings):

    docker run --name fcs-app \
    -v /home/foodcoopshop/logs/apache2:/var/log/apache2 \
    -v /home/foodcoopshop/config/vhosts/010-foodcoopshop.conf:/etc/apache2/sites-availabe/010-foodcoopshop.conf \
    -v /home/foodcoopshop/config/app/credentials.php:/var/www/foodcoopshop/config/credentials.php \
    -v /home/foodcoopshop/config/app/custom_config.php:/var/www/foodcoopshop/config/custom_config.php \
    -p 80:80 \
    --network=fcs-testnet \
    -d mantenpanther/foodcoopshop:3.2.0

Following files need to be customized:
- vhost for Apache conf (eventually, maybe the default-file is good enough)
- credentials.php
- custom_config.php

See https://foodcoopshop.github.io/en/installation-guide.html for installation details.

Most steps of this guide are already done by using the _mantenpanther/foodcoopshop_ image. Just update the configs with your Email-settings in both php config files, the security salt in _custom_config.php_ (which should be displayed when you open the application for the first time in the browser), and admin-password after registration of the superadmin in _credentials.php_.

Also the application writes to some locations:
- /var/www/foodcoopshop/logs (eg. errors)
- /var/www/foodcoopshop/webroot/files (eg. uploaded images)
- /var/www/foodcoopshop/files_private

Therefore these folders must be mapped to the host system to keep the changes after container restarts or container updates (e.g. on new versions) and to be availabe for backups on the host-system (besides the SQL-backup).

This is currently the biggest flaw with this approach (Docker-hosting), because it's not certain the application does not depend on the webroot/files folder in some way in a future release. Also the application could persist in other folders (subfolders of webroot). Therefore I do not recommend using this approach for live systems.

Also some unsupported (but rather harmless) customizations can be done explicitly by mapping files into the container. E.g. changing the background tile:
- ${PWD}/images/background/bg.jpg:/var/www/foodcoopshop/webroot/img/bg.jpg

### 6. Other

#### 6.1 Manual Backup Images/Content
scp -r root@HOST:/var/www/APPLICATION_FOLDER/webroot/files ./foodcoopshop_backup/webroot_files


### 6. TODOs
- Use Docker secrets