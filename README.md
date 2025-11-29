# Caribbean Hispanic Sociodemographic Heterogeneity: Comparing Older Adults by Country and U.S. Migration Status

## Authors

**William H. Dow, PhD** (Corresponding author)
University of California, Berkeley
wdow@berkeley.edu

**Chris Soria, MA**
University of California, Berkeley
chrissoria@berkeley.edu

**Henry T. Dow**
University of California, Berkeley
htdow@berkeley.edu

**Date:** March 31, 2025

---

## Project Overview

This project analyzes socioeconomic status and demographic characteristics among older adult (60+) Hispanic immigrants in the U.S. compared to their origin countries. The analysis focuses on four main origin countries: Mexico, Cuba, Dominican Republic, and Puerto Rico.

## Repository Structure

```
us_international_ses/
├── code/
│   ├── stata_prep/        # Stata data preprocessing scripts
│   ├── r_analysis/        # R analysis and table generation
│   │   └── helpers/       # R helper functions
│   └── README.md          # Code documentation
├── data/                  # Raw and processed data files
│   └── weights/           # Age standardization weight files
├── tables/                # Output tables (Excel)
│   └── r_tables/          # Output tables (LaTeX)
└── plots/                 # Output visualizations
```

## Workflow

All data preparation happens in **Stata**, and all analysis, tables, and plots are generated in **R**.

```
Raw Data → Stata (prep) → Processed .dta files → R (analysis) → Tables/Plots
```

### Stata Preprocessing (`code/stata_prep/`)

Run these files in order:

| Order | File | Description |
|-------|------|-------------|
| 1 | `00_process_data.do` | Processes raw IPUMS data, creates derived variables |
| 2 | `01_create_weights.do` | Creates age standardization weights using US 2010 Census Hispanics 60+ |
| 3 | `02_apply_weights.do` | Applies age standardization weights to all datasets |

### R Analysis (`code/r_analysis/`)

Run these files after Stata preprocessing:

| Order | File | Description |
|-------|------|-------------|
| 1 | `01_background_data.Rmd` | Background indicators and Table 1 |
| 2 | `02_tables.Rmd` | All summary tables (Tables 2-3, Supplemental Tables 1-8) |
| 3 | `03_regressions.Rmd` | Regression analyses |
| 4 | `04_plots.Rmd` | Visualization plots |
| 5 | `05_regression_plots.Rmd` | Regression-based plots |

## Tables

### Main Tables

| Table | Description | Weights |
|-------|-------------|---------|
| Table 1 | Hispanic Immigrants Ages 60+ Living in US (2016-2020), and Birth Country Demographic Indicators | Original (perwt) |
| Table 2 | Sociodemographic Comparison of Hispanics Ages 60+ in the U.S. by Birth Country (2016-20 ACS) | Original (perwt) |
| Table 3 | Sociodemographic Comparison of Hispanics Ages 60+ by Birth Country: Non-Migrants versus US Immigrants (~2010) | Original (perwt) |

### Supplemental Tables

| Table | Description | Weights |
|-------|-------------|---------|
| Supplemental Table 1 | Sociodemographic Comparison by Birth Country (2016-20 ACS): Females | Original (perwt) |
| Supplemental Table 2 | Sociodemographic Comparison by Birth Country (2016-20 ACS): Males | Original (perwt) |
| Supplemental Table 3 | Sociodemographic Comparison by Birth Country (2008-10 ACS) | Original (perwt) |
| Supplemental Table 4 | Sociodemographic Comparison by Birth Country (2016-20 ACS): Migrated After Age 24 | Original (perwt) |
| Supplemental Table 5 | Age-Standardized Sociodemographic Comparison by Birth Country (~2010) | Age-standardized (except age groups) |
| Supplemental Table 6 | Summary Statistics by Country and Sex, Comparing 2010 versus 2020 | Age-standardized |
| Supplemental Table 7 | Changing Educational Attainment of the 1930-1950 Birth Cohort due to Selection: 2010 versus 2020 | Original (perwt) |
| Supplemental Table 8 | Alternative Education Comparison (2016-20 ACS), Defining Completed Primary as 5+ Years | Original (perwt) |

## Age Standardization

All datasets can be standardized to the age distribution of **US 2010 Census Hispanics 60+** (by sex). This allows valid comparisons across:
- Different countries of origin
- Different survey years (2010 vs 2020)
- US immigrants vs origin country populations

The `perwt_age_standardized` variable is calculated as:
```
perwt_age_standardized = perwt * (reference_weight / group_weight)
```

## Data Sources

- **US ACS 2010 & 2020**: IPUMS USA
- **US Census 2010**: IPUMS International format
- **International Censuses**: Cuba, Dominican Republic, Mexico, Puerto Rico (~2010)
- **Background Indicators**: GDP per capita, life expectancy at 60, infant mortality rates

## Requirements

### Stata
- Version 14 or higher

### R Packages
- `tidyverse`, `haven`, `here`
- `xtable`, `kableExtra`, `writexl`
- Additional packages as specified in each .Rmd file

## Contact

For questions about this project, please contact William H. Dow at wdow@berkeley.edu.
