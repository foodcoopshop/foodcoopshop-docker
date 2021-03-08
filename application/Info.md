# Example build
docker build -t mantenpanther/foodcoopshop:3.2.0 .

# Create Net
docker network create -d bridge fcs-testnet

# Run MySQL
docker run --name fcs-mysql \
-v $FCS_CONFIG_PATH/mysql/setup:/home/setup \
-v $FCS_CONFIG_PATH/mysql/sql:/home/sql \
-v $FCS_CONFIG_PATH/data/mysql:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=mysecret \
--network=fcs-testnet \
-d mysql:5.7

docker exec -it CONTAINER_ID /bin/bash
# bash /home/setup/setup.sh

# Run application container
docker run --name fcs-app \
-v $FCS_CONFIG_PATH/logs/apache2:/var/log/apache2 \
-v $FCS_CONFIG_PATH/config/vhosts/010-sgartl.conf:/etc/apache2/sites-availabe/010-sgartl.conf \
-v $FCS_CONFIG_PATH/config/app/credentials.php:/var/www/foodcoopshop/config/credentials.php \
-v $FCS_CONFIG_PATH/config/app/custom_config.php:/var/www/foodcoopshop/config/custom_config.php \
-p 80:80 \
--network=fcs-testnet \
-d mantenpanther/foodcoopshop:3.2.0