# 05_split_scale.R
# Split each feature dataset by year (issue #11), standardize numeric features
# (issue #10), and assign country-grouped cross-validation folds (issue #12).
#
#   Train: 2000-2014    Test: 2015-2019
#
# CV folds: the TRAINING countries are split into CV_K folds so that all of a
# country's years are in the same fold. Validating on countries the model
# never saw stops it from "remembering" a country through its neighbouring
# years. Countries are shuffled with a fixed seed and dealt out one income group
# at a time, each to the fold with the fewest rows of that income group (ties:
# fewest rows overall). That keeps fold sizes even and every fold's income mix
# close to the full sample's. Each dataset gets its own folds (they contain
# different countries).
#
# Standardizing (z = (x - mean) / sd) uses means and SDs from the TRAINING rows
# only; the same parameters are then applied to the test rows, so nothing about
# the test period leaks into the model. Ridge, lasso, elastic net and the neural
# network use the scaled data; tree models (rpart, ranger, gbm, xgboost) and
# plain lm can use the unscaled data.
#
# Scaled columns: year, log_gdp_pc, u5_mort, log_pop, the education column, and
# the 1-year lags. Dummy columns (region_*, income_*) stay 0/1. Outcome
# (life_exp) is never scaled, so errors stay in years.
#
# Interaction in the scaled data: the product of the *standardized* GDP and
# education columns (then standardized itself), not a rescaled raw product. The
# raw product correlates ~0.97 with sec_enroll; centering first removes most of
# that collinearity. The unscaled data keeps the raw product from 04_features.R.
#
# Input:  data/processed/wdi_features{,_prim,_noedu,_gap7,_usa}.rds  (04_features.R)
# Output: data/processed/model_data{,_prim,_noedu,_gap7}.rds, each a list:
#           train, test               unscaled (tree models, lm)
#           train_scaled, test_scaled standardized (glmnet, neural net)
#           scaler                    tibble: column, mean, sd (from train)
#           folds                     tibble: iso3c, country, fold (training countries)
#           fold_id                   integer fold for each row of train / train_scaled
#         model_data.rds also has usa / usa_scaled: the US case-study rows,
#         scaled with the MAIN training parameters.
#         output/tables/scaling_params.csv  (all variants)
#         output/tables/cv_folds.csv        (all variants)
#
# Usage in a model script:
#   md <- readRDS("data/processed/model_data.rds")
#   fit <- lm(life_exp ~ ..., data = md$train); predict(fit, md$test)
#   cv.glmnet(x, y, foldid = md$fold_id)   # x built from md$train_scaled
#   for (k in 1:5) { tr <- md$train[md$fold_id != k, ]; va <- md$train[md$fold_id == k, ] }
#
# Note: train_scaled uses parameters from the whole training set, so inside CV
# the validation fold has influenced the scaling slightly. That is standard for
# tuning; glmnet also re-standardizes internally by default.
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(readr)

TRAIN_YEARS <- 2000:2014
TEST_YEARS  <- 2015:2019

EDU_COLS <- c("sec_enroll", "prim_enroll")

CV_K    <- 5
CV_SEED <- 475

split_by_year <- function(df) {
  list(train = filter(df, year %in% TRAIN_YEARS),
       test  = filter(df, year %in% TEST_YEARS))
}

# Numeric feature columns present in this dataset, excluding the interaction
# (handled separately) and dummies.
scale_cols <- function(df) {
  edu <- intersect(EDU_COLS, names(df))
  base <- c("year", "log_gdp_pc", "u5_mort", "log_pop", edu)
  c(base, intersect(paste0(c("log_gdp_pc", "u5_mort", "log_pop", edu), "_lag1"), names(df)))
}

fit_scaler <- function(train, cols) {
  tibble(
    column = cols,
    mean   = vapply(cols, function(c) mean(train[[c]], na.rm = TRUE), numeric(1)),
    sd     = vapply(cols, function(c) sd(train[[c]], na.rm = TRUE), numeric(1))
  )
}

apply_scaler <- function(df, scaler) {
  for (i in seq_len(nrow(scaler))) {
    col <- scaler$column[i]
    if (col %in% names(df)) df[[col]] <- (df[[col]] - scaler$mean[i]) / scaler$sd[i]
  }
  df
}

