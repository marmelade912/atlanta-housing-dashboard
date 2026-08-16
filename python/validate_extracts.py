"""Validate the Tableau extracts against the BigQuery marts and the raw source.

Run from the repo root: python python/validate_extracts.py

Checks:
1. Row counts of each extract vs the BigQuery mart counts (hardcoded below).
2. Reconciliation: national median ZHVI for 3 spot-check months recomputed in pandas
   from the RAW Zillow download vs BigQuery's value. BigQuery uses APPROX_QUANTILES
   (no aggregate PERCENTILE_CONT), so the comparison is to a 1% tolerance.
3. Sanity: no zip with a >60% single-month ZHVI swing. Flagged, not deleted —
   survivors land in extracts/outliers.csv.
4. Enrichment: friendly county labels for the 11 core metro-Atlanta counties →
   extracts/zip_growth_ga_enriched.csv (adds county_label, is_core_atl_county).
"""

from pathlib import Path

import pandas as pd

REPO = Path(__file__).resolve().parent.parent
EXTRACTS = REPO / "extracts"
RAW_ZHVI = REPO / "data" / "Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv"

# BigQuery mart counts, queried 2026-08-16 (project atl-housing-portfolio).
EXPECTED_ROWS = {
    "zip_growth_ga.csv": 178_684,     # SELECT COUNT(*) FROM marts.zip_growth WHERE is_georgia
    "metro_benchmark.csv": 319,       # SELECT COUNT(*) FROM marts.metro_benchmark
    "spread_atl.csv": 202,            # SELECT COUNT(*) FROM marts.spread_atl
}

# BigQuery marts.metro_benchmark.us_median_zhvi, queried 2026-08-16.
BQ_US_MEDIAN = {
    "2010-06-30": 153_589.08955033438,
    "2020-06-30": 199_136.38622660728,
    "2026-06-30": 289_673.58300688583,
}
MEDIAN_TOLERANCE = 0.01  # APPROX_QUANTILES vs exact pandas median

# The 11 core metro-Atlanta counties (six years working this market at Metro Homes).
CORE_ATL_COUNTIES = {
    "Fulton County": "Fulton",
    "DeKalb County": "DeKalb",
    "Gwinnett County": "Gwinnett",
    "Cobb County": "Cobb",
    "Clayton County": "Clayton",
    "Cherokee County": "Cherokee",
    "Douglas County": "Douglas",
    "Fayette County": "Fayette",
    "Forsyth County": "Forsyth",
    "Henry County": "Henry",
    "Rockdale County": "Rockdale",
}

MAX_MONTHLY_SWING = 0.60

results = []  # (check, status, detail)


def check_row_counts() -> None:
    for name, expected in EXPECTED_ROWS.items():
        actual = sum(1 for _ in open(EXTRACTS / name)) - 1  # minus header
        ok = actual == expected
        results.append((f"row count {name}", "PASS" if ok else "FAIL",
                        f"extract={actual:,} bigquery={expected:,}"))


def check_median_reconciliation() -> None:
    id_cols = ["RegionID", "SizeRank", "RegionName", "RegionType", "StateName",
               "State", "City", "Metro", "CountyName"]
    months = list(BQ_US_MEDIAN)
    raw = pd.read_csv(RAW_ZHVI, usecols=months)
    for month in months:
        series = raw[month].dropna()
        series = series[series > 10_000]  # same filter as marts.stg_zhvi
        pandas_median = series.median()
        bq_median = BQ_US_MEDIAN[month]
        delta = abs(pandas_median - bq_median) / bq_median
        ok = delta <= MEDIAN_TOLERANCE
        results.append((f"US median {month}", "PASS" if ok else "FAIL",
                        f"pandas={pandas_median:,.0f} bigquery={bq_median:,.0f} "
                        f"delta={delta:.3%}"))
    del id_cols  # documented for readers; only month columns are read


def check_outliers(ga: pd.DataFrame) -> None:
    ga = ga.sort_values(["zip_code", "month"])
    ga["mom_change"] = ga.groupby("zip_code")["zhvi"].pct_change().abs()
    outliers = ga[ga["mom_change"] > MAX_MONTHLY_SWING]
    outliers.to_csv(EXTRACTS / "outliers.csv", index=False)
    results.append(("single-month swing <= 60%",
                    "PASS" if outliers.empty else "FLAG",
                    f"{len(outliers)} rows flagged -> extracts/outliers.csv"))


def enrich_counties(ga: pd.DataFrame) -> None:
    ga = ga.copy()
    ga["county_label"] = ga["county"].map(CORE_ATL_COUNTIES).fillna(
        ga["county"].str.replace(" County", "", regex=False))
    ga["is_core_atl_county"] = ga["county"].isin(CORE_ATL_COUNTIES)
    out = EXTRACTS / "zip_growth_ga_enriched.csv"
    ga.to_csv(out, index=False)
    n_core = ga.loc[ga["is_core_atl_county"], "zip_code"].nunique()
    results.append(("county enrichment", "PASS",
                    f"{n_core} zips in the 11 core counties -> {out.name}"))


def main() -> None:
    check_row_counts()
    check_median_reconciliation()
    ga = pd.read_csv(EXTRACTS / "zip_growth_ga.csv",
                     dtype={"zip_code": str}, parse_dates=["month"])
    check_outliers(ga)
    enrich_counties(ga)

    width = max(len(c) for c, _, _ in results)
    print(f"\n{'CHECK'.ljust(width)}  RESULT  DETAIL")
    print("-" * (width + 50))
    for check, status, detail in results:
        print(f"{check.ljust(width)}  {status:6}  {detail}")

    if any(s == "FAIL" for _, s, _ in results):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
