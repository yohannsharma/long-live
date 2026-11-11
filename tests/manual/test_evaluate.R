# Test the shared evaluation helper

source("R/06_evaluate.R")

# Small example using life expectancy in years
actual <- c(65, 70, 75, 80, 85)
predicted <- c(66, 68, 76, 79, 83)

results <- evaluate_model(
  actual = actual,
  predicted = predicted,
  model = "test_model",
  dataset_variant = "sample_data",
  results_path = "output/tables/test_model_results.csv"
)

print(results)

# Check expected metrics
stopifnot(abs(results$RMSE - sqrt(2.2)) < 1e-10)
stopifnot(abs(results$MAE - 1.4) < 1e-10)
stopifnot(abs(results$R2 - 0.956) < 1e-10)

cat("\nAll evaluation tests passed!\n")