# Project Progress

Tracks what's done and what's left against the project proposal. Tick boxes as work is pushed.

*Last updated: 2026-10-28*

## Midpoint check-in requirements (November 4)

Per the proposal:

- [x] Cleaned data
- [ ] EDA figures — **at least 2 meaningful visualizations, each with a written interpretation**
- [ ] Baseline results — **at least 3 models, methods, or configurations tested**

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

- [ ] Year as a feature; region and income group as categories
- [ ] GDP × education interaction (lags optional)
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
- [ ] **Week 5 (11/7–11/14):** model comparison, feature importance (permutation importance, SHAP), analysis across the four time windows, country case studies, robustness checks on `wdi_clean_prim.rds` and `wdi_clean_noedu.rds`
- [ ] **Week 6 (11/14–11/21):** report and slides, final figures, internal review
- [ ] **Final presentation:** 12/7–12/14
- [ ] **Final submission:** 12/18 (report, code, slides)
