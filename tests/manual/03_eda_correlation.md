# Hand-tests: correlation matrix (issue #4)

Checks that `R/03_eda_correlation.R` works. Expected values were worked out from `data/processed/wdi_clean.csv`.

## Setup

Open `Long-Live-Humanity.Rproj` (working directory = project root). Packages: `dplyr`, `readr`, `ggplot2`.

## 1. The script runs cleanly

```r
source("R/03_eda_correlation.R")
```

- [ ] No errors or warnings.
- [ ] The console shows 3 `Saved ...` lines (two CSVs, one PNG), then a table close to this:

| | pearson | spearman |
|---|---|---|
| log_gdp_pc | 0.83 | 0.88 |
| sec_enroll | 0.81 | 0.78 |
| u5_mort | -0.91 | -0.93 |
| log_pop | -0.14 | -0.13 |
| year | 0.23 | 0.23 |

## 2. The CSVs are correct

```r
pm <- readr::read_csv("output/tables/correlation_matrix.csv")
pm
```

- [ ] There are 6 rows and 7 columns (`variable` plus the 6 variables), in the order life_exp, log_gdp_pc, sec_enroll, u5_mort, log_pop, year.
- [ ] The diagonal is all `1`, and the matrix is symmetric (e.g. the `sec_enroll` row's `life_exp` value equals the `life_exp` row's `sec_enroll` value).
- [ ] **`life_exp` × `sec_enroll` = 0.81**: this confirms the README figure.
- [ ] Independent check: `round(cor(wdi$life_exp, wdi$u5_mort), 3)` matches the CSV (−0.91 to 2 dp).
- [ ] `output/tables/correlation_matrix_spearman.csv` has the same layout.

## 3. The figure looks right

Open `output/figures/correlation_matrix.png`.

- [ ] It shows a lower triangle: Life expectancy is the top row, with one cell (1.00) at the top left, and the bottom row (Year) has all 6 cells.
- [ ] Every cell shows its value to 2 decimals and matches the CSV.
- [ ] Positive values are blue and negative values red, on a fixed −1 to 1 scale. Under-5 mortality × life expectancy (−0.91) is the darkest red.
- [ ] Values with |r| ≥ 0.6 are printed in white and the rest in dark grey, and all of them are readable.
- [ ] The x-axis labels are angled, nothing is cut off, and the subtitle reads `Pearson r, main dataset: 2,409 country-years, 127 countries, 2000-2019`.
