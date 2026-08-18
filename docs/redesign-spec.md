# Spec: Metropolitan Atlanta Housing — Dashboard v2

Goal: turn the current "six charts on a page" into a dashboard a non-analyst (or an exec)
can read top-to-bottom in under a minute, interact with, and repeat the findings from.
This spec is the single source of truth for the next build session (browser automation
and/or hand-tuning in Tableau Desktop).

**Live v1:** https://public.tableau.com/app/profile/mahir.haque/viz/AtlantaHousingPriceValueExplorer/MetropolitanAtlantaHousing

---

## 1. Audience & story

**Audience:** leadership / non-analysts. Assume they know nothing about ZHVI, indexing,
or growth multiples. Every panel must answer "what am I looking at?" in its own caption.

**The one-sentence story:**
> Metro Atlanta's typical home is worth ~$363K — still well above the U.S. — but the
> market has turned: every core county sits below its peak, the correction started
> intown (Fulton, mid-2022) and is spreading outward, and sellers are cutting prices
> faster than the rest of the country.

**Narrative order (top to bottom):**
1. Where we are today (headline numbers)
2. Where values are falling (map)
3. How deep the correction is (county off-peak)
4. Who won the boom on the way up (zip scatter)
5. What sellers are doing about it (price-cut gap)
6. The long view for context (indexed trend)

## 2. Canvas & layout

- **Size:** fixed **1100 × 1750** (vertical scroll). The 1300×800 canvas is the root
  cause of the cramped feel — a phone-style vertical story reads better and screenshots
  better on LinkedIn/GitHub.
- **Structure (tiled, with padded containers):**

```
┌──────────────────────────────────────────────┐
│ TITLE: Metropolitan Atlanta Housing          │
│ Subtitle: What a typical home is worth       │
│ across 29 counties · Zillow ZHVI, monthly    │
│ through Jul 2026 · by Mahir Haque            │
├──────────┬──────────┬──────────┬─────────────┤
│ $362.6K  │ +0.7%    │ 34 / 50  │ −5.4%       │  ← BAN row (big numbers)
│ typical  │ vs last  │ growth   │ Gwinnett    │
│ home, ATL│ year     │ rank, US │ off peak    │
│ metro    │          │ metros   │             │
├──────────┴──────────┴──────────┴─────────────┤
│ [County filter ▾]      ← controls strip      │
├──────────────────────────────────────────────┤
│ 1 · WHERE VALUES ARE FALLING                 │
│ (map, full width, tall)                      │
├──────────────────────────────────────────────┤
│ 2 · HOW DEEP THE CORRECTION IS               │
│ (county off-peak bars, full width)           │
├───────────────────────┬──────────────────────┤
│ 3 · WHO WON THE BOOM  │ 4 · SELLER PRESSURE  │
│ (2012 scatter)        │ (price-cut gap line) │
├───────────────────────┴──────────────────────┤
│ 5 · THE LONG VIEW (indexed trend, full width)│
├──────────────────────────────────────────────┤
│ Footnote: source, methodology, repo link     │
└──────────────────────────────────────────────┘
```

- **Padding:** 8px outer / 12px between sections (Layout pane per container).
- Every section header is a Text object: numbered, ALL-CAPS-ish short label + one
  plain-English sentence beneath it.

## 3. BAN row (replaces the current KPI text table)

Four separate single-value sheets (not one Measure Values table), each:
- Value in **24–32pt bold**, label in 9pt gray beneath.
- Number formats: `$362.6K` (currency, 1 decimal, K), `+0.7%` (1 decimal, signed),
  `34 of 50` (string or custom format), `−5.4%`.
- Data: `metro_benchmark` (latest month filter) + `county_offpeak` (Gwinnett row).
- The Gwinnett BAN is deliberate — it personalizes the dashboard and invites the
  county filter below.

## 4. Panel specs

Shared rules: no legends (direct labels/captions instead), no dual axes, tooltips written
in sentences, axis numbers formatted for humans (`$400K`, `2.5×`, `−10%`, `+4 pts`).

