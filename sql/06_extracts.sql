-- Extract queries feeding Tableau (run via bq query --format=csv, see README).
-- Each stays well under Tableau Public's comfort zone.

-- extracts/zip_growth_ga.csv — all Georgia zips, all months
SELECT zip_code, county, metro, is_atl_metro, month, zhvi,
       yoy_growth, zhvi_12mo_avg, index_vs_start
FROM marts.zip_growth
WHERE is_georgia
ORDER BY zip_code, month;

-- extracts/metro_benchmark.csv
SELECT * FROM marts.metro_benchmark ORDER BY month;

-- extracts/spread_atl.csv
SELECT * FROM marts.spread_atl ORDER BY metro, month;
