# Predicting Life Expectancy Using World Development Indicators

CPTS 475 final project — Team Long Live Humanity.

See [Project-Progress.md](Project-Progress.md) for what's done and what's left.

## Setup

Open `Long-Live-Humanity.Rproj` in RStudio (this sets the working directory to the project root), then install packages once:

```r
install.packages(c("WDI", "dplyr", "tidyr", "zoo", "readr"))
```

## Pipeline

Run the scripts in order from the project root:

| Script | Does | Writes |
|---|---|---|
| `R/01_download_wdi.R` | Downloads life expectancy + 5 predictors (incl. primary enrollment as a fallback) for all countries, 2000–2019, with region/income metadata. Skips if the raw file exists (set `FORCE_DOWNLOAD <- TRUE` to refresh). | `data/raw/wdi_raw.csv` |
| `R/02_clean_wdi.R` | Removes aggregates, reports missingness, nulls implausible values, drops rows missing the outcome, flags statistical outliers for review, drops countries with >30% of any feature missing, interpolates gaps of ≤3 years, keeps complete cases, adds `log_gdp_pc` / `log_pop`. Builds three dataset variants (below). | `data/processed/wdi_clean*.{csv,rds}`, `output/tables/*.csv` |

Downstream scripts should load the `.rds` files (they keep `region` and `income` as factors).

## Dataset variants

The 30% missingness rule drops many countries because enrollment data is patchy, so the cleaning script writes three versions. All share GDP per capita, under-5 mortality and population.

| File | Education feature | Countries | Rows (train / test) |
|---|---|---|---|
| `wdi_clean.rds` (main) | secondary enrollment | 127 | 2,409 (1,828 / 581) |
| `wdi_clean_prim.rds` | primary enrollment | 155 | 2,987 (2,250 / 737) |
| `wdi_clean_noedu.rds` | none | 189 | 3,778 (2,834 / 944) |

`output/tables/variant_summary.csv` breaks the retained countries down by income group; `countries_dropped.csv` lists every dropped country and the feature responsible.

### Which one to use

> **Decision (2026-10-28): the team's dataset is `wdi_clean.rds` (secondary enrollment).** Use it for all modeling, evaluation and figures. The other two are robustness checks only.

Why:

- **It answers the research question.** The question asks which economic, educational, health and demographic indicators matter, so the education feature has to measure something. Secondary enrollment correlates 0.81 with life expectancy; primary enrollment only 0.11, because most countries sit near 100% (interquartile range ≈ 92–110%). With primary enrollment, education would look unimportant because of the measure, not the relationship.
- **It's what the proposal specified** (`SE.SEC.ENRR`), and the sample is not skewed by income: it keeps roughly half of each income group (see `variant_summary.csv`).
- **It's big enough.** 1,828 training rows is plenty for the linear, regularized and tree models; the neural network is the one model that may struggle, which the proposal's contingency plan already covers.

Run the final best models on the other two as well and report the differences:

- `wdi_clean_noedu.rds` (189 countries) shows whether the 62 extra countries change accuracy or the GDP / under-5 mortality importance rankings — i.e. how much the smaller sample costs.
- `wdi_clean_prim.rds` shows how sensitive the education conclusion is to the indicator chosen.

## Outliers

`output/tables/outliers_flagged.csv` lists values that are plausible but unusual. They are **kept in the data**; the list is for review and for explaining large residuals. Two checks, with skewed indicators on the log scale:

- `cross_section`: more than 3 × IQR from that year's quartiles across countries.
- `yoy_jump`: a year-over-year change within a country more than 10 × IQR from the typical change. (Changes are tightly bunched, so 3 × IQR flags ordinary noise.)

Most life-expectancy jumps are real events: Haiti 2010 (earthquake), Myanmar 2008 (Cyclone Nargis), Sri Lanka 2004 (tsunami), Somalia 2011 (famine), Syria 2012, South Sudan 2014. The Central African Republic series is erratic (swings of 6–21 years most years, 31.5 in 2019) and looks like a data problem; it is only in `wdi_clean_noedu.rds`. Most `prim_enroll` cross-section flags are genuinely low-enrollment countries (e.g. Niger, Sudan, Rwanda).

## Layout

```
R/                 analysis scripts, numbered in run order
data/raw/          untouched API download
data/processed/    cleaned modeling dataset
output/figures/    ggplot2 figures
output/tables/     missingness and cleaning reports
```
