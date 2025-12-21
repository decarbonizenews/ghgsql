#!/usr/bin/python3
# SPDX-License-Identifier: 0BSD

import MySQLdb
import MySQLdb.cursors

con = MySQLdb.connect(cursorclass=MySQLdb.cursors.DictCursor, host="127.0.0.1",
                      database="eu", user="ghg", password="ghg")  # noqa: S106
c = con.cursor()

c.execute("CREATE TABLE `ird` LIKE `irdraw`")
c.execute("INSERT INTO `ird` SELECT * FROM `irdraw`")

c.execute("ALTER TABLE `ird` DROP COLUMN `PublicationDate`")
c.execute("ALTER TABLE `ird` DROP COLUMN `TargetRelease`")

c.execute("ALTER TABLE `ird` RENAME COLUMN `countryName` TO `country`")
c.execute("ALTER TABLE `ird` RENAME COLUMN `reportingYear` TO `year`")
c.execute("ALTER TABLE `ird` RENAME COLUMN `facilityName` TO `name`")
c.execute("ALTER TABLE `ird` RENAME COLUMN `facilityInspireId` TO `inspireid`")
c.execute("ALTER TABLE `ird` RENAME COLUMN `Pollutant` TO `pollutant`")
c.execute("ALTER TABLE `ird` RENAME COLUMN `Releases` TO `releases`")

c.execute("SELECT pollutant FROM ird GROUP BY pollutant")
for p in c.fetchall():
    pollutant = p["pollutant"]
    if not pollutant.endswith(")") or "(as " in pollutant:
        continue
    # we also remove lowercase s to avoid plural forms like CFCs
    shortname = pollutant.split("(")[-1].strip(")s")
    # this one is special...
    if shortname == "HFCS":
        shortname = "HFC"
    c.execute("UPDATE ird SET pollutant=%s WHERE pollutant=%s", (shortname, pollutant))

con.commit()

c.execute("OPTIMIZE TABLE `ird`")
con.close()
