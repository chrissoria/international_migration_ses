#' Table Helper Functions
#'
#' This file contains reusable functions for creating summary tables
#' in the US International SES project.
#'
#' Usage: source("helpers/table_functions.R")

# ==============================================================================
# VARIABLE RECODE MAPS
# ==============================================================================

# Full recode: all variables including immigration and cognitive
variable_recode_full <- c(
  mean_age_60_69 = "60 - 69",
  mean_age_70_79 = "70 - 79",
  mean_age_80_89 = "80 - 89",
  mean_age_90plus = "90 plus",
  mean_married_cohab = "Married/Cohabiting",
  mean_hhsize = "Household Size",
  mean_lives_alone = "Lives Alone",
  mean_has_child_in_hh = "Lives with Child",
  mean_english_speaker = "English Speakers",
  mean_is_citizen = "Citizen",
  mean_age_at_immigration_15 = "Less than 15",
  mean_age_at_immigration_15to24 = "15 - 24",
  mean_age_at_immigration_25to49 = "25 - 49",
  mean_age_at_immigration_50plus = "50 and Above",
  mean_years_in_us = "Years in US",
  mean_less_than_primary_completed = "Less than Primary",
  mean_primary_completed = "Primary",
  mean_secondary_completed = "Secondary",
  mean_university_completed = "University",
  mean_yrimm_before1965 = "Before 1965",
  mean_yrimm_1965_1979 = "1965 - 1979",
  mean_yrimm_1980_1999 = "1980 - 1999",
  mean_yrimm_2000plus = "After 1999",
  mean_cog_difficulty = "Cognitive Difficulty",
  mean_ind_live_difficulty = "Independence Difficulty"
)

# Basic recode: age, education, household (for international comparisons without immigration vars)
variable_recode_basic <- c(
  mean_age_60_69 = "60 - 69",
  mean_age_70_79 = "70 - 79",
  mean_age_80_89 = "80 - 89",
  mean_age_90plus = "90 plus",
  mean_less_than_primary_completed = "Less than Primary",
  mean_primary_completed = "Primary",
  mean_secondary_completed = "Secondary",
  mean_university_completed = "University",
  mean_hhsize = "Household Size",
  mean_lives_alone = "Lives Alone",
  mean_has_child_in_hh = "Lives with Child",
  mean_married_cohab = "Married/Cohabiting"
)

# Education only recode
variable_recode_education <- c(
  mean_less_than_primary_completed = "Less than Primary",
  mean_primary_completed = "Primary",
  mean_secondary_completed = "Secondary",
  mean_university_completed = "University"
)

# ==============================================================================
# TABLE HEADERS
# ==============================================================================

# Standard headers for US comparison tables
us_table_headers <- list(
  "Age" = 1,
  "Education Completed" = 6,
  "Household" = 11,
  "Age Migrated" = 16,
  "Migration Cohort" = 21,
  "Acculturation" = 26
)

# Standard headers for international comparison tables
intl_table_headers <- list(
  "Age" = 1,
  "Education Completed" = 6,
  "Household" = 11
)

# ==============================================================================
# CONSTANTS
# ==============================================================================

# Main countries of interest
main_countries <- c("mexico", "puerto rico", "dominican republic", "cuba")

# ==============================================================================
# CORE SUMMARY FUNCTIONS
# ==============================================================================

