# 02_clean_wdi.R
# Clean the raw WDI download into modeling-ready country-year panels.
#
# Steps (per the project proposal):
#   1. Remove WDI aggregates ("World", "Euro area", income groups, ...)
#   2. Report missingness per indicator and year
#   3. Set implausible values to NA
#   4. Drop rows missing the outcome (life expectancy)
#   4b. Flag statistical outliers for review (report only; nothing is changed)
#   5. Drop countries with more than 30% of any feature missing
#   6. Interpolate short gaps within each country over time
#   7. Keep complete cases and add log transforms
#
# Steps 5-7 depend on which features are used, so they run once per variant:
#   main  - secondary enrollment (the proposal's primary specification)
#   prim  - primary enrollment instead (better coverage; contingency plan)
#   noedu - no education indicator (keeps the most countries)
# Comparing models across variants shows what the education choice costs.
#
# Input:  data/raw/wdi_raw.csv  (from 01_download_wdi.R)
# Output: data/processed/wdi_clean.{csv,rds}        (main)
#         data/processed/wdi_clean_prim.{csv,rds}
#         data/processed/wdi_clean_noedu.{csv,rds}
#         output/tables/missingness_by_indicator_year.csv
#         output/tables/countries_dropped.csv
#         output/tables/variant_summary.csv
#         output/tables/outliers_flagged.csv
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(tidyr)
library(readr)
library(zoo)

OUTCOME   <- "life_exp"
BASE_FEATURES <- c("gdp_pc", "u5_mort", "population")

VARIANTS <- list(
  main  = c(BASE_FEATURES, "sec_enroll"),
  prim  = c(BASE_FEATURES, "prim_enroll"),
  noedu = BASE_FEATURES
)
ALL_FEATURES <- unique(unlist(VARIANTS))

MAX_COUNTRY_MISSING <- 0.30  # drop a country if any feature is missing in > 30% of its years
MAX_INTERP_GAP      <- 3     # longest run of missing years to fill by linear interpolation

raw_path <- file.path("data", "raw", "wdi_raw.csv")
if (!file.exists(raw_path)) stop("Run R/01_download_wdi.R first: ", raw_path, " not found.")

