#!/bin/sh -x
# SPDX-License-Identifier: 0BSD

SCHEMA="eu_schema.sql"
DB="ghg"
USER="ghg"
PW="ghg"
TABLE="eu"

mariadbd --user=root &

while ! mariadb -uroot -e "show databases;"; do
	sleep 1
done

sleep 5

echo """
CREATE DATABASE $DB;
CREATE USER '$USER'@'%' IDENTIFIED BY '$PW';GRANT ALL PRIVILEGES ON $DB.* TO '$USER'@'%';
""" | mariadb -u root

echo "import industrial reporting schema"

mariadb -u root $DB <$SCHEMA

COLS=$(tail -n +3 $SCHEMA | head -n -2 | sed -e 's:^  `::g' -e 's:`.*:,:g' | tr -d '\n' | sed -e 's:,$::g')

echo "import industrial reporting data"

# needed because mariadb-import uses filename as table name
ln -s /F1_4_Air_Releases_Facilities.csv $TABLE
mariadb-import --ignore-lines=1 --fields-terminated-by=, \
	--fields-optionally-enclosed-by='"' \
	--local -u root $DB /$TABLE \
	--columns=$COLS

echo "import ets schema"

mariadb -u root $DB </ets_schema.sql

COLS=$(tail -n +3 /ets_schema.sql | head -n -2 | sed -e 's:^  `::g' -e 's:`.*:,:g' | tr -d '\n' | sed -e 's:,$::g')

echo "import ets data"

sed -i -e 's:Excluded:NULL:g' /ets

mariadb-import --ignore-lines=21 --fields-terminated-by=, \
	--fields-optionally-enclosed-by='"' \
	--local -u root $DB /ets \
	--columns=$COLS
