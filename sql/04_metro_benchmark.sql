-- Mart: metro Atlanta vs Georgia vs national, monthly — plus Atlanta's YoY-growth rank
-- among the 50 largest metros.
--
-- Notes:
-- * Medians use APPROX_QUANTILES (BigQuery has no aggregate PERCENTILE_CONT); the
--   Phase 2 reconciliation compares against pandas to tolerance for this reason.
-- * The zip file's SizeRank ranks zips, not metros, and its metro names don't match
--   the metro-level files ('Atlanta-Sandy Springs-Alpharetta, GA' vs 'Atlanta, GA'),
--   so "top-50 metros" is defined by zip count in the ZHVI data — a documented proxy.

CREATE OR REPLACE TABLE marts.metro_benchmark AS
WITH medians AS (
  SELECT
    month,
    APPROX_QUANTILES(IF(is_atl_metro, zhvi, NULL), 100)[OFFSET(50)] AS atl_median_zhvi,
    APPROX_QUANTILES(IF(is_georgia,  zhvi, NULL), 100)[OFFSET(50)]  AS ga_median_zhvi,
    APPROX_QUANTILES(zhvi, 100)[OFFSET(50)]                         AS us_median_zhvi
  FROM marts.stg_zhvi
  GROUP BY month
),
top50_metros AS (
  SELECT metro
  FROM marts.stg_zhvi
  WHERE metro IS NOT NULL
  GROUP BY metro
  ORDER BY COUNT(DISTINCT zip_code) DESC
  LIMIT 50
),
metro_monthly AS (
  SELECT metro, month, APPROX_QUANTILES(zhvi, 100)[OFFSET(50)] AS metro_median
  FROM marts.stg_zhvi
  WHERE metro IN (SELECT metro FROM top50_metros)
  GROUP BY metro, month
),
metro_growth AS (
  SELECT
    metro, month,
    SAFE_DIVIDE(metro_median - LAG(metro_median, 12) OVER w,
                LAG(metro_median, 12) OVER w) AS metro_yoy
  FROM metro_monthly
  WINDOW w AS (PARTITION BY metro ORDER BY month)
),
ranked AS (
  SELECT
    metro, month, metro_yoy,
    RANK() OVER (PARTITION BY month ORDER BY metro_yoy DESC) AS yoy_rank_top50
  FROM metro_growth
  WHERE metro_yoy IS NOT NULL
)
SELECT
  m.month,
  m.atl_median_zhvi,
  m.ga_median_zhvi,
  m.us_median_zhvi,
  r.metro_yoy      AS atl_metro_yoy,
  r.yoy_rank_top50 AS atl_yoy_rank_top50
FROM medians m
LEFT JOIN ranked r
  ON r.month = m.month AND r.metro LIKE 'Atlanta%'
ORDER BY m.month;
