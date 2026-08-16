-- Mart: list-vs-sale spread and price-cut share for Atlanta and the US benchmark.
-- sale_to_list_ratio > 1 means homes selling over list (seller's market gauge).
-- Series start dates differ (list/price-cut 2018-03, sale 2018-08) — FULL JOIN keeps all.

CREATE OR REPLACE TABLE marts.spread_atl AS
SELECT
  metro,
  month,
  s.median_sale_price,
  l.median_list_price,
  p.price_cut_share,
  SAFE_DIVIDE(s.median_sale_price, l.median_list_price) AS sale_to_list_ratio
FROM marts.sale_price_long s
FULL JOIN marts.list_price_long  l USING (metro, month)
FULL JOIN marts.price_cut_long   p USING (metro, month)
WHERE metro IN ('Atlanta, GA', 'United States')
ORDER BY metro, month;
