/*==============================================================================
	US International SES - Data Processing

	This script processes US Census/ACS data and international census data
	for comparative analysis of older adult (60+) Hispanic immigrants.

	Outputs:
	  - data/US_2010_v100.dta (ACS 2010)
	  - data/US_2020_v100.dta (ACS 2020)
	  - data/US_2010_v100_census.dta (Census 2010)
	  - data/CuDrMePrUs_10_12.dta (Combined international)

	Next step: Run 01_create_weights.do
==============================================================================*/

capture cd "/Users/chrissoria/Documents/Research/us_international_ses"
capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close

/*------------------------------------------------------------------------------
	PROGRAMS: Reusable code blocks
------------------------------------------------------------------------------*/

* Program: Create age group variables
capture program drop create_age_groups
program define create_age_groups
	gen age_groups = .
	replace age_groups = 1 if age < 70
	replace age_groups = 2 if age >= 70 & age < 80
	replace age_groups = 3 if age >= 80 & age < 90
	replace age_groups = 4 if age >= 90

	label define age_group_labels 1 "60-69" 2 "70-79" 3 "80-89" 4 "90+"
	label values age_groups age_group_labels
	label variable age_groups "Age Groups"

	gen age_60to69 = (age >= 60 & age < 70)
	gen age_70to79 = (age >= 70 & age < 80)
	gen age_80to89 = (age >= 80 & age < 90)
	gen age_90plus = (age >= 90)
end

