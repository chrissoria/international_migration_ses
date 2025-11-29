/*==============================================================================
	US International SES - Apply Age Standardization Weights

	This script applies the age standardization weights created by
	01_create_weights.do to all processed datasets.

	Reference population: US 2010 Census Hispanics 60+

	Prerequisites:
	  - Run 00_process_data.do first
	  - Run 01_create_weights.do second

	Inputs:
	  - data/US_2010_v100.dta
	  - data/US_2020_v100.dta
	  - data/CuDrMePrUs_10_12.dta
	  - data/weights/us_age_weights_*.dta
	  - data/weights/in_age_weights_*.dta

	Outputs (updated with perwt_age_standardized):
	  - data/US_2010_v100.dta
	  - data/US_2020_v100.dta
	  - data/CuDrMePrUs_10_12.dta
==============================================================================*/

capture cd "/Users/chrissoria/Documents/Research/us_international_ses"
capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close

/*==============================================================================
	PART 1: Apply Weights to US ACS Data (2010 and 2020)
==============================================================================*/

foreach data in "2020" "2010" {

	if "`data'" == "2020" {
		use "data/US_2020_v100.dta", clear
	}
	else {
		use "data/US_2010_v100.dta", clear
	}

	* Create matching variable
	decode age2, gen(age2_string)
	gen match_var_us = sex_string + age2_string

	* Merge US 2010 Census reference weights
	merge m:1 match_var_us using data/weights/us_age_weights_female.dta, nogenerate keep(master match)
	merge m:1 match_var_us using data/weights/us_age_weights_male.dta, nogenerate keep(master match)

	gen age_weight_us = cond(age_weight_female != ., age_weight_female, age_weight_male)
	drop age_weight_female age_weight_male

	* Calculate age distribution for each country-sex combination in this ACS data
	preserve

	keep if hispan_string == "hispanic"

	collapse (sum) perwt, by(age2 sex_string country_string)
	bysort sex_string country_string: egen total_perwt_grp = total(perwt)
	gen age_weight_grp = perwt / total_perwt_grp
	drop perwt total_perwt_grp

	decode age2, gen(age2_string)
	gen match_var_acs = sex_string + age2_string + country_string

	tempfile acs_weights
	save `acs_weights'

	restore

	* Create matching variable and merge
	gen match_var_acs = sex_string + age2_string + country_string
	merge m:1 match_var_acs using `acs_weights', nogenerate keep(master match)

	* Calculate age-standardized weights
	* ratio = reference weight / group weight
	gen age_weight_ratio = age_weight_us / age_weight_grp
	replace age_weight_ratio = 1 if age_weight_ratio == .

	gen perwt_age_standardized = perwt * age_weight_ratio

	* Clean up temporary variables
	drop age_weight_ratio age_weight_grp age_weight_us match_var_us match_var_acs age2_string

	* Save
	if "`data'" == "2020" {
		save "data/US_2020_v100.dta", replace
		di "Applied weights to US ACS 2020"
	}
	else {
		save "data/US_2010_v100.dta", replace
		di "Applied weights to US ACS 2010"
	}

	clear
}

/*==============================================================================
	PART 2: Apply Weights to International Census Data
==============================================================================*/

use data/CuDrMePrUs_10_12.dta, clear

levelsof country_year, local(countries)
levelsof sex_string, local(sexes)

* Create matching variables
decode age2, gen(age2_string)
gen match_var_in = country_year + sex_string + age2_string
gen match_var_us = sex_string + age2_string

* Merge US reference weights
foreach s of local sexes {
	merge m:1 match_var_us using data/weights/us_age_weights_`s'.dta, nogenerate
}

gen age_weight_us = cond(age_weight_female != ., age_weight_female, age_weight_male)
drop age_weight_female age_weight_male

* Merge international weights
foreach c of local countries {
	foreach s of local sexes {
		merge m:1 match_var_in using "data/weights/in_age_weights_`c'_`s'.dta", nogenerate
	}
}

* Consolidate international weights
gen age_weight_in = .
foreach c of local countries {
	capture replace age_weight_in = age_weight_`c'_female if sex_string == "female" & age_weight_in == .
	capture replace age_weight_in = age_weight_`c'_male if sex_string == "male" & age_weight_in == .
	capture drop age_weight_`c'_male age_weight_`c'_female
}

* Calculate age-standardized weights
gen age_weight_ratio = age_weight_us / age_weight_in
gen perwt_age_standardized = perwt * age_weight_ratio

* Clean up temporary variables
drop age_weight_ratio age_weight_us age_weight_in match_var_us match_var_in age2_string

save data/CuDrMePrUs_10_12.dta, replace
di "Applied weights to international data"

clear all

di ""
di "=========================================="
di "Weight application complete!"
di "=========================================="
di ""
di "All datasets now have perwt_age_standardized variable"
di "Reference population: US 2010 Census Hispanics 60+"
di ""
di "Updated files:"
di "  - data/US_2010_v100.dta"
di "  - data/US_2020_v100.dta"
di "  - data/CuDrMePrUs_10_12.dta"
di ""
di "Ready for analysis!"
di ""
