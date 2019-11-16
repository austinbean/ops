* fake data for prescriptions.
	* https://stackoverflow.com/questions/46716199/expand-rows-from-existing-data-in-sql

	* The DEA data has strength per unit.  Can we get total units out of the FDA data?
	
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
bysort Z_PATID (presdate): gen mdiff = abs(mnth-mnth[_n+1])
expand mdiff, gen(expr1)
	* Set as missing when observation is added.  
replace NDC = "" if expr1 == 1
replace presdate = . if expr1 == 1
replace NDC_Numeric  = 0 if expr1 == 1
replace Product_Name  = "" if expr1 == 1
replace Generic_Drug_Name  = "" if expr1 == 1
replace Master_Form  = "" if expr1 == 1
replace Class  = "" if expr1 == 1
replace Drug  = "" if expr1 == 1
replace LongShortActing  = "" if expr1 == 1
replace DEAClassCode  = "" if expr1 == 1
replace Strength_Per_Unit  = . if expr1 == 1
replace UOM  = "" if expr1 == 1
replace MME_Conversion_Factor = 0 if expr1 == 1

sort Z_PATID presdate expr1 
bysort Z_PATID presdate expr1: gen ctr1 = _n 
	* there is another case where mdiff == 0.  But this is nearly it.  
replace mnth = mnth + ctr1 if expr1 == 1
bysort Z_PATID (mnth): gen m2 = mnth - mnth[_n-1]
