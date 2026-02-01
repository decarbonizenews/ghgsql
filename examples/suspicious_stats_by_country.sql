# SPDX-License-Identifier: 0BSD
#
# Aggregating potential off-by-1000x errors by country to identify
# systematic issues or lack thereof.
#
# You can execute this by piping it into the ghgsql script:
#   ./ghgsql < examples/suspicious_stats_by_country.sql
#
# Alternatively, you can run this in any SQL client connecting to the database,
# or in the phpMyAdmin web interface (http://localhost/ by default) by pasting
# the query into the SQL window.

WITH YoY_Analysis AS (
    -- 1. Calculate Previous Year's Release for every row
    SELECT inspireid,
           pollutant,
           year,
           releases,
           LAG(releases) OVER (PARTITION BY inspireid, pollutant ORDER BY year) as prev_releases
    FROM eu.iep
    WHERE releases > 0 -- Ignore 0s
),
     Suspicious_Facilities AS (
         -- 2. Find unique IDs that have at least one bad jump in any pollutant
         SELECT DISTINCT inspireid
         FROM YoY_Analysis
         WHERE prev_releases IS NOT NULL
           AND (
             (CAST(releases AS FLOAT) / prev_releases BETWEEN 500 AND 2000) -- Jump up ~1000x
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 0.0005 AND 0.002) -- Drop down ~1000x
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 500000 AND 2000000) -- Jump up ~1,000,000x
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 0.0000005 AND 0.000002) -- Drop down ~1,000,000x
             ))
-- 3. Aggregation by Country
SELECT t.country,
       COUNT(DISTINCT t.inspireid) AS total_companies,
       COUNT(DISTINCT s.inspireid) AS suspicious_companies,
       ROUND(
               (COUNT(DISTINCT s.inspireid) * 100.0 / COUNT(DISTINCT t.inspireid)),
               2
       )                           AS percentage_suspicious
FROM eu.iep t
         LEFT JOIN Suspicious_Facilities s ON t.inspireid = s.inspireid
GROUP BY t.country
ORDER BY percentage_suspicious DESC;
