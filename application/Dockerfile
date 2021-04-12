FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
ENV FCS_VERSION="v3.2.2"
ENV PHP_VERSION="7.4"
ENV FCS_SITE_CONF_NAME="010-foodcoopshop.conf"

RUN apt-get -y update --fix-missing --no-install-recommends
RUN apt-get -y upgrade

# Install useful tools & libs
RUN apt-get -yq install apt-utils nano wget dialog unzip curl cron

# MySQL
# RUN apt-get -yq install mysql-server mysql-client libmysqlclient-dev
# RUN apt-get -yq install mysql-client

RUN apt-get -yq install apache2 apache2-doc apache2-utils libexpat1 ssl-cert
# Enable apache modules
RUN a2enmod rewrite headers

# PHP
RUN apt-get -yq install software-properties-common
RUN add-apt-repository ppa:ondrej/php
RUN apt-get update
RUN apt-get -yq install libapache2-mod-php$PHP_VERSION php$PHP_VERSION php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-dev php$PHP_VERSION-gd php-pear php-imagick php$PHP_VERSION-mysql php$PHP_VERSION-ps php$PHP_VERSION-xsl php$PHP_VERSION-intl php$PHP_VERSION-mbstring php$PHP_VERSION-xml
RUN a2enmod php$PHP_VERSION

# Copy application files
WORKDIR /var/www
RUN wget https://github.com/foodcoopshop/foodcoopshop/releases/download/$FCS_VERSION/FoodCoopShop-$FCS_VERSION.zip
RUN unzip FoodCoopShop-$FCS_VERSION.zip
RUN rm FoodCoopShop-$FCS_VERSION.zip

COPY $FCS_SITE_CONF_NAME /etc/apache2/sites-available/$FCS_SITE_CONF_NAME
RUN ln -sr /etc/apache2/sites-available/$FCS_SITE_CONF_NAME /etc/apache2/sites-enabled
RUN rm /etc/apache2/sites-enabled/000-default.conf

RUN chown -R www-data:www-data foodcoopshop

WORKDIR /var/www/foodcoopshop

RUN chmod -R a+w ./files_private
RUN chmod -R a+w ./tmp
RUN chmod -R a+w ./webroot/cache
RUN chmod -R a+w ./webroot/files
RUN chmod -R a+w ./webroot/tmp

CMD apachectl -DFOREGROUND