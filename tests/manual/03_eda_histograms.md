# Hand-tests: histograms (issue #3)

Checks that `R/03_eda_histograms.R` works. Expected values were worked out from `data/processed/wdi_clean.csv` (2,409 rows, 127 countries, 2000–2019).

## Setup

1. Open `Long-Live-Humanity.Rproj` in RStudio so the working directory is the project root.
2. Install packages if needed: `install.packages(c("ggplot2", "scales"))` (needs scales ≥ 1.2.0; check with `packageVersion("scales")`).

## 1. The script runs cleanly

```r
source("R/03_eda_histograms.R")
```

- [ ] No errors.
- [ ] **No** `Removed n rows containing non-finite values` warnings. That warning would mean NA or zero values got through cleaning.
- [ ] The console shows 8 `Saved output/figures/...png` lines, then a skewness table close to this:

| histogram | skewness |
|---|---|
| hist_life_exp | -1.05 |
| hist_gdp_pc | 2.15 |
| hist_gdp_pc_log | -0.16 |
| hist_sec_enroll | -0.62 |
| hist_u5_mort | 2.05 |
| hist_population | 9.19 |
| hist_population_log | -0.34 |

## 2. All files exist

```r
list.files("output/figures", pattern = "^hist_")
```

- [ ] There are exactly 8 files: `hist_all.png`, `hist_gdp_pc.png`, `hist_gdp_pc_log.png`, `hist_life_exp.png`, `hist_population.png`, `hist_population_log.png`, `hist_sec_enroll.png`, `hist_u5_mort.png`.

## 3. Every histogram counts every row

```r
sapply(hist_plots[names(hist_plots) != "hist_all"], function(p) sum(layer_data(p)$count))
sum(layer_data(hist_plots$hist_all)$count)
```

- [ ] The first line gives `2409` for all 7 plots.
- [ ] The second gives `16863` (7 panels × 2,409).

## 4. The medians on the plots are correct

```r
sapply(wdi[c("life_exp", "gdp_pc", "sec_enroll", "u5_mort", "population")], median)
```

- [ ] The values match each plot's subtitle and the dashed line: life_exp ≈ 73.2, gdp_pc ≈ $6.2K, sec_enroll ≈ 88.7%, u5_mort ≈ 16.5, population ≈ 7.6M.

## 5. Look at each figure

Open each PNG in `output/figures/`. Each one should have a title, a subtitle reading `n = 2,409 country-years, 127 countries, 2000-2019 | median ... | range ...`, labelled axes, and a dashed median line.

| File | What you should see | Range in the subtitle |
|---|---|---|
| `hist_life_exp.png` | Most rows between 70 and 80, with a long **left** tail. The low end is Lesotho in the mid-2000s (HIV/AIDS). | 43.2 to 84.5 |
| `hist_gdp_pc.png` | Almost all the bars are piled up on the left, with a long right tail. **This shows why the log is needed.** | $243 to $112K |
| `hist_gdp_pc_log.png` | Roughly bell-shaped. The axis is labelled in dollars ($1K, $10K, $100K…), spaced evenly. | $243 to $112K |
| `hist_sec_enroll.png` | Left-skewed, with a large block **above 100%** (663 rows). That's expected for *gross* enrollment, not an error. | 5.9% to 164.1% |
| `hist_u5_mort.png` | Strongly right-skewed: about 80% of rows are under 50, with a tail up to Malawi 2001. | 2.4 to 239.0 |
| `hist_population.png` | Nearly every row is in the first one or two bars. India (about 1.1–1.4B) stretches the axis, and Indonesia, Pakistan and Nigeria (200–270M) are the only other rows well clear of the first bars. | 45.2K to 1.4B |
| `hist_population_log.png` | Roughly bell-shaped, centered around 5–20M. | 45.2K to 1.4B |
| `hist_all.png` | All 7 histograms in a 3-column grid. The log panels are titled "… (log10)", and their axes run from about 2.4–5.1 (GDP) and 4.7–9.1 (population). | — |

- [ ] Every figure matches its row in the table above.
- [ ] The text isn't cut off and the panels don't overlap in `hist_all.png`.

## 6. Re-running is safe

- [ ] Running `source("R/03_eda_histograms.R")` a second time works and overwrites the PNGs (their modified times update), without creating duplicates.

## 7. Missing input gives a clear error (optional)

1. Rename `data/processed/wdi_clean.rds` to `wdi_clean.rds.bak`.
2. Run `source("R/03_eda_histograms.R")`.

- [ ] It stops with `Run R/02_clean_wdi.R first: data/processed/wdi_clean.rds not found.`
- [ ] Rename the file back afterwards.
