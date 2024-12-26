capture cd "/hdir/0/chrissoria/ses_international/data"
capture cd "C:\Users\Ty\Desktop\ses_international/data_out"
clear all
capture log close

use international__65_89.dta

log using Table1_1, text replace

collapse (mean) married_cohab yrschool age [aweight=perwt], by(country sex age2)
list

log close