* Program: Create year of immigration variables
* Usage: create_yrimm_vars varname (yrimmig for ACS, yrimm for international)
capture program drop create_yrimm_vars
program define create_yrimm_vars
	args yrimm_var

	gen year_of_immigration_groups = .
	replace year_of_immigration_groups = 1 if `yrimm_var' < 1965 & `yrimm_var' != 0
	replace year_of_immigration_groups = 2 if `yrimm_var' >= 1965 & `yrimm_var' < 1981 & `yrimm_var' != 0
	replace year_of_immigration_groups = 3 if `yrimm_var' >= 1980 & `yrimm_var' < 2000 & `yrimm_var' != 0
	replace year_of_immigration_groups = 4 if `yrimm_var' >= 2000 & `yrimm_var' != 0

	label define year_of_immigration_groups_l 1 "Before 1965" 2 "1965 - 1979" 3 "1980 - 1999" 4 "After 1999"
	label values year_of_immigration_groups year_of_immigration_groups_l
	label variable year_of_immigration_groups "Year of Immigration Cohort"

	decode year_of_immigration_groups, gen(year_of_immig_groups_string)

	gen yrimm_before1965 = (`yrimm_var' < 1965 & `yrimm_var' != 0)
	gen yrimm_1965to1980 = (`yrimm_var' >= 1965 & `yrimm_var' < 1981 & `yrimm_var' != 0)
	gen yrimm_1980to1999 = (`yrimm_var' >= 1980 & `yrimm_var' < 2000 & `yrimm_var' != 0)
	gen yrimm_2000plus   = (`yrimm_var' >= 2000 & `yrimm_var' != 0)
end

* Program: Create age at immigration variables
capture program drop create_age_at_immig_vars
program define create_age_at_immig_vars
	gen age_at_immigration_groups = .
	replace age_at_immigration_groups = 1 if age_at_immigration < 15
	replace age_at_immigration_groups = 2 if age_at_immigration >= 15 & age_at_immigration < 25
	replace age_at_immigration_groups = 3 if age_at_immigration >= 25 & age_at_immigration < 50
	replace age_at_immigration_groups = 4 if age_at_immigration >= 50

	label define age_immig_labels 1 "Under 15" 2 "15-24" 3 "25-49" 4 "50 and above"
	label values age_at_immigration_groups age_immig_labels
	label variable age_at_immigration_groups "Age at Immigration Groups"

	decode age_at_immigration_groups, gen(age_at_immig_groups_string)

	gen age_at_immigration_under15 = (age_at_immigration < 15)
	gen age_at_immigration_15to24  = (age_at_immigration >= 15 & age_at_immigration < 25)
	gen age_at_immigration_25to49  = (age_at_immigration >= 25 & age_at_immigration < 50)
	gen age_at_immigration_50plus  = (age_at_immigration >= 50)
	gen age_at_immigration_15to49  = (age_at_immigration >= 15 & age_at_immigration < 50)
end

* Program: Create race/nativity category (12-category classification)
capture program drop create_race_nativity_category
program define create_race_nativity_category
	gen race_native_category = .

	* Foreign-born Hispanic
	replace race_native_category = 1 if native_foreign_race == "foreign-born black hispanic"
	replace race_native_category = 2 if native_foreign_race == "foreign-born white hispanic"
	replace race_native_category = 3 if native_foreign_race == "foreign-born other hispanic"

	* Foreign-born Non-Hispanic
	replace race_native_category = 4 if native_foreign_race == "foreign-born black not hispanic"
	replace race_native_category = 5 if native_foreign_race == "foreign-born white not hispanic"
	replace race_native_category = 6 if native_foreign_race == "foreign-born other not hispanic"

	* Native-born Hispanic
	replace race_native_category = 7 if native_foreign_race == "native-born black hispanic"
	replace race_native_category = 8 if native_foreign_race == "native-born white hispanic"
	replace race_native_category = 9 if native_foreign_race == "native-born other hispanic"

	* Native-born Non-Hispanic
	replace race_native_category = 10 if native_foreign_race == "native-born black not hispanic"
	replace race_native_category = 11 if native_foreign_race == "native-born white not hispanic"
	replace race_native_category = 12 if native_foreign_race == "native-born other not hispanic"

	label define category_labels ///
		1 "Foreign-Born Black Hispanic" ///
		2 "Foreign-Born White Hispanic" ///
		3 "Foreign-Born Other Hispanic" ///
		4 "Foreign-Born Black Non-Hispanic" ///
		5 "Foreign-Born White Non-Hispanic" ///
		6 "Foreign-Born Other Non-Hispanic" ///
		7 "Native-Born Black Hispanic" ///
		8 "Native-Born White Hispanic" ///
		9 "Native-Born Other Hispanic" ///
		10 "Native-Born Black Non-Hispanic" ///
		11 "Native-Born White Non-Hispanic" ///
		12 "Native-Born Other Non-Hispanic"

	label values race_native_category category_labels
end

* Program: Create education variables (for ACS detailed codes)
capture program drop create_education_vars_acs
program define create_education_vars_acs
	decode educd, gen(edattain_string)
	replace edattain_string = lower(edattain_string)

	gen less_than_primary_completed = 0
	gen primary_completed = 0
	gen secondary_completed = 0
	gen university_completed = 0

	replace less_than_primary_completed = 1 if inlist(edattain_string, ///
		"grade 1", "grade 2", "grade 3", "grade 4", "grade 5", ///
		"kindergarten", "no schooling completed", "nursery school, preschool")

	replace primary_completed = 1 if inlist(edattain_string, ///
		"grade 6", "grade 7", "grade 8", "grade 9", "grade 10", "grade 11")

	replace secondary_completed = 1 if inlist(edattain_string, ///
		"regular high school diploma", "ged or alternative credential", ///
		"1 or more years of college credit, no degree", ///
		"some college, but less than 1 year", "12th grade, no diploma", ///
		"associate's degree, type not specified")

	replace university_completed = 1 if inlist(edattain_string, ///
		"bachelor's degree", "master's degree", "doctoral degree", ///
		"professional degree beyond a bachelor's degree")

	* Binary education variables
	gen primary_or_above = (primary_completed == 1 | secondary_completed == 1 | university_completed == 1)
	gen secondary_or_above = (secondary_completed == 1 | university_completed == 1)
end

* Program: Create education variables (for international census)
capture program drop create_education_vars_intl
program define create_education_vars_intl
	decode edattain, gen(edattain_string)

	gen less_than_primary_completed = (edattain_string == "less than primary completed")
	gen primary_completed = (edattain_string == "primary completed")
	gen secondary_completed = (edattain_string == "secondary completed")
	gen university_completed = (edattain_string == "university completed")

	* Binary education variables
	gen primary_or_above = (primary_completed == 1 | secondary_completed == 1 | university_completed == 1)
	gen secondary_or_above = (secondary_completed == 1 | university_completed == 1)
end

* Program: Create household variables
capture program drop create_household_vars
program define create_household_vars
	gen lives_alone = (famsize == 1 & famsize != .)
	gen child_in_household = (nchild > 0) if nchild != .
end

* Program: Create sex dummy variables
capture program drop create_sex_vars
program define create_sex_vars
	gen male = (sex == 1)
	gen female = (sex == 2)
end

/*==============================================================================
	PART 1: Process US Census 2010 (International IPUMS format)
==============================================================================*/

use data/ipumsi_00002_US_2010.dta, clear
keep if age > 59

* Hispanic Category (using international bplcountry codes)
* Central America: 22010-22080 (Belize, Costa Rica, El Salvador, Guatemala, Honduras, Nicaragua, Panama)
gen HispanicCategory = .
replace HispanicCategory = 3 if (bplcountry >= 22010 & bplcountry <= 22080) & hispan != 0
replace HispanicCategory = 2 if hispan != 0 & HispanicCategory != 3
replace HispanicCategory = 1 if HispanicCategory != 3 & HispanicCategory != 2
replace HispanicCategory = 0 if hispan == 0

label define HispanicCategory_labels 3 "Central-American Latino" 2 "Other Latino" 1 "Hispanic Non-Latino" 0 "Not Latino"
label values HispanicCategory HispanicCategory_labels
label variable HispanicCategory "Hispanic Category"
decode HispanicCategory, gen(HispanicCategoryString)

create_household_vars

* Latin American identifier
gen latin_american = (bpl > 21019 & bpl < 24000)
replace latin_american = 1 if hispan > 0 & bpl == 24040
replace hispan = 0 if latin_american == 0

* Continue with variable creation
decode bplcountry, gen(country_string)

create_age_groups
create_yrimm_vars yrimm

* Nativity and race
decode nativity, gen(nativity_string)
decode race, gen(race_string)
decode hispan, gen(hispan_string)

replace hispan_string = "hispanic" if hispan_string != "not hispanic"
replace hispan_string = "hispanic" if bpl == 26010  // Fix Dominican misclassification

replace race_string = "other" if race_string != "white" & race_string != "black"
replace race_string = race_string + " " + hispan_string

gen native_foreign_race = nativity_string + " " + race_string

create_race_nativity_category

* Marital status (international coding: 2 = married/cohabiting)
gen married_cohab = (marst == 2) if marst != .

* Immigration timing
gen years_in_us = 2010 - yrimm
replace years_in_us = . if years_in_us == 2010

gen age_at_immigration = age - years_in_us

create_age_at_immig_vars

* Citizenship (international coding: 3 = naturalized, 2 = birth citizen)
gen is_naturalized_citizen = (citizen == 3)
gen is_birth_citizen = (citizen == 2)

create_sex_vars

* English proficiency
gen english_speaker = (speakeng == 1)

* Education with years of schooling correction
decode edattain, gen(edattain_string)

gen less_than_primary_completed = (edattain_string == "less than primary completed")
gen primary_completed = (edattain_string == "primary completed")
gen secondary_completed = (edattain_string == "secondary completed")
gen university_completed = (edattain_string == "university completed")

drop edattain_string

* Correct education based on years of schooling
replace edattain = 2 if yrschool < 12 & secondary_completed == 1
replace edattain = 3 if yrschool > 12 & primary_completed == 1
replace edattain = 4 if yrschool > 15 & secondary_completed == 1

drop less_than_primary_completed primary_completed secondary_completed university_completed

create_education_vars_intl

* Country-year identifiers
decode year, gen(year_str)
gen country_year = country_string + "_" + year_str

* Combined status variables
gen hispanic_migrant_status = nativity_string + " " + hispan_string
gen hispanic_category_migrant_status = nativity_string + " " + HispanicCategoryString
replace hispanic_category_migrant_status = "foreign-born Not Latino" if hispanic_category_migrant_status == "foreign-born Hispanic Non-Latino"
gen hispanic_migrant_status_race = nativity_string + " " + race_string

save data/US_2010_v100_census.dta, replace

/*==============================================================================
	PART 2: Process US ACS Data (2010 and 2020)
==============================================================================*/

foreach data in "2020" "2010" {

	* Load dataset and filter by sample
	use "data/usa_00007.dta", clear
	if "`data'" == "2020" {
		keep if sample == 202003
	}
	else {
		keep if sample == 201003
	}

	* Filter to ages 60+
	keep if age > 59

	*---------------------------------------------------------------------------
	* Hispanic Category Classification
	*---------------------------------------------------------------------------
	gen HispanicCategory = .
	replace HispanicCategory = 3 if bpl == 210 & hispan != 0                           // Central American
	replace HispanicCategory = 2 if (bpl < 400 | bpl > 599) & hispan != 0 & bpl != 210 // Other Latino
	replace HispanicCategory = 1 if (bpl >= 400 & bpl <= 599) & hispan != 0            // Hispanic Non-Latino
	replace HispanicCategory = 0 if HispanicCategory == .                               // Not Latino

	label define HispanicCategory_labels 3 "Central-American Latino" 2 "Other Latino" 1 "Hispanic Non-Latino" 0 "Not Latino"
	label values HispanicCategory HispanicCategory_labels
	label variable HispanicCategory "Hispanic Category"
	decode HispanicCategory, gen(HispanicCategoryString)

	*---------------------------------------------------------------------------
	* Create derived variables
	*---------------------------------------------------------------------------
	create_household_vars
	create_age_groups
	create_yrimm_vars yrimmig

	* Nativity: Identify US-born via state of birth
	decode bpl, gen(bpl_string)
	local states `" "alabama" "alaska" "arizona" "arkansas" "california" "colorado" "connecticut" "delaware" "florida" "georgia" "hawaii" "idaho" "illinois" "indiana" "iowa" "kansas" "kentucky" "louisiana" "maine" "maryland" "massachusetts" "michigan" "minnesota" "mississippi" "missouri" "montana" "nebraska" "nevada" "new hampshire" "new jersey" "new mexico" "new york" "north carolina" "north dakota" "ohio" "oklahoma" "oregon" "pennsylvania" "rhode island" "south carolina" "south dakota" "tennessee" "texas" "utah" "vermont" "virginia" "washington" "west virginia" "wisconsin" "wyoming" "district of columbia" "'
	gen contains_us_state = 0
	foreach state of local states {
		replace contains_us_state = 1 if strpos(lower(bpl_string), lower("`state'")) > 0
	}

	decode bpld, gen(bplcountry)
	replace bplcountry = "united states" if contains_us_state == 1

	gen nativity_string = cond(contains_us_state == 1, "native-born", "foreign-born")

	* Race string processing
	decode race, gen(race_string)
	replace race_string = lower(race_string)
	replace race_string = "black" if race_string == "black/african american"
	replace race_string = "other" if race_string != "white" & race_string != "black"

	* Hispanic string processing
	decode hispan, gen(hispan_string)
	replace hispan_string = lower(hispan_string)
	replace hispan_string = "hispanic" if hispan_string != "not hispanic"
	replace hispan_string = "hispanic" if bpld == 26010  // Fix: Dominicans often misclassified

	* Combined race-hispanic variable
	replace race_string = race_string + " " + hispan_string
	gen native_foreign_race = nativity_string + " " + race_string

	create_race_nativity_category

	* Marital status
	gen married_cohab = (marst == 1 | marst == 2) if marst != .
	gen married_not_cohab = (marst == 2) if marst != .

	* Immigration timing
	gen years_in_us = yrsusa1
	gen age_at_immigration = age - years_in_us
	replace age_at_immigration = . if nativity_string == "native-born"

	create_age_at_immig_vars

	* Citizenship
	gen is_naturalized_citizen = (citizen == 2)
	gen is_born_citizen = (citizen == 0)
	gen is_citizen = (citizen != 3)

	create_sex_vars

	* English proficiency
	decode speakeng, gen(speakeng_string)
	replace speakeng_string = lower(speakeng_string)
	gen english_speaker = (speakeng_string != "does not speak english")
	gen english_speaker_not_well = (speakeng_string == "yes, but not well")
	gen english_speaker_well = (english_speaker == 1 & english_speaker_not_well == 0)

	create_education_vars_acs

	* Country-year identifiers
	decode year, gen(year_str)
	gen country_string = lower(bplcountry)
	gen country_year = country_string + "_" + year_str

	* Combined status variables
	gen hispanic_migrant_status = nativity_string + " " + hispan_string
	gen hispanic_category_migrant_status = nativity_string + " " + HispanicCategoryString
	replace hispanic_category_migrant_status = "foreign-born Not Latino" if hispanic_category_migrant_status == "foreign-born Hispanic Non-Latino"
	gen hispanic_migrant_status_race = nativity_string + " " + race_string

	* Create sex_string and age2 for weight matching (will be used by 02_apply_weights.do)
	decode sex, gen(sex_string)
	replace sex_string = lower(sex_string)

	gen age2 = .
	replace age2 = 1 if age >= 60 & age < 65
	replace age2 = 2 if age >= 65 & age < 70
	replace age2 = 3 if age >= 70 & age < 75
	replace age2 = 4 if age >= 75 & age < 80
	replace age2 = 5 if age >= 80 & age < 85
	replace age2 = 6 if age >= 85

	label define age2_lbl 1 "60 to 64" 2 "65 to 69" 3 "70 to 74" 4 "75 to 79" 5 "80 to 84" 6 "85+"
	label values age2 age2_lbl

	* Save
	if "`data'" == "2020" {
		save "data/US_2020_v100.dta", replace
	}
	else {
		save "data/US_2010_v100.dta", replace
	}

	clear
}

/*==============================================================================
	PART 3: Process International Census Data
==============================================================================*/

clear
use data/ses_v2.dta

capture append using "/Users/chrissoria/Documents/Research/us_international_ses/data/ipumsi_00002_US_2010.dta"
capture append using "C:\Users\Ty\Desktop\ses_international\data\ipumsi_00002_US_2010.dta"
capture append using data/ipumsi_00002_US_2010.dta

decode country, gen(country_string)
keep if age > 59

create_household_vars
create_age_groups
create_sex_vars

* Education
decode edattain, gen(edattain_string)
decode edattaind, gen(edattaind_string)

gen less_than_primary_completed = (edattain_string == "less than primary completed")
gen primary_completed = (edattain_string == "primary completed")
gen secondary_completed = (edattain_string == "secondary completed")
gen university_completed = (edattain_string == "university completed")
gen education_unknown = (edattain_string == "unknown")

gen married_cohab = (marst == 2) if marst != .

* Standardize country names
replace country_string = "United States" if country_string == "united states"
replace country_string = "Puerto Rico" if country_string == "puerto rico"
replace country_string = "Mexico" if country_string == "mexico"
replace country_string = "Honduras" if country_string == "honduras"
replace country_string = "Guatemala" if country_string == "guatemala"
replace country_string = "El Salvador" if country_string == "el salvador"
replace country_string = "Dominican Republic" if country_string == "dominican republic"
replace country_string = "Cuba" if country_string == "cuba"
replace country_string = "Colombia" if country_string == "colombia"

* Abbreviate for identifiers
replace country_string = "DR" if country_string == "Dominican Republic"
replace country_string = "US" if country_string == "United States"
replace country_string = "ES" if country_string == "El Salvador"
replace country_string = "PR" if country_string == "Puerto Rico"

decode year, gen(year_str)
gen country_year = country_string + "_" + year_str

decode sex, gen(sex_string)
replace sex_string = lower(sex_string)

* Keep analysis sample
keep if inlist(country_year, "Cuba_2012", "DR_2010", "Mexico_2010", "PR_2010", "Mexico_2020", "PR_2020")

save data/CuDrMePrUs_10_12.dta, replace

clear all

di ""
di "=========================================="
di "Data processing complete!"
di "=========================================="
di ""
di "Output files:"
di "  - data/US_2010_v100.dta"
di "  - data/US_2020_v100.dta"
di "  - data/US_2010_v100_census.dta"
di "  - data/CuDrMePrUs_10_12.dta"
di ""
di "Next step: Run 01_create_weights.do"
di ""
