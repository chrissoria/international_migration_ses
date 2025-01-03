capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close
use data/ipumsi_00002_US_2010.dta

keep if age > 59 & age < 90

***below I will create the age standardization variable***

preserve
decode sex, gen(sex_string)
replace sex_string = lower(sex_string)
levelsof sex_string, local(sexes)
tempfile original_data
save `original_data'

foreach s of local sexes {
    use `original_data', clear
    
    keep if sex_string == "`s'"
    
    collapse (sum) perwt, by(age2)
    egen total_perwt = total(perwt)
    gen age_weight_`s' = perwt / total_perwt
    drop total_perwt
    drop perwt
    decode age2, gen(age2_string)
    gen match_var_us = "`s'" + age2_string
    
    export delimited using "data/weights/us_age_weights_`s'.csv", replace
    save "data/weights/us_age_weights_`s'.dta", replace
}
restore

keep if (bplcountry == 23050 | bplcountry == 21080 | bplcountry == 21100 | bplcountry == 22030 | bplcountry == 22040 | bplcountry == 22050 | bplcountry == 22060 | bplcountry == 21180 | bplcountry == 24040)

gen age_groups = .
replace age_groups = 1 if age <70
replace age_groups = 2 if age >69 & age <80
replace age_groups = 3 if age >79 & age <90

label define age_group_labels 1 "60-69" 2 "69-78" 3 "79-88"
label values age_groups age_group_labels
label variable age_groups "Age Groups"

gen year_of_immigration_groups = .
replace year_of_immigration_groups = 1 if yrimm < 1965 & yrimm != 0
replace year_of_immigration_groups = 2 if yrimm >= 1965 & yrimm < 1981 & yrimm != 0
replace year_of_immigration_groups = 3 if yrimm >= 1980 & yrimm < 2000 & yrimm != 0
replace year_of_immigration_groups = 4 if yrimm >= 2000 & yrimm != 0

label define year_of_immigration_groups_l 1 "Before 1965" 2 "Between 1965 and 1980" 3 "Between 1980 and 1999" 4 "After 2000"
label values year_of_immigration_groups year_of_immigration_groups_l
label variable year_of_immigration_groups "Year of Immigration Cohort"

decode nativity, gen(nativity_string)
decode race, gen(race_string)
decode hispan, gen(hispan_string)

replace hispan_string = "hispanic" if hispan_string != "not hispanic"

replace race_string = "other" if race_string != "white" & race_string != "black"
replace race_string = race_string + " " + hispan_string

/*we want these six categories
1. hispanic black foreign
2. hispanic white foreign (this category is least meaningful)
3. hispanic other foreign
4. non-hispanic black native
5. non-hispanic white native
6. non-hispanic other native
*/

gen native_foreign_race = nativity_string + " " + race_string
tab native_foreign_race

gen race_native_category = .

* Recode into six categories
replace race_native_category = 1 if native_foreign_race == "foreign-born black hispanic"
replace race_native_category = 2 if native_foreign_race == "foreign-born white hispanic"
replace race_native_category = 3 if native_foreign_race == "foreign-born other hispanic"
replace race_native_category = 4 if native_foreign_race == "native-born black not hispanic"
replace race_native_category = 5 if native_foreign_race == "native-born white not hispanic"
replace race_native_category = 6 if native_foreign_race == "native-born other not hispanic"

replace race_native_category = 7 if inlist(native_foreign_race, "native-born black hispanic", "native-born white hispanic", "native-born other hispanic")

label define category_labels 1 "Hispanic Black Foreign" ///
                             2 "Hispanic White Foreign" ///
                             3 "Hispanic Other Foreign" ///
                             4 "Non-Hispanic Black Native" ///
                             5 "Non-Hispanic White Native" ///
                             6 "Non-Hispanic Other Native" ///
                             7 "All Native Hispanic"

label values race_native_category category_labels

tab native_foreign_race
tab race_native_category, miss

gen married_cohab = (marst == 2) if marst != .

gen years_in_us = 2020 - yrimm
replace years_in_us = . if citizen == 2

gen age_at_immigration = age - years_in_us
replace age_at_immigration = . if citizen == 2

gen age_at_immigration_groups = .
replace age_at_immigration_groups = 1 if age_at_immigration < 15
replace age_at_immigration_groups = 2 if age_at_immigration >= 15 & age_at_immigration < 50
replace age_at_immigration_groups = 3 if age_at_immigration >= 50


label define age_immig_labels 1 "Under 15" 2 "15-49" 3 "50 and above"
label values age_at_immigration_groups age_immig_labels
label variable age_at_immigration_groups "Age at Immigration Groups"

gen is_citizen = (citizen == 3)

gen male = (sex == 1)
gen female = (sex == 2)

gen english_speaker = (speakeng == 1)

