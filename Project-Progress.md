# Project Progress

Tracks what's done and what's left against the project proposal. Tick boxes as work is pushed.

*Last updated: 2026-11-09*

Every item below has a [GitHub issue](https://github.com/yohannsharma/long-live/issues), grouped by [milestone](https://github.com/yohannsharma/long-live/milestones). Close the issue when its work is pushed.

## Status at a glance

- **Closed: 10 of 32 issues** (#3–#12), plus 2 merged pull requests (#33, #34).
- **Data, features, splits and EDA are done.** Model scripts can start from `data/processed/model_data.rds` (see the README).
- **Next, due at the midpoint check-in on 11/10/26:** the baseline models and check-in write-up (#13–#18), and the two EDA summary items (#1, #2). The 3+ baseline models (#13–#17) are the one check-in requirement not yet met.
- **Follow-ups from PR #34 are fixed in this update:** EDA figures and tables committed, four trend values corrected (see [below](#follow-ups-from-pr-34)).

## Who's doing what (midpoint check-in)

| Who | Issues | Workstream | Status |
|---|---|---|---|
| **Michael** (@Erouy) | [#3](https://github.com/yohannsharma/long-live/issues/3), [#4](https://github.com/yohannsharma/long-live/issues/4), [#5](https://github.com/yohannsharma/long-live/issues/5), [#6](https://github.com/yohannsharma/long-live/issues/6), [#7](https://github.com/yohannsharma/long-live/issues/7) | EDA figures and written interpretations | **All closed** (PR #34); follow-ups fixed |
| **Yohann** (@yohannsharma) | [#8](https://github.com/yohannsharma/long-live/issues/8), [#9](https://github.com/yohannsharma/long-live/issues/9), [#10](https://github.com/yohannsharma/long-live/issues/10), [#11](https://github.com/yohannsharma/long-live/issues/11), [#12](https://github.com/yohannsharma/long-live/issues/12) | Features, standardizing, time split, CV folds | **All closed** |
| **Josh** (@JoshABurk) | [#13](https://github.com/yohannsharma/long-live/issues/13), [#14](https://github.com/yohannsharma/long-live/issues/14), [#15](https://github.com/yohannsharma/long-live/issues/15), [#16](https://github.com/yohannsharma/long-live/issues/16) | Metrics helper and baseline models | Open |
| **Aiden** (@AidenBoyer) | [#1](https://github.com/yohannsharma/long-live/issues/1), [#2](https://github.com/yohannsharma/long-live/issues/2), [#17](https://github.com/yohannsharma/long-live/issues/17), [#18](https://github.com/yohannsharma/long-live/issues/18) | Summary stats, missingness heatmap, results table, check-in write-up | #1, #2 Closed, Rest Open |

Week 4 and later issues (#19–#32) aren't assigned yet.

## Midpoint check-in requirements (due November 10, 2026)

Per the proposal:

- [x] Cleaned data
- [x] EDA figures — **at least 2 meaningful visualizations, each with a written interpretation**: three figures written up in [EDA-Findings.md](EDA-Findings.md), with the PNGs in `output/figures/`.
- [ ] Baseline results — **at least 3 models, methods, or configurations tested** (#13–#17)

## Closed issues

| Issue | What | Closed | Done in |
|---|---|---|---|
| [#1](https://github.com/yohannsharma/long-live/issues/1) | Summary statistics table | 2026-11-10 | `R/03_eda_wdi_summary.R` (PR #?) |
| [#2](https://github.com/yohannsharma/long-live/issues/2) | Missing predictor percentage by year  | 2026-11-10 | `R/03_eda_missingness_heatmap.R` (PR #?) |
| [#3](https://github.com/yohannsharma/long-live/issues/3) | Histograms of each variable | 2026-11-09 | `R/03_eda_histograms.R` (PR #34) |
| [#4](https://github.com/yohannsharma/long-live/issues/4) | Correlation matrix | 2026-11-09 | `R/03_eda_correlation.R` (PR #34) |
| [#5](https://github.com/yohannsharma/long-live/issues/5) | Scatterplots of each predictor vs. life expectancy | 2026-11-09 | `R/03_eda_scatter.R` (PR #34) |
| [#6](https://github.com/yohannsharma/long-live/issues/6) | Life expectancy trends by region and income group | 2026-11-09 | `R/03_eda_trends.R` (PR #34) |
| [#7](https://github.com/yohannsharma/long-live/issues/7) | 2+ polished figures with written interpretations | 2026-11-09 | `EDA-Findings.md` (PR #34) |
| [#8](https://github.com/yohannsharma/long-live/issues/8) | Year as a feature; region and income group as categories | 2026-11-05 | `R/04_features.R` (af92524) |
| [#9](https://github.com/yohannsharma/long-live/issues/9) | GDP × education interaction, optional lags | 2026-11-08 | `R/04_features.R` (6c18d2f) |
| [#10](https://github.com/yohannsharma/long-live/issues/10) | Standardize features (training-set parameters only) | 2026-11-08 | `R/05_split_scale.R` (394703e) |
| [#11](https://github.com/yohannsharma/long-live/issues/11) | Time-based split: train 2000–2014, test 2015–2019 | 2026-11-08 | `R/05_split_scale.R` (394703e) |
| [#12](https://github.com/yohannsharma/long-live/issues/12) | Cross-validation folds grouped by country | 2026-11-08 | `R/05_split_scale.R` (509a20a) |

Merged pull requests: [#33](https://github.com/yohannsharma/long-live/pull/33) (who's doing what), [#34](https://github.com/yohannsharma/long-live/pull/34) (EDA).

## Follow-ups from PR #34

PR #34 was merged before the fixes from its [review](https://github.com/yohannsharma/long-live/pull/34#pullrequestreview-5822715111) went in. They're fixed in commit 22802e6 (part of this update):

1. [x] **Generate and commit the EDA outputs.** Ran the four `R/03_eda_*.R` scripts (no errors or warnings) and committed the 18 PNGs in `output/figures/` and the EDA tables (`correlation_matrix.csv`, `correlation_matrix_spearman.csv`, `life_exp_trends.csv`). The images in `EDA-Findings.md` now display. **Why:** the findings doc embeds these files, so without them the check-in figures were broken images.
2. [x] **Fix four life-expectancy changes that were 0.1 too high.** Now High income **+4.2**, Low income **+10.6**, Middle East, North Africa, Afghanistan & Pakistan **+5.1**, South Asia **+8.8**, in `EDA-Findings.md` and `tests/manual/03_eda_trends.md`. **Why:** the script computes the change before rounding (correct), but the docs subtracted the rounded values; all 11 rows of the hand-test now match the script's output.
3. [x] *Optional wording:* "the high-income mean dipped once, in 2015" now reads "levelled off in 2015 (a dip of under 0.01 years)". **Why:** the dip is −0.006 years, about 2 days.
4. [ ] *Optional, not done:* `hist_all.png` shows raw population in scientific notation, and the under-5 mortality smoother curls up above ~200 deaths per 1,000 where there are only a few points. Cosmetic only.

## Things the team should know about the data

- **North America is only Canada** in the main dataset (`wdi_clean.rds`): 16 rows, 11 in training (2000–2014) and 5 in testing (2015–2019). Treat the North America region coefficient or importance as "Canada", not the continent.
- **Income group doesn't change over time.** WDI gives each country's *current* income group, so a country has the same group for every year 2000–2019. Countries that moved up a group in that period are labeled with where they ended up.
- **Large countries are missing from the main dataset** because their secondary enrollment data is too sparse. Besides the US (below), these include China, Japan, Brazil, Vietnam, DR Congo, Kenya and Saudi Arabia. Results describe the 127 countries in the data, not the whole world. Say so in the report.
- **Outliers are kept, not removed.** `output/tables/outliers_flagged.csv` lists unusual values; most large life-expectancy drops are real events (Haiti 2010, Myanmar 2008, Sri Lanka 2004, Somalia 2011). Use it to explain large residuals.
- **From the EDA** ([EDA-Findings.md](EDA-Findings.md)): under-5 mortality is the strongest predictor (r = −0.91) but curved on its raw scale; log GDP, secondary enrollment and under-5 mortality correlate 0.76–0.84 with each other; the test years average 74.1 years of life expectancy vs. 70.9 in training, so tree models may underpredict them.

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
| 2 | **US case study data:** `data/processed/wdi_features_usa.rds`, the 8 US years where every feature is actually reported (2005, 2013–2019), with no filled values. Use it in the country case studies ([#28](https://github.com/yohannsharma/long-live/issues/28)): predict US life expectancy for 2015–2019 with the final model. | Data ready (also in `model_data.rds` as `usa` / `usa_scaled`); analysis waits for the final model | Tests whether "rich country, lower life expectancy" fools the model, without any guessed enrollment values. Note the model's North America effect is learned from Canada only. |
| 3 | **Robustness dataset:** `data/processed/wdi_features_gap7.rds` (147 countries, includes the US). Re-run the best models on it in the robustness checks ([#29](https://github.com/yohannsharma/long-live/issues/29)) and compare accuracy and feature importance with the main dataset. | Data ready (also `model_data_gap7.rds`); analysis waits for the final models | Shows whether the 30% rule changed the conclusions. If results barely move, the rule is vindicated; if they do, that's worth reporting. |
| 4 | **State the coverage in the report** ([#30](https://github.com/yohannsharma/long-live/issues/30)), e.g.: *"Results cover 127 countries with sufficient data. Several large countries, including the United States, China, Japan and Brazil, are excluded because secondary enrollment is missing in more than 30% of years. The United States is examined separately as a case study, and a 147-country version with longer gap-filling is used as a robustness check."* | Wording ready; goes in the final report | Readers shouldn't assume results describe the whole world. |

All of this is produced by `R/02_clean_wdi.R` (the `gap7` variant and the US file) and `R/04_features.R`.

## Done

### Data collection and cleaning (Week 1)

- [x] Download 2000–2019 WDI data (life expectancy, GDP per capita, secondary enrollment, under-5 mortality, population, region, income group) — `R/01_download_wdi.R`
- [x] Clean the data: remove aggregates, check missingness, remove implausible values, fill short gaps, drop sparse countries — `R/02_clean_wdi.R`
- [x] Flag outliers for review — `output/tables/outliers_flagged.csv`
- [x] Choose the dataset: `data/processed/wdi_clean.rds` (secondary enrollment; 127 countries, 2,409 rows) — see README
- [x] Robustness and case-study datasets: `prim`, `noedu`, `gap7`, `usa` — `R/02_clean_wdi.R`
- [x] Basic transforms: `log_gdp_pc`, `log_pop`
- [x] Set up the GitHub repo, README, issues and milestones

### Exploratory analysis and visualization (Week 2)

- [x] Histograms of each variable — `R/03_eda_histograms.R` (#3)
- [x] Correlation matrix — `R/03_eda_correlation.R` (#4)
- [x] Scatterplots of each predictor vs. life expectancy — `R/03_eda_scatter.R` (#5)
- [x] Life expectancy trends by region and income group — `R/03_eda_trends.R` (#6)
- [x] **At least 2 polished figures with written interpretations** (check-in requirement) — [EDA-Findings.md](EDA-Findings.md) (#7); figures in `output/figures/`

### Feature engineering and splits (Week 2)

- [x] Year as a feature; region and income group as categories — `R/04_features.R` (#8)
- [x] GDP × education interaction (lags optional) — `R/04_features.R` (`log_gdp_x_sec_enroll`, `*_lag1`) (#9)
- [x] Standardize features (needed for ridge, lasso and elastic net) — `R/05_split_scale.R` (training-set means/SDs only) (#10)
- [x] Time-based split: train on 2000–2014, test on 2015–2019 — `R/05_split_scale.R` → `data/processed/model_data.rds` (1,828 / 581) (#11)
- [x] Cross-validation folds grouped by country — `R/05_split_scale.R` → `md$fold_id` (5 folds, seed 475) (#12)

## Still to do

### Midpoint check-in (due 11/10/26)

- [ ] Shared metrics helper (RMSE, MAE, R²) — [#13](https://github.com/yohannsharma/long-live/issues/13) (Josh)
- [ ] Linear regression (baseline) — [#14](https://github.com/yohannsharma/long-live/issues/14) (Josh)
- [ ] Polynomial regression — [#15](https://github.com/yohannsharma/long-live/issues/15) (Josh)
- [ ] Ridge, lasso, elastic net — [#16](https://github.com/yohannsharma/long-live/issues/16) (Josh)
- [ ] **At least 3 models fitted, reporting test RMSE, MAE and R²** (check-in requirement) — [#17](https://github.com/yohannsharma/long-live/issues/17) (Aiden)
- [ ] Short summary or slides of the cleaned data, figures, and first model results — [#18](https://github.com/yohannsharma/long-live/issues/18) (Aiden)

### After the check-in (unassigned)

- [ ] **Week 4 (10/31–11/7):** decision tree, random forest, gradient boosting, XGBoost, neural network; hyperparameter tuning — #19–#24
- [ ] **Week 5 (11/7–11/14):** model comparison, feature importance (permutation importance, SHAP), analysis across the four time windows, country case studies (including the US, `wdi_features_usa.rds`), robustness checks on the `prim`, `noedu` and `gap7` datasets — #25–#29
- [ ] **Week 6 (11/14–11/21):** report and slides, final figures, internal review — #30, #31
- [ ] **Final presentation:** 12/7–12/14 — #31
- [ ] **Final submission:** 12/18 (report, code, slides) — #32
