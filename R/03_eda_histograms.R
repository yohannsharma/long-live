# 03_eda_histograms.R
# Histograms of each variable in the main dataset (issue #3).
#
# One histogram per numeric variable, plus a log-scale version for the two
# heavily right-skewed ones (GDP per capita and population), since the models
# use log_gdp_pc and log_pop. A dashed line marks the median; the subtitle gives
# n, the median and the range. A combined panel of all histograms is also saved.
#
# The log-scale histograms put gdp_pc / population on a log10 axis, so the axis
# reads in dollars and people. The shape is identical to a histogram of
# log_gdp_pc / log_pop (natural log); only the axis labels differ.
#
# Uses every row of the main dataset (2000-2019, train and test). This is
# description only, so no model sees the test years through it.
#
# Region and income group are categorical, so they don't get histograms; their
# counts belong in the summary statistics table (issue #1).
#
# Input:  data/processed/wdi_clean.rds  (from 02_clean_wdi.R)
# Output: output/figures/hist_<variable>.png      (one per histogram, below)
#         output/figures/hist_all.png             (all histograms in one panel)
# After sourcing, `hist_plots` (named list of ggplot objects) and `hist_skew`
# (skewness table) are left in the environment for checking.
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

BINS     <- 30
FILL     <- "#3B75AF"
FIG_DIR  <- file.path("output", "figures")

clean_path <- file.path("data", "processed", "wdi_clean.rds")
if (!file.exists(clean_path)) stop("Run R/02_clean_wdi.R first: ", clean_path, " not found.")
wdi <- readRDS(clean_path)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

# Number formats for axes and subtitles.
fmt_years  <- label_number(accuracy = 0.1)
fmt_dollar <- label_number(accuracy = 1, prefix = "$", scale_cut = cut_short_scale())
fmt_pct    <- label_number(accuracy = 0.1, suffix = "%")
fmt_rate   <- label_number(accuracy = 0.1)
fmt_people <- label_number(accuracy = 0.1, scale_cut = cut_short_scale())

# One entry per histogram. `file` becomes output/figures/<file>.png.
HISTS <- list(
  list(file = "hist_life_exp",       column = "life_exp",   log_x = FALSE, fmt = fmt_years,
       title = "Life expectancy at birth",        x = "Years"),
  list(file = "hist_gdp_pc",         column = "gdp_pc",     log_x = FALSE, fmt = fmt_dollar,
       title = "GDP per capita",                  x = "Constant 2015 US$"),
  list(file = "hist_gdp_pc_log",     column = "gdp_pc",     log_x = TRUE,  fmt = fmt_dollar,
       title = "GDP per capita (log scale)",      x = "Constant 2015 US$, log scale"),
  list(file = "hist_sec_enroll",     column = "sec_enroll", log_x = FALSE, fmt = fmt_pct,
       title = "Secondary school enrollment",     x = "% gross (can exceed 100%)"),
  list(file = "hist_u5_mort",        column = "u5_mort",    log_x = FALSE, fmt = fmt_rate,
       title = "Under-5 mortality",               x = "Deaths per 1,000 live births"),
  list(file = "hist_population",     column = "population", log_x = FALSE, fmt = fmt_people,
       title = "Population",                      x = "People"),
  list(file = "hist_population_log", column = "population", log_x = TRUE,  fmt = fmt_people,
       title = "Population (log scale)",          x = "People, log scale")
)

missing_cols <- setdiff(vapply(HISTS, `[[`, "", "column"), names(wdi))
if (length(missing_cols)) stop("wdi_clean.rds lacks ", paste(missing_cols, collapse = ", "))

n_countries <- n_distinct(wdi$iso3c)

