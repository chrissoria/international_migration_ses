capture cd "/hdir/0/chrissoria/ses_international"
capture include cd "C:\Users\Ty\Desktop\ses_international"
clear all
capture log close
use data/ipumsi_00002.dta

keep if age > 64 & age < 90

keep if (bplcountry == 23050 | bplcountry == 21080 | bplcountry == 21100 | bplcountry == 22030 | bplcountry == 22040 | bplcountry == 22050 | bplcountry == 22060 | bplcountry == 21180 | bplcountry == 24040)

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

gen is_citizen = (citizen == 3)

gen male = (sex == 1)
gen female = (sex == 2)

gen english_speaker = (speakeng == 1)

decode edattain, gen(edattain_string)

gen less_than_primary_completed = (edattain_string == "less than primary completed")
gen primary_completed = (edattain_string == "primary completed")
gen secondary_completed = (edattain_string == "secondary completed")
gen university_completed = (edattain_string == "university completed")

save data/US_65_89.dta, replace

***below I will create the age standardization variable***

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

clear

use data/ses.dta

keep if age > 64 & age < 90

gen male = (sex == 1)
gen female = (sex == 2)

decode edattain, gen(edattain_string)

gen less_than_primary_completed = (edattain_string == "Less than primary completed")
gen primary_completed = (edattain_string == "Primary completed")
gen secondary_completed = (edattain_string == "Secondary completed")
gen university_completed = (edattain_string == "University completed")
gen education_unknown = (edattain_string == "Unknown")

gen married_cohab = (marst == 2) if marst != .

decode country, gen(country_string)

replace country_string = "DR" if country_string == "Dominican Republic"
replace country_string = "US" if country_string == "United States"
replace country_string = "ES" if country_string == "El Salvador"
replace country_string = "PR" if country_string == "Puerto Rico"

decode sex, gen(sex_string)
replace sex_string = lower(sex_string)

levelsof country_string, local(countries)
levelsof sex_string, local(sexes)

preserve

tempfile original_data_in
save `original_data_in'

* Calculating weights for each country and sex in international sample
foreach c of local countries {
    foreach s of local sexes {
        use `original_data_in', clear
        
        keep if country_string == "`c'" & sex_string == "`s'"
        
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
gen match_var_in = country_string + sex_string + age2_string
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

levelsof country_string, local(countries)
levelsof sex_string, local(sexes)

foreach c of local countries {
    foreach s of local sexes {
	
	merge m:1 match_var_in using "data/weights/in_age_weights_`c'_`s'.dta"
	drop _merge
    }
}

levelsof country_string, local(countries)
gen age_weight_in = .

foreach c of local countries {
    replace age_weight_in = age_weight_`c'_female if sex_string == "female" & age_weight_in == .
    replace age_weight_in = age_weight_`c'_male if sex_string == "male" & age_weight_in == .
    drop age_weight_`c'_male age_weight_`c'_female
}

gen age_weight_ratio = (age_weight_us/age_weight_in)

gen perwt_age_standardized = perwt * age_weight_ratio

save data/international__65_89.dta, replace

clear all