| # | Panel | Source | Spec |
|---|-------|--------|------|
| 1 | **Map — Where values are falling** | `zip_growth_ga_tableau` | Zip choropleth, AVG YoY, diverging orange↔blue centered at 0, latest month auto-filter, metro-only. Tooltip: "30044 (Gwinnett): typical value $408K, down 2.4% vs last year." Format YoY as % (currently raw decimal). |
| 2 | **Off-peak bars — How deep the correction is** | `county_offpeak` | One bar per county, sorted worst-first. Add labels at bar ends (−11.1%, …). Color: single muted red/orange, NOT blue (falling = warm). Tooltip includes peak month and peak/now values. |
| 3 | **Boom scatter — Who won the boom** | `zip_boom` | X = 2012 value ($ axis, K format), Y = multiple (suffix ×). Highlight color for the reader's filtered county (via county filter action); others gray. Optional reference line at 3×, annotated "tripled". |
| 4 | **Price-cut gap — Seller pressure** | `spread_gap` | Line/area of `cut_gap_pp`, zero line emphasized, axis label "pts above U.S.". Annotate last point "+3.9 pts (Jul 2026)". |
| 5 | **Indexed trend — The long view** | `benchmark_long` | Metro Atlanta vs U.S. only. Direct-label line ends ("Atlanta 254", "U.S. 236") instead of a legend. Optional annotations at 2008 ("crash") and 2020 ("boom"). |

Captions (already live in v1, keep): each panel's subtitle explains the encoding in one
sentence, e.g. "Each dot is a zip code: its 2012 typical value vs how many times it has
multiplied since."

## 5. Interactivity

- **County filter (single-value dropdown)** in the controls strip. Drives the map;
  if feasible via filter actions, also highlights that county's dots in the scatter and
  its bar in panel 2. (Sources differ, so cross-source filtering needs a filter action
  on `County Label` ↔ `County` name match — county names were normalized to match:
  "Gwinnett" etc.)
- **Map → detail action (stretch):** clicking a zip on the map highlights its dot in
  the scatter.
- Keep the latest-month auto-filters (already set) so the dashboard self-updates when
  data refreshes.

## 6. Design system

- **Palette:** one warm accent for "falling/pressure" (orange `#E8762D`-family), one cool
  for "rising" (steel blue), gray `#666` for text/context, U.S. benchmark always the same
  neutral red-gray. Never introduce a color that means nothing.
- **Fonts:** Tableau Light; titles 12–13pt semibold, subtitles/captions 9pt gray,
  BANs 24–32pt.
- **No chart junk:** no gridlines heavier than 10% gray, no borders on tiles, no "Month of
  Month" axis captions (hide axis titles where the caption already explains).

## 7. Data layer (already built — no changes required)

| Extract | Grain | Feeds |
|---|---|---|
| `zip_growth_ga_tableau.csv` | zip × month | map |
| `county_offpeak.csv` | county | off-peak bars, Gwinnett BAN |
| `zip_boom.csv` | zip | scatter |
| `spread_gap.csv` | month | pressure line |
| `benchmark_long.csv` | month × geography | trend |
| `metro_benchmark.csv` | month | BANs |

Regenerate any of these from `sql/` + BigQuery (`atl-housing-portfolio`), see README.

## 8. Build plan & division of labor

**Automation-friendly (browser session):** new dashboard tab at 1100×1750; add tiles in
order; title/caption text edits; latest-month filters; number formats via pill → Format
Number; publish-flag + publish; Edit Details title rename to "Metropolitan Atlanta
Housing" (still pending from v1).

**Faster by hand in Tableau Desktop (~30–45 min, click-list):** BAN sheets + font sizes,
container padding, direct line labels, annotations, filter actions across sources,
palette assignment. (Hands-on time here also makes the CV claim interview-proof.)

**Known web-authoring traps (from v1):** publish early and often; the dashboard tab's
right-click "Publish" checkbox must stay checked or saving fails; screenshot every
context menu before clicking (item positions shift); first keystrokes after a dialog
opens can land in the data-pane search box — retype and verify; renaming the dashboard
tab changes the public URL slug (rename is DONE — don't rename again).

## 9. Acceptance criteria

1. A non-analyst answers "which county's home values fell the most?" in ≤15 seconds.
2. A non-analyst can say what ZHVI means after reading only the page.
3. Every number on screen has a unit ($, %, ×, pts) — no bare decimals anywhere.
4. The reader can filter to Gwinnett (or any county) and see its map + highlighted context.
5. Nothing on the page requires the words "indexed", "YoY", or "pp" to be understood —
   captions translate them.
6. Screenshot of the full dashboard reads as a story when pasted in Slack/LinkedIn.
