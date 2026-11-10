# Issue #16: Regularized Linear Regression
# Ridge, Lasso, and Elastic Net

library(glmnet)
source("R/06_evaluate.R")

# --------------------------------------------------
# 1. Load prepared dataset
# --------------------------------------------------

model_data <- readRDS("data/processed/model_data.rds")

train <- model_data$train
test <- model_data$test
fold_id <- model_data$fold_id

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

# --------------------------------------------------
# 2. Filter invalid observations
# --------------------------------------------------

valid_rows <- function(df) {
  values <- as.matrix(df[, required_cols, drop = FALSE])
  rowSums(!is.finite(values)) == 0
}

train_valid <- valid_rows(train)
test_valid <- valid_rows(test)

train <- train[train_valid, , drop = FALSE]
test <- test[test_valid, , drop = FALSE]
fold_id <- fold_id[train_valid]

stopifnot(nrow(train) > 0, nrow(test) > 0)
stopifnot(!anyNA(fold_id))
stopifnot(length(unique(fold_id)) == 5)

# Verify that each country belongs to only one fold
country_folds <- tapply(
  fold_id,
  train$iso3c,
  function(x) length(unique(x))
)

stopifnot(all(country_folds == 1))

cat("Training rows:", nrow(train), "\n")
cat("Testing rows:", nrow(test), "\n")

# --------------------------------------------------
# 3. Prepare predictor matrices
# --------------------------------------------------

x_train <- as.matrix(
  train[, predictors, drop = FALSE]
)

y_train <- train$life_exp

x_test <- as.matrix(
  test[, predictors, drop = FALSE]
)

y_test <- test$life_exp

# glmnet standardizes predictors using the
# training observations for each fit.
# This avoids leakage from validation/test data.

fold_id <- as.integer(factor(fold_id))

# --------------------------------------------------
# 4. Define alpha and lambda search
# --------------------------------------------------

# Ridge and Lasso have fixed alpha values.
# Elastic Net searches multiple mixing parameters.

alpha_grid <- list(
  Ridge = 0,
  Lasso = 1,
  Elastic_Net = c(0.25, 0.5, 0.75)
)

lambda_grid <- exp(
  seq(log(1000), log(0.0001), length.out = 200)
)

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

results_path <- "output/tables/model_results.csv"

# --------------------------------------------------
# 5. Tune alpha and lambda using grouped CV
# --------------------------------------------------

tuning_results <- data.frame(
  model = character(),
  alpha = numeric(),
  best_lambda = numeric(),
  cv_RMSE = numeric()
)

selected_models <- list()

for (model_name in names(alpha_grid)) {

  cat("\n====================================\n")
  cat("Tuning:", model_name, "\n")
  cat("====================================\n")

  alpha_values <- alpha_grid[[model_name]]

  model_tuning <- data.frame(
    model = character(),
    alpha = numeric(),
    best_lambda = numeric(),
    cv_RMSE = numeric()
  )

  for (alpha_value in alpha_values) {

    cv_model <- cv.glmnet(
      x = x_train,
      y = y_train,
      alpha = alpha_value,
      lambda = lambda_grid,
      foldid = fold_id,
      family = "gaussian",
      type.measure = "mse",
      standardize = TRUE,
      grouped = FALSE
    )

    best_lambda <- cv_model$lambda.min

    best_index <- which.min(
      abs(cv_model$lambda - best_lambda)
    )

    cv_rmse <- sqrt(cv_model$cvm[best_index])

    model_tuning <- rbind(
      model_tuning,
      data.frame(
        model = model_name,
        alpha = alpha_value,
        best_lambda = best_lambda,
        cv_RMSE = cv_rmse
      )
    )

    cat(
      "Alpha:", alpha_value,
      "| Lambda:", best_lambda,
      "| CV RMSE:", cv_rmse, "\n"
    )
  }

  tuning_results <- rbind(
    tuning_results,
    model_tuning
  )

  # Select alpha/lambda with lowest CV RMSE
  best_row <- model_tuning[
    which.min(model_tuning$cv_RMSE),
    ,
    drop = FALSE
  ]

  selected_models[[model_name]] <- best_row

  cat("\nSelected parameters for", model_name, ":\n")
  print(best_row, row.names = FALSE)
}

