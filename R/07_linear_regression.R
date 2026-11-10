# Issue #14: OLS Regression with Country-Grouped Cross-Validation

# --------------------------------------------------
# 1. Load evaluation helper and prepared dataset
# --------------------------------------------------

source("R/06_evaluate.R")

model_data <- readRDS("data/processed/model_data.rds")

train <- model_data$train
test <- model_data$test
fold_id <- model_data$fold_id

# --------------------------------------------------
# 2. Define predictors and formula
# --------------------------------------------------

predictors <- c(
  "log_gdp_pc",
  "sec_enroll",
  "u5_mort",
  "log_pop"
)

required_cols <- c("life_exp", predictors)

stopifnot(all(required_cols %in% names(train)))
stopifnot(all(required_cols %in% names(test)))
stopifnot(length(fold_id) == nrow(train))

model_formula <- life_exp ~ log_gdp_pc +
  sec_enroll + u5_mort + log_pop

# --------------------------------------------------
# 3. Identify complete, finite observations
# --------------------------------------------------

valid_rows <- function(df) {
  values <- as.matrix(df[, required_cols, drop = FALSE])
  rowSums(!is.finite(values)) == 0
}

train_valid <- valid_rows(train)
test_valid <- valid_rows(test)

train_complete <- train[train_valid, , drop = FALSE]
test_complete <- test[test_valid, , drop = FALSE]

# Keep fold IDs aligned with filtered training rows
fold_complete <- fold_id[train_valid]

cat("Training rows:", nrow(train_complete), "\n")
cat("Testing rows:", nrow(test_complete), "\n")

# --------------------------------------------------
# 4. Country-grouped cross-validation
# --------------------------------------------------

cat("\n=== FIVE-FOLD CROSS-VALIDATION ===\n")

folds <- sort(unique(fold_complete))

stopifnot(length(folds) == 5)
stopifnot(!anyNA(fold_complete))

# Confirm countries are not split between folds
country_folds <- tapply(
  fold_complete,
  train_complete$iso3c,
  function(x) length(unique(x))
)

stopifnot(all(country_folds == 1))

cv_results <- data.frame(
  fold = integer(),
  n_train = integer(),
  n_validation = integer(),
  RMSE = numeric(),
  MAE = numeric(),
  R2 = numeric()
)

for (fold in folds) {

  # Split training data using existing fold assignments
  cv_train <- train_complete[
    fold_complete != fold, ,
    drop = FALSE
  ]

  cv_validation <- train_complete[
    fold_complete == fold, ,
    drop = FALSE
  ]

  # Fit a new OLS model for this fold
  cv_model <- lm(
    model_formula,
    data = cv_train
  )

  # Predict on held-out countries
  cv_predictions <- as.numeric(
    predict(cv_model, newdata = cv_validation)
  )

  # Calculate fold metrics without writing to CSV
  actual <- cv_validation$life_exp
  errors <- actual - cv_predictions

  rmse <- sqrt(mean(errors^2))
  mae <- mean(abs(errors))

  ss_res <- sum(errors^2)
  ss_tot <- sum((actual - mean(actual))^2)

  r2 <- if (ss_tot == 0) {
    NA_real_
  } else {
    1 - ss_res / ss_tot
  }

  # Save this fold's results
  cv_results <- rbind(
    cv_results,
    data.frame(
      fold = fold,
      n_train = nrow(cv_train),
      n_validation = nrow(cv_validation),
      RMSE = rmse,
      MAE = mae,
      R2 = r2
    )
  )
}

print(cv_results, row.names = FALSE)

# --------------------------------------------------
# 5. Summarize cross-validation
# --------------------------------------------------

cv_summary <- data.frame(
  model = "OLS_4_predictors",
  mean_RMSE = mean(cv_results$RMSE),
  sd_RMSE = sd(cv_results$RMSE),
  mean_MAE = mean(cv_results$MAE),
  mean_R2 = mean(cv_results$R2, na.rm = TRUE)
)

cat("\n=== CROSS-VALIDATION SUMMARY ===\n")
print(cv_summary, row.names = FALSE)

# --------------------------------------------------
# 6. Fit final model on all training observations
# --------------------------------------------------

ols_model <- lm(
  model_formula,
  data = train_complete
)

cat("\n=== FINAL OLS MODEL SUMMARY ===\n")
print(summary(ols_model))

# --------------------------------------------------
# 7. Evaluate on held-out test set
# --------------------------------------------------

test_predictions <- as.numeric(
  predict(ols_model, newdata = test_complete)
)

# Prevent duplicate entries for this model on reruns
results_path <- "output/tables/model_results.csv"

if (file.exists(results_path)) {
  existing <- read.csv(results_path)

  existing <- existing[
    !(existing$model == "OLS_4_predictors" &
      existing$dataset_variant == "main"),
    ,
    drop = FALSE
  ]

  write.csv(existing, results_path, row.names = FALSE)
}

test_results <- evaluate_model(
  actual = test_complete$life_exp,
  predicted = test_predictions,
  model = "OLS_4_predictors",
  dataset_variant = "main",
  results_path = results_path
)

cat("\n=== FINAL TEST PERFORMANCE ===\n")
print(test_results)

# --------------------------------------------------
# 8. Save cross-validation results and trained model
# --------------------------------------------------

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "output/models",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  cv_results,
  "output/tables/ols_cv_folds.csv",
  row.names = FALSE
)

write.csv(
  cv_summary,
  "output/tables/ols_cv_summary.csv",
  row.names = FALSE
)

saveRDS(
  ols_model,
  "output/models/ols_4_predictors.rds"
)

cat("\nOLS cross-validation and test evaluation completed!\n")
