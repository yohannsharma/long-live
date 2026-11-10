# 03_eda_correlation.R
# Correlation matrix of life expectancy and the numeric predictors (issue #4).
#
# Variables: life_exp, log_gdp_pc, sec_enroll, u5_mort, log_pop, year. GDP and
# population use their logs, matching what the models use. Region and income
# group are categorical and are left out.
#
# The figure shows Pearson correlations (lower triangle, values printed). The
# Spearman (rank) matrix is saved too: where it differs from Pearson, the
# relationship is monotonic but not linear (e.g. under-5 mortality).
#
# Uses every row of the main dataset (2000-2019). Description only; no model
# sees the test years through it.
#
# Input:  data/processed/wdi_clean.rds  (from 02_clean_wdi.R)
# Output: output/figures/correlation_matrix.png
#         output/tables/correlation_matrix.csv           (Pearson)
#         output/tables/correlation_matrix_spearman.csv  (Spearman)
# After sourcing, `cor_pearson`, `cor_spearman` (matrices) and `cor_plot` are
# left in the environment for checking.
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(readr)
library(ggplot2)

# Column -> label, in display order (outcome first).
VARS <- c(
  life_exp   = "Life expectancy",
  log_gdp_pc = "GDP per capita (log)",
  sec_enroll = "Secondary enrollment",
  u5_mort    = "Under-5 mortality",
  log_pop    = "Population (log)",
  year       = "Year"
)

clean_path <- file.path("data", "processed", "wdi_clean.rds")
if (!file.exists(clean_path)) stop("Run R/02_clean_wdi.R first: ", clean_path, " not found.")
wdi <- readRDS(clean_path)
dir.create(file.path("output", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("output", "tables"),  recursive = TRUE, showWarnings = FALSE)

X <- as.data.frame(wdi[names(VARS)])
if (anyNA(X)) stop("Unexpected NA values in wdi_clean.rds; re-run R/02_clean_wdi.R.")

cor_pearson  <- cor(X, method = "pearson")
cor_spearman <- cor(X, method = "spearman")

write_matrix <- function(m, path) {
  out <- data.frame(variable = rownames(m), round(m, 3), check.names = FALSE, row.names = NULL)
  write_csv(out, path)
  message("Saved ", path)
}
write_matrix(cor_pearson,  file.path("output", "tables", "correlation_matrix.csv"))
write_matrix(cor_spearman, file.path("output", "tables", "correlation_matrix_spearman.csv"))

# Lower triangle (including the diagonal), outcome in the top row.
labels <- unname(VARS)
k <- length(VARS)
cor_long <- expand.grid(row = seq_len(k), col = seq_len(k)) %>%
  filter(row >= col) %>%
  mutate(r = cor_pearson[cbind(row, col)],
         x = factor(labels[col], levels = labels),
         y = factor(labels[row], levels = rev(labels)),
         dark = abs(r) >= 0.6)

cor_plot <- ggplot(cor_long, aes(x = x, y = y, fill = r)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.2f", r), colour = dark), size = 3.6) +
  scale_fill_gradient2(low = "#B2182B", mid = "white", high = "#2166AC",
                       midpoint = 0, limits = c(-1, 1), name = "Pearson r") +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "grey15"), guide = "none") +
  coord_fixed() +
  labs(title = "Correlations between life expectancy and the predictors",
       subtitle = sprintf("Pearson r, main dataset: %s country-years, %d countries, %d-%d",
                          format(nrow(wdi), big.mark = ","), n_distinct(wdi$iso3c),
                          min(wdi$year), max(wdi$year)),
       caption = "GDP per capita and population on the natural-log scale. Source: World Bank WDI.",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1),
        panel.grid = element_blank(),
        plot.subtitle = element_text(size = 9, colour = "grey30"),
        plot.caption  = element_text(size = 8, colour = "grey40"))

path <- file.path("output", "figures", "correlation_matrix.png")
ggsave(path, cor_plot, width = 7, height = 6, dpi = 300, bg = "white")
message("Saved ", path)

message("\nCorrelation with life expectancy (Pearson / Spearman):")
print(round(cbind(pearson = cor_pearson[-1, "life_exp"], spearman = cor_spearman[-1, "life_exp"]), 2))
