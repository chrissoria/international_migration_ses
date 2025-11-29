/*==============================================================================
	US International SES - Create Age Standardization Weights

	This script creates reference weights for age standardization using
	US 2010 Census Hispanics 60+ as the reference population.

	These weights will be applied by 02_apply_weights.do to:
	  - US ACS 2010
	  - US ACS 2020
	  - International census data

	Prerequisite: Run 00_process_data.do first

	Outputs:
	  - data/weights/us_age_weights_female.dta
	  - data/weights/us_age_weights_male.dta
	  - data/weights/us_age_weights_female.csv
	  - data/weights/us_age_weights_male.csv
	  - data/weights/in_age_weights_[country]_[sex].dta (for each country-sex)

	Next step: Run 02_apply_weights.do
==============================================================================*/

capture cd "/Users/chrissoria/Documents/Research/us_international_ses"
capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close

* Create weights directory if it doesn't exist
capture mkdir "data/weights"

/*==============================================================================
	PART 1: Create Reference Weights from US 2010 Census
	        Reference: US 2010 Census Hispanics 60+, by sex
==============================================================================*/

use data/US_2010_v100_census.dta, clear

* Filter to Hispanics only for the reference population
keep if hispan != 0

decode sex, gen(sex_string)
replace sex_string = lower(sex_string)
levelsof sex_string, local(sexes)

tempfile hispanic_data
save `hispanic_data'

foreach s of local sexes {
	use `hispanic_data', clear
	keep if sex_string == "`s'"

	* Calculate age distribution using age2 (5-year age groups)
	collapse (sum) perwt, by(age2)
	egen total_perwt = total(perwt)
	gen age_weight_`s' = perwt / total_perwt
	drop total_perwt perwt

	* Create matching variable
	decode age2, gen(age2_string)
	gen match_var_us = "`s'" + age2_string

	* Save weights
	export delimited using "data/weights/us_age_weights_`s'.csv", replace
	save "data/weights/us_age_weights_`s'.dta", replace

	di ""
	di "Reference weights for `s':"
	list
}

/*==============================================================================
	PART 2: Create International Country-Specific Weights
==============================================================================*/

use data/CuDrMePrUs_10_12.dta, clear

levelsof country_year, local(countries)
levelsof sex_string, local(sexes)

tempfile original_data
save `original_data'

foreach c of local countries {
	foreach s of local sexes {
		use `original_data', clear
		keep if country_year == "`c'" & sex_string == "`s'"

		* Calculate age distribution
		collapse (sum) perwt, by(age2)
		egen total_perwt = total(perwt)
		gen age_weight_`c'_`s' = perwt / total_perwt
		drop total_perwt perwt

		* Create matching variable
		decode age2, gen(age2_string)
		gen match_var_in = "`c'" + "`s'" + age2_string

		* Save weights
		export delimited using "data/weights/in_age_weights_`c'_`s'.csv", replace
		save "data/weights/in_age_weights_`c'_`s'.dta", replace
	}
}

clear all

di ""
di "=========================================="
di "Weight creation complete!"
di "=========================================="
di ""
di "Reference population: US 2010 Census Hispanics 60+"
di ""
di "Output files:"
di "  - data/weights/us_age_weights_female.dta"
di "  - data/weights/us_age_weights_male.dta"
di "  - data/weights/in_age_weights_[country]_[sex].dta"
di ""
di "Next step: Run 02_apply_weights.do"
di ""
