capture cd "/hdir/0/chrissoria/ses_international"
capture include cd "C:\Users\Ty\Desktop\ses_international"

clear all
capture log close

use data/international__65_89.dta

collapse (mean) female married_cohab less_than_primary_completed primary_completed secondary_completed university_completed age [aweight=perwt_age_standardized], by(country)
list
export delimited using "tables/I_nativity_table.csv", replace

*table 2
clear all 
use data/US_65_89.dta

preserve

*nativities of interest in the US as migrants
collapse (mean) female age married_cohab english_speaker is_citizen age_at_immigration years_in_us less_than_primary_completed primary_completed secondary_completed university_completed education_unknown [aweight=perwt], by(bplcountry)
list
export delimited using "tables/US_nativity_table.csv", replace

restore

preserve
*nativities of interest in the US as migrants by sex

collapse (mean) age married_cohab english_speaker is_citizen age_at_immigration years_in_us less_than_primary_completed primary_completed secondary_completed university_completed [aweight=perwt], by(bplcountry sex)
list
export delimited using "tables/US_nativity_table_by_sex.csv", replace

restore

preserve

collapse (mean) female age married_cohab english_speaker is_citizen age_at_immigration years_in_us less_than_primary_completed primary_completed secondary_completed university_completed [aweight=perwt], by(race_native_category)
list

export delimited using "tables/US_racial_nativity_table.csv", replace

restore

preserve

*lumping all of our nativities of interest into one category
collapse (mean) married_cohab yrschool sex age [aweight=perwt], by(nativity)
list

export delimited using "tables/US_nativity_binary_table.csv", replace

restore
