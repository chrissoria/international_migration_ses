capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close

foreach data in "2020" "2010" {
use "data/usa_00003.dta", clear
if "`data'" == "2020" {
    keep if sample == 202003
}
else {
	keep if sample == 201005
}
keep if age > 59

gen HispanicCategory = .
*identify hispanics from central america
replace HispanicCategory = 3 if bpl == 210 & hispan ~= 0
*identify hispanics from outside europe, asia, central america
replace HispanicCategory = 2 if (bpl < 400 | bpl > 599) & hispan ~= 0 & bpl ~= 210
*identify hispanic-europeans and hispanic-asians
replace HispanicCategory = 1 if (bpl >= 400 & bpl <= 599) & hispan ~= 0 & bpl ~= 210
*identify non-hispanics
replace HispanicCategory = 0 if HispanicCategory == .

label define HispanicCategory_labels 3 "Central-American Latino" 2 "Other Latino" 1 "Hispanic Non-Latino" 0 "Not Latino"
label values HispanicCategory HispanicCategory_labels
label variable HispanicCategory "Hispanic Category"

decode HispanicCategory, gen(HispanicCategoryString)

/*household variables 
FAMSIZE counts the number of own family members residing with each individual, including the person her/himself. Persons not living with others related to them by blood, marriage/cohabitating partnership, or adoption are coded 1.
*/
gen lives_alone = (famsize == 1 & famsize != .)

gen child_in_household = 0
replace child_in_household = 1 if nchild > 0 
tab child_in_household

/*for this study, we want to focus on "hispanic" as in those who are non-european
gen latin_american = (bpld > 21019 & bpld < 24000)
replace latin_american = 1 if hispan > 0 & bpld == 24040
tab latin_american hispan
replace hispan = 0 if latin_american == 0
*/

gen age_groups = .
replace age_groups = 1 if age <70
replace age_groups = 2 if age >69 & age <80
replace age_groups = 3 if age >79 & age <90
replace age_groups = 4 if age >89

label define age_group_labels 1 "60-69" 2 "69-78" 3 "79-89" 4 "90+"
label values age_groups age_group_labels
label variable age_groups "Age Groups"

gen age_60to69 = (age >= 60 & age < 70)
gen age_70to79 = (age >= 70 & age < 80)
gen age_80to89 = (age >= 80 & age < 90)
gen age_90plus = age >= 90

gen year_of_immigration_groups = .
replace year_of_immigration_groups = 1 if yrimmig < 1965 & yrimmig != 0
replace year_of_immigration_groups = 2 if yrimmig >= 1965 & yrimmig < 1981 & yrimmig != 0
replace year_of_immigration_groups = 3 if yrimmig >= 1980 & yrimmig < 2000 & yrimmig != 0
replace year_of_immigration_groups = 4 if yrimmig >= 2000 & yrimmig != 0

label define year_of_immigration_groups_l 1 "Before 1965" 2 "1965 - 1979" 3 "1980 - 1999" 4 "After 1999"
label values year_of_immigration_groups year_of_immigration_groups_l
label variable year_of_immigration_groups "Year of Immigration Cohort"

decode year_of_immigration_groups, gen(year_of_immig_groups_string)

gen yrimm_before1965 = (yrimmig < 1965 & yrimmig != 0)
gen yrimm_1965to1980 = (yrimmig >= 1965 & yrimmig < 1981 & yrimmig != 0)
gen yrimm_1980to1999 = (yrimmig >= 1980 & yrimmig < 2000 & yrimmig != 0)
gen yrimm_2000plus = (yrimmig >= 2000 & yrimmig != 0)

decode bpl, gen(bpl_string)
local states `" "alabama" "alaska" "arizona" "arkansas" "california" "colorado" "connecticut" "delaware" "florida" "georgia" "hawaii" "idaho" "illinois" "indiana" "iowa" "kansas" "kentucky" "louisiana" "maine" "maryland" "massachusetts" "michigan" "minnesota" "mississippi" "missouri" "montana" "nebraska" "nevada" "new hampshire" "new jersey" "new mexico" "new york" "north carolina" "north dakota" "ohio" "oklahoma" "oregon" "pennsylvania" "rhode island" "south carolina" "south dakota" "tennessee" "texas" "utah" "vermont" "virginia" "washington" "west virginia" "wisconsin" "wyoming" "district of columbia" "'
gen contains_us_state = 0
foreach state of local states {
    replace contains_us_state = 1 if strpos(lower(bpl_string), lower("`state'")) > 0
}

decode bpld, gen(bplcountry)

replace bplcountry = "united states" if contains_us_state == 1

gen nativity_string = "."
replace nativity_string = "foreign-born" if contains_us_state == 0
replace nativity_string = "native-born" if contains_us_state == 1

decode race, gen(race_string)
replace race_string = "black" if race_string == "black/african american"

decode hispan, gen(hispan_string)

replace hispan_string = "hispanic" if hispan_string != "not hispanic"
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
replace age_at_immigration_groups = 2 if age_at_immigration >= 15 & age_at_immigration < 25
replace age_at_immigration_groups = 3 if age_at_immigration >= 25 & age_at_immigration < 50
replace age_at_immigration_groups = 4 if age_at_immigration >= 50

