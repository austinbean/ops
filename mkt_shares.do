* mkt shares...


local whereami = "austinbean"
global hcci_located  "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
di "${hcci_located}"

use "${hcci_located}state_data/all_painmeds_by_state_year.dta", clear

drop if state == ""

replace pres_count = 1 if std_coins == "1.#QNAN" & pres_count == .
replace pat_count = 1 if std_coins == "1.#QNAN" & pres_count == 1

replace std_coins = "0" if std_coins == "1.#QNAN"
replace std_copay = "0" if std_copay == "1.#QNAN"
replace std_deduct = "0" if std_deduct == "1.#QNAN"

destring std_coins, replace
destring std_copay, replace
destring std_deduct, replace

gen pat_count_low = 1 if pres_count == .
gen pat_count_high = 10 if pres_count == .

egen tot_pat_low = rowmin(pat_count_low pat_count)
egen tot_pat_high = rowmin(pat_count_high pat_count)

* need to add ALL drugs to EVERY state 
	levelsof yr, local(all_years)
	foreach yr1 of local all_years{
		preserve 
		keep if yr == `yr1'
		keep ndc_code 
		duplicates drop ndc_code, force 
		di "`yr1'"
		count 
		save "${hcci_located}state_data/ndcs_for_`yr1'.dta", replace
		restore
	}
	* these lists seem a little short.  
	* Can use the longer list from FDA.
	
	
* combine these:

use "${hcci_located}state_data/ndcs_for_2009.dta", clear
gen yr2009 = 2009
foreach yr of numlist 2010(1)2013{
	append using "${hcci_located}state_data/ndcs_for_`yr'.dta", gen(yr`yr')
	replace yr`yr' = `yr' if yr`yr' != 0
}
egen year = rowtotal(yr*)
drop yr*
gen ctr = 1
bysort ndc_code: egen tot_year = total(ctr)
drop ctr 
bysort ndc_code: egen mnyear = min(year)
bysort ndc_code: egen mxyear = max(year)
drop year 
duplicates drop ndc_code, force
	
	
* every drug, every state combination:

cross using "${demo_filep}state_names_and_geoids.dta"	
gen np_mkt_share = 0
save "${hcci_located}state_data/all_ndcs_all_states.dta", replace
	
	
* MKT shares initial -> contains non-opioids 

bysort state yr: egen tot_m_h = sum(tot_pat_high)
bysort state yr: egen tot_m_l = sum(tot_pat_low)

gen ms_high = tot_pat_high/tot_m_h 
gen ms_low = tot_pat_low/tot_m_l

