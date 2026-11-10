# Hand-tests: life expectancy trends (issue #6)

Checks that `R/03_eda_trends.R` works. Expected values were worked out from `data/raw/wdi_raw.csv`, restricted to the 127 countries in `wdi_clean.rds`.

## Setup

Open `Long-Live-Humanity.Rproj`. Packages: `dplyr`, `readr`, `tidyr`, `ggplot2` (≥ 3.4.0, for `linewidth`), `patchwork`.

## 1. The script runs cleanly

```r
source("R/03_eda_trends.R")
```

- [ ] No errors, and **no** warning that `country-years lack life expectancy` (all 127 × 20 = 2,540 values are present).
- [ ] The console shows 4 `Saved ...` lines (one CSV, three PNGs) and a table of 2000 vs 2019 values. Check it against the table below.

| Group | 2000 | 2019 | Change |
|---|---|---|---|
| High income (50) | 75.7 | 80.0 | +4.3 |
| Upper middle income (38) | 70.3 | 74.1 | +3.8 |
| Lower middle income (27) | 61.4 | 68.3 | +6.9 |
| Low income (12) | 52.1 | 62.8 | +10.7 |
| Europe & Central Asia (43) | 74.5 | 79.1 | +4.6 |
| Middle East, North Africa, Afghanistan & Pakistan (16) | 71.1 | 76.3 | +5.2 |
| Latin America & Caribbean (26) | 71.3 | 74.3 | +3.0 |
| South Asia (5) | 64.0 | 72.9 | +8.9 |
| East Asia & Pacific (13) | 68.5 | 72.6 | +4.1 |
| Sub-Saharan Africa (23) | 54.7 | 63.9 | +9.2 |
| North America (Canada only) | 79.2 | 82.2 | +3.0 |

(Change is computed before rounding, so it can differ from 2019 − 2000 by 0.1.)

## 2. The same countries every year

```r
t <- readr::read_csv("output/tables/life_exp_trends.csv")
nrow(t)
table(t$grouping)
tapply(t$n_countries, t$group, function(x) length(unique(x)))
```

- [ ] There are `220` rows (11 groups × 20 years), 80 of them `income` and 140 `region`.
- [ ] Every group gives `1`: its country count doesn't change between years. **This is the main point of the script**; see the note in its header.
- [ ] The income groups' country counts sum to 127, and so do the regions'.

## 3. The figures

Open `life_exp_trend_income.png`, `life_exp_trend_region.png` and `life_exp_trends.png` in `output/figures/`.

- [ ] Income: 4 lines, all rising, with no crossings, and the gap clearly narrowing. The legend order (top to bottom) is High, Upper middle, Lower middle, Low. That matches the order of the lines on the right-hand side, and the colours match the scatterplots (Low = purple, High = yellow-green).
- [ ] Region: 7 lines, with the legend in the same order as the lines in 2019. North America is labelled **"North America (Canada only)"**, and Sub-Saharan Africa is the lowest line throughout.
- [ ] There are small visible dips in East Asia & Pacific in 2008 (Myanmar's Cyclone Nargis) and in Canada in 2017–2018. They're real, not bugs.
- [ ] The x-axis ticks are at 2000, 2005, 2010, 2015 (plus 2020 at the edge), and the y-axis reads "Mean life expectancy (years)".
- [ ] `life_exp_trends.png` shows both panels side by side, each with its own legend, under one shared title. Nothing overlaps.

## 4. The composition check (optional; shows why the script uses the raw file)

```r
w <- readRDS("data/processed/wdi_clean.rds")
table(w$year)[c("2000", "2001", "2019")]
```

- [ ] It shows 83, 118 and 106: the cleaned panel's set of countries changes from year to year, which is why the trends don't use it.
