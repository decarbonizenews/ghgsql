# SPDX-License-Identifier: 0BSD
#
# Heuristically detecting potential t/kg unit confusion/off-by-1000x
# errors in the Industrial Emissions Portal data.
#
# You can execute this by piping it into the ghgsql script:
#   ./ghgsql < examples/suspicious_jumps.sql
#
# Alternatively, you can run this in any SQL client connecting to the database,
# or in the phpMyAdmin web interface (http://localhost/ by default) by pasting
# the query into the SQL window.

WITH YoY_Analysis AS (
    -- 1. Calculate Previous Year's Release for every row
    SELECT id,
           inspireid,
           pollutant,
           year,
           releases,
           LAG(releases) OVER (PARTITION BY inspireid, pollutant ORDER BY year) as prev_releases
    FROM eu.iep
    WHERE releases > 0 -- Ignore 0s to avoid divide-by-zero errors
),
     Suspicious_Pairs AS (
         -- 2. Find specific Pollutant streams that have the error
         SELECT DISTINCT inspireid,
                         pollutant
         FROM YoY_Analysis
         WHERE prev_releases IS NOT NULL
           AND (
             (CAST(releases AS FLOAT) / prev_releases BETWEEN 500 AND 2000) -- Jump up ~1000x
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 0.0005 AND 0.002) -- Drop down ~1000x
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 500000 AND 2000000) -- Jump up ~1,000,000x
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 0.0000005 AND 0.000002) -- Drop down ~1,000,000x
             ))
-- 3. Select all years, but ONLY for the specific bad pollutants found above
SELECT t.id,
       t.country,
       t.year,
       t.inspireid,
       t.name,
       t.pollutant,
       t.releases,
       t.city,
       -- Re-calculate the flag for display purposes
       CASE
           WHEN y.prev_releases IS NOT NULL AND (
               (CAST(t.releases AS FLOAT) / y.prev_releases BETWEEN 500 AND 2000)
                   OR (CAST(t.releases AS FLOAT) / y.prev_releases BETWEEN 0.0005 AND 0.002)
                   OR (CAST(t.releases AS FLOAT) / y.prev_releases BETWEEN 500000 AND 2000000)
                   OR (CAST(t.releases AS FLOAT) / y.prev_releases BETWEEN 0.0000005 AND 0.000002)
               )
               THEN '<<< SUSPICIOUS JUMP'
           ELSE ''
           END as status_flag
FROM eu.iep t
         JOIN Suspicious_Pairs sp
              ON t.inspireid = sp.inspireid
                  AND t.pollutant = sp.pollutant
         LEFT JOIN YoY_Analysis y ON t.id = y.id
ORDER BY t.country,
         t.name,
         t.pollutant,
         t.year;
