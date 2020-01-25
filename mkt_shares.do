* mkt shares...


local whereami = "austinbean"
global hcci_located  "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
di "${hcci_located}"

use "${hcci_located}state_data/all_painmeds_by_state_year.dta", clear

replace pres_count = 1 if std_coins == "1.#QNAN" & pres_count == .
replace pat_count = 1 if std_coins == "1.#QNAN" & pat_count == 1

replace std_coins = "0" if std_coins == "1.#QNAN"
replace std_copay = "0" if std_copay == "1.#QNAN"
replace std_deduct = "0" if std_deduct == "1.#QNAN"

destring std_coins, replace
destring std_copay, replace
destring std_deduct, replace

gen pres_count_low = 1 if pres_count == .
gen pres_count_high = 10 if pres_count == .

egen tot_pres_low = rowmin(pres_count_low pres_count)
egen tot_pres_high = rowmin(pres_count_high pres_count)

* need to add ALL drugs to EVERY state 
	levelsof yr, local(all_years)
	foreach yr1 of local all_years{
	preserve 
	keep if yr == `yr1'
	keep ndc_code 
	duplicates drop ndc_code, force 
	save "${hcci_located}state_data/ndcs_for_`yr1'.dta", replace
	restore
	}