#' Calculate weighted summary statistics
#'
#' @param df Data frame to summarize
#' @param group_var Variable to group by
#' @param weight_var Weight variable (default: "perwt")
#' @param include_immigration Include immigration-related variables
#' @param include_cognitive Include cognitive difficulty variables
#' @return Data frame with weighted means by group
calculate_weighted_summary <- function(df, group_var, weight_var = "perwt",
                                       include_immigration = TRUE,
                                       include_cognitive = FALSE) {

  base_vars <- list(
    mean_age_60_69 = "age_60to69",
    mean_age_70_79 = "age_70to79",
    mean_age_80_89 = "age_80to89",
    mean_age_90plus = "age_90plus",
    mean_less_than_primary_completed = "less_than_primary_completed",
    mean_primary_completed = "primary_completed",
    mean_secondary_completed = "secondary_completed",
    mean_university_completed = "university_completed",
    mean_hhsize = "famsize",
    mean_lives_alone = "lives_alone",
    mean_has_child_in_hh = "child_in_household",
    mean_married_cohab = "married_cohab"
  )

  immigration_vars <- list(
    mean_age_at_immigration_15 = "age_at_immigration_under15",
    mean_age_at_immigration_15to24 = "age_at_immigration_15to24",
    mean_age_at_immigration_25to49 = "age_at_immigration_25to49",
    mean_age_at_immigration_50plus = "age_at_immigration_50plus",
    mean_yrimm_before1965 = "yrimm_before1965",
    mean_yrimm_1965_1979 = "yrimm_1965to1980",
    mean_yrimm_1980_1999 = "yrimm_1980to1999",
    mean_yrimm_2000plus = "yrimm_2000plus",
    mean_is_citizen = "is_naturalized_citizen",
    mean_english_speaker = "english_speaker"
  )

  cognitive_vars <- list(
    mean_cog_difficulty = "cognitive_difficulty",
    mean_ind_live_difficulty = "independent_living_difficulty"
  )

  all_vars <- base_vars
  if (include_immigration) all_vars <- c(all_vars, immigration_vars)
  if (include_cognitive) all_vars <- c(all_vars, cognitive_vars)

  # Build summarise expressions dynamically
  summary_exprs <- lapply(names(all_vars), function(name) {
    var <- all_vars[[name]]
    rlang::expr(weighted.mean(!!rlang::sym(var), !!rlang::sym(weight_var), na.rm = TRUE))
  })
  names(summary_exprs) <- names(all_vars)
  summary_exprs$N <- rlang::expr(n())

  df %>%
    dplyr::group_by(!!rlang::sym(group_var)) %>%
    dplyr::summarise(!!!summary_exprs, .groups = "drop")
}

#' Pivot and recode summary table
#'
#' @param df Data frame to pivot
#' @param group_var Variable that was grouped by
#' @param recode_map Named vector for recoding variable names
#' @return Pivoted and recoded data frame
pivot_and_recode <- function(df, group_var, recode_map = variable_recode_full) {
  df %>%
    tidyr::pivot_longer(cols = -dplyr::all_of(group_var), names_to = "variable", values_to = "value") %>%
    tidyr::pivot_wider(names_from = dplyr::all_of(group_var), values_from = value) %>%
    dplyr::mutate(variable = dplyr::recode(variable, !!!recode_map))
}

#' Format table for output
#'
#' @param df Data frame to format
#' @param digits Number of digits for rounding
#' @return Formatted data frame with rounded values and NaN/0 handling
format_table <- function(df, digits = 2) {
  df %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~round(., digits))) %>%
    dplyr::mutate(dplyr::across(everything(), as.character)) %>%
    dplyr::mutate(dplyr::across(everything(), ~ifelse(. == "NaN", "-", .))) %>%
    dplyr::mutate(dplyr::across(everything(), ~ifelse(. == "0", "-", .)))
}

#' Create complete summary table for a filtered dataset
#'
#' @param df Data frame to summarize
#' @param group_var Variable to group by
#' @param weight_var Weight variable (default: "perwt")
#' @param include_immigration Include immigration-related variables
#' @param include_cognitive Include cognitive difficulty variables
#' @param recode_map Named vector for recoding variable names
#' @return Formatted summary table
create_summary_table <- function(df, group_var, weight_var = "perwt",
                                 include_immigration = TRUE,
                                 include_cognitive = FALSE,
                                 recode_map = variable_recode_full) {
  df %>%
    calculate_weighted_summary(group_var, weight_var, include_immigration, include_cognitive) %>%
    pivot_and_recode(group_var, recode_map)
}