dir.create(file.path("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("output", "tables"),  recursive = TRUE, showWarnings = FALSE)

wdi_raw <- read_csv(raw_path, show_col_types = FALSE)
missing_cols <- setdiff(c(OUTCOME, ALL_FEATURES), names(wdi_raw))
if (length(missing_cols) > 0) {
  stop("Raw file lacks ", paste(missing_cols, collapse = ", "),
       ". Re-run R/01_download_wdi.R with FORCE_DOWNLOAD <- TRUE.")
}

# 1. Remove aggregates -------------------------------------------------------
# Real countries have a region; aggregates have region "Aggregates" or NA.
wdi <- wdi_raw %>%
  filter(!is.na(region), region != "Aggregates") %>%
  select(country, iso3c, year, region, income, all_of(c(OUTCOME, ALL_FEATURES))) %>%
  arrange(country, year)

message("Countries after removing aggregates: ", n_distinct(wdi$iso3c),
        " (", nrow(wdi), " country-years)")

# 2. Missingness report ------------------------------------------------------
missing_by_year <- wdi %>%
  group_by(year) %>%
  summarise(across(all_of(c(OUTCOME, ALL_FEATURES)), ~ mean(is.na(.x))), .groups = "drop")
write_csv(missing_by_year, file.path("output", "tables", "missingness_by_indicator_year.csv"))

message("Share missing by indicator (all years):")
print(round(colMeans(is.na(wdi[c(OUTCOME, ALL_FEATURES)])), 3))

# 3. Implausible values -> NA ------------------------------------------------
# Gross enrollment can legitimately exceed 100%, so the upper bound is loose.
plausible <- list(
  life_exp    = c(20, 95),
  gdp_pc      = c(1, Inf),
  sec_enroll  = c(0, 200),
  prim_enroll = c(0, 200),
  u5_mort     = c(0, 400),
  population  = c(1, Inf)
)
for (v in names(plausible)) {
  bad <- !is.na(wdi[[v]]) & (wdi[[v]] < plausible[[v]][1] | wdi[[v]] > plausible[[v]][2])
  if (any(bad)) message("Setting ", sum(bad), " implausible value(s) of ", v, " to NA")
  wdi[[v]][bad] <- NA
}

# 4. Drop rows missing the outcome --------------------------------------------
n_before <- nrow(wdi)
wdi <- filter(wdi, !is.na(.data[[OUTCOME]]))
message("Dropped ", n_before - nrow(wdi), " rows missing ", OUTCOME)

# 4b. Flag statistical outliers -----------------------------------------------
# Plausible but unusual values are flagged for the team to review, not removed:
# a real shock (war, epidemic, disaster) looks just like a data error here.
#   cross_section - beyond CROSS_SECTION_IQR_MULT x IQR from the quartiles of that year
#   yoy_jump      - year-over-year change within a country beyond
#                   YOY_IQR_MULT x IQR of all such changes for the indicator
# Year-over-year changes are tightly bunched (life expectancy usually moves
# < 0.5 years), so the jump fence is wider; at 3x it flags ordinary noise.
# Skewed indicators are checked on the log scale.
CROSS_SECTION_IQR_MULT <- 3
YOY_IQR_MULT           <- 10
LOG_SCALE <- c("gdp_pc", "population", "u5_mort")

iqr_outlier <- function(x, mult) {
  q <- quantile(x, c(0.25, 0.75), na.rm = TRUE)
  fence <- mult * (q[2] - q[1])
  !is.na(x) & (x < q[1] - fence | x > q[2] + fence)
}

outliers <- wdi %>%
  select(country, iso3c, year, all_of(c(OUTCOME, ALL_FEATURES))) %>%
  pivot_longer(all_of(c(OUTCOME, ALL_FEATURES)), names_to = "indicator", values_to = "value") %>%
  filter(!is.na(value)) %>%
  mutate(scaled = if_else(indicator %in% LOG_SCALE, log(value), value)) %>%
  group_by(indicator, iso3c) %>%
  arrange(year, .by_group = TRUE) %>%
  # Change from the previous non-missing year, per year elapsed.
  mutate(yoy_change = (scaled - lag(scaled)) / (year - lag(year))) %>%
  group_by(indicator, year) %>%
  mutate(cross_section = iqr_outlier(scaled, CROSS_SECTION_IQR_MULT)) %>%
  group_by(indicator) %>%
  mutate(yoy_jump = iqr_outlier(yoy_change, YOY_IQR_MULT)) %>%
  ungroup() %>%
  filter(cross_section | yoy_jump) %>%
  mutate(flag = case_when(cross_section & yoy_jump ~ "both",
                          cross_section ~ "cross_section",
                          TRUE ~ "yoy_jump")) %>%
  select(indicator, country, iso3c, year, value, yoy_change, flag) %>%
  arrange(indicator, country, year)
write_csv(outliers, file.path("output", "tables", "outliers_flagged.csv"))

message("Outliers flagged for review (kept in the data):")
print(count(outliers, indicator, flag) %>% pivot_wider(names_from = flag, values_from = n, values_fill = 0))

# Steps 5-7 for one feature set ------------------------------------------------
clean_variant <- function(wdi, features, variant) {
  message("\n--- Variant '", variant, "': ", paste(features, collapse = ", "), " ---")
  wdi <- select(wdi, country, iso3c, year, region, income, all_of(c(OUTCOME, features)))

  # 5. Drop countries with too much missing data.
  # Measured before interpolation, so filled values don't hide sparse series.
  dropped <- wdi %>%
    group_by(country, iso3c) %>%
    summarise(across(all_of(features), ~ mean(is.na(.x))), .groups = "drop") %>%
    pivot_longer(all_of(features), names_to = "feature", values_to = "share_missing") %>%
    filter(share_missing > MAX_COUNTRY_MISSING) %>%
    mutate(variant = variant, .before = 1) %>%
    arrange(country, feature)

  message("Countries dropped (> ", MAX_COUNTRY_MISSING * 100, "% missing): ",
          n_distinct(dropped$iso3c), "; by feature responsible:")
  print(count(dropped, feature))

  wdi <- filter(wdi, !iso3c %in% dropped$iso3c)

  # 6. Interpolate short gaps within each country.
  # Interior gaps only (rule = 1): leading/trailing NAs are not extrapolated.
  wdi <- wdi %>%
    group_by(iso3c) %>%
    arrange(year, .by_group = TRUE) %>%
    mutate(across(
      all_of(features),
      ~ if (sum(!is.na(.x)) >= 2) na.approx(.x, x = year, maxgap = MAX_INTERP_GAP, na.rm = FALSE, rule = 1) else .x
    )) %>%
    ungroup()

  # 7. Complete cases + light feature prep.
  n_before <- nrow(wdi)
  clean <- wdi %>%
    drop_na(all_of(features)) %>%
    mutate(
      log_gdp_pc = log(gdp_pc),
      log_pop    = log(population),
      region     = factor(region),
      income     = factor(income, levels = c("Low income", "Lower middle income",
                                             "Upper middle income", "High income"))
    )
  message("Dropped ", n_before - nrow(clean), " rows with remaining (non-interpolable) gaps")

  suffix <- if (variant == "main") "" else paste0("_", variant)
  write_csv(clean, file.path("data", "processed", paste0("wdi_clean", suffix, ".csv")))
  saveRDS(clean, file.path("data", "processed", paste0("wdi_clean", suffix, ".rds")))

  message("Final: ", nrow(clean), " rows, ", n_distinct(clean$iso3c), " countries; ",
          "train 2000-2014 / test 2015-2019 rows: ",
          sum(clean$year <= 2014), " / ", sum(clean$year >= 2015))

  list(clean = clean, dropped = dropped)
}

results <- setNames(Map(clean_variant, list(wdi), VARIANTS, names(VARIANTS)), names(VARIANTS))

write_csv(bind_rows(lapply(results, `[[`, "dropped")),
          file.path("output", "tables", "countries_dropped.csv"))

# Rows by income group show whether dropping countries skews the sample.
variant_summary <- bind_rows(lapply(names(results), function(v) {
  results[[v]]$clean %>%
    distinct(iso3c, income) %>%
    count(income, name = "countries") %>%
    mutate(variant = v, .before = 1)
}))
variant_summary <- bind_rows(
  wdi %>% distinct(iso3c, income) %>% count(income, name = "countries") %>%
    mutate(variant = "all_countries", .before = 1),
  variant_summary
) %>%
  pivot_wider(names_from = variant, values_from = countries, values_fill = 0)
write_csv(variant_summary, file.path("output", "tables", "variant_summary.csv"))

message("\nCountries by income group (all countries vs. each variant):")
print(variant_summary)
