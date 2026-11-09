# Hand-tests: scatterplots (issue #5)

Checks that `R/03_eda_scatter.R` works. Expected values were worked out from `data/processed/wdi_clean.csv`.

## Setup

Open `Long-Live-Humanity.Rproj`. Packages: `dplyr`, `ggplot2`, `scales` (≥ 1.2.0), `patchwork` (`install.packages("patchwork")`).

## 1. The script runs cleanly

```r
source("R/03_eda_scatter.R")
```

- [ ] No errors.
- [ ] **No** `Removed n rows` warnings, and no `geom_smooth() using method = ...` messages (the method is set explicitly).
- [ ] The console shows 6 `Saved ...` lines: `scatter_gdp_pc.png`, `scatter_sec_enroll.png`, `scatter_u5_mort.png`, `scatter_population.png`, `scatter_year.png`, `scatter_predictors.png`.

## 2. Every point is plotted

```r
sapply(scatter_plots[1:5], function(p) nrow(layer_data(p, 1)))
```

- [ ] It gives `2409` for all 5.

## 3. The combined figure

Open `output/figures/scatter_predictors.png`.

- [ ] It has 5 panels in a 3 × 2 grid, and the **income group legend fills the sixth slot** (bottom right). There is only one legend, not one per panel.
- [ ] The panel titles show these correlations:

| Panel | r |
|---|---|
| GDP per capita | 0.83 |
| Secondary enrollment | 0.81 |
| Under-5 mortality | -0.91 |
| Population | -0.14 |
| Year | 0.23 |

- [ ] The GDP and population axes are log-scaled, with labels in $ / people (e.g. `$1K`, `$10K`, `$100K`; `100K`, `10M`, `1B`).
- [ ] Each panel has a black loess line. The **under-5 mortality line is clearly curved**: steep on the left, flatter on the right.
- [ ] The colours run from dark purple (Low income) to yellow-green (High income). High-income points cluster at the top right of the GDP panel and the top left of the mortality panel.
- [ ] In the legend, the dots are solid (not see-through) and in order Low → High income.
- [ ] A few points sit well below the curve on the mortality panel at about 40–60 years of life expectancy. These are South Africa, Eswatini, Namibia and Burundi. Optional check: `subset(wdi, u5_mort < 60 & life_exp < 62, country)`.

## 4. The single-panel files

- [ ] Each `scatter_<predictor>.png` shows one panel with the legend underneath, a subtitle, and a caption explaining r.

## 5. Re-running is safe

- [ ] Running the script a second time works and overwrites the files.
