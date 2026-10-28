# 01_download_wdi.R
# Download the outcome and predictor indicators from the World Bank WDI API
# for all countries, 2000-2019, along with country metadata (region, income).
#
# Output: data/raw/wdi_raw.csv
# Run from the project root (open Long-Live-Humanity.Rproj in RStudio).

library(WDI)
library(readr)

START_YEAR <- 2000
END_YEAR   <- 2019

# Named vector: names become the column names in the downloaded data.
INDICATORS <- c(
  life_exp   = "SP.DYN.LE00.IN",   # Life expectancy at birth, total (years) - OUTCOME
  gdp_pc     = "NY.GDP.PCAP.KD",   # GDP per capita (constant 2015 US$)
  sec_enroll = "SE.SEC.ENRR",      # School enrollment, secondary (% gross)
  prim_enroll = "SE.PRM.ENRR",     # School enrollment, primary (% gross) - better-covered fallback
  u5_mort    = "SH.DYN.MORT",      # Mortality rate, under-5 (per 1,000 live births)
  population = "SP.POP.TOTL"       # Population, total
)

raw_path <- file.path("data", "raw", "wdi_raw.csv")

# Set FORCE_DOWNLOAD <- TRUE to re-pull from the API even if a cached file exists.
FORCE_DOWNLOAD <- FALSE

if (file.exists(raw_path) && !FORCE_DOWNLOAD) {
  message("Raw file already exists at ", raw_path, " - skipping download.")
} else {
  message("Downloading ", length(INDICATORS), " indicators for ",
          START_YEAR, "-", END_YEAR, " ...")

  wdi_raw <- WDI(
    country   = "all",
    indicator = INDICATORS,
    start     = START_YEAR,
    end       = END_YEAR,
    extra     = TRUE   # adds iso3c, region, income, capital, lat/long, lending
  )

  dir.create(dirname(raw_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(wdi_raw, raw_path)
  message("Saved ", nrow(wdi_raw), " rows to ", raw_path)
}
