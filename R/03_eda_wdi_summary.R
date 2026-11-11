# Summary statistics for WDI data
library(dplyr)
library(tidyr)

# Load data
wdi <- readRDS("data/processed/wdi_clean.rds")

vars <- c("life_exp", "gdp_pc", "log_gdp_pc", "u5_mort",
          "population", "log_pop", "sec_enroll")

summary_stats <- wdi %>%
  select(all_of(vars)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
  group_by(variable) %>%
  summarise(
    Mean   = mean(value, na.rm = TRUE),
    SD     = sd(value, na.rm = TRUE),
    Min    = min(value, na.rm = TRUE),
    Median = median(value, na.rm = TRUE),
    Max    = max(value, na.rm = TRUE),
    n      = sum(!is.na(value)),
    .groups = "drop"
  ) %>%
  mutate(variable = factor(variable, levels = vars)) %>%   # keep your variable order
  arrange(variable) %>%
  mutate(variable = as.character(variable))

print(summary_stats)

write.csv(summary_stats, "output/tables/wdi_summary.csv", row.names = FALSE)