# Project Progress

Tracks what's done and what's left against the project proposal. Tick boxes as work is pushed.

*Last updated: 2026-11-05*

Every item below has a [GitHub issue](https://github.com/yohannsharma/long-live/issues), grouped by [milestone](https://github.com/yohannsharma/long-live/milestones). Close the issue when its work is pushed.

## Who's doing what (midpoint check-in)

| Who | Issues | Workstream |
|---|---|---|
| **Michael** (@Erouy) | [#3](https://github.com/yohannsharma/long-live/issues/3), [#4](https://github.com/yohannsharma/long-live/issues/4), [#5](https://github.com/yohannsharma/long-live/issues/5), [#6](https://github.com/yohannsharma/long-live/issues/6), [#7](https://github.com/yohannsharma/long-live/issues/7) | EDA figures and written interpretations |
| **Yohann** (@yohannsharma) | [#8](https://github.com/yohannsharma/long-live/issues/8), [#9](https://github.com/yohannsharma/long-live/issues/9), [#10](https://github.com/yohannsharma/long-live/issues/10), [#11](https://github.com/yohannsharma/long-live/issues/11), [#12](https://github.com/yohannsharma/long-live/issues/12) | Features, standardizing, time split, CV folds |
| **Josh** (@JoshABurk) | [#13](https://github.com/yohannsharma/long-live/issues/13), [#14](https://github.com/yohannsharma/long-live/issues/14), [#15](https://github.com/yohannsharma/long-live/issues/15), [#16](https://github.com/yohannsharma/long-live/issues/16) | Metrics helper and baseline models |
| **Aiden** | [#1](https://github.com/yohannsharma/long-live/issues/1), [#2](https://github.com/yohannsharma/long-live/issues/2), [#17](https://github.com/yohannsharma/long-live/issues/17), [#18](https://github.com/yohannsharma/long-live/issues/18) | Summary stats, missingness heatmap, results table, check-in write-up |

Aiden isn't on the repo yet, so his issues are unassigned on GitHub until he joins. Week 4 and later issues aren't assigned yet.

## Midpoint check-in requirements (November 4)

Per the proposal:

- [x] Cleaned data
- [ ] EDA figures — **at least 2 meaningful visualizations, each with a written interpretation**
- [ ] Baseline results — **at least 3 models, methods, or configurations tested**

## Things the team should know about the data

- **North America is only Canada** in the main dataset (`wdi_clean.rds`): 16 rows, 11 in training (2000–2014) and 5 in testing (2015–2019). Treat the North America region coefficient or importance as "Canada", not the continent.
- **Income group doesn't change over time.** WDI gives each country's *current* income group, so a country has the same group for every year 2000–2019. Countries that moved up a group in that period are labeled with where they ended up.
- **Large countries are missing from the main dataset** because their secondary enrollment data is too sparse. Besides the US (below), these include China, Japan, Brazil, Vietnam, DR Congo, Kenya and Saudi Arabia. Results describe the 127 countries in the data, not the whole world. Say so in the report.
- **Outliers are kept, not removed.** `output/tables/outliers_flagged.csv` lists unusual values; most large life-expectancy drops are real events (Haiti 2010, Myanmar 2008, Sri Lanka 2004, Somalia 2011). Use it to explain large residuals.

### Why the United States was dropped, and whether that's right

The US has complete life expectancy, GDP, under-5 mortality and population data, but **secondary enrollment is missing for 12 of 20 years (60%)**: only 2005 and 2013–2019 are reported. The cleaning rule drops any country missing more than 30% of a feature, and the 2006–2012 gap (7 years) is longer than the 3-year limit for filling gaps.

**For the US this is a poor outcome.** Its enrollment barely moves (95.1% in 2005, 96.2% in 2013, about 100% by 2019), so filling the gap would be very safe. The US is also an important case for this question: the richest large country, with lower life expectancy than its peers.

**But the rule itself is reasonable** and shouldn't simply be loosened. Filling *every* interior gap would bring back 27 countries (127 → 154, including the US), but their gaps run up to 16 years (median 6), and it would also bring back the Central African Republic, whose data looks unreliable. China, Japan and Brazil would still be missing either way.

Raising the gap limit alone doesn't help either: the 30% rule is checked *before* gaps are filled, so the US would still be dropped. It only comes back if gaps of up to 7 years are filled **and** the rule is checked afterward, and that adds 20 countries, not just the US:

| Option | Countries | Rows (train / test) | US? |
|---|---|---|---|
| Current rules (gap ≤ 3 years, 30% checked before filling) | 127 | 2,409 (1,828 / 581) | No |
| Gap ≤ 7 years only | 127 | 2,430 | No |
| 30% checked after filling (gap ≤ 3 years) | 134 | 2,518 | No |
| Gap ≤ 7 years **and** 30% checked after filling | 147 | 2,769 (2,120 / 649) | Yes |

The 20 extra countries include the Central African Republic (unreliable data), seven microstates (Monaco, San Marino, Palau, Marshall Islands, Nauru, Antigua and Barbuda, Vanuatu), and countries like Angola, Benin and Togo, where filling up to 7 years of enrollment with a straight line is mostly guesswork.

### Decision (2026-11-05): keep the main dataset; handle the US in a case study and a robustness check

| # | What | Status | Why |
|---|---|---|---|
| 1 | **Keep `wdi_clean.rds` / `wdi_features.rds` (127 countries) as the dataset for all main modeling.** | Done (unchanged) | The rule is applied the same way to every country, which is easy to defend. Making an exception just for the US would look like cherry-picking. The baseline models are already built on this dataset. |
| 2 | **US case study data:** `data/processed/wdi_features_usa.rds`, the 8 US years where every feature is actually reported (2005, 2013–2019), with no filled values. Use it in the country case studies ([#28](https://github.com/yohannsharma/long-live/issues/28)): predict US life expectancy for 2015–2019 with the final model. | Data ready; analysis waits for the final model | Tests whether "rich country, lower life expectancy" fools the model, without any guessed enrollment values. Note the model's North America effect is learned from Canada only. |
| 3 | **Robustness dataset:** `data/processed/wdi_features_gap7.rds` (147 countries, includes the US). Re-run the best models on it in the robustness checks ([#29](https://github.com/yohannsharma/long-live/issues/29)) and compare accuracy and feature importance with the main dataset. | Data ready; analysis waits for the final models | Shows whether the 30% rule changed the conclusions. If results barely move, the rule is vindicated; if they do, that's worth reporting. |
| 4 | **State the coverage in the report** ([#30](https://github.com/yohannsharma/long-live/issues/30)), e.g.: *"Results cover 127 countries with sufficient data. Several large countries, including the United States, China, Japan and Brazil, are excluded because secondary enrollment is missing in more than 30% of years. The United States is examined separately as a case study, and a 147-country version with longer gap-filling is used as a robustness check."* | Wording ready; goes in the final report | Readers shouldn't assume results describe the whole world. |

All of this is produced by `R/02_clean_wdi.R` (the `gap7` variant and the US file) and `R/04_features.R`.

## Done

- [x] Download 2000–2019 WDI data (life expectancy, GDP per capita, secondary enrollment, under-5 mortality, population, region, income group) — `R/01_download_wdi.R`
- [x] Clean the data: remove aggregates, check missingness, remove implausible values, fill short gaps, drop sparse countries — `R/02_clean_wdi.R`
- [x] Flag outliers for review — `output/tables/outliers_flagged.csv`
- [x] Choose the dataset: `data/processed/wdi_clean.rds` (secondary enrollment; 127 countries, 2,409 rows) — see README
- [x] Basic transforms: `log_gdp_pc`, `log_pop`
- [x] Set up the GitHub repo and README

## To do before November 4

### Exploratory analysis and visualization (Week 2, 10/17–10/24 — behind schedule)

- [ ] Summary statistics table
- [ ] Missingness heatmap (data in `output/tables/missingness_by_indicator_year.csv`)
- [ ] Histograms of each variable
- [ ] Correlation matrix
- [ ] Scatterplots of each predictor vs. life expectancy
- [ ] Life expectancy trends by region and income group
- [ ] **At least 2 polished figures with written interpretations** (check-in requirement)

### Feature engineering and splits (Week 2)

- [x] Year as a feature; region and income group as categories — `R/04_features.R`
- [x] GDP × education interaction (lags optional) — `R/04_features.R` (`log_gdp_x_sec_enroll`, `*_lag1`)
- [ ] Standardize features (needed for ridge, lasso and elastic net)
- [ ] Time-based split: train on 2000–2014, test on 2015–2019
- [ ] Cross-validation folds grouped by country

### Baseline models (Week 3, 10/24–10/31)

- [ ] Linear regression (baseline)
- [ ] Polynomial regression
- [ ] Ridge, lasso, elastic net
- [ ] **At least 3 models fitted, reporting test RMSE, MAE and R²** (check-in requirement)

### Presentation

- [ ] Short summary or slides of the cleaned data, figures, and first model results

## After the check-in

- [ ] **Week 4 (10/31–11/7):** decision tree, random forest, gradient boosting, XGBoost, neural network; hyperparameter tuning
- [ ] **Week 5 (11/7–11/14):** model comparison, feature importance (permutation importance, SHAP), analysis across the four time windows, country case studies (including the US, `wdi_features_usa.rds`), robustness checks on the `prim`, `noedu` and `gap7` datasets
- [ ] **Week 6 (11/14–11/21):** report and slides, final figures, internal review
- [ ] **Final presentation:** 12/7–12/14
- [ ] **Final submission:** 12/18 (report, code, slides)