# ==============================================================================
# LATEX EXPORT FUNCTIONS
# ==============================================================================

# LaTeX row width adjustments
latex_adjustments <- list(
  list(rows = c("60 - 69", "70 - 79", "80 - 89", "90 plus"), width = 1.5),
  list(rows = c("Less than Primary"), width = 3.2),
  list(rows = c("Primary"), width = 1.7),
  list(rows = c("Secondary", "University"), width = 2),
  list(rows = c("Less than 15"), width = 2.4),
  list(rows = c("50 and Above"), width = 2.6),
  list(rows = c("15 - 24", "25 - 49", "Citizen"), width = 1.6),
  list(rows = c("Lives with Child"), width = 2.9),
  list(rows = c("Before 1965"), width = 2.3),
  list(rows = c("1965 - 1979", "1980 - 1999", "Lives Alone"), width = 2.2),
  list(rows = c("After 1999"), width = 2.1),
  list(rows = c("Household Size"), width = 2.7),
  list(rows = c("English Speakers"), width = 3.0),
  list(rows = c("Married/Cohabiting"), width = 3.4)
)

#' Adjust LaTeX row formatting
#'
#' @param latex_code Vector of LaTeX code lines
#' @param adjustments List of row adjustments
#' @return Modified LaTeX code
adjust_latex_rows <- function(latex_code, adjustments = latex_adjustments) {
  for (adjustment in adjustments) {
    for (row in adjustment$rows) {
      row_index <- grep(paste0("^\\s*", row), latex_code)
      if (length(row_index) > 0) {
        latex_code[row_index] <- gsub(
          "^(\\s*)(.*?)(&.*)",
          sprintf("\\1\\\\multicolumn{1}{>{\\\\raggedleft\\\\arraybackslash}p{%scm}|}{\\\\makebox[%scm][r]{\\2}}\\3",
                  adjustment$width, adjustment$width),
          latex_code[row_index]
        )
      }
    }
  }
  return(latex_code)
}

#' Export table to both Excel and LaTeX
#'
#' @param df Data frame to export
#' @param excel_path Path for Excel output
#' @param latex_path Path for LaTeX output (optional)
#' @param caption LaTeX table caption
#' @param align LaTeX column alignment
#' @param tabular_override Override for tabular environment
export_table <- function(df, excel_path, latex_path = NULL, caption = "",
                         align = NULL, tabular_override = NULL) {
  writexl::write_xlsx(df, excel_path)

  if (!is.null(latex_path)) {
    tbl <- xtable::xtable(df, caption = caption, align = align)
    latex_code <- capture.output(print(tbl, type = "latex", caption.placement = "top",
                                       size = "\\small", include.rownames = FALSE))

    if (!is.null(tabular_override)) {
      tabular_idx <- grep("\\\\begin\\{tabular\\}", latex_code)
      latex_code[tabular_idx] <- tabular_override
    }

    latex_code <- adjust_latex_rows(latex_code)
    writeLines(latex_code, latex_path)
  }
}

# ==============================================================================
# HEADER FUNCTIONS
# ==============================================================================

#' Add category header rows to formatted table
#'
#' @param df Data frame to modify
#' @param headers Named list of header positions (e.g., list("Age" = 1, "Education" = 6))
#' @return Data frame with header rows added
add_category_headers <- function(df, headers) {
  for (header in names(headers)) {
    pos <- headers[[header]]
    df <- df %>% tibble::add_row(Demographics = header, .before = pos)
    # Adjust subsequent positions
    headers <- lapply(headers, function(x) if(x > pos) x + 1 else x)
  }
  df
}

# ==============================================================================
# DATA LOADING HELPERS
# ==============================================================================