decode edattain, gen(edattain_string)

gen less_than_primary_completed = (edattain_string == "less than primary completed")
gen primary_completed = (edattain_string == "primary completed")
gen secondary_completed = (edattain_string == "secondary completed")
gen university_completed = (edattain_string == "university completed")

decode year, gen(year_str)
decode country, gen(country_string)

replace country_string = "United States" if country_string == "united states"
replace country_string = "Puerto Rico" if country_string == "puerto rico"
replace country_string = "Mexico" if country_string == "mexico"
replace country_string = "US" if country_string == "United States"

drop if country_string == "Mexico"
gen country_year = country_string + "_" + year_str

save data/US_2010_v100.dta, replace

clear

*/
use data/ses_v2.dta

*capture append using "C:\Users\Ty\Desktop\ses_international\data_in\ipumsi_00002_US_2010.dta"

capture append using "/hdir/0/chrissoria/ses_international\data\ipumsi_00002_US_2010.dta"

decode country, gen(country_string)

keep if age > 59 & age < 90

gen male = (sex == 1)
gen female = (sex == 2)

decode edattain, gen(edattain_string)

gen less_than_primary_completed = (edattain_string == "less than primary completed")
gen primary_completed = (edattain_string == "primary completed")
gen secondary_completed = (edattain_string == "secondary completed")
gen university_completed = (edattain_string == "university completed")
gen education_unknown = (edattain_string == "unknown")

gen married_cohab = (marst == 2) if marst != .

replace country_string = "United States" if country_string == "united states"
replace country_string = "Puerto Rico" if country_string == "puerto rico"
replace country_string = "Mexico" if country_string == "mexico"
replace country_string = "Honduras" if country_string == "honduras"
replace country_string = "Guatemala" if country_string == "guatemala"
replace country_string = "El Salvador" if country_string == "el salvador"
replace country_string = "Dominican Republic" if country_string == "dominican republic"
replace country_string = "Cuba" if country_string == "cuba"
replace country_string = "Colombia" if country_string == "colombia"

replace country_string = "DR" if country_string == "Dominican Republic"
replace country_string = "US" if country_string == "United States"
replace country_string = "ES" if country_string == "El Salvador"
replace country_string = "PR" if country_string == "Puerto Rico"

decode year, gen(year_str)
gen country_year = country_string + "_" + year_str

decode sex, gen(sex_string)
replace sex_string = lower(sex_string)

levelsof country_year, local(countries)
levelsof sex_string, local(sexes)

preserve

tempfile original_data_in
save `original_data_in'

* Calculating weights for each country and sex in international sample
foreach c of local countries {
    foreach s of local sexes {
        use `original_data_in', clear
        
        keep if country_year == "`c'" & sex_string == "`s'"
        
        collapse (sum) perwt, by(age2)
        egen total_perwt = total(perwt)
        gen age_weight_`c'_`s' = perwt / total_perwt
        drop total_perwt
        drop perwt
        
        decode age2, gen(age2_string)
        gen match_var_in = "`c'" + "`s'" + age2_string
        
        sum age_weight_`c'_`s'
        
        export delimited using "data/weights/in_age_weights_`c'_`s'.csv", replace
        save "data/weights/in_age_weights_`c'_`s'.dta", replace
    }
}

restore

decode age2, gen(age2_string)
gen match_var_in = country_year + sex_string + age2_string
gen match_var_us = sex_string + age2_string

*next, I want to merge in the US weights by sex
levelsof sex_string, local(sexes)

foreach s of local sexes {
	merge m:1 match_var_us using data/weights/us_age_weights_`s'.dta
	drop _merge
}

gen age_weight_us = age_weight_female 
replace age_weight_us = age_weight_male if age_weight_us == .

drop age_weight_female age_weight_male
*save data/international__65_89.dta, replace

levelsof country_year, local(countries)
levelsof sex_string, local(sexes)

foreach c of local countries {
    foreach s of local sexes {
	
	merge m:1 match_var_in using "data/weights/in_age_weights_`c'_`s'.dta"
	drop _merge
    }
}

levelsof country_year, local(countries)
gen age_weight_in = .

foreach c of local countries {
    replace age_weight_in = age_weight_`c'_female if sex_string == "female" & age_weight_in == .
    replace age_weight_in = age_weight_`c'_male if sex_string == "male" & age_weight_in == .
    drop age_weight_`c'_male age_weight_`c'_female
}

gen age_weight_ratio = (age_weight_us/age_weight_in)

gen perwt_age_standardized = perwt * age_weight_ratio

keep if (country_year == "Mexico_2010" | country_year == "Mexico_2020" | country_year == "PR_2010" | country_year == "PR_2020" | country_year == "US_2010" | country_year == "US_2020")

save data/UsPrMe_10_20.dta, replace

clear all
