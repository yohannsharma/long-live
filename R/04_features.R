# 04_features.R
# Build model features from the cleaned panels:
#   - year as a numeric feature (issue #8)
#   - region and income group as factors with fixed levels, plus matching
#     dummy columns, so every model sees the same encoding (issue #8)
#   - GDP x education interaction, log_gdp_x_sec_enroll (issue #9)
#   - optional 1-year lags of the predictors, *_lag1 (issue #9)
#
# Formula-based models (lm, rpart, ranger) use the `region` / `income` factors.
# Matrix-based models (glmnet, xgboost, neural net) use the dummy columns.
# Both use treatment coding with the same reference levels:
#   region: "East Asia & Pacific"   income: "Low income"
# so coefficients from either route mean the same thing.
#
# Note: WDI's income group is the *current* classification, so it is constant
# within a country across 2000-2019 rather than the group in each year.
#
# Input:  data/processed/wdi_clean{,_prim,_noedu,_gap7,_usa}.rds  (from 02_clean_wdi.R)
# Output: data/processed/wdi_features{,_prim,_noedu,_gap7,_usa}.{csv,rds}
#         data/processed/feature_spec.rds  (column names by role, for later scripts)
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(readr)

# Fixed levels; the first is the reference level for treatment coding.
REGION_LEVELS <- c(
  "East Asia & Pacific",
  "Europe & Central Asia",
  "Latin America & Caribbean",
  "Middle East, North Africa, Afghanistan & Pakistan",
  "North America",
  "South Asia",
  "Sub-Saharan Africa"
)
INCOME_LEVELS <- c("Low income", "Lower middle income", "Upper middle income", "High income")

# "Sub-Saharan Africa" -> "sub_saharan_africa"
slug <- function(x) gsub("^_|_$", "", gsub("[^a-z0-9]+", "_", tolower(x)))

REGION_DUMMIES <- paste0("region_", slug(REGION_LEVELS[-1]))
INCOME_DUMMIES <- paste0("income_", slug(INCOME_LEVELS[-1]))

# Predictors that get a 1-year lag. The education column is whichever the
# dataset has (sec_enroll, or prim_enroll in the prim variant).
LAG_BASE <- c("log_gdp_pc", "u5_mort", "log_pop")
EDU_COLS <- c("sec_enroll", "prim_enroll")

build_features <- function(clean) {
  unknown_region <- setdiff(unique(as.character(clean$region)), REGION_LEVELS)
  unknown_income <- setdiff(unique(as.character(clean$income)), INCOME_LEVELS)
  if (length(unknown_region) || length(unknown_income) || anyNA(clean$region) || anyNA(clean$income)) {
    stop("Unexpected or missing region/income values: ",
         paste(c(unknown_region, unknown_income), collapse = ", "))
  }

  features <- clean %>%
    mutate(
      year   = as.numeric(year),
      region = factor(as.character(region), levels = REGION_LEVELS),
      income = factor(as.character(income), levels = INCOME_LEVELS)
    )

  # Dummy columns from the same factors, dropping the reference level.
  dummies <- model.matrix(~ region + income, data = features)[, -1, drop = FALSE]
  colnames(dummies) <- c(REGION_DUMMIES, INCOME_DUMMIES)
  features <- bind_cols(features, as_tibble(dummies))

  # GDP x education interaction, from the unscaled columns (standardizing,
  # issue #10, happens later). The noedu variant has no education column.
  edu <- intersect(EDU_COLS, names(features))
  if (length(edu) == 1) {
    features[[paste0("log_gdp_x_", edu)]] <- features$log_gdp_pc * features[[edu]]
  }

  # 1-year lags within each country. A lag is the value from exactly year - 1
  # in the same country, so it is NA in a country's first year and after a
  # missing year (rows dropped in cleaning), never a value from another country
  # or from further back. Lags only look backward, so a training row
  # (2000-2014) never sees a test-period (2015-2019) value; a 2015 test row
  # uses 2014, which is known at prediction time.
  lag_cols <- c(LAG_BASE, edu)
  lagged <- features %>%
    select(iso3c, year, all_of(lag_cols)) %>%
    mutate(year = year + 1) %>%
    rename_with(~ paste0(.x, "_lag1"), all_of(lag_cols))
  left_join(features, lagged, by = c("iso3c", "year"))
}

VARIANT_SUFFIXES <- c(main = "", prim = "_prim", noedu = "_noedu", gap7 = "_gap7", usa = "_usa")

for (v in names(VARIANT_SUFFIXES)) {
  in_path <- file.path("data", "processed", paste0("wdi_clean", VARIANT_SUFFIXES[[v]], ".rds"))
  if (!file.exists(in_path)) stop("Run R/02_clean_wdi.R first: ", in_path, " not found.")

  features <- build_features(readRDS(in_path))

  out_stem <- file.path("data", "processed", paste0("wdi_features", VARIANT_SUFFIXES[[v]]))
  write_csv(features, paste0(out_stem, ".csv"))
  saveRDS(features, paste0(out_stem, ".rds"))

  message(v, ": ", nrow(features), " rows, ", ncol(features), " columns -> ", out_stem, ".rds")
  empty <- c(REGION_DUMMIES, INCOME_DUMMIES)[colSums(features[c(REGION_DUMMIES, INCOME_DUMMIES)]) == 0]
  if (length(empty) && v != "usa") message("  Note: no rows for ", paste(empty, collapse = ", "))
}

# Column names by role, so modeling scripts pick features the same way.
# Education is sec_enroll in the main dataset (prim_enroll / none in the variants).
feature_spec <- list(
  outcome        = "life_exp",
  id             = c("country", "iso3c"),
  numeric        = c("year", "log_gdp_pc", "u5_mort", "log_pop", "sec_enroll"),
  factors        = c("region", "income"),
  dummies        = c(REGION_DUMMIES, INCOME_DUMMIES),
  interaction    = "log_gdp_x_sec_enroll",
  # Optional; NA in each country's first year, so models using them lose those rows.
  lags           = paste0(c(LAG_BASE, "sec_enroll"), "_lag1"),
  region_levels  = REGION_LEVELS,
  income_levels  = INCOME_LEVELS
)
saveRDS(feature_spec, file.path("data", "processed", "feature_spec.rds"))
message("Saved feature_spec.rds")