#' Add derived variables to US data
#'
#' @param df US ACS/Census data frame
#' @return Data frame with added cognitive and education variables
add_us_derived_vars <- function(df) {
  df %>%
    dplyr::mutate(
      cognitive_difficulty = dplyr::case_when(
        diffrem == 1 ~ 0, diffrem == 2 ~ 1, TRUE ~ NA_real_
      ),
      independent_living_difficulty = dplyr::case_when(
        diffmob == 1 ~ 0, diffmob == 2 ~ 1, TRUE ~ NA_real_
      ),
      independent_care_difficulty = dplyr::case_when(
        diffcare == 1 ~ 0, diffcare == 2 ~ 1, TRUE ~ NA_real_
      ),
      less_than_primary_completed_alt = dplyr::case_when(
        educd == 22 ~ 0, TRUE ~ less_than_primary_completed
      ),
      primary_completed_alt = dplyr::case_when(
        educd == 22 ~ 1, TRUE ~ primary_completed
      )
    )
}

# ==============================================================================
# SPECIALIZED TABLE FUNCTIONS
# ==============================================================================

# Recode for 25+ migrants (no under-15 or 15-24 age at immigration categories)
variable_recode_25plus <- c(
  mean_age_60_69 = "60 - 69",
  mean_age_70_79 = "70 - 79",
  mean_age_80_89 = "80 - 89",
  mean_age_90plus = "90 plus",
  mean_less_than_primary_completed = "Less than Primary",
  mean_primary_completed = "Primary",
  mean_secondary_completed = "Secondary",
  mean_university_completed = "University",
  mean_hhsize = "Household Size",
  mean_lives_alone = "Lives Alone",
  mean_has_child_in_hh = "Lives with Child",
  mean_married_cohab = "Married/Cohabiting",
  mean_age_at_immigration_25to49 = "25 - 49",
  mean_age_at_immigration_50plus = "50 and Above",
  mean_yrimm_before1965 = "Before 1965",
  mean_yrimm_1965_1979 = "1965 - 1979",
  mean_yrimm_1980_1999 = "1980 - 1999",
  mean_yrimm_2000plus = "After 1999",
  mean_is_citizen = "Citizen",
  mean_english_speaker = "English Speakers"
)

#' Create international comparison table by sex
#'
#' @param in_data International data frame
#' @param us_data US data frame
#' @param weight_var Weight variable (default: "perwt")
#' @return Formatted comparison table
create_intl_comparison_table <- function(in_data, us_data, weight_var = "perwt") {

  create_sex_table <- function(df, sex_val, group_var, wt = weight_var) {
    df %>%
      dplyr::filter(sex == sex_val) %>%
      create_summary_table(group_var, weight_var = wt,
                          include_immigration = FALSE,
                          recode_map = variable_recode_basic)
  }

  # International data by sex
  intl_female <- in_data %>%
    dplyr::filter(age != 999, !is.na(country_string)) %>%
    dplyr::filter(!country_year %in% c("Mexico_2020", "PR_2020", "US_2020")) %>%
    create_sex_table(2, "country_string")

  intl_male <- in_data %>%
    dplyr::filter(age != 999, !is.na(country_string)) %>%
    dplyr::filter(!country_year %in% c("Mexico_2020", "PR_2020", "US_2020")) %>%
    create_sex_table(1, "country_string")

  intl_combined <- dplyr::bind_rows(intl_female, intl_male) %>%
    format_table() %>%
    dplyr::rename(Demographics = variable)

  # US counterparts by sex
  us_female <- us_data %>%
    dplyr::filter(country_string %in% main_countries) %>%
    create_sex_table(2, "country_string")

  us_male <- us_data %>%
    dplyr::filter(country_string %in% main_countries) %>%
    create_sex_table(1, "country_string")

  us_combined <- dplyr::bind_rows(us_female, us_male) %>%
    format_table() %>%
    dplyr::select(-variable)

  # Combine
  result <- cbind(intl_combined, us_combined)

  # Rename columns that exist
  rename_map <- c(
    `US Mexican-born` = "mexico",
    `US Puerto-Rican-born` = "puerto rico",
    `US Dominican-born` = "dominican republic",
    `US Cuban-born` = "cuba",
    Cubans = "Cuba",
    Dominicans = "DR",
    Mexicans = "Mexico",
    `Puerto Ricans` = "PR"
  )

  for (new_name in names(rename_map)) {
    old_name <- rename_map[new_name]
    if (old_name %in% names(result)) {
      names(result)[names(result) == old_name] <- new_name
    }
  }

  # Remove US column if present (from international data)
  if ("US" %in% names(result)) {
    result <- result %>% dplyr::select(-US)
  }

  result %>%
    dplyr::select(Demographics, Mexicans, `US Mexican-born`,
           `Puerto Ricans`, `US Puerto-Rican-born`,
           Dominicans, `US Dominican-born`,
           Cubans, `US Cuban-born`)
}