plot_hist <- function(h) {
  x   <- wdi[[h$column]]
  med <- median(x, na.rm = TRUE)
  subtitle <- sprintf("n = %s country-years, %d countries, %d-%d | median %s | range %s to %s",
                      comma(sum(!is.na(x))), n_countries, min(wdi$year), max(wdi$year),
                      h$fmt(med), h$fmt(min(x, na.rm = TRUE)), h$fmt(max(x, na.rm = TRUE)))

  p <- ggplot(wdi, aes(x = .data[[h$column]])) +
    geom_histogram(bins = BINS, fill = FILL, colour = "white") +
    geom_vline(xintercept = med, linetype = "dashed", colour = "grey20") +
    labs(title = h$title, subtitle = subtitle, x = h$x, y = "Country-years",
         caption = "Dashed line: median. Source: World Bank WDI, main dataset (wdi_clean.rds).") +
    theme_minimal(base_size = 11) +
    theme(plot.subtitle = element_text(size = 8.5, colour = "grey30"),
          plot.caption  = element_text(size = 7.5, colour = "grey40"),
          panel.grid.minor = element_blank())

  if (h$log_x) {
    p + scale_x_log10(labels = h$fmt, breaks = breaks_log(n = 6))
  } else {
    p + scale_x_continuous(labels = h$fmt, breaks = breaks_extended(n = 6))
  }
}

hist_plots <- setNames(lapply(HISTS, plot_hist), vapply(HISTS, `[[`, "", "file"))

for (name in names(hist_plots)) {
  path <- file.path(FIG_DIR, paste0(name, ".png"))
  ggsave(path, hist_plots[[name]], width = 6.5, height = 4, dpi = 300, bg = "white")
  message("Saved ", path)
}

# Combined panel ---------------------------------------------------------------
# facet_wrap can't give individual panels a log axis, so the log panels plot
# log10 of the value and say so in the panel title.
panel_titles <- vapply(HISTS, function(h) {
  if (h$log_x) paste0(sub(" \\(log scale\\)", "", h$title), " (log10)") else h$title
}, "")

panel_data <- bind_rows(lapply(seq_along(HISTS), function(i) {
  h <- HISTS[[i]]
  v <- wdi[[h$column]]
  tibble(panel = panel_titles[i], value = if (h$log_x) log10(v) else v)
})) %>%
  mutate(panel = factor(panel, levels = panel_titles))

panel_medians <- panel_data %>%
  group_by(panel) %>%
  summarise(median = median(value, na.rm = TRUE), .groups = "drop")

hist_all <- ggplot(panel_data, aes(x = value)) +
  geom_histogram(bins = BINS, fill = FILL, colour = "white") +
  geom_vline(data = panel_medians, aes(xintercept = median), linetype = "dashed", colour = "grey20") +
  facet_wrap(~ panel, scales = "free", ncol = 3) +
  labs(title = "Distribution of each variable",
       subtitle = sprintf("Main dataset: %s country-years, %d countries, %d-%d. Dashed line: median.",
                          comma(nrow(wdi)), n_countries, min(wdi$year), max(wdi$year)),
       x = NULL, y = "Country-years") +
  theme_minimal(base_size = 10) +
  theme(strip.text = element_text(face = "bold"), panel.grid.minor = element_blank())

hist_plots$hist_all <- hist_all
path <- file.path(FIG_DIR, "hist_all.png")
ggsave(path, hist_all, width = 10, height = 8, dpi = 300, bg = "white")
message("Saved ", path)

# Skewness, for the written interpretation ---------------------------------------
# > 1 or < -1 is strongly skewed; near 0 is roughly symmetric.
skewness <- function(x) {
  x <- x[!is.na(x)]
  mean((x - mean(x))^3) / mean((x - mean(x))^2)^1.5
}
hist_skew <- tibble(
  histogram = names(hist_plots)[seq_along(HISTS)],
  skewness  = round(vapply(HISTS, function(h) {
    v <- wdi[[h$column]]
    skewness(if (h$log_x) log(v) else v)
  }, numeric(1)), 2)
)
message("\nSkewness of each histogram (log versions computed on the log scale):")
print(hist_skew)
