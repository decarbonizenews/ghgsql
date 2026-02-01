# SPDX-License-Identifier: 0BSD
#
# Aggregating potential off-by-1000x errors by country and year to
# identify temporal patterns (e.g., process changes).
#
# You can execute this by piping it into the ghgsql script:
#   ./ghgsql < examples/suspicious_stats_by_year.sql
#
# Alternatively, you can run this in any SQL client connecting to the database,
# or in the phpMyAdmin web interface (http://localhost/ by default) by pasting
# the query into the SQL window.

WITH YoY_Analysis AS (
    -- 1. Calculate Previous Year's Release
    SELECT inspireid,
           pollutant,
           country,
           year,
           releases,
           LAG(releases) OVER (PARTITION BY inspireid, pollutant ORDER BY year) as prev_releases
    FROM eu.iep
    WHERE releases > 0),
     Suspicious_Rows AS (
         -- 2. Identify the specific rows (Country + Year + Company + Pollutant) that are jumps
         SELECT country,
                year,
                inspireid,
                pollutant
         FROM YoY_Analysis
         WHERE prev_releases IS NOT NULL
           AND (
             (CAST(releases AS FLOAT) / prev_releases BETWEEN 500 AND 2000)
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 0.0005 AND 0.002)
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 500000 AND 2000000)
                 OR (CAST(releases AS FLOAT) / prev_releases BETWEEN 0.0000005 AND 0.000002)
             ))
-- 3. Group by Country AND Year to find the "Bad Forms"
SELECT t.country,
       t.year,
       -- Count how many pollutant reports were filed that year total
       COUNT(*)           AS total_pollutant_reports,
       -- Count how many of those were suspicious jumps
       COUNT(s.inspireid) AS suspicious_jumps,
       -- Calculate the error rate for that specific year
       ROUND(
               (COUNT(s.inspireid) * 100.0 / COUNT(*)),
               2
       )                  AS error_rate_percentage
FROM eu.iep t
         LEFT JOIN Suspicious_Rows s
                   ON t.country = s.country
                       AND t.year = s.year
                       AND t.inspireid = s.inspireid
                       AND t.pollutant = s.pollutant
GROUP BY t.country, t.year
HAVING total_pollutant_reports > 10 -- Filter out tiny datasets to avoid noise
ORDER BY country, year;