#' Create sex-specific US comparison table
#'
#' @param df Data frame
#' @param sex_val Sex value (1 = male, 2 = female)
#' @param year_label Year label for output
#' @return Formatted sex-specific table
create_sex_specific_table <- function(df, sex_val, year_label) {

  sex_main <- df %>%
    dplyr::filter(country_string %in% main_countries, sex == sex_val) %>%
    create_summary_table("country_string", include_cognitive = FALSE)

  sex_migrant <- df %>%
    dplyr::filter(!country_string %in% main_countries, sex == sex_val) %>%
    dplyr::filter(!hispanic_category_migrant_status %in% c("native-born Not Latino")) %>%
    create_summary_table("hispanic_category_migrant_status", include_cognitive = FALSE) %>%
    dplyr::select(-variable)

  sex_native <- df %>%
    dplyr::filter(race_native_category %in% c(10, 11, 12), sex == sex_val) %>%
    create_summary_table("race_native_category", include_cognitive = FALSE) %>%
    dplyr::select(-variable) %>%
    dplyr::rename(Black = `10`, White = `11`, Other = `12`)

  result <- dplyr::bind_cols(sex_main, sex_migrant, sex_native) %>%
    format_table() %>%
    dplyr::select(variable, mexico, `puerto rico`, `dominican republic`, cuba,
           `foreign-born Central-American Latino`, `foreign-born Other Latino`,
           `foreign-born Not Latino`, `native-born Other Latino`, Black, White, Other) %>%
    dplyr::rename(
      Demographics = variable,
      `Dominican Republic` = `dominican republic`,
      Mexico = mexico,
      `Puerto Rico` = `puerto rico`,
      Cuba = cuba,
      `Central America` = `foreign-born Central-American Latino`,
      `Latin America` = `foreign-born Other Latino`,
      `Other Countries` = `foreign-born Not Latino`,
      Hispanic = `native-born Other Latino`
    )

  for (i in seq_along(us_table_headers)) {
    result <- result %>% tibble::add_row(Demographics = names(us_table_headers)[i],
                                  .before = us_table_headers[[i]] + (i - 1))
  }

  result
}

