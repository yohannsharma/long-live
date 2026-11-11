# Issue #13: Shared regression evaluation helper

evaluate_model <- function(actual, predicted, model,
                           dataset_variant,
                           results_path = "output/tables/model_results.csv") {

  # Validate inputs
  if (!is.numeric(actual) || !is.numeric(predicted)) {
    stop("Actual and predicted values must be numeric.")
  }

  if (length(actual) != length(predicted)) {
    stop("Actual and predicted must have equal lengths.")
  }

  if (length(actual) == 0 ||
      any(!is.finite(actual)) ||
      any(!is.finite(predicted))) {
    stop("Predictions and actual values must be nonempty and finite.")
  }

  # Calculate prediction errors
  errors <- actual - predicted

  rmse <- sqrt(mean(errors^2))
  mae <- mean(abs(errors))

  # Calculate R-squared relative to the test-set mean
  ss_res <- sum(errors^2)
  ss_tot <- sum((actual - mean(actual))^2)

  r2 <- if (ss_tot == 0) NA_real_ else 1 - ss_res / ss_tot

  # Create results row
  results <- data.frame(
    model = model,
    dataset_variant = dataset_variant,
    RMSE = rmse,
    MAE = mae,
    R2 = r2
  )

  # Create output directory if necessary
  dir.create(dirname(results_path),
             recursive = TRUE,
             showWarnings = FALSE)

  # Append to existing results or create new file
  if (file.exists(results_path)) {
    existing <- read.csv(results_path)
    results <- rbind(existing, results)
  }

  write.csv(results, results_path, row.names = FALSE)

  # Return only the current model's metrics
  current <- data.frame(
    model = model,
    dataset_variant = dataset_variant,
    RMSE = rmse,
    MAE = mae,
    R2 = r2
  )

  return(current)
}