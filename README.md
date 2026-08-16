# Atlanta Housing: Price & Value Explorer

End-to-end housing analytics pipeline: 25 years of Zillow home-value data (26K+ US zip
codes, ~8M monthly observations) loaded and modeled in Google BigQuery, validated with a
Python reconciliation script, and published as an interactive Tableau Public dashboard
focused on metro Atlanta against national benchmarks.

> Work in progress — sections below are filled in as each phase ships.

## Architecture

Zillow Research CSVs → BigQuery (`raw` → `marts` via SQL: UNPIVOT, window functions) →
CSV extracts → Python validation (`python/validate_extracts.py`) → Tableau Public.

## Data

Source: [Zillow Research](https://www.zillow.com/research/data/) public CSVs.
**Downloaded: 2026-08-16.** Zillow revises history, so re-downloads will not match exactly.

| File | Geography | Series |
|---|---|---|
| ZHVI, All Homes (SFR+Condo), smoothed, seasonally adjusted | ZIP code | monthly, 2000–present |
| Median Sale Price | Metro | monthly |
| Median List Price | Metro | monthly |
| Share of Listings With a Price Cut | Metro | monthly |

## Repo layout

- `sql/` — every BigQuery query, in run order
- `python/` — validation / reconciliation scripts
- `extracts/` — CSVs feeding Tableau (gitignored; regenerate from `sql/`)
- `data/` — raw Zillow downloads (gitignored)

## Cleaning decisions

- **Unpivot:** the ZHVI file arrives wide (26,269 zips × 319 month columns ≈ 8.38M cells).
  `python/generate_unpivot_sql.py` generates the BigQuery `UNPIVOT` IN-list from the CSV
  header — the documented pattern for ~320-column unpivots (the alternative is hand-writing
  the list). The three metro files are wide too and get the same treatment.
- **NULL cells:** UNPIVOT drops NULLs by design; 22.95% of raw cells were NULL (sparse
  early-2000s coverage), leaving **6,456,323 observations** in `marts.zhvi_long`.
- **Quality filter:** `zhvi > 10000` in `marts.stg_zhvi` drops **87 rows** (counted before
  applying).
- **Zip codes:** BigQuery autodetect types `RegionName` as INTEGER, which strips leading
  zeros from northeastern zips — restored with `LPAD(CAST(... AS STRING), 5, '0')`.
- **Metro naming:** the zip file spells the metro `Atlanta-Sandy Springs-Alpharetta, GA`
  while metro-level files use `Atlanta, GA`; flags and joins handle each form where it lives.
- **"Top-50 metros"** for the YoY rank is defined by zip count in the ZHVI data (the zip
  file's `SizeRank` ranks zips, not metros, and its metro names don't match the metro files).

## Validation

`python/validate_extracts.py`, run 2026-08-16 — all checks PASS:

| Check | Result | Detail |
|---|---|---|
| Row count `zip_growth_ga.csv` | PASS | extract 178,684 = BigQuery 178,684 |
| Row count `metro_benchmark.csv` | PASS | extract 319 = BigQuery 319 |
| Row count `spread_atl.csv` | PASS | extract 202 = BigQuery 202 |
| US median 2010-06 | PASS | pandas 153,632 vs BigQuery 153,589 (Δ 0.028%) |
| US median 2020-06 | PASS | pandas 199,145 vs BigQuery 199,136 (Δ 0.004%) |
| US median 2026-06 | PASS | pandas 289,763 vs BigQuery 289,674 (Δ 0.031%) |
| Single-month swing ≤ 60% | PASS | 0 rows flagged |
| County enrichment | PASS | 103 zips across the 11 core metro-ATL counties |

Medians reconcile pandas (exact) against BigQuery `APPROX_QUANTILES` to a 1% tolerance;
BigQuery has no aggregate `PERCENTILE_CONT`. The reconciliation recomputes from the raw
Zillow download, not the extract, so it tests the whole pipeline.

## Dashboard

_Live link and screenshots added in Phase 4._
