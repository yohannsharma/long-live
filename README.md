# Predicting Life Expectancy Using World Development Indicators

CPTS 475 final project — Team Long Live Humanity.

**Status (2026-11-09):** data collection, cleaning, EDA, feature engineering, the train/test split, scaling and CV folds are done (issues #3–#12 closed). Baseline models (#13–#17) are next. See [Project-Progress.md](Project-Progress.md) for what's done, what's left and who's doing it.

## Setup

Open `Long-Live-Humanity.Rproj` in RStudio (this sets the working directory to the project root), then install packages once:

```r
install.packages(c("WDI", "dplyr", "tidyr", "zoo", "readr", "ggplot2", "scales", "patchwork", "glmnet"))
```

The EDA scripts need ggplot2 ≥ 3.4.0 and scales ≥ 1.2.0 (check with `packageVersion("ggplot2")` and `packageVersion("scales")`).

## Pipeline

Run the scripts in order from the project root:

| Script | Does | Writes |
|---|---|---|
| `R/01_download_wdi.R` | Downloads life expectancy + 5 predictors (incl. primary enrollment as a fallback) for all countries, 2000–2019, with region/income metadata. Skips if the raw file exists (set `FORCE_DOWNLOAD <- TRUE` to refresh). | `data/raw/wdi_raw.csv` |
| `R/02_clean_wdi.R` | Removes aggregates, reports missingness, nulls implausible values, drops rows missing the outcome, flags statistical outliers for review, drops countries with >30% of any feature missing, interpolates gaps of ≤3 years, keeps complete cases, adds `log_gdp_pc` / `log_pop`. Builds the main dataset plus the robustness and US case-study variants (below). | `data/processed/wdi_clean*.{csv,rds}`, `output/tables/*.csv` |
| `R/03_eda_histograms.R` | Histograms of each variable in the main dataset (log-scale versions for GDP per capita and population), with the median marked, plus a combined panel. Prints skewness. | `output/figures/hist_*.png` |
| `R/03_eda_correlation.R` | Pearson correlation matrix of life expectancy and the numeric predictors (log GDP and population), plus the Spearman matrix. | `output/figures/correlation_matrix.png`, `output/tables/correlation_matrix{,_spearman}.csv` |
| `R/03_eda_scatter.R` | Each predictor against life expectancy, coloured by income group, with a loess smoother; one combined panel and one file per predictor. | `output/figures/scatter_*.png` |
| `R/03_eda_missingness_heatmap.R` | Each predictor with heatmap missing data percentage by year.  | `output/figures/heatmap_missing.png` |
| `R//03_eda_wdi_summary.R` | table of summary statistics for clean wdi.  | `output/tables/wdi_summary.csv` |
| `R/03_eda_trends.R` | Mean life expectancy per year by income group and by region, for the same 127 countries every year (life expectancy taken from the raw file; see the script header). | `output/figures/life_exp_trend*.png`, `output/tables/life_exp_trends.csv` |
| `R/04_features.R` | Adds model features to each variant: `year` as numeric, `region` / `income` as factors with fixed levels, and matching dummy columns (`region_*`, `income_*`). Reference levels: East Asia & Pacific, Low income. Adds the GDP × education interaction `log_gdp_x_sec_enroll` (`log_gdp_x_prim_enroll` in `prim`) and optional 1-year lags (`*_lag1`, same country, exactly the previous year; NA in a country's first year). Saves `feature_spec.rds` listing columns by role. | `data/processed/wdi_features*.{csv,rds}`, `data/processed/feature_spec.rds` |
| `R/05_split_scale.R` | Splits by year (train 2000–2014, test 2015–2019), assigns 5 cross-validation folds grouped by country (training countries only), and standardizes numeric features with means/SDs from the **training rows only**, applied unchanged to the test rows. Keeps unscaled copies for tree models. In the scaled data the interaction is rebuilt from the standardized GDP and education columns. The US case-study rows are scaled with the main training parameters. | `data/processed/model_data*.rds`, `output/tables/scaling_params.csv` |
| `R/06_evaluate.R` | Shared evaluation helper for calculating test RMSE, MAE, and R² and appending model results to a comparison CSV. | `output/tables/model_results.csv` (when called by a model script) |
| `R/07_linear_regression.R` | Fits a four-predictor OLS baseline using the existing training split and five country-grouped CV folds. | `output/tables/ols_cv_folds.csv`, `output/tables/ols_cv_summary.csv`, `output/models/ols_4_predictors.rds` |
| `R/08_polynomial_regression.R` | Compares polynomial degrees 1–3 using country-grouped CV, selects the degree with the lowest mean CV RMSE, and evaluates the selected model on the test set. | `output/tables/polynomial_cv_folds.csv`, `output/tables/polynomial_cv_summary.csv`, `output/models/polynomial_model.rds` |
| `R/09_regularized_regression.R` | Fits Ridge, Lasso, and Elastic Net using standardized features. Tunes lambda and Elastic Net alpha with country-grouped CV and records Lasso coefficients. | `output/tables/regularized_cv_summary.csv`, `output/tables/lasso_coefficients.csv`, `output/models/*_model.rds` |

What the EDA figures show is written up in [EDA-Findings.md](EDA-Findings.md). Each `R/03_eda_*.R` script has a hand-test checklist in `tests/manual/`. The figures and tables they produce are committed in `output/figures/` and `output/tables/`; re-run the scripts to regenerate them after the data changes.

Downstream scripts should load the `.rds` files (they keep `region` and `income` as factors). `wdi_features.rds` has every feature for the full 2000–2019 panel: formula models (`lm`, `rpart`, `ranger`) use the `region` / `income` factors, and matrix models (`glmnet`, `xgboost`, neural net) use the dummy columns. Both use the same reference levels, so results line up. `feature_spec.rds` holds the column names by role (`outcome`, `numeric`, `factors`, `dummies`, `interaction`, `lags`).

**Model scripts should load `data/processed/model_data.rds`** so every model uses the same split and scaling:

```r
md <- readRDS("data/processed/model_data.rds")
md$train, md$test                # unscaled: lm, rpart, ranger, gbm, xgboost
md$train_scaled, md$test_scaled  # standardized: ridge / lasso / elastic net, neural net
md$scaler                        # mean and sd used for each column (from train)
md$fold_id                       # CV fold (1-5) for each row of md$train, grouped by country
md$folds                         # which training country is in which fold
md$usa, md$usa_scaled            # US case-study rows (2005, 2013-2019)
```

For tuning, use the saved folds rather than making new ones, e.g. `cv.glmnet(x, y, foldid = md$fold_id)`, or loop `k in 1:5` with `md$train[md$fold_id != k, ]` as training and `md$train[md$fold_id == k, ]` as validation. All of a country's years are in one fold, so validation is always on unseen countries. Folds are built from training countries only, balanced by row count and income group, with a fixed seed (475); the assignments are also in `output/tables/cv_folds.csv`.

`life_exp` is never scaled, so errors stay in years. Dummy columns stay 0/1. Lag columns are NA in each country's first year; drop those rows (or the lag columns) in models that can't handle NA.

Income group is WDI's current classification, so it doesn't change within a country over 2000–2019. North America is only Canada in the main dataset (16 rows).


## Regression Models (Issues #13–16)

The project implements five regression models across three approaches (ordinary least squares, polynomial regression, and regularized regression) for predicting life expectancy using four World Development Indicators.

- `log_gdp_pc`: Log GDP per capita
- `sec_enroll`: Secondary school enrollment
- `u5_mort`: Under-five mortality
- `log_pop`: Log population

The target variable is `life_exp`, measured in years.

### Training and Evaluation

All regression models use the prepared main dataset stored in `data/processed/model_data.rds`.

- Training period: 2000–2014 (1,828 observations)
- Test period: 2015–2019 (581 observations)
- Cross-validation: Five folds grouped by country
- Evaluation metrics: RMSE, MAE, and R²

Country-grouped cross-validation ensures that observations from the same country are assigned to the same validation fold.

The held-out test set is not used to select model hyperparameters.

### Models

**Ordinary Least Squares (OLS)**

`R/07_linear_regression.R`

Fits a linear regression model using the four predictors. Reports five-fold cross-validation results and evaluates the fitted model on the held-out test set.

**Polynomial Regression**

`R/08_polynomial_regression.R`

Extends OLS by adding squared and cubic terms for individual predictors, without cross-predictor interaction terms.

Compares polynomial degrees 1, 2, and 3 using country-grouped cross-validation. The degree with the lowest mean validation RMSE is selected.

**Regularized Regression**

`R/09_regularized_regression.R`

Implements three regularized linear models using `glmnet`:

- Ridge (L2): alpha = 0
- Lasso (L1): alpha = 1
- Elastic Net (L1 + L2): alpha selected from 0.25, 0.5, and 0.75

Lambda is tuned using country-grouped cross-validation for each model.

Regularized regression uses `model_data$train_scaled` and `model_data$test_scaled`, which were standardized using the training-set means and standard deviations.

Because the scaling parameters were calculated using the full training period, validation-fold feature distributions contribute to the preprocessing statistics. This introduces limited preprocessing leakage within cross-validation, but not from the held-out test set.

The regularized models use `standardize = FALSE` in `glmnet` to avoid applying an additional scaling transformation.

### Running the Models

From the project root, after generating `data/processed/model_data.rds`, run:

```powershell
Rscript.exe R/07_linear_regression.R
Rscript.exe R/08_polynomial_regression.R
Rscript.exe R/09_regularized_regression.R
```

The shared evaluation helper (`R/06_evaluate.R`) is loaded automatically by each model script.

### Model Results

The following held-out test results were obtained using the main dataset:

| Model | RMSE | MAE | R² |
|---|---:|---:|---:|
| OLS | 2.7128 | 2.1576 | 0.8516 |
| Polynomial (degree 2) | 2.3393 | 1.9103 | 0.8896 |
| Ridge | 2.7153 | 2.1567 | 0.8513 |
| Lasso | 2.7271 | 2.1611 | 0.8500 |
| Elastic Net | 2.7285 | 2.1624 | 0.8498 |

Polynomial regression achieved the lowest test RMSE among these models.

Regularization did not substantially improve test accuracy compared with OLS. However, Lasso eliminated secondary school enrollment by assigning it a coefficient of zero.

These results describe predictive associations and should not be interpreted as causal relationships.

### Output Files

Regression results are saved in `output/tables/`:

| File | Description |
|---|---|
| `model_results.csv` | Test RMSE, MAE, and R² for all regression models |
| `ols_cv_folds.csv` | OLS cross-validation metrics for each fold |
| `ols_cv_summary.csv` | OLS cross-validation summary |
| `polynomial_cv_folds.csv` | Polynomial cross-validation results by degree and fold |
| `polynomial_cv_summary.csv` | Polynomial cross-validation summary by degree |
| `regularized_cv_summary.csv` | Alpha, lambda, and CV RMSE for regularized models |
| `lasso_coefficients.csv` | Lasso coefficients for feature-importance discussion |

Trained models are saved locally in `output/models/` as `.rds` files. This directory is excluded from Git tracking because the models can be regenerated by running the scripts.

The model scripts replace their existing entries in `model_results.csv` when rerun, preventing duplicate model results.

## Dataset variants

The 30% missingness rule drops many countries because enrollment data is patchy, so the cleaning script writes several versions: the main dataset, three robustness checks and the US case study. All share GDP per capita, under-5 mortality and population.

| File | Education feature | Countries | Rows (train / test) |
|---|---|---|---|
| `wdi_clean.rds` (main) | secondary enrollment | 127 | 2,409 (1,828 / 581) |
| `wdi_clean_prim.rds` | primary enrollment | 155 | 2,987 (2,250 / 737) |
| `wdi_clean_noedu.rds` | none | 189 | 3,778 (2,834 / 944) |
| `wdi_clean_gap7.rds` | secondary enrollment, gaps ≤ 7 years filled, 30% rule checked after filling | 147 | 2,769 (2,120 / 649) |
| `wdi_clean_usa.rds` | US only, years with every feature reported (2005, 2013–2019) | 1 | 8 |

`gap7` is a robustness check that brings back the US and 19 other countries; `usa` is for the US case study. Each has a matching `wdi_features_*.rds` from `R/04_features.R`. See the decision in [Project-Progress.md](Project-Progress.md#decision-2026-11-05-keep-the-main-dataset-handle-the-us-in-a-case-study-and-a-robustness-check).

`output/tables/variant_summary.csv` breaks the retained countries down by income group; `countries_dropped.csv` lists every dropped country and the feature responsible.

### Which one to use

> **Decision (2026-10-28): the team's dataset is `wdi_clean.rds` (secondary enrollment).** Use it for all modeling, evaluation and figures. The other datasets are robustness checks or the US case study only.

Why:

- **It answers the research question.** The question asks which economic, educational, health and demographic indicators matter, so the education feature has to measure something. Secondary enrollment correlates 0.81 with life expectancy; primary enrollment only 0.11, because most countries sit near 100% (interquartile range ≈ 92–110%). With primary enrollment, education would look unimportant because of the measure, not the relationship.
- **It's what the proposal specified** (`SE.SEC.ENRR`), and the sample is not skewed by income: it keeps roughly half of each income group (see `variant_summary.csv`).
- **It's big enough.** 1,828 training rows is plenty for the linear, regularized and tree models; the neural network is the one model that may struggle, which the proposal's contingency plan already covers.

Run the final best models on the robustness datasets as well and report the differences (#29):

- `wdi_clean_noedu.rds` (189 countries) shows whether the 62 extra countries change accuracy or the GDP / under-5 mortality importance rankings — i.e. how much the smaller sample costs.
- `wdi_clean_prim.rds` shows how sensitive the education conclusion is to the indicator chosen.
- `wdi_clean_gap7.rds` (147 countries, includes the US) shows whether the 30% missingness rule changed the conclusions.

The US is predicted separately as a case study (#28) from `md$usa` / `md$usa_scaled` in `model_data.rds`.

## Outliers

`output/tables/outliers_flagged.csv` lists values that are plausible but unusual. They are **kept in the data**; the list is for review and for explaining large residuals. Two checks, with skewed indicators on the log scale:

- `cross_section`: more than 3 × IQR from that year's quartiles across countries.
- `yoy_jump`: a year-over-year change within a country more than 10 × IQR from the typical change. (Changes are tightly bunched, so 3 × IQR flags ordinary noise.)

Most life-expectancy jumps are real events: Haiti 2010 (earthquake), Myanmar 2008 (Cyclone Nargis), Sri Lanka 2004 (tsunami), Somalia 2011 (famine), Syria 2012, South Sudan 2014. The Central African Republic series is erratic (swings of 6–21 years most years, 31.5 in 2019) and looks like a data problem; it is only in `wdi_clean_noedu.rds`. Most `prim_enroll` cross-section flags are genuinely low-enrollment countries (e.g. Niger, Sudan, Rwanda).

## Layout

```
R/                 analysis scripts, numbered in run order
tests/manual/      hand-test checklists for scripts
data/raw/          untouched API download
data/processed/    cleaned datasets (wdi_clean*), features (wdi_features*),
                   model-ready split/scaling/folds (model_data*)
output/figures/    ggplot2 figures (EDA figures from R/03_eda_*.R)
output/tables/     cleaning, scaling, CV-fold, EDA, cross-validation, and model evaluation results
output/models/     locally saved trained models (Git-ignored)
EDA-Findings.md    written interpretations of the EDA figures
Project-Progress.md  status, decisions, closed and open issues
```
