-- Core mart: zip-level growth metrics via window functions.

CREATE OR REPLACE TABLE marts.zip_growth AS
SELECT
  zip_code, state, metro, county, is_georgia, is_atl_metro, month, zhvi,
  LAG(zhvi, 12) OVER w                                       AS zhvi_prior_year,
  SAFE_DIVIDE(zhvi - LAG(zhvi, 12) OVER w,
              LAG(zhvi, 12) OVER w)                          AS yoy_growth,
  AVG(zhvi) OVER (PARTITION BY zip_code ORDER BY month
                  ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS zhvi_12mo_avg,
  SAFE_DIVIDE(zhvi, FIRST_VALUE(zhvi) OVER w)                AS index_vs_start
FROM marts.stg_zhvi
WINDOW w AS (PARTITION BY zip_code ORDER BY month);
