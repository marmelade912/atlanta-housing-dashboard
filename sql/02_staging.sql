-- Staging: quality filter + geography flags.
-- Run the count first and record the result in the README before applying the filter:
--   SELECT COUNT(*) AS dropped_rows, COUNTIF(zhvi <= 10000) / COUNT(*) AS drop_share
--   FROM marts.zhvi_long WHERE zhvi <= 10000;

CREATE OR REPLACE VIEW marts.stg_zhvi AS
SELECT
  *,
  state = 'GA'          AS is_georgia,
  metro LIKE 'Atlanta%' AS is_atl_metro   -- zip file spells it 'Atlanta-Sandy Springs-Alpharetta, GA'
FROM marts.zhvi_long
WHERE zhvi > 10000;
