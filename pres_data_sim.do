* fake data for prescriptions.

global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


clear 
set seed 41
set obs 1000
gen Z_PATID = _n 
gen rexp = runiformint(3, 20)
expand rexp, gen(expr1)
sort Z_PATID
bysort Z_PATID: gen visid = _n 
bysort Z_PATID: gen dinc = runiformint(1,365)
bysort Z_PATID: gen ds = sum(dinc)
gen presdate = visid + 17800 + ds 
format presdate %td
drop expr1 visid dinc ds visid rexp
 
quietly do "${op_pr}rand_ndc_all.do"

merge m:1 NDC using "${op_fp}opioid_mme.dta"
drop if _merge == 2
drop _merge 

* want a continuous history for each patient, so expand months which aren't there.
gen mnth = mofd(presdate)
bysort Z_PATID (presdate): gen mdiff = mnth-mnth[_n-1]
expand mdiff, gen(expr1)
sort Z_PATID presdate expr1 
bysort Z_PATID presdate expr1: gen ctr1 = _n 
replace ctr1 = ctr1 - 1
replace mnth = mnth + ctr1 if expr1 == 1