# Scale train and test with training parameters; rebuild the interaction from
# the standardized columns. Returns the scaled sets plus the parameters used.
scale_split <- function(train, test) {
  cols   <- scale_cols(train)
  scaler <- fit_scaler(train, cols)
  train_s <- apply_scaler(train, scaler)
  test_s  <- apply_scaler(test, scaler)

  edu <- intersect(EDU_COLS, names(train))
  if (length(edu) == 1) {
    ix <- paste0("log_gdp_x_", edu)
    train_s[[ix]] <- train_s$log_gdp_pc * train_s[[edu]]
    test_s[[ix]]  <- test_s$log_gdp_pc * test_s[[edu]]
    ix_scaler <- fit_scaler(train_s, ix)
    train_s <- apply_scaler(train_s, ix_scaler)
    test_s  <- apply_scaler(test_s, ix_scaler)
    scaler  <- bind_rows(scaler, mutate(ix_scaler, column = paste0(ix, " (from standardized terms)")))
  }
  list(train_scaled = train_s, test_scaled = test_s, scaler = scaler,
       interaction_scaler = if (length(edu) == 1) ix_scaler else NULL)
}

# Assign training countries to folds, stratified by income group: shuffle
# (seeded), then give each country to the fold with the fewest rows of its
# income group so far, breaking ties by fewest rows overall.
make_country_folds <- function(train, k = CV_K, seed = CV_SEED) {
  countries <- count(train, iso3c, country, income, name = "rows")
  set.seed(seed)
  countries <- countries[sample(nrow(countries)), ]
  countries <- countries[order(countries$income), ]  # stable: shuffle kept within group
  fold_rows   <- integer(k)
  income_rows <- matrix(0L, nrow = nlevels(train$income), ncol = k)
  countries$fold <- NA_integer_
  for (i in seq_len(nrow(countries))) {
    g <- as.integer(countries$income[i])
    f <- order(income_rows[g, ], fold_rows)[1]
    countries$fold[i] <- f
    fold_rows[f]      <- fold_rows[f] + countries$rows[i]
    income_rows[g, f] <- income_rows[g, f] + countries$rows[i]
  }
  arrange(countries, fold, country)
}

VARIANT_SUFFIXES <- c(main = "", prim = "_prim", noedu = "_noedu", gap7 = "_gap7")
all_params <- list()
all_folds  <- list()

for (v in names(VARIANT_SUFFIXES)) {
  in_path <- file.path("data", "processed", paste0("wdi_features", VARIANT_SUFFIXES[[v]], ".rds"))
  if (!file.exists(in_path)) stop("Run R/04_features.R first: ", in_path, " not found.")

  sp <- split_by_year(readRDS(in_path))
  sc <- scale_split(sp$train, sp$test)
  md <- list(train = sp$train, test = sp$test,
             train_scaled = sc$train_scaled, test_scaled = sc$test_scaled,
             scaler = sc$scaler)

  folds <- make_country_folds(sp$train)
  md$folds   <- select(folds, iso3c, country, fold)
  md$fold_id <- folds$fold[match(sp$train$iso3c, folds$iso3c)]
  all_folds[[v]] <- mutate(folds, variant = v, .before = 1)

  # US case study: scaled with the main training parameters, like any test row.
  if (v == "main") {
    usa <- readRDS(file.path("data", "processed", "wdi_features_usa.rds"))
    usa_s <- apply_scaler(usa, filter(sc$scaler, column %in% names(usa)))
    usa_s$log_gdp_x_sec_enroll <- apply_scaler(
      tibble(log_gdp_x_sec_enroll = usa_s$log_gdp_pc * usa_s$sec_enroll), sc$interaction_scaler
    )$log_gdp_x_sec_enroll
    md$usa <- usa
    md$usa_scaled <- usa_s
  }

  saveRDS(md, file.path("data", "processed", paste0("model_data", VARIANT_SUFFIXES[[v]], ".rds")))
  all_params[[v]] <- mutate(sc$scaler, variant = v, .before = 1)
  message(v, ": train ", nrow(md$train), " / test ", nrow(md$test), " rows; ",
          nrow(sc$scaler), " columns standardized; ", CV_K, " CV folds of ",
          paste(tabulate(md$fold_id, CV_K), collapse = "/"), " rows -> model_data",
          VARIANT_SUFFIXES[[v]], ".rds")
}

write_csv(bind_rows(all_folds), file.path("output", "tables", "cv_folds.csv"))
message("Saved output/tables/cv_folds.csv")

dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
write_csv(bind_rows(all_params), file.path("output", "tables", "scaling_params.csv"))
message("Saved output/tables/scaling_params.csv")
