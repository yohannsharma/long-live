# 1. Load the required libraries
library(ggplot2)
library(tidyr)

# 2. Read CSV file
df_wide <- read.csv("output/tables/missingness_by_indicator_year.csv")

# 3. Pivot from wide to long format
df_long <- pivot_longer(df_wide, 
                        cols = -"year", 
                        names_to = "Predictor", 
                        values_to = "Value")

# 4. Create the heatmap
p <- ggplot(df_long, aes(x = year, y = Predictor, fill = Value)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c(option = "viridis") +
  coord_fixed() +
  theme_minimal() +
  labs(
    title = "Missing Predictor by Year",
    x = "Year",
    y = "Predictor",
    fill = "Missing (%)"
  ) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))

ggsave(
  filename = "output/figures/heatmap_missing.png", 
  plot = p, 
  width = 8, 
  height = 6, 
  dpi = 300
)