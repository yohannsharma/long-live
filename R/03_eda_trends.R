# 03_eda_trends.R
# Life expectancy over 2000-2019 by region and by income group (issue #6).
#
# Mean life expectancy per year, one line per group, for the 127 countries in
# the main dataset.
#
# Why life expectancy comes from the raw download, not wdi_clean.rds: the
# cleaned panel keeps only years where every predictor is available, so the
# set of countries changes from year to year (83 countries in 2000, about 125
# in 2003-2015, 106 in 2019). In 2000, 33 high-income countries are missing
# because their secondary enrollment isn't reported. A mean over whichever
# countries happen to be present would jump for reasons that have nothing to
# do with life expectancy. Life expectancy itself is reported for all 127 countries in
# every year, so the raw values give the same countries every year and the
# lines show real change. Region and income group come from wdi_clean.rds.
#
# North America is only Canada in the main dataset and is labelled so.
#
# Input:  data/processed/wdi_clean.rds  (which countries, region, income group)
#         data/raw/wdi_raw.csv          (life expectancy, every year)
# Output: output/figures/life_exp_trend_income.png
#         output/figures/life_exp_trend_region.png
#         output/figures/life_exp_trends.png        (both side by side)
#         output/tables/life_exp_trends.csv         (the plotted means)
# After sourcing, `trends` (the plotted table) and `trend_plots` are left in
# the environment for checking.
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(dplyr)
library(readr)
library(ggplot2)
library(patchwork)

YEARS <- 2000:2019

clean_path <- file.path("data", "processed", "wdi_clean.rds")
raw_path   <- file.path("data", "raw", "wdi_raw.csv")
if (!file.exists(clean_path)) stop("Run R/02_clean_wdi.R first: ", clean_path, " not found.")
if (!file.exists(raw_path))   stop("Run R/01_download_wdi.R first: ", raw_path, " not found.")

countries <- readRDS(clean_path) %>% distinct(iso3c, country, region, income)
if (anyDuplicated(countries$iso3c)) stop("A country has more than one region or income group.")

le <- read_csv(raw_path, show_col_types = FALSE) %>%
  filter(iso3c %in% countries$iso3c, year %in% YEARS) %>%
  select(iso3c, year, life_exp) %>%
  inner_join(select(countries, iso3c, region, income), by = "iso3c")

n_missing <- sum(is.na(le$life_exp)) + (nrow(countries) * length(YEARS) - nrow(le))
if (n_missing > 0) {
  warning(n_missing, " country-years lack life expectancy; yearly means use the countries available.")
}

dir.create(file.path("output", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("output", "tables"),  recursive = TRUE, showWarnings = FALSE)

# Mean per group and year. Labels carry the number of countries.
group_trend <- function(var) {
  le %>%
    group_by(grouping = var, group = as.character(.data[[var]]), year) %>%
    summarise(mean_life_exp = mean(life_exp, na.rm = TRUE),
              n_countries = sum(!is.na(life_exp)), .groups = "drop") %>%
    group_by(group) %>%
    mutate(label = if (group[1] == "North America") "North America (Canada only)"
                   else sprintf("%s (%d)", group[1], max(n_countries))) %>%
    ungroup()
}
trends <- bind_rows(group_trend("income"), group_trend("region"))

write_csv(mutate(trends, mean_life_exp = round(mean_life_exp, 2)),
          file.path("output", "tables", "life_exp_trends.csv"))
message("Saved output/tables/life_exp_trends.csv")

# Legend in the same top-to-bottom order as the lines in 2019.
order_by_last_year <- function(d) {
  last <- d %>% filter(year == max(year)) %>% arrange(desc(mean_life_exp))
  mutate(d, label = factor(label, levels = last$label))
}

# Okabe-Ito colours (colour-blind safe), minus yellow, which is hard to see on white.
REGION_COLOURS <- c(
  "East Asia & Pacific"                                = "#E69F00",
  "Europe & Central Asia"                              = "#0072B2",
  "Latin America & Caribbean"                          = "#009E73",
  "Middle East, North Africa, Afghanistan & Pakistan"  = "#CC79A7",
  "North America"                                      = "#000000",
  "South Asia"                                         = "#56B4E9",
  "Sub-Saharan Africa"                                 = "#D55E00"
)

plot_trend <- function(d, title, colours) {
  ggplot(d, aes(x = year, y = mean_life_exp, colour = label)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 1.2) +
    colours +
    scale_x_continuous(breaks = seq(2000, 2020, 5), minor_breaks = YEARS) +
    labs(title = title, x = NULL, y = "Mean life expectancy (years)", colour = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "right", plot.title = element_text(face = "bold"),
          panel.grid.minor.y = element_blank())
}

income_d <- order_by_last_year(filter(trends, grouping == "income"))
region_d <- order_by_last_year(filter(trends, grouping == "region"))

region_cols <- setNames(REGION_COLOURS[as.character(region_d$group[match(levels(region_d$label), region_d$label)])],
                        levels(region_d$label))

TREND_TITLES <- c(income = "By income group", region = "By region")
trend_plots <- list(
  income = plot_trend(income_d, TREND_TITLES[["income"]],
                      scale_colour_viridis_d(end = 0.85, direction = -1)),
  region = plot_trend(region_d, TREND_TITLES[["region"]], scale_colour_manual(values = region_cols))
)

subtitle <- sprintf("Mean across the %d countries in the main dataset, every year %d-%d (same countries each year). Countries per group in brackets.",
                    nrow(countries), min(YEARS), max(YEARS))
caption  <- "Income group is the World Bank's current classification. Source: World Bank WDI."
note <- theme(plot.subtitle = element_text(size = 8.5, colour = "grey30"),
              plot.caption  = element_text(size = 7.5, colour = "grey40"))

for (g in names(trend_plots)) {
  path <- file.path("output", "figures", paste0("life_exp_trend_", g, ".png"))
  p <- trend_plots[[g]] +
    labs(title = paste("Life expectancy, 2000-2019,", tolower(TREND_TITLES[[g]])),
         subtitle = subtitle, caption = caption) + note
  ggsave(path, p, width = 8, height = 4.5, dpi = 300, bg = "white")
  message("Saved ", path)
}

trend_plots$both <- (trend_plots$income | trend_plots$region) +
  plot_annotation(title = "Life expectancy, 2000-2019", subtitle = subtitle, caption = caption,
                  theme = theme(plot.title = element_text(size = 14, face = "bold")) + note)
path <- file.path("output", "figures", "life_exp_trends.png")
ggsave(path, trend_plots$both, width = 14, height = 5, dpi = 300, bg = "white")
message("Saved ", path)

message("\nChange in mean life expectancy, 2000 to 2019:")
print(trends %>%
        filter(year %in% range(YEARS)) %>%
        select(grouping, label, year, mean_life_exp) %>%
        tidyr::pivot_wider(names_from = year, values_from = mean_life_exp, names_prefix = "y") %>%
        mutate(change = round(y2019 - y2000, 1), y2000 = round(y2000, 1), y2019 = round(y2019, 1)),
      n = Inf)