#' Create 2010 vs 2020 year comparison table
#'
#' @param in_data International data frame
#' @param us_2010 US 2010 data frame
#' @param us_2020 US 2020 data frame
#' @return Formatted year comparison table
create_year_comparison_table <- function(in_data, us_2010, us_2020) {

  create_sex_year_table <- function(df, sex_val, group_var) {
    df %>%
      dplyr::filter(sex == sex_val, !is.na(country_string)) %>%
      dplyr::filter(country_year %in% c("Mexico_2010", "Mexico_2020", "PR_2010", "PR_2020")) %>%
      create_summary_table(group_var, include_immigration = FALSE,
                          recode_map = variable_recode_basic)
  }

  create_us_table <- function(df, sex_val) {
    # Calculate overall US weighted means (not by country)
    df %>%
      dplyr::filter(sex == sex_val) %>%
      dplyr::summarise(
        mean_age_60_69 = weighted.mean(age_60to69, perwt, na.rm = TRUE),
        mean_age_70_79 = weighted.mean(age_70to79, perwt, na.rm = TRUE),
        mean_age_80_89 = weighted.mean(age_80to89, perwt, na.rm = TRUE),
        mean_age_90plus = weighted.mean(age_90plus, perwt, na.rm = TRUE),
        mean_less_than_primary_completed = weighted.mean(less_than_primary_completed, perwt, na.rm = TRUE),
        mean_primary_completed = weighted.mean(primary_completed, perwt, na.rm = TRUE),
        mean_secondary_completed = weighted.mean(secondary_completed, perwt, na.rm = TRUE),
        mean_university_completed = weighted.mean(university_completed, perwt, na.rm = TRUE),
        mean_hhsize = weighted.mean(famsize, perwt, na.rm = TRUE),
        mean_lives_alone = weighted.mean(lives_alone, perwt, na.rm = TRUE),
        mean_has_child_in_hh = weighted.mean(child_in_household, perwt, na.rm = TRUE),
        mean_married_cohab = weighted.mean(married_cohab, perwt, na.rm = TRUE),
        N = dplyr::n()
      ) %>%
      tidyr::pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
      dplyr::mutate(variable = dplyr::recode(variable, !!!variable_recode_basic))
  }

  intl_female <- create_sex_year_table(in_data, 2, "country_year")
  intl_male <- create_sex_year_table(in_data, 1, "country_year")
  intl_combined <- dplyr::bind_rows(intl_female, intl_male) %>% format_table()

  us_2010_female <- create_us_table(us_2010, 2) %>% dplyr::rename(US_2010 = value)
  us_2010_male <- create_us_table(us_2010, 1) %>% dplyr::rename(US_2010 = value)
  us_2010_combined <- dplyr::bind_rows(us_2010_female, us_2010_male) %>%
    format_table() %>% dplyr::select(-variable)

  us_2020_female <- create_us_table(us_2020, 2) %>% dplyr::rename(US_2020 = value)
  us_2020_male <- create_us_table(us_2020, 1) %>% dplyr::rename(US_2020 = value)
  us_2020_combined <- dplyr::bind_rows(us_2020_female, us_2020_male) %>%
    format_table() %>% dplyr::select(-variable)

  result <- dplyr::bind_cols(intl_combined, us_2010_combined, us_2020_combined) %>%
    dplyr::rename(
      Demographics = variable,
      `Mexico 2010` = Mexico_2010,
      `Mexico 2020` = Mexico_2020,
      `Puerto Rico 2010` = PR_2010,
      `Puerto Rico 2020` = PR_2020,
      `United States 2010` = US_2010,
      `United States 2020` = US_2020
    ) %>%
    dplyr::select(Demographics, `Mexico 2010`, `Mexico 2020`,
           `Puerto Rico 2010`, `Puerto Rico 2020`,
           `United States 2010`, `United States 2020`)

  result %>%
    tibble::add_row(Demographics = "Age", .before = 1) %>%
    tibble::add_row(Demographics = "Education Completed", .before = 6) %>%
    tibble::add_row(Demographics = "Household", .before = 11) %>%
    tibble::add_row(Demographics = "Age", .before = 17) %>%
    tibble::add_row(Demographics = "Education Completed", .before = 22) %>%
    tibble::add_row(Demographics = "Household", .before = 27) %>%
    dplyr::mutate(Gender = ifelse(dplyr::row_number() == 1, "Female",
                         ifelse(dplyr::row_number() == 17, "Male", ""))) %>%
    dplyr::select(Gender, everything())
}

