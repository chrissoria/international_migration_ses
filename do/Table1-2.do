capture cd "/hdir/0/chrissoria/ses_international/data"
capture cd "C:\Users\Ty\Desktop\ses_international/data_out"
clear all
capture log close

use international__65_89.dta

collapse (mean) married_cohab yrschool age [aweight=perwt], by(country sex)
list
