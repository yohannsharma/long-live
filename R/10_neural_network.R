# Issue #23: Neural network (single hidden layer) with country-grouped CV
#
# A small feed-forward network fitted with `nnet` (ships with R). It uses the
# same four predictors as the baselines (#14-#16) so the results are directly
# comparable, and the standardized data (`train_scaled` / `test_scaled`).
#
# Choices:
# - One hidden layer. With ~1,800 training rows and 4 inputs, a deeper network
#   has far more weights than the data can support (see the README note and
#   the proposal's contingency plan).
# - The outcome is standardized inside every fit (mean/sd of that fit's own
#   training rows) and converted back to years afterwards. Networks train
#   badly when the target is ~70 and the inputs are ~0.
# - Each configuration is fitted with several random starting weights and the
#   predictions are averaged. A single `nnet` fit can land in a poor local
#   minimum, so one seed makes the CV comparison noisy.
# - Hidden units (`size`) and weight decay (`decay`, an L2 penalty like ridge)
#   are tuned on the saved country-grouped folds. The test set is used once.

# --------------------------------------------------
# 1. Load evaluation helper and prepared dataset
# --------------------------------------------------

library(nnet)

source("R/06_evaluate.R")

model_data <- readRDS("data/processed/model_data.rds")

train <- model_data$train_scaled
test <- model_data$test_scaled
fold_id <- model_data$fold_id

# --------------------------------------------------
# 2. Define predictors
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

valid_rows <- function(df) {
  values <- as.matrix(df[, required_cols, drop = FALSE])
  rowSums(!is.finite(values)) == 0
}

train_valid <- valid_rows(train)
test_valid <- valid_rows(test)

train <- train[train_valid, , drop = FALSE]
test <- test[test_valid, , drop = FALSE]
fold_id <- fold_id[train_valid]

cat("Training rows:", nrow(train), "\n")
cat("Testing rows:", nrow(test), "\n")

# --------------------------------------------------
# 3. Fit / predict helpers
# --------------------------------------------------

seeds <- 475 + 0:4   # five random starts per configuration
max_iter <- 2000

# Fits one network per seed. Returns everything needed to predict in years.
fit_nn <- function(data, size, decay) {

  x <- as.matrix(data[, predictors, drop = FALSE])

  y_mean <- mean(data$life_exp)
  y_sd <- sd(data$life_exp)
  y <- (data$life_exp - y_mean) / y_sd

  nets <- lapply(seeds, function(s) {
    set.seed(s)
    nnet(
      x = x,
      y = y,
      size = size,
      decay = decay,
      linout = TRUE,     # regression: linear output, not a 0-1 sigmoid
      maxit = max_iter,
      trace = FALSE
    )
  })

  converged <- sapply(nets, function(n) n$convergence == 0)

  list(
    nets = nets,
    y_mean = y_mean,
    y_sd = y_sd,
    size = size,
    decay = decay,
    converged = converged
  )
}

# Averages the seeds' predictions and converts back to years.
predict_nn <- function(fit, newdata) {

  x <- as.matrix(newdata[, predictors, drop = FALSE])

  preds <- sapply(fit$nets, function(n) as.numeric(predict(n, x)))
  preds <- matrix(preds, nrow = nrow(x))

  rowMeans(preds) * fit$y_sd + fit$y_mean
}

metrics <- function(actual, predicted) {
  errors <- actual - predicted
  ss_tot <- sum((actual - mean(actual))^2)
  data.frame(
    RMSE = sqrt(mean(errors^2)),
    MAE = mean(abs(errors)),
    R2 = if (ss_tot == 0) NA_real_ else 1 - sum(errors^2) / ss_tot
  )
}

# --------------------------------------------------
# 4. Country-grouped cross-validation over the grid
# --------------------------------------------------

grid <- expand.grid(
  size = c(1, 2, 4, 8),
  decay = c(0.01, 0.1, 0.3, 1)
)

folds <- sort(unique(fold_id))

cv_results <- data.frame()

cat("\n=== NEURAL NETWORK CROSS-VALIDATION ===\n")

for (g in seq_len(nrow(grid))) {

  size <- grid$size[g]
  decay <- grid$decay[g]

  for (fold in folds) {

    cv_train <- train[fold_id != fold, , drop = FALSE]
    cv_validation <- train[fold_id == fold, , drop = FALSE]

    fit <- fit_nn(cv_train, size, decay)
    predictions <- predict_nn(fit, cv_validation)

    cv_results <- rbind(
      cv_results,
      cbind(
        data.frame(
          size = size,
          decay = decay,
          fold = fold,
          seeds_converged = sum(fit$converged)
        ),
        metrics(cv_validation$life_exp, predictions)
      )
    )
  }

  cat(sprintf("size = %2d, decay = %-6g done\n", size, decay))
}

# --------------------------------------------------
# 5. Summarize CV performance by configuration
# --------------------------------------------------

cv_summary <- do.call(
  rbind,
  lapply(seq_len(nrow(grid)), function(g) {

    rows <- cv_results[
      cv_results$size == grid$size[g] &
        cv_results$decay == grid$decay[g], ]

    data.frame(
      size = grid$size[g],
      decay = grid$decay[g],
      mean_RMSE = mean(rows$RMSE),
      sd_RMSE = sd(rows$RMSE),
      mean_MAE = mean(rows$MAE),
      mean_R2 = mean(rows$R2, na.rm = TRUE),
      seeds_converged = sum(rows$seeds_converged),
      seeds_total = nrow(rows) * length(seeds)
    )
  })
)

cv_summary <- cv_summary[order(cv_summary$mean_RMSE), ]

cat("\n=== CROSS-VALIDATION SUMMARY (best first) ===\n")
print(cv_summary, row.names = FALSE)

best <- cv_summary[1, ]

cat(
  "\nSelected: size =", best$size,
  ", decay =", best$decay,
  ", mean CV RMSE =", round(best$mean_RMSE, 4), "\n"
)

# --------------------------------------------------
# 6. Fit selected configuration on all training data
# --------------------------------------------------

final_fit <- fit_nn(train, best$size, best$decay)

cat(
  "Final model: seeds converged",
  sum(final_fit$converged), "of", length(seeds), "\n"
)

# --------------------------------------------------
# 7. Evaluate on held-out test set
# --------------------------------------------------

predictions <- predict_nn(final_fit, test)

# Avoid duplicate model rows on reruns
results_path <- "output/tables/model_results.csv"

if (file.exists(results_path)) {
  existing <- read.csv(results_path)

  existing <- existing[
    !(existing$model == "Neural_Network" &
        existing$dataset_variant == "main"),
    ,
    drop = FALSE
  ]

  write.csv(existing, results_path, row.names = FALSE)
}

test_results <- evaluate_model(
  actual = test$life_exp,
  predicted = predictions,
  model = "Neural_Network",
  dataset_variant = "main",
  results_path = results_path
)

cat("\n=== TEST PERFORMANCE ===\n")
print(test_results)

# --------------------------------------------------
# 8. Save results and fitted model
# --------------------------------------------------

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/models", recursive = TRUE, showWarnings = FALSE)

write.csv(
  cv_results,
  "output/tables/nn_cv_folds.csv",
  row.names = FALSE
)

write.csv(
  cv_summary,
  "output/tables/nn_cv_summary.csv",
  row.names = FALSE
)

saveRDS(
  final_fit,
  "output/models/neural_network_model.rds"
)

cat("\nNeural network completed successfully!\n")
