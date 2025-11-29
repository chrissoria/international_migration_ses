# US International SES - Code Documentation

This project analyzes socioeconomic status among older adult (60+) Hispanic immigrants in the US compared to their origin countries.

## Workflow Overview

All data preparation happens in **Stata**, and all analysis, tables, and plots are generated in **R**.

```
Raw Data → Stata (prep) → Processed .dta files → R (analysis) → Tables/Plots/Regressions
```

---

## Stata Preprocessing (`stata_prep/`)

Run these files in order:

| Order | File | Description |
|-------|------|-------------|
| 1 | `00_process_data.do` | Processes raw IPUMS data (US ACS 2010/2020, US Census 2010, International censuses). Creates derived variables for age groups, education, immigration status, race/ethnicity, household composition, etc. |
| 2 | `01_create_weights.do` | Creates age standardization weights using US 2010 Census Hispanics 60+ as the reference population. Weights are saved to `data/weights/`. |
| 3 | `02_apply_weights.do` | Applies age standardization weights to all processed datasets, adding `perwt_age_standardized` variable. |
| - | `hispanic_immigrant_count.do` | Standalone script that generates Hispanic immigrant counts by country of origin for background/context. |

### Output Files (saved to `data/`)
- `US_2010_v100.dta` - US ACS 2010
- `US_2020_v100.dta` - US ACS 2020
- `US_2010_v100_census.dta` - US Census 2010 (international IPUMS format)
- `CuDrMePrUs_10_12.dta` - Combined international data (Cuba, DR, Mexico, Puerto Rico)
- `weights/` - Age standardization weight files

### Age Standardization
All datasets are standardized to the age distribution of **US 2010 Census Hispanics 60+** (by sex). This allows valid comparisons across:
- Different countries of origin
- Different survey years (2010 vs 2020)
- US immigrants vs origin country populations

---

## R Analysis (`r_analysis/`)

Run these files after Stata preprocessing is complete:

| Order | File | Description |
|-------|------|-------------|
| 1 | `01_background_data.Rmd` | Processes background indicators (GDP, life expectancy, infant mortality) and creates Table 1. |
| 2 | `02_tables.Rmd` | Generates all summary tables comparing demographic characteristics across groups. Uses helper functions from `helpers/table_functions.R`. |
| 3 | `03_regressions.Rmd` | Runs regression analyses. |
| 4 | `04_plots.Rmd` | Creates visualization plots (non-regression based). |
| 5 | `05_regression_plots.Rmd` | Creates plots based on regression outputs. |
| - | `99_read_with_R.Rmd` | Alternative R-based data processing (reference only, Stata is primary). |
| - | `tables.Rmd` | Legacy tables file (superseded by `02_tables.Rmd`). |

### Helper Files (`r_analysis/helpers/`)
- `table_functions.R` - Reusable functions for creating summary tables, formatting, and LaTeX export.

### Output Locations
- Tables: `tables/` (Excel) and `tables/r_tables/` (LaTeX)
- Plots: `plots/`

---

## Data Requirements

### Raw Input Files (in `data/`)
- `usa_00007.dta` - US ACS 2010 and 2020 combined (filter by `sample`)
- `ipumsi_00002_US_2010.dta` - US Census 2010 (international IPUMS format)
- `ses_v2.dta` - International census data (Cuba, DR, Mexico, Puerto Rico, etc.)
- `gdp_per_capita.xlsx` - GDP data
- `e60.csv` - Life expectancy at 60
- `IMR/` - Infant mortality rate files

---

## Key Variables

| Variable | Description |
|----------|-------------|
| `perwt` | Original person weight |
| `perwt_age_standardized` | Age-standardized weight (use for cross-group comparisons) |
| `country_string` | Country of birth |
| `hispan_string` | Hispanic status |
| `age_groups` | Age categories (60-69, 70-79, 80-89, 90+) |
| `less_than_primary_completed` | Education: less than primary |
| `primary_completed` | Education: primary |
| `secondary_completed` | Education: secondary |
| `university_completed` | Education: university |
| `married_cohab` | Married or cohabiting |
| `lives_alone` | Lives alone |
| `age_at_immigration` | Age when immigrated to US |
| `english_speaker` | Speaks English |
| `is_naturalized_citizen` | Naturalized US citizen |
