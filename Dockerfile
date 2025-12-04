# SPDX-License-Identifier: 0BSD

FROM debian:trixie

ENV PHPMYADMIN_VERSION="5.2.3"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get -y install apache2 \
	mariadb-server \
	php libapache2-mod-php php-mysql \
	php-mbstring \
	wget xz-utils \
	nano less \
	xlsx2csv

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
RUN wget --content-disposition 'https://sdi.eea.europa.eu/datashare/public.php/dav/files/gkNxiP52NwafRGs/User%20friendly%20.csv%20file/F1_4_Air_Releases_Facilities.csv'

# Latest "Verified Emissions" from
# https://union-registry-data.ec.europa.eu/report/welcome
# Last data update: 2025-04-01
RUN wget --content-disposition 'https://climate.ec.europa.eu/document/download/385daec1-0970-44ab-917d-f500658e72aa_en?filename=verified_emissions_2024_en.xlsx'
RUN xlsx2csv verified_emissions_2024_en.xlsx /ets

# Download linking data
# https://cadmus.eui.eu/entities/publication/d8887cdd-c98c-4ba3-8e91-0710747f4e4e
RUN wget --content-disposition https://cadmus.eui.eu/server/api/core/bitstreams/6723beed-f56f-43e7-8cb4-dc526a62f087/content

ADD mprep.sh /mprep.sh
ADD eu_schema.sql /eu_schema.sql
ADD ets_schema.sql /ets_schema.sql
ADD linking_schema.sql /linking_schema.sql
RUN /mprep.sh

RUN rm /mprep.sh /eu_schema.sql /F1_4_Air_Releases_Facilities.csv /eu

ADD run.sh /run.sh
CMD ["/run.sh"]

EXPOSE 80
EXPOSE 3306
