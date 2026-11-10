# 03_eda_scatter.R
# Scatterplots of each predictor against life expectancy (issue #5).
#
# One panel per numeric predictor: GDP per capita and population on a log10
# axis (the models use their logs), secondary enrollment, under-5 mortality
# and year. Points are coloured by income group; the black line is a loess
# smoother over all points. Each panel title gives Pearson r with life
# expectancy (on the log scale for the log-axis panels, matching
# R/03_eda_correlation.R).
#
# Under-5 mortality stays on its raw axis because the models use it raw: the
# bend in the smoother shows the relationship is not linear on that scale.
#
# Uses every row of the main dataset (2000-2019). Description only.
#
# Input:  data/processed/wdi_clean.rds  (from 02_clean_wdi.R)
# Output: output/figures/scatter_predictors.png      (all panels + legend)
#         output/figures/scatter_<column>.png        (one per predictor)
# After sourcing, `scatter_plots` (named list of ggplot objects) is left in the
# environment for checking.
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(ggplot2)
library(scales)
library(patchwork)

FIG_DIR <- file.path("output", "figures")

clean_path <- file.path("data", "processed", "wdi_clean.rds")
if (!file.exists(clean_path)) stop("Run R/02_clean_wdi.R first: ", clean_path, " not found.")
wdi <- readRDS(clean_path)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

PREDICTORS <- list(
  list(column = "gdp_pc",     log_x = TRUE,  title = "GDP per capita",
       x = "Constant 2015 US$ (log scale)",
       fmt = label_number(accuracy = 1, prefix = "$", scale_cut = cut_short_scale())),
  list(column = "sec_enroll", log_x = FALSE, title = "Secondary enrollment",
       x = "% gross",
       fmt = label_number(accuracy = 1, suffix = "%")),
  list(column = "u5_mort",    log_x = FALSE, title = "Under-5 mortality",
       x = "Deaths per 1,000 live births",
       fmt = label_number(accuracy = 1)),
  list(column = "population", log_x = TRUE,  title = "Population",
       x = "People (log scale)",
       fmt = label_number(accuracy = 1, scale_cut = cut_short_scale())),
  list(column = "year",       log_x = FALSE, title = "Year",
       x = "Year",
       fmt = label_number(accuracy = 1, big.mark = ""))
)

# Income groups, low to high: dark purple (low) to yellow-green (high).
income_scale <- scale_colour_viridis_d(name = "Income group", end = 0.85, drop = FALSE)

plot_scatter <- function(p) {
  x <- wdi[[p$column]]
  r <- cor(if (p$log_x) log(x) else x, wdi$life_exp)

  g <- ggplot(wdi, aes(x = .data[[p$column]], y = life_exp)) +
    geom_point(aes(colour = income), alpha = 0.35, size = 0.8) +
    geom_smooth(method = "loess", formula = y ~ x, se = FALSE, colour = "black") +
    income_scale +
    guides(colour = guide_legend(override.aes = list(alpha = 1, size = 3))) +
    labs(title = sprintf("%s (r = %.2f)", p$title, r), x = p$x, y = "Life expectancy (years)") +
    theme_minimal(base_size = 10) +
    theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold", size = 10.5))

  if (p$log_x) {
    g + scale_x_log10(labels = p$fmt, breaks = breaks_log(n = 6))
  } else {
    g + scale_x_continuous(labels = p$fmt, breaks = breaks_extended(n = 6))
  }
}

scatter_plots <- setNames(lapply(PREDICTORS, plot_scatter), vapply(PREDICTORS, `[[`, "", "column"))

subtitle <- sprintf("Main dataset: %s country-years, %d countries, %d-%d. Black line: loess smoother over all points.",
                    format(nrow(wdi), big.mark = ","), n_distinct(wdi$iso3c), min(wdi$year), max(wdi$year))
caption  <- "r = Pearson correlation with life expectancy (log scale for GDP and population). Source: World Bank WDI."

# One file per predictor, legend underneath.
for (name in names(scatter_plots)) {
  path <- file.path(FIG_DIR, paste0("scatter_", name, ".png"))
  single <- scatter_plots[[name]] +
    labs(subtitle = subtitle, caption = caption) +
    theme(legend.position = "bottom",
          plot.subtitle = element_text(size = 8, colour = "grey30"),
          plot.caption  = element_text(size = 7.5, colour = "grey40"))
  ggsave(path, single, width = 6.5, height = 4.5, dpi = 300, bg = "white")
  message("Saved ", path)
}

# All panels; the shared legend fills the sixth slot.
scatter_all <- wrap_plots(c(scatter_plots, list(guide_area())), ncol = 3) +
  plot_layout(guides = "collect") +
  plot_annotation(
    title = "Life expectancy against each predictor",
    subtitle = subtitle, caption = caption,
    theme = theme(plot.title = element_text(size = 14, face = "bold"),
                  plot.subtitle = element_text(size = 9.5, colour = "grey30"),
                  plot.caption  = element_text(size = 8, colour = "grey40"))
  )
scatter_plots$scatter_predictors <- scatter_all

path <- file.path(FIG_DIR, "scatter_predictors.png")
ggsave(path, scatter_all, width = 12, height = 7.5, dpi = 300, bg = "white")
message("Saved ", path)