label define age_immig_labels 1 "Under 15" 2 "15-24" 3 "25-50" 4 "50 and above"
label values age_at_immigration_groups age_immig_labels
label variable age_at_immigration_groups "Age at Immigration Groups"

gen age_at_immigration_under15 = age_at_immigration < 15
gen age_at_immigration_15to24 = age_at_immigration >= 15 & age_at_immigration < 25
gen age_at_immigration_25to49 = age_at_immigration >= 25 & age_at_immigration < 50
gen age_at_immigration_50plus = (age_at_immigration >= 50)

gen is_naturalized_citizen = (citizen == 2)
gen is_born_citizen = (citizen == 0)
gen is_citizen = (citizen != 3)

gen male = (sex == 1)
gen female = (sex == 2)

decode speakeng, gen(speakeng_string)

gen english_speaker = 0
replace english_speaker = 1 if speakeng_string != "does not speak english"

gen english_speaker_not_well = 0
replace english_speaker_not_well = 1 if speakeng_string == "yes, but not well"

gen english_speaker_well = 0
replace english_speaker_well = 1 if (english_speaker == 1 & english_speaker_not_well == 0)

decode educd, gen(edattain_string)

generate less_than_primary_completed = 0
generate primary_completed = 0
generate secondary_completed = 0
generate university_completed = 0

if "`data'" == "2020" {
    replace less_than_primary_completed = 1 if inlist(edattain_string, "grade 1", "grade 2", "grade 3", "grade 4", "grade 5", ///
        "kindergarten", "no schooling completed", "nursery school, preschool")
    
    replace primary_completed = 1 if inlist(edattain_string, "grade 6", "grade 7", "grade 8")
    
    replace secondary_completed = 1 if inlist(edattain_string, "grade 9", "grade 10", "grade 11", "12th grade, no diploma", ///
        "ged or alternative credential", "regular high school diploma", ///
        "1 or more years of college credit, no degree", "some college, but less than 1 year")
    
    replace university_completed = 1 if inlist(edattain_string, "associate's degree, type not specified", "bachelor's degree", ///
        "master's degree", "doctoral degree", "professional degree beyond a bachelor's degree")
}
else {
    replace less_than_primary_completed = 1 if inlist(edattain_string, "nursery school to grade 4", "grade 5 or 6", ///
        "no schooling completed")
    
    replace primary_completed = 1 if inlist(edattain_string, "grade 7 or 8")
    
    replace secondary_completed = 1 if inlist(edattain_string, "grade 9", "grade 10", "grade 11", "12th grade, no diploma", ///
        "high school graduate or ged", "1 or more years of college credit, no degree", "some college, but less than 1 year")
    
    replace university_completed = 1 if inlist(edattain_string, "associate's degree, type not specified", "bachelor's degree", ///
        "master's degree", "doctoral degree", "professional degree beyond a bachelor's degree")	
}


tab less_than_primary_completed
tab primary_completed
tab secondary_completed
tab university_completed

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

gen country_year = country_string + "_" + year_str

gen hispanic_migrant_status = nativity_string + " " + hispan_string
tab hispanic_migrant_status

gen hispanic_category_migrant_status = nativity_string + " " + HispanicCategoryString
tab hispanic_category_migrant_status

replace hispanic_category_migrant_status = "foreign-born Not Latino" if hispanic_category_migrant_status == "foreign-born Hispanic Non-Latino"

gen hispanic_migrant_status_race = nativity_string + " " + race_string

if "`data'" == "2020" {
        save "data/US_2020_v100.dta", replace
    }
    else {
        save "data/US_2010_v100.dta", replace
    }
clear all
}


use data/ses_v2.dta

capture append using "C:\Users\Ty\Desktop\ses_international\data\ipumsi_00002_US_2010.dta"

capture append using data/ipumsi_00002_US_2010.dta

decode country, gen(country_string)

keep if age > 59

gen lives_alone = (famsize == 1 & famsize != .)
gen child_in_household = 0
replace child_in_household = 1 if nchild > 0 
tab child_in_household

gen age_groups = .
replace age_groups = 1 if age <70
replace age_groups = 2 if age >69 & age <80
replace age_groups = 3 if age >79 & age <90
replace age_groups = 4 if age >89

label define age_group_labels 1 "60-69" 2 "69-78" 3 "79-89" 4 "90+"
label values age_groups age_group_labels
label variable age_groups "Age Groups"

gen age_60to69 = (age >= 60 & age < 70)
gen age_70to79 = (age >= 70 & age < 80)
gen age_80to89 = (age >= 80 & age < 90)
gen age_90plus = age >= 90

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

*keep if (country_year == "Mexico_2010" | country_year == "Mexico_2020" | country_year == "PR_2010" | country_year == "PR_2020" | country_year == "US_2010" | country_year == "US_2020")

keep if country_year == "Cuba_2012" | country_year == "DR_2010" | country_year == "Mexico_2010" | country_year == "PR_2010" | country_year == "US_2010" | country_year == "Mexico_2020" | country_year == "PR_2020" | | country_year == "US_2020"

save data/CuDrMePrUs_10_12.dta, replace

clear all
