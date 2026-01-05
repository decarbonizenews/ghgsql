#!/bin/sh -x
# SPDX-License-Identifier: 0BSD
set -euo pipefail

DB="eu"
USER="ghg"

mariadbd --user=root &

while ! mariadb -uroot -e "show databases;"; do
	sleep 1
done

sleep 5

echo """
CREATE DATABASE $DB;
CREATE USER '$USER'@'%' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON $DB.* TO '$USER'@'%';
RENAME USER 'root'@'localhost' TO 'root'@'%';
SET PASSWORD FOR 'root'@'%' = PASSWORD('');
""" | mariadb -u root

echo "Import SQL schemas"
cat *.sql | mariadb -u root $DB

echo "Import industrial reporting data"
COLS=$(tail -n +3 iep_schema.sql | head -n -2 | sed -e 's:^  `::g' -e 's:`.*:,:g' | tr -d '\n' | sed -e 's:,$::g' -e 's:EPRTR_SectorCode:@EPRTR_SectorCode:g' -e 's:Releases:@Releases:g')
echo "LOAD DATA INFILE '/iepraw.csv' INTO TABLE iepraw
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES
      ($COLS) SET EPRTR_SectorCode=NULLIF(@EPRTR_SectorCode, ''),
      Releases=NULLIF(@Releases, '');SHOW WARNINGS" | mariadb -u root eu

echo "Import ets data"
COLS=$(tail -n +3 ets_schema.sql | head -n -2 | sed -e 's:^  `::g' -e 's:`.*:,:g' | tr -d '\n' | sed -e 's:,$::g')
sed -i -e 's:Excluded:NULL:g' ets.csv
echo "LOAD DATA INFILE '/ets.csv' INTO TABLE ets
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 21 LINES
      ($COLS);SHOW WARNINGS" | mariadb -u root eu

echo "Import linking data"
sed -i -e 's:^\([A-Z][A-Z]\)_:\1,:g' linking.csv
echo "LOAD DATA INFILE '/linking.csv' INTO TABLE linking
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' IGNORE 1 LINES
      (country,ets,iep,probability);SHOW WARNINGS" | mariadb -u root eu

./simplifydb.py
