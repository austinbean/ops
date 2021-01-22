* state pop and opioid user market shares:
	* see also mkt_shares.do
/*

	have these privately insured patients by state
	know opioid prescription receivers by state
	can get avg prescriptions per state when this is large
	make this assumption for other states:
		- potential users is x% of state population (among insured?)
		- potential prescriptions is based on the average?

*/

local whereami = "austinbean"
global demo_filep = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/census_demographic_files/"
global hcci_located = "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
global hcci = "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/"
di "${hcci_located}"

import excel "${hcci_located}total_opioid_patients_by_state_year.xlsx", sheet("Sheet1") clear firstrow
rename COUNT OP_COUNT
save "${hcci_located}total_opioid_patients_by_state_year.dta", replace

import excel "${hcci_located}total_patients_by_state_year.xlsx", sheet("Sheet1") clear firstrow
rename COUNT STATE_COUNT
save "${hcci_located}total_patients_by_state_year.dta", replace

merge 1:1 STATE YR using "${hcci_located}total_opioid_patients_by_state_year.dta"
drop if _merge != 3
drop _merge 

destring OP_COUNT, replace
destring STATE_COUNT, replace
gen OP_FRAC = OP_COUNT/STATE_COUNT

bysort YR: summarize OP_FRAC, d

* from mkt_shares.do, we have 2-3 prescriptions per person per year.
bysort STATE : egen MAX_POP = max(STATE_COUNT)
bysort STATE : egen MAX_FRAC = max(OP_FRAC)
gen diff = MAX_FRAC - OP_FRAC

gen MAX_MARKET = ceil(3*MAX_POP*MAX_FRAC) // mkt size: 3 prescriptions x largest population x largest fraction of users 
replace MAX_MARKET = ceil((1.05)*MAX_MARKET) if MAX_POP == STATE_COUNT & MAX_FRAC == OP_FRAC // increase for state-years where the max population and the max opioid frac are the same.  5% per the 99th %-ile of diff = MAX_FRAC - OP_FRAC 

drop diff MAX_FRAC MAX_POP 
destring YR, replace
merge 1:1 STATE YR using "${hcci_located}state_data/tot_prescriptions_state_year.dta"

browse if TOT_MKT_H > MAX_MARKET | TOT_MKT_L > MAX_MARKET

	* four state year records where max_market < TOT_MKT_L or _H 
replace MAX_MARKET = (1.05)*TOT_MKT_H if TOT_MKT_H > MAX_MARKET | TOT_MKT_L > MAX_MARKET



histogram OP_FRAC, by(YR, total)
	* What about prescriptions?  
	* Take the number of patients here by state, compute the total number of prescriptions (by state), get a per-patient 
	* count, then compute avg. # of prescriptions per patient.  
	* Can then scale this to total # of privately insured patients?  
	
	foreach yr of numlist 2009(1)2013{
	graph bar OP_FRAC if YR == "`yr'", over(STATE, label(angle(45) labsize(vsmall)) sort(1))  graphregion(color(white))  title("Fraction of Privately Insured Patients w/ Opioid Prescription") subtitle("`yr'") ytitle("")
	
	graph save "${hcci}graphs/state_opioid_usage_`yr'.gph", replace 
	graph export "${hcci}graphs/state_opioid_usage_`yr'.png", replace 

	}
	
	collapse (max) OP_FRAC, by(STATE)
	
	graph bar OP_FRAC, over(STATE, label(angle(45) labsize(vsmall)) sort(1)) graphregion(color(white)) ytitle("") title("Largest Fraction of Patients w/ Opioid Prescriptions" "2009 - 2013")
	graph save "${hcci}graphs/state_max_opioid_usage_`yr'.gph", replace 
	graph export "${hcci}graphs/state_max_opioid_usage_`yr'.png", replace
	save "${hcci_located}opioid_max_frac_by_state_year.dta", replace
	
* Now, how many prescriptions?  What does the state level ACS look like?
	

