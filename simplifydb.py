#!/usr/bin/python3
# SPDX-License-Identifier: 0BSD

import MySQLdb
import MySQLdb.cursors
import pycountry

con = MySQLdb.connect(cursorclass=MySQLdb.cursors.DictCursor, host="127.0.0.1",
                      database="eu", user="ghg")
c = con.cursor()

c.execute("DROP TABLE IF EXISTS iep")
c.execute("CREATE TABLE iep LIKE iepraw")
c.execute("INSERT INTO iep SELECT * FROM iepraw")

c.execute("ALTER TABLE iep DROP COLUMN `PublicationDate`")
c.execute("ALTER TABLE iep DROP COLUMN `TargetRelease`")

c.execute("ALTER TABLE iep RENAME COLUMN `countryName` TO `country`")
c.execute("ALTER TABLE iep RENAME COLUMN `reportingYear` TO `year`")
c.execute("ALTER TABLE iep RENAME COLUMN `EPRTR_SectorCode` TO `sectorcode`")
c.execute("ALTER TABLE iep RENAME COLUMN `EPRTR_SectorName` TO `sectorname`")
c.execute("ALTER TABLE iep RENAME COLUMN `EPRTRAnnexIMainActivity` TO `annexiactivity`")
c.execute("ALTER TABLE iep RENAME COLUMN `facilityInspireId` TO `inspireid`")
c.execute("ALTER TABLE iep RENAME COLUMN `facilityName` TO `name`")
c.execute("ALTER TABLE iep RENAME COLUMN `Longitude` TO `lon`")
c.execute("ALTER TABLE iep RENAME COLUMN `Latitude` TO `lat`")
c.execute("ALTER TABLE iep RENAME COLUMN `addressConfidentialityReason` TO `addrconfreason`")
c.execute("ALTER TABLE iep RENAME COLUMN `Pollutant` TO `pollutant`")
c.execute("ALTER TABLE iep RENAME COLUMN `Releases` TO `releases`")
c.execute("ALTER TABLE iep RENAME COLUMN `ConfidentialityReason` TO `confreason`")

c.execute("ALTER TABLE iep MODIFY "
          "`addrconfreason` VARCHAR(32) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE iep MODIFY "
          "`annexiactivity` VARCHAR(16) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE iep MODIFY "
          "`sectorname` VARCHAR(128) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE iep MODIFY `sectorcode` TINYINT unsigned NOT NULL AFTER `releases`")
c.execute("ALTER TABLE iep MODIFY `lat` VARCHAR(32) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE iep MODIFY `lon` VARCHAR(32) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE iep MODIFY `city` VARCHAR(128) NOT NULL AFTER `releases`")

c.execute("SELECT pollutant FROM iep GROUP BY pollutant")
for p in c.fetchall():
    pollutant = p["pollutant"]
    if not pollutant.endswith(")") or "(as " in pollutant:
        continue
    # we also remove lowercase s to avoid plural forms like CFCs
    shortname = pollutant.split("(")[-1].strip(")s")
    # this one is special...
    if shortname == "HFCS":
        shortname = "HFC"
    c.execute("UPDATE iep SET pollutant=%s WHERE pollutant=%s", (shortname, pollutant))

# Use 2-letter country codes to align with ETS database
c.execute("SELECT country FROM iep GROUP BY country")
for x in c.fetchall():
    countryname = x["country"]
    countryshort = pycountry.countries.get(name=countryname).alpha_2
    c.execute("UPDATE iep SET country=%s WHERE country=%s", (countryshort, countryname))

con.commit()

c.execute("OPTIMIZE TABLE iep")
con.close()
