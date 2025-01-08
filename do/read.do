capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close
use data/usa_00004.dta

keep if sample == 202003
keep if age > 59 & age < 90

gen age_groups = .
replace age_groups = 1 if age <70
replace age_groups = 2 if age >69 & age <80
replace age_groups = 3 if age >79 & age <90

label define age_group_labels 1 "60-69" 2 "69-78" 3 "79-88"
label values age_groups age_group_labels
label variable age_groups "Age Groups"

gen age_60to69 = (age >= 60 & age < 70)
gen age_70to79 = (age >= 70 & age < 80)
gen age_80to89 = (age >= 80 & age < 90)

gen year_of_immigration_groups = .
replace year_of_immigration_groups = 1 if yrimmig < 1965 & yrimmig != 0
replace year_of_immigration_groups = 2 if yrimmig >= 1965 & yrimmig < 1981 & yrimmig != 0
replace year_of_immigration_groups = 3 if yrimmig >= 1980 & yrimmig < 2000 & yrimmig != 0
replace year_of_immigration_groups = 4 if yrimmig >= 2000 & yrimmig != 0

label define year_of_immigration_groups_l 1 "Before 1965" 2 "Between 1965 and 1980" 3 "Between 1980 and 1999" 4 "After 2000"
label values year_of_immigration_groups year_of_immigration_groups_l
label variable year_of_immigration_groups "Year of Immigration Cohort"

gen yrimm_before1965 = (yrimmig < 1965 & yrimmig != 0)
gen yrimm_1965to1980 = (yrimmig >= 1965 & yrimmig < 1981 & yrimmig != 0)
gen yrimm_1980to1999 = (yrimmig >= 1980 & yrimmig < 2000 & yrimmig != 0)
gen yrimm_2000plus = (yrimmig >= 2000 & yrimmig != 0)

decode bpl, gen(bpl_string)
local states `" "Alabama" "Alaska" "Arizona" "Arkansas" "California" "Colorado" "Connecticut" "Delaware" "Florida" "Georgia" "Hawaii" "Idaho" "Illinois" "Indiana" "Iowa" "Kansas" "Kentucky" "Louisiana" "Maine" "Maryland" "Massachusetts" "Michigan" "Minnesota" "Mississippi" "Missouri" "Montana" "Nebraska" "Nevada" "New Hampshire" "New Jersey" "New Mexico" "New York" "North Carolina" "North Dakota" "Ohio" "Oklahoma" "Oregon" "Pennsylvania" "Rhode Island" "South Carolina" "South Dakota" "Tennessee" "Texas" "Utah" "Vermont" "Virginia" "Washington" "West Virginia" "Wisconsin" "Wyoming" "District of Columbia" "'
gen contains_us_state = 0
foreach state of local states {
    replace contains_us_state = 1 if strpos(lower(bpl_string), lower("`state'")) > 0
}

decode bpld, gen(bplcountry)

replace bplcountry = "United States" if contains_us_state == 1

gen nativity_string = "."
replace nativity_string = "foreign-born" if contains_us_state == 0
replace nativity_string = "native-born" if contains_us_state == 1

decode race, gen(race_string)
replace race_string = "black" if race_string == "Black/African American"
replace race_string = "white" if race_string == "White"

decode hispan, gen(hispan_string)

replace hispan_string = "hispanic" if hispan_string != "Not Hispanic"
replace hispan_string = lower(hispan_string)

*a weird thing in the data, dominicans are often classified as not hispanic. changing to hispanic. 
replace hispan_string = "hispanic" if bpld == 26010

replace race_string = "other" if race_string != "white" & race_string != "black"
replace race_string = race_string + " " + hispan_string

gen native_foreign_race = nativity_string + " " + race_string
tab native_foreign_race

gen race_native_category = .

* foreign hispanic
replace race_native_category = 1 if native_foreign_race == "foreign-born black hispanic"
replace race_native_category = 2 if native_foreign_race == "foreign-born white hispanic"
replace race_native_category = 3 if native_foreign_race == "foreign-born other hispanic"

