clear all
capture log close

* Set working directory
capture cd "/Users/chrissoria/Documents/Research/us_international_ses"
capture cd "/hdir/0/chrissoria/ses_international"
capture cd "C:\Users\Ty\Desktop\ses_international"

use "data/US_2020_v100.dta"

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
*drop Americas, ns category
drop if bpld == 29900

*drop countries with less than 1500 immigrating in to US
egen countrycount = total(perwt) , by(bpld)
drop if countrycount < 1500

*get count and percent
tab bpld [fweight=perwt]

collapse (sum) perwt, by(bpld)
egen total_perwt = total(perwt)
gen percent = perwt / total_perwt
drop total_perwt
rename perwt count
decode bpld, gen(bpld_string)
drop bpld
order bpld_string

export delimited using "data/hispanic_immigrant_count.csv", replace
save "data/hispanic_immigrant_count.dta", replace

capture import excel using "/Users/chrissoria/Documents/Research/us_international_ses/data/gdp_per_capita.xlsx", clear firstrow
capture import excel using "data/gdp_per_capita.xlsx", clear firstrow

rename Country bpld_string
replace bpld_string = "Venezuela" if bpld_string == "Venezuela, RB"
replace bpld_string = "Belize/British Honduras" if bpld_string == "Belize"
replace bpld_string = "Guyana/British Guiana" if bpld_string == "Guyana"
merge 1:1 bpld_string using "data/hispanic_immigrant_count.dta"

drop if _merge == 1
drop _merge

export delimited using "data/hispanic_immigrant_count.csv", replace
save "data/hispanic_immigrant_count.dta", replace

capture import delimited using "/Users/chrissoria/Documents/Research/us_international_ses/data/e60.csv", clear
capture import delimited using "data/e60.csv", clear

keep if period == 2019
rename location bpld_string
keep if indicator == "Life expectancy at age 60 (years)"
keep if dim1 == "Both sexes"

replace bpld_string = "Venezuela" if bpld_string == "Venezuela (Bolivarian Republic of)"
replace bpld_string = "Belize/British Honduras" if bpld_string == "Belize"
replace bpld_string = "Guyana/British Guiana" if bpld_string == "Guyana"
replace bpld_string = "Bolivia" if bpld_string == "Bolivia (Plurinational State of)"

merge 1:1 bpld_string using "data/hispanic_immigrant_count.dta"

keep if bpld_string == "Dominica" | _merge == 3
drop _merge

gen IMR_1950 = 68 if bpld == "Argentina"
gen IMR_2010 = 12.53762599 if bpld == "Argentina"

replace IMR_1950 = 89.33711052 if bpld == "Belize/British Honduras"
replace IMR_2010 = 12.98982464 if bpld == "Belize/British Honduras"

replace IMR_1950 = 182.161 if bpld == "Bolivia"
replace IMR_2010 = 58.09 if bpld == "Bolivia"

replace IMR_1950 = 143.768 if bpld == "Brazil"
replace IMR_2010 = 13.15590527 if bpld == "Brazil"

replace IMR_1950 = 41.47320264 if bpld == "Canada"
replace IMR_2010 = 5.034420313 if bpld == "Canada"

replace IMR_1950 = 139 if bpld == "Chile"
replace IMR_2010 = 7.337242852 if bpld == "Chile"

replace IMR_1950 = 97.32532501 if bpld == "Colombia"
replace IMR_2010 = 10.60047557 if bpld == "Colombia"

replace IMR_1950 = 80.93523979 if bpld == "Costa Rica"
replace IMR_2010 = 8.972639467 if bpld == "Costa Rica"

replace IMR_1950 = 87.121 if bpld == "Cuba"
replace IMR_2010 = 4.584651987 if bpld == "Cuba"

replace IMR_1950 = 63 if bpld == "Dominican Republic"
replace IMR_2010 = 2.647283439 if bpld == "Dominican Republic"

replace IMR_1950 = 144.019 if bpld == "Ecuador"
replace IMR_2010 = 9.329078873 if bpld == "Ecuador"

replace IMR_1950 = 78.04638147 if bpld == "El Salvador"
replace IMR_2010 = 6.394987215 if bpld == "El Salvador"

replace IMR_1950 = 107 if bpld == "Guatemala"
replace IMR_2010 = 19.41221466 if bpld == "Guatemala"

replace IMR_1950 = 82.8 if bpld == "Guyana/British Guiana"
replace IMR_2010 = 12.66726155 if bpld == "Guyana/British Guiana"

replace IMR_1950 = 237.193 if bpld == "Haiti"
replace IMR_2010 = 57.1 if bpld == "Haiti"

replace IMR_1950 = 86 if bpld == "Honduras"
replace IMR_2010 = 7.192101935 if bpld == "Honduras"

replace IMR_1950 = 91.873 if bpld == "Jamaica"
replace IMR_2010 = 19.1 if bpld == "Jamaica"

replace IMR_1950 = 96 if bpld == "Mexico"
replace IMR_2010 = 12.73354295 if bpld == "Mexico"

replace IMR_1950 = 55.14460802 if bpld == "Nicaragua"
replace IMR_2010 = 13.42527788 if bpld == "Nicaragua"

replace IMR_1950 = 53.02095413 if bpld == "Panama"
replace IMR_2010 = 11.99664616 if bpld == "Panama"

replace IMR_1950 = 75.694 if bpld == "Paraguay"
replace IMR_2010 = 14.19464991 if bpld == "Paraguay"

replace IMR_1950 = 164.758 if bpld == "Peru"
replace IMR_2010 = 8.380685714 if bpld == "Peru"

replace IMR_1950 = 70.531 if bpld == "Puerto Rico"
replace IMR_2010 = 6.861 if bpld == "Puerto Rico"

replace IMR_1950 = 74.64748621 if bpld == "Trinidad and Tobago"
replace IMR_2010 = 12.36974376 if bpld == "Trinidad and Tobago"

replace IMR_1950 = 62.5077486 if bpld == "Uruguay"
replace IMR_2010 = 7.410694218 if bpld == "Uruguay"

replace IMR_1950 = 80 if bpld == "Venezuela"
replace IMR_2010 = 15.06078755 if bpld == "Venezuela"

replace IMR_1950 = . if bpld == "Dominica"
replace IMR_2010 = 15.84453368 if bpld == "Dominica"

drop indicator* valuetype parent* locationtype spatial period* islatest dim* datasource* *prefix factvalueuom factvaluetranslationid factcomments language datemodified

export delimited using "data/hispanic_immigrant_count.csv", replace
save "data/hispanic_immigrant_count.dta", replace
