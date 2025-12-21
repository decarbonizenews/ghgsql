#!/bin/sh -x
# SPDX-License-Identifier: 0BSD
set -euo pipefail

DB="eu"
USER="ghg"
PW="ghg"

mariadbd --user=root &

while ! mariadb -uroot -e "show databases;"; do
	sleep 1
done

sleep 5

echo """
CREATE DATABASE $DB;
CREATE USER '$USER'@'%' IDENTIFIED BY '$PW';GRANT ALL PRIVILEGES ON $DB.* TO '$USER'@'%';
""" | mariadb -u root

echo "Import SQL schemas"
cat *.sql | mariadb -u root $DB

echo "Import industrial reporting data"
COLS=$(tail -n +3 ird_schema.sql | head -n -2 | sed -e 's:^  `::g' -e 's:`.*:,:g' | tr -d '\n' | sed -e 's:,$::g')
mariadb-import --ignore-lines=1 --fields-terminated-by=, \
	--fields-optionally-enclosed-by='"' \
	--local -u root $DB irdraw.csv \
	--columns=$COLS

echo "Import ets data"
COLS=$(tail -n +3 ets_schema.sql | head -n -2 | sed -e 's:^  `::g' -e 's:`.*:,:g' | tr -d '\n' | sed -e 's:,$::g')
sed -i -e 's:Excluded:NULL:g' ets.csv
mariadb-import --ignore-lines=21 --fields-terminated-by=, \
	--fields-optionally-enclosed-by='"' \
	--local -u root $DB ets.csv \
	--columns=$COLS

echo "Import linking data"
mariadb-import --ignore-lines=1 --fields-terminated-by=, \
	--local -u root $DB linking.csv \
	--columns=ets,iep,probability

./simplifydb.py