* foreign born not hispanic
replace race_native_category = 4 if native_foreign_race == "foreign-born black not hispanic"
replace race_native_category = 5 if native_foreign_race == "foreign-born white not hispanic"
replace race_native_category = 6 if native_foreign_race == "foreign-born other not hispanic"

*hispanic natives
replace race_native_category = 7 if native_foreign_race == "native-born black hispanic"
replace race_native_category = 8 if native_foreign_race == "native-born white hispanic"
replace race_native_category = 9 if native_foreign_race == "native-born other hispanic"

*non-hispanic natives
replace race_native_category = 10 if native_foreign_race == "native-born black not hispanic"
replace race_native_category = 11 if native_foreign_race == "native-born white not hispanic"
replace race_native_category = 12 if native_foreign_race == "native-born other not hispanic"

label define category_labels 1 "Foreign-Born Black Hispanic" ///
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

tab native_foreign_race
tab race_native_category, miss

gen married_cohab = (marst == 1) if marst != .

gen years_in_us = yrsusa1

gen age_at_immigration = age - years_in_us
replace age_at_immigration = . if (nativity_string == "native-born")

gen age_at_immigration_groups = .
replace age_at_immigration_groups = 1 if age_at_immigration < 15
replace age_at_immigration_groups = 2 if age_at_immigration >= 15 & age_at_immigration < 50
replace age_at_immigration_groups = 3 if age_at_immigration >= 50


label define age_immig_labels 1 "Under 15" 2 "15-49" 3 "50 and above"
label values age_at_immigration_groups age_immig_labels
label variable age_at_immigration_groups "Age at Immigration Groups"

gen age_at_immigration_under15 = (age_at_immigration < 15)
gen age_at_immigration_15to49 = (age_at_immigration >= 15 & age_at_immigration < 50)
gen age_at_immigration_50plus = (age_at_immigration >= 50)

gen is_naturalized_citizen = (citizen == 2)
gen is_born_citizen = (citizen == 0)
gen is_citizen = (citizen != 3)

gen male = (sex == 1)
gen female = (sex == 2)

decode speakeng, gen(speakeng_string)

gen english_speaker = 0
replace english_speaker = 1 if speakeng_string != "Does not speak English"

gen english_speaker_not_well = 0
replace english_speaker_not_well = 1 if speakeng_string == "Yes, but not well"

gen english_speaker_well = 0
replace english_speaker_well = 1 if (english_speaker == 1 & english_speaker_not_well == 0)

decode educd, gen(edattain_string)

generate less_than_primary_completed = 0
replace less_than_primary_completed = 1 if inlist(edattain_string, "Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5", "Kindergarten", "No schooling completed", "Nursery school, preschool")

generate primary_completed = 0
replace primary_completed = 1 if inlist(edattain_string, "Grade 6", "Grade 7", "Grade 8")

generate secondary_completed = 0
replace secondary_completed = 1 if inlist(edattain_string, "Grade 9", "Grade 10", "Grade 11", "12th grade, no diploma", "GED or alternative credential", "Regular high school diploma", "1 or more years of college credit, no degree", "Some college, but less than 1 year")

generate university_completed = 0
replace university_completed = 1 if inlist(edattain_string, "Associate's degree, type not specified", "Bachelor's degree", "Master's degree", "Doctoral degree", "Professional degree beyond a bachelor's degree")

*primary school binary
generate primary_or_above = 0
replace primary_or_above = 1 if university_completed == 1
replace primary_or_above = 1 if secondary_completed == 1
replace primary_or_above = 1 if primary_completed == 1

*secondary school binary
generate secondary_or_above = 0
replace secondary_or_above = 1 if university_completed == 1
replace secondary_or_above = 1 if secondary_completed == 1

decode year, gen(year_str)
gen country_string = lower(bplcountry)

replace country_string = "US" if country_string == "United States"

