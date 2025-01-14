clear all
capture log close

use "D:\US_2020_v100.dta"

*identify hispanics from central america
gen SALat = 1 if bpl == 210 & hispan ~= 0
*identify hispanics from outside europe, asia, central america
replace SALat = 0 if (bpl < 400 | bpl > 599) & hispan ~= 0 & bpl ~= 210
*identify non-hispanics
replace SALat = 2 if hispan == 0
*identify hispanic-europeans and hispanic-asians
replace SALat = 3 if (bpl >= 400 & bpl <= 599) & hispan ~= 0 & bpl ~= 210

*drop if born in the US
drop if bpl <= 99
*only keep hispanics outside europe and asia
keep if SALat == 1 | SALat == 0

*drop South America, ns category
drop if bpld == 30090

*drop countries with less than 1500 immigrating in to US
egen countrycount = total(perwt) , by(bpld)
drop if countrycount < 1500

*get count and percent
tab bpld [fweight=perwt]

export delimited using "hispanic_immigrant_count.csv", replace
