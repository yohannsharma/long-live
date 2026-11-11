# Issue #15: Polynomial Regression

source("R/06_evaluate.R")

# --------------------------------------------------
# 1. Load data
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
# 2. Remove missing/non-finite observations
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

# Check country-grouped folds
country_folds <- tapply(
  fold_id,
  train$iso3c,
  function(x) length(unique(x))
)

stopifnot(all(country_folds == 1))

cat("Training rows:", nrow(train), "\n")
cat("Testing rows:", nrow(test), "\n")

# --------------------------------------------------
# 3. Build polynomial formula
# --------------------------------------------------

make_poly_formula <- function(degree) {

  terms <- unlist(lapply(predictors, function(p) {
    if (degree == 1) {
      return(p)
    }

    paste0(
      "poly(", p, ", ", degree, ", raw = TRUE)"
    )
  }))

  as.formula(
    paste("life_exp ~", paste(terms, collapse = " + "))
  )
}

# --------------------------------------------------
# 4. Country-grouped cross-validation
# --------------------------------------------------

degrees <- 1:3
folds <- sort(unique(fold_id))

cv_results <- data.frame(
  degree = integer(),
  fold = integer(),
  RMSE = numeric(),
  MAE = numeric(),
  R2 = numeric()
)

cat("\n=== POLYNOMIAL CROSS-VALIDATION ===\n")

for (degree in degrees) {

  model_formula <- make_poly_formula(degree)

  for (fold in folds) {

    cv_train <- train[
      fold_id != fold, ,
      drop = FALSE
    ]

    cv_validation <- train[
      fold_id == fold, ,
      drop = FALSE
    ]

    # Fit on four folds
    cv_model <- lm(
      model_formula,
      data = cv_train
    )

    # Predict on held-out fold
    predictions <- as.numeric(
      predict(cv_model, newdata = cv_validation)
    )

    actual <- cv_validation$life_exp
    errors <- actual - predictions

    rmse <- sqrt(mean(errors^2))
    mae <- mean(abs(errors))

    ss_res <- sum(errors^2)
    ss_tot <- sum((actual - mean(actual))^2)

    r2 <- if (ss_tot == 0) {
      NA_real_
    } else {
      1 - ss_res / ss_tot
    }

    cv_results <- rbind(
      cv_results,
      data.frame(
        degree = degree,
        fold = fold,
        RMSE = rmse,
        MAE = mae,
        R2 = r2
      )
    )
  }
}

print(cv_results, row.names = FALSE)

# --------------------------------------------------
# 5. Summarize CV performance by degree
# --------------------------------------------------

cv_summary <- do.call(
  rbind,
  lapply(degrees, function(d) {

    rows <- cv_results[cv_results$degree == d, ]

    data.frame(
      degree = d,
      mean_RMSE = mean(rows$RMSE),
      sd_RMSE = sd(rows$RMSE),
      mean_MAE = mean(rows$MAE),
      mean_R2 = mean(rows$R2, na.rm = TRUE)
    )
  })
)

cat("\n=== CROSS-VALIDATION SUMMARY ===\n")
print(cv_summary, row.names = FALSE)

# Select lowest mean CV RMSE
best_degree <- cv_summary$degree[
  which.min(cv_summary$mean_RMSE)
]

cat("\nSelected polynomial degree:", best_degree, "\n")

# --------------------------------------------------
# 6. Fit selected model on all training data
# --------------------------------------------------

final_formula <- make_poly_formula(best_degree)

final_model <- lm(
  final_formula,
  data = train
)

cat("\n=== FINAL POLYNOMIAL MODEL ===\n")
print(summary(final_model))

# --------------------------------------------------
# 7. Evaluate on held-out test set
# --------------------------------------------------

predictions <- as.numeric(
  predict(final_model, newdata = test)
)

# Avoid duplicate model rows on reruns
results_path <- "output/tables/model_results.csv"

if (file.exists(results_path)) {
  existing <- read.csv(results_path)

  existing <- existing[
    !(existing$model == "Polynomial" &
      existing$dataset_variant == "main"),
    ,
    drop = FALSE
  ]

  write.csv(existing, results_path, row.names = FALSE)
}

test_results <- evaluate_model(
  actual = test$life_exp,
  predicted = predictions,
  model = "Polynomial",
  dataset_variant = "main",
  results_path = results_path
)

cat("\n=== TEST PERFORMANCE ===\n")
print(test_results)

# --------------------------------------------------
# 8. Save results and fitted model
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
  "output/tables/polynomial_cv_folds.csv",
  row.names = FALSE
)

write.csv(
  cv_summary,
  "output/tables/polynomial_cv_summary.csv",
  row.names = FALSE
)

saveRDS(
  final_model,
  "output/models/polynomial_model.rds"
)

cat("\nPolynomial regression completed successfully!\n")