gen country_year = country_string + "_" + year_str

gen hispanic_migrant_status = nativity_string + " " + hispan_string
tab hispanic_migrant_status

gen hispanic_migrant_status_race = nativity_string + " " + race_string

save data/US_2020_v100.dta, replace
clear all

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

*keep if (bplcountry == 23050 | bplcountry == 21080 | bplcountry == 21100 | bplcountry == 22030 | bplcountry == 22040 | bplcountry == 22050 | bplcountry == 22060 | bplcountry == 21180 | bplcountry == 24040)

decode bplcountry, gen(country_string)

gen age_groups = .
replace age_groups = 1 if age <70
replace age_groups = 2 if age >69 & age <80
replace age_groups = 3 if age >79 & age <90

label define age_group_labels 1 "60-69" 2 "69-78" 3 "79-88"
label values age_groups age_group_labels
label variable age_groups "Age Groups"

gen age_60to69 = (age >= 60 & age < 70)
gen age_70to79 = (age >= 70 & age < 80)
gen age_80to89 = (age >= 80 & age < 90)

gen year_of_immigration_groups = .
replace year_of_immigration_groups = 1 if yrimm < 1965 & yrimm != 0
replace year_of_immigration_groups = 2 if yrimm >= 1965 & yrimm < 1981 & yrimm != 0
replace year_of_immigration_groups = 3 if yrimm >= 1980 & yrimm < 2000 & yrimm != 0
replace year_of_immigration_groups = 4 if yrimm >= 2000 & yrimm != 0

label define year_of_immigration_groups_l 1 "Before 1965" 2 "Between 1965 and 1980" 3 "Between 1980 and 1999" 4 "After 2000"
label values year_of_immigration_groups year_of_immigration_groups_l
label variable year_of_immigration_groups "Year of Immigration Cohort"

gen yrimm_before1965 = (yrimm < 1965 & yrimm != 0)
gen yrimm_1965to1980 = (yrimm >= 1965 & yrimm < 1981 & yrimm != 0)
gen yrimm_1980to1999 = (yrimm >= 1980 & yrimm < 2000 & yrimm != 0)
gen yrimm_2000plus = (yrimm >= 2000 & yrimm != 0)

decode nativity, gen(nativity_string)
decode race, gen(race_string)
decode hispan, gen(hispan_string)

replace hispan_string = "hispanic" if hispan_string != "not hispanic"

*a weird thing in the data, dominicans are often classified as not hispanic. changing to hispanic. 
replace hispan_string = "hispanic" if bpl == 26010

replace race_string = "other" if race_string != "white" & race_string != "black"
replace race_string = race_string + " " + hispan_string

gen native_foreign_race = nativity_string + " " + race_string
tab native_foreign_race

gen race_native_category = .

* foreign hispanic
replace race_native_category = 1 if native_foreign_race == "foreign-born black hispanic"
replace race_native_category = 2 if native_foreign_race == "foreign-born white hispanic"
replace race_native_category = 3 if native_foreign_race == "foreign-born other hispanic"

* foreign born not hispanic
replace race_native_category = 4 if native_foreign_race == "foreign-born black not hispanic"
replace race_native_category = 5 if native_foreign_race == "foreign-born white not hispanic"
replace race_native_category = 6 if native_foreign_race == "foreign-born other not hispanic"

*hispanic natives
replace race_native_category = 7 if native_foreign_race == "native-born black hispanic"
replace race_native_category = 8 if native_foreign_race == "native-born white hispanic"
replace race_native_category = 9 if native_foreign_race == "native-born other hispanic"

*non-hispanic natives
replace race_native_category = 10 if native_foreign_race == "native-born black not hispanic"
replace race_native_category = 11 if native_foreign_race == "native-born white not hispanic"
replace race_native_category = 12 if native_foreign_race == "native-born other not hispanic"

label define category_labels 1 "Foreign-Born Black Hispanic" ///
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

tab native_foreign_race
tab race_native_category, miss

