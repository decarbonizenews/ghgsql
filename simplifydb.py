#!/usr/bin/python3
# SPDX-License-Identifier: 0BSD

import MySQLdb
import MySQLdb.cursors

con = MySQLdb.connect(cursorclass=MySQLdb.cursors.DictCursor, host="127.0.0.1",
                      database="eu", user="ghg")
c = con.cursor()

c.execute("DROP TABLE IF EXISTS prtr")
c.execute("CREATE TABLE prtr LIKE prtrraw")
c.execute("INSERT INTO prtr SELECT * FROM prtrraw")

c.execute("ALTER TABLE prtr DROP COLUMN `PublicationDate`")
c.execute("ALTER TABLE prtr DROP COLUMN `TargetRelease`")

c.execute("ALTER TABLE prtr RENAME COLUMN `countryName` TO `country`")
c.execute("ALTER TABLE prtr RENAME COLUMN `reportingYear` TO `year`")
c.execute("ALTER TABLE prtr RENAME COLUMN `EPRTR_SectorCode` TO `sectorcode`")
c.execute("ALTER TABLE prtr RENAME COLUMN `EPRTR_SectorName` TO `sectorname`")
c.execute("ALTER TABLE prtr RENAME COLUMN `EPRTRAnnexIMainActivity` TO `annexiactivity`")
c.execute("ALTER TABLE prtr RENAME COLUMN `facilityInspireId` TO `inspireid`")
c.execute("ALTER TABLE prtr RENAME COLUMN `facilityName` TO `name`")
c.execute("ALTER TABLE prtr RENAME COLUMN `Longitude` TO `lon`")
c.execute("ALTER TABLE prtr RENAME COLUMN `Latitude` TO `lat`")
c.execute("ALTER TABLE prtr RENAME COLUMN `addressConfidentialityReason` TO `addrconfreason`")
c.execute("ALTER TABLE prtr RENAME COLUMN `Pollutant` TO `pollutant`")
c.execute("ALTER TABLE prtr RENAME COLUMN `Releases` TO `releases`")
c.execute("ALTER TABLE prtr RENAME COLUMN `ConfidentialityReason` TO `confreason`")

c.execute("ALTER TABLE prtr MODIFY "
          "`addrconfreason` VARCHAR(32) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE prtr MODIFY "
          "`annexiactivity` VARCHAR(16) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE prtr MODIFY "
          "`sectorname` VARCHAR(128) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE prtr MODIFY `sectorcode` TINYINT unsigned NOT NULL AFTER `releases`")
c.execute("ALTER TABLE prtr MODIFY `lat` VARCHAR(32) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE prtr MODIFY `lon` VARCHAR(32) CHARACTER SET ascii NOT NULL AFTER `releases`")
c.execute("ALTER TABLE prtr MODIFY `city` VARCHAR(128) NOT NULL AFTER `releases`")

c.execute("SELECT pollutant FROM prtr GROUP BY pollutant")
for p in c.fetchall():
    pollutant = p["pollutant"]
    if not pollutant.endswith(")") or "(as " in pollutant:
        continue
    # we also remove lowercase s to avoid plural forms like CFCs
    shortname = pollutant.split("(")[-1].strip(")s")
    # this one is special...
    if shortname == "HFCS":
        shortname = "HFC"
    c.execute("UPDATE prtr SET pollutant=%s WHERE pollutant=%s", (shortname, pollutant))

con.commit()

c.execute("OPTIMIZE TABLE prtr")
con.close()
