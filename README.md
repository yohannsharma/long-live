# Predicting Life Expectancy Using World Development Indicators

CPTS 475 final project — Team Long Live Humanity.

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
| `R/02_clean_wdi.R` | Removes aggregates, reports missingness, nulls implausible values, drops rows missing the outcome, drops countries with >30% of any feature missing, interpolates gaps of ≤3 years, keeps complete cases, adds `log_gdp_pc` / `log_pop`. Builds three dataset variants (below). | `data/processed/wdi_clean*.{csv,rds}`, `output/tables/*.csv` |

Downstream scripts should load the `.rds` files (they keep `region` and `income` as factors).

## Dataset variants

The 30% missingness rule drops many countries because enrollment data is patchy, so the cleaning script writes three versions. All share GDP per capita, under-5 mortality and population.

| File | Education feature | Countries | Rows (train / test) |
|---|---|---|---|
| `wdi_clean.rds` (main) | secondary enrollment | 127 | 2,409 (1,828 / 581) |
| `wdi_clean_prim.rds` | primary enrollment | 155 | 2,987 (2,250 / 737) |
| `wdi_clean_noedu.rds` | none | 189 | 3,778 (2,834 / 944) |

Fitting the same models to each shows what the education indicator adds versus what the lost countries cost. `output/tables/variant_summary.csv` breaks the retained countries down by income group; `countries_dropped.csv` lists every dropped country and the feature responsible.

## Layout

```
R/                 analysis scripts, numbered in run order
data/raw/          untouched API download
data/processed/    cleaned modeling dataset
output/figures/    ggplot2 figures
output/tables/     missingness and cleaning reports
```