gen married_cohab = (marst == 2) if marst != .

gen years_in_us = 2010 - yrimm
replace years_in_us = . if years_in_us == 2010

gen age_at_immigration = age - years_in_us
*replace age_at_immigration = . if (citizen == 2 & bplcountry != 21180)

gen age_at_immigration_groups = .
replace age_at_immigration_groups = 1 if age_at_immigration < 15
replace age_at_immigration_groups = 2 if age_at_immigration >= 15 & age_at_immigration < 50
replace age_at_immigration_groups = 3 if age_at_immigration >= 50


label define age_immig_labels 1 "Under 15" 2 "15-49" 3 "50 and above"
label values age_at_immigration_groups age_immig_labels
label variable age_at_immigration_groups "Age at Immigration Groups"

gen age_at_immigration_under15 = (age_at_immigration < 15)
gen age_at_immigration_15to49 = (age_at_immigration >= 15 & age_at_immigration < 50)
gen age_at_immigration_50plus = (age_at_immigration >= 50)

gen is_naturalized_citizen = (citizen == 3)
gen is_birth_citizen = (citizen == 2)

gen male = (sex == 1)
gen female = (sex == 2)

gen english_speaker = (speakeng == 1)

decode edattain, gen(edattain_string)

gen less_than_primary_completed = (edattain_string == "less than primary completed")
gen primary_completed = (edattain_string == "primary completed")
gen secondary_completed = (edattain_string == "secondary completed")
gen university_completed = (edattain_string == "university completed")

*primary school binary
generate primary_or_above = 0
replace primary_or_above = 1 if university_completed == 1
replace primary_or_above = 1 if secondary_completed == 1
replace primary_or_above = 1 if primary_completed == 1

*primary school binary
generate secondary_or_above = 0
replace secondary_or_above = 1 if university_completed == 1
replace secondary_or_above = 1 if secondary_completed == 1

decode year, gen(year_str)

gen country_year = country_string + "_" + year_str

gen hispanic_migrant_status = nativity_string + " " + hispan_string
tab hispanic_migrant_status

gen hispanic_migrant_status_race = nativity_string + " " + race_string

save data/US_2010_v100.dta, replace

clear

*/
use data/ses_v2.dta

capture append using "C:\Users\Ty\Desktop\ses_international\data\ipumsi_00002_US_2010.dta"

capture append using data/ipumsi_00002_US_2010.dta

decode country, gen(country_string)

keep if age > 59 & age < 90

gen age_groups = .
replace age_groups = 1 if age <70
replace age_groups = 2 if age >69 & age <80
replace age_groups = 3 if age >79 & age <90

label define age_group_labels 1 "60-69" 2 "69-78" 3 "79-88"
label values age_groups age_group_labels
label variable age_groups "Age Groups"

gen age_60to69 = (age >= 60 & age < 70)
gen age_70to79 = (age >= 70 & age < 80)
gen age_80to89 = (age >= 80 & age < 90)

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

tempfile original_data
save `original_data'

* Calculating weights for each country and sex in international sample
foreach c of local countries {
    foreach s of local sexes {
        use `original_data', clear
        
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

save data/All_International.dta, replace

*keep if (country_year == "Mexico_2010" | country_year == "Mexico_2020" | country_year == "PR_2010" | country_year == "PR_2020" | country_year == "US_2010" | country_year == "US_2020")
keep if country_year == "Cuba_2012" | country_year == "DR_2010" | country_year == "Mexico_2010" | country_year == "PR_2010" | country_year == "US_2010"

gen country_year_bpl = "US 2010 PR-born" if bpl == 21180
replace country_year_bpl = "US 2010 DR-born" if bpl == 21100
replace country_year_bpl = "US 2010 Cuban-born" if bpl == 21080
replace country_year_bpl = "US 2010 Mexican-born" if bpl == 22060
replace country_year_bpl = country_year if country_year_bpl == "."

save data/CuDrMePrUs_10_12.dta, replace

clear all
