# SPDX-License-Identifier: 0BSD

FROM debian:trixie

ENV PHPMYADMIN_VERSION="5.2.2"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get -y install apache2 \
	mariadb-server \
	php libapache2-mod-php php-mysql \
	php-mbstring \
	wget xz-utils \
	nano less

RUN wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.xz

RUN rm /var/www/html/index.html
RUN tar --strip-components=1 -xf phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.xz -C /var/www/html
RUN rm phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.xz
RUN mkdir /var/www/html/tmp
RUN chown www-data:www-data /var/www/html/tmp

# phpMyAdmin config file
ADD config.inc.php /var/www/html/config.inc.php

RUN mkdir /var/run/mysqld
RUN chown mysql:mysql /var/run/mysqld
RUN sed -e 's:^bind-address:#bind-address:g' -i /etc/mysql/mariadb.conf.d/50-server.cnf


# Check for latest version:
# https://sdi.eea.europa.eu/catalogue/srv/eng/catalog.search#/metadata/9405f714-8015-4b5b-a63c-280b82861b3d
# Last data update: 2024-12-17

# Download emission data
RUN wget --content-disposition 'https://sdi.eea.europa.eu/datashare/s/qKbdiHx3yrqzjZ6/download?path=%2FUser%20friendly%20.csv%20file&files=F1_4_Air_Releases_Facilities.csv&downloadStartSecret=gx3d3xxpo8u'

ADD mprep.sh /mprep.sh
ADD eu_schema.sql /eu_schema.sql
RUN /mprep.sh

RUN rm /mprep.sh /eu_schema.sql /F1_4_Air_Releases_Facilities.csv /eu

ADD run.sh /run.sh
CMD ["/run.sh"]

EXPOSE 80
EXPOSE 3306