#' Create education by birth cohort table
#'
#' @param df Data frame
#' @param sex_val Sex value (1 = male, 2 = female)
#' @param group_var Variable to group by
#' @param birth_range Vector of birth year range (default: c(1930, 1950))
#' @return Education cohort table
create_education_cohort_table <- function(df, sex_val, group_var, birth_range = c(1930, 1950)) {
  df %>%
    dplyr::filter(sex == sex_val) %>%
    dplyr::filter(birth_year >= birth_range[1] & birth_year <= birth_range[2]) %>%
    dplyr::filter(!is.na(country_string)) %>%
    dplyr::group_by(!!rlang::sym(group_var)) %>%
    dplyr::summarise(
      mean_less_than_primary_completed = weighted.mean(less_than_primary_completed, perwt, na.rm = TRUE),
      mean_primary_completed = weighted.mean(primary_completed, perwt, na.rm = TRUE),
      mean_secondary_completed = weighted.mean(secondary_completed, perwt, na.rm = TRUE),
      mean_university_completed = weighted.mean(university_completed, perwt, na.rm = TRUE),
      N = dplyr::n(),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(cols = -dplyr::all_of(group_var), names_to = "variable", values_to = "value") %>%
    tidyr::pivot_wider(names_from = dplyr::all_of(group_var), values_from = value) %>%
    dplyr::mutate(variable = dplyr::recode(variable, !!!variable_recode_education))
}

#' Calculate summary for migrants who arrived after age 24
#'
#' @param df Data frame
#' @param group_var Variable to group by
#' @return Summary table for 25+ migrants
calculate_summary_25plus <- function(df, group_var) {
  df %>%
    dplyr::group_by(!!rlang::sym(group_var)) %>%
    dplyr::summarise(
      mean_age_60_69 = weighted.mean(age_60to69, perwt, na.rm = TRUE),
      mean_age_70_79 = weighted.mean(age_70to79, perwt, na.rm = TRUE),
      mean_age_80_89 = weighted.mean(age_80to89, perwt, na.rm = TRUE),
      mean_age_90plus = weighted.mean(age_90plus, perwt, na.rm = TRUE),
      mean_less_than_primary_completed = weighted.mean(less_than_primary_completed, perwt, na.rm = TRUE),
      mean_primary_completed = weighted.mean(primary_completed, perwt, na.rm = TRUE),
      mean_secondary_completed = weighted.mean(secondary_completed, perwt, na.rm = TRUE),
      mean_university_completed = weighted.mean(university_completed, perwt, na.rm = TRUE),
      mean_hhsize = weighted.mean(famsize, perwt, na.rm = TRUE),
      mean_lives_alone = weighted.mean(lives_alone, perwt, na.rm = TRUE),
      mean_has_child_in_hh = weighted.mean(child_in_household, perwt, na.rm = TRUE),
      mean_married_cohab = weighted.mean(married_cohab, perwt, na.rm = TRUE),
      mean_age_at_immigration_25to49 = weighted.mean(age_at_immigration_25to49, perwt, na.rm = TRUE),
      mean_age_at_immigration_50plus = weighted.mean(age_at_immigration_50plus, perwt, na.rm = TRUE),
      mean_yrimm_before1965 = weighted.mean(yrimm_before1965, perwt, na.rm = TRUE),
      mean_yrimm_1965_1979 = weighted.mean(yrimm_1965to1980, perwt, na.rm = TRUE),
      mean_yrimm_1980_1999 = weighted.mean(yrimm_1980to1999, perwt, na.rm = TRUE),
      mean_yrimm_2000plus = weighted.mean(yrimm_2000plus, perwt, na.rm = TRUE),
      mean_is_citizen = weighted.mean(is_naturalized_citizen, perwt, na.rm = TRUE),
      mean_english_speaker = weighted.mean(english_speaker, perwt, na.rm = TRUE),
      N = dplyr::n(),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(cols = -dplyr::all_of(group_var), names_to = "variable", values_to = "value") %>%
    tidyr::pivot_wider(names_from = dplyr::all_of(group_var), values_from = value) %>%
    dplyr::mutate(variable = dplyr::recode(variable, !!!variable_recode_25plus))
}

#' Create alternative education table using alt education variables
#'
#' @param data Data frame
#' @return Alternative education table
create_alt_education_table <- function(data) {
  # Main countries
  summary_table <- data %>%
    dplyr::filter(country_string %in% main_countries) %>%
    dplyr::group_by(country_string) %>%
    dplyr::summarise(
      mean_less_than_primary_completed_alt = weighted.mean(less_than_primary_completed_alt, perwt, na.rm = TRUE),
      mean_primary_completed_alt = weighted.mean(primary_completed_alt, perwt, na.rm = TRUE),
      mean_secondary_completed = weighted.mean(secondary_completed, perwt, na.rm = TRUE),
      mean_university_completed = weighted.mean(university_completed, perwt, na.rm = TRUE),
      N = dplyr::n(),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(cols = -country_string, names_to = "variable", values_to = "value") %>%
    tidyr::pivot_wider(names_from = country_string, values_from = value) %>%
    dplyr::mutate(variable = dplyr::recode(variable,
      mean_less_than_primary_completed_alt = "Less than Primary",
      mean_primary_completed_alt = "Primary",
      mean_secondary_completed = "Secondary",
      mean_university_completed = "University"
    ))

  # Other migrants
  table_migrant <- data %>%
    dplyr::filter(!country_string %in% main_countries) %>%
    dplyr::filter(!hispanic_category_migrant_status %in% c("native-born Not Latino")) %>%
    dplyr::group_by(hispanic_category_migrant_status) %>%
    dplyr::summarise(
      mean_less_than_primary_completed_alt = weighted.mean(less_than_primary_completed_alt, perwt, na.rm = TRUE),
      mean_primary_completed_alt = weighted.mean(primary_completed_alt, perwt, na.rm = TRUE),
      mean_secondary_completed = weighted.mean(secondary_completed, perwt, na.rm = TRUE),
      mean_university_completed = weighted.mean(university_completed, perwt, na.rm = TRUE),
      N = dplyr::n(),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(cols = -hispanic_category_migrant_status, names_to = "variable", values_to = "value") %>%
    tidyr::pivot_wider(names_from = hispanic_category_migrant_status, values_from = value) %>%
    dplyr::select(-variable)

  # Native-born by race
  table_native_race <- data %>%
    dplyr::filter(race_native_category %in% c(10, 11, 12)) %>%
    dplyr::group_by(race_native_category) %>%
    dplyr::summarise(
      mean_less_than_primary_completed_alt = weighted.mean(less_than_primary_completed_alt, perwt, na.rm = TRUE),
      mean_primary_completed_alt = weighted.mean(primary_completed_alt, perwt, na.rm = TRUE),
      mean_secondary_completed = weighted.mean(secondary_completed, perwt, na.rm = TRUE),
      mean_university_completed = weighted.mean(university_completed, perwt, na.rm = TRUE),
      N = dplyr::n(),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(cols = -race_native_category, names_to = "variable", values_to = "value") %>%
    tidyr::pivot_wider(names_from = race_native_category, values_from = value) %>%
    dplyr::rename(Black = `10`, White = `11`, Other = `12`) %>%
    dplyr::select(-variable)

  # Combine
  dplyr::bind_cols(summary_table, table_migrant, table_native_race) %>%
    format_table() %>%
    dplyr::select(variable, mexico, `puerto rico`, `dominican republic`, cuba,
           `foreign-born Central-American Latino`, `foreign-born Other Latino`,
           `foreign-born Not Latino`, `native-born Other Latino`, Black, White, Other) %>%
    dplyr::rename(
      Demographics = variable,
      `Dominican Republic` = `dominican republic`,
      Mexico = mexico,
      `Puerto Rico` = `puerto rico`,
      Cuba = cuba,
      `Central America` = `foreign-born Central-American Latino`,
      `Latin America` = `foreign-born Other Latino`,
      `Other Countries` = `foreign-born Not Latino`,
      Hispanic = `native-born Other Latino`
    )
}