# --------------------------------------------------
# 6. Train selected models and evaluate
# --------------------------------------------------

for (model_name in names(selected_models)) {

  settings <- selected_models[[model_name]]

  best_alpha <- settings$alpha
  best_lambda <- settings$best_lambda

  cat("\n====================================\n")
  cat("Final model:", model_name, "\n")
  cat("====================================\n")

  final_model <- glmnet(
    x = x_train,
    y = y_train,
    alpha = best_alpha,
    lambda = best_lambda,
    family = "gaussian",
    standardize = TRUE
  )

  predictions <- as.numeric(
    predict(final_model, newx = x_test)
  )

  # Remove previous result for this model
  # to prevent duplicate rows on reruns.
  if (file.exists(results_path)) {

    existing <- read.csv(results_path)

    existing <- existing[
      !(existing$model == model_name &
        existing$dataset_variant == "main"),
      ,
      drop = FALSE
    ]

    write.csv(
      existing,
      results_path,
      row.names = FALSE
    )
  }

  test_results <- evaluate_model(
    actual = y_test,
    predicted = predictions,
    model = model_name,
    dataset_variant = "main",
    results_path = results_path
  )

  cat("\nTest performance:\n")
  print(test_results)

  cat("\nCoefficients:\n")
  print(coef(final_model))

  # ------------------------------------------------
  # 7. Record Lasso coefficients
  # ------------------------------------------------

  if (model_name == "Lasso") {

    coefficient_matrix <- as.matrix(
      coef(final_model)
    )

    lasso_coefficients <- data.frame(
      feature = rownames(coefficient_matrix),
      coefficient = as.numeric(coefficient_matrix[, 1])
    )

    # Standardized coefficient magnitudes provide
    # a more comparable feature-importance measure.
    # The intercept is not included in this ranking.

    predictor_sds <- apply(x_train, 2, sd)

    lasso_coefficients$standardized_coefficient <- NA_real_

    for (feature in predictors) {

      row_index <- which(
        lasso_coefficients$feature == feature
      )

      lasso_coefficients$standardized_coefficient[
        row_index
      ] <- lasso_coefficients$coefficient[
        row_index
      ] * predictor_sds[feature]
    }

    lasso_coefficients$abs_standardized_coefficient <-
      abs(lasso_coefficients$standardized_coefficient)

    write.csv(
      lasso_coefficients,
      "output/tables/lasso_coefficients.csv",
      row.names = FALSE
    )

    cat("\nLasso coefficients saved.\n")
    print(lasso_coefficients)
  }

  saveRDS(
    final_model,
    paste0(
      "output/models/",
      tolower(model_name),
      "_model.rds"
    )
  )
}

# --------------------------------------------------
# 8. Save tuning results
# --------------------------------------------------

write.csv(
  tuning_results,
  "output/tables/regularized_cv_summary.csv",
  row.names = FALSE
)

cat("\n=== REGULARIZATION TUNING SUMMARY ===\n")
print(tuning_results, row.names = FALSE)

# --------------------------------------------------
# 9. Compare all model test results
# --------------------------------------------------

all_results <- read.csv(results_path)

comparison <- all_results[
  all_results$dataset_variant == "main",
  ,
  drop = FALSE
]

comparison <- comparison[
  order(comparison$RMSE),
  ,
  drop = FALSE
]

cat("\n=== ALL MODEL TEST PERFORMANCE ===\n")
print(comparison, row.names = FALSE)

cat("\nIssue #16 completed successfully!\n")