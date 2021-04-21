* mkt shares...
	* see also pop_markets.do 
		* per pop_markets, reasonable to assume 10% of the population takes opioids.  What about broader painkillers
		* another option: every privately insured person above a certain age is a potential taker in this market.
	* TODO: use package size information to get better shares, esp. for pills. 
	* TODO: better shares for patches / liquids.  
		* Stick to tablets exclusively for now, do patches/liquids later if possible.
		* non-tablets dropped after units_quantity.dta merged.  
		
/*
takes inputs from 
units_measurement.do
package_sizes.do 
mme_list.do 

*/
		
local whereami = "austinbean"
global demo_filep = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/census_demographic_files/"
global op_fp = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
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

	** Patient counts are censored below 10, generate two values, one high and one low 
		* another option runiformint(1,10)

gen pat_count_low = 1 if pres_count == .
gen pat_count_high = 10 if pres_count == .

gen tot_pat_low =  pat_count                           // keep actual if available 
replace tot_pat_low = pat_count_low if pat_count == .  // make 1 if missing - lowest possibility

gen tot_pat_high = pat_count
replace tot_pat_high = pat_count_high if pat_count == .

drop pat_count_low pat_count_high


gen pat_count_rand = runiformint(1,9) if pres_count == .   // random integer 1-9 if missing
replace pat_count_rand = pat_count if pat_count_rand == .

	** Prescription counts were censored too, but if we have 0 std for some variable the number must have been 1.

		* double-check reporting criteria for censoring of prescription counts.
		
replace pres_count = 1 if avg_copay > 0 & std_copay == 0 // this case we know
gen pres_count_low = 2 if pres_count == .                // lowest possible 
gen pres_count_high = 10 if pres_count == .

gen tot_pres_low = pres_count                            // lowest possible if missing 
replace tot_pres_low =  pres_count_low if pres_count == .

gen tot_pres_high = pres_count                           // highest possible if missing
replace tot_pres_high = pres_count_high if pres_count == .

drop pres_count_low pres_count_high

gen pres_count_rand = runiformint(2,9) if pres_count == .  // random 2-9 if missing
replace pres_count_rand = pres_count if pres_count != .

gen cop2 = avg_copay 

	
* per-state composite inside good, below 75%-ile.

levelsof yr, local(all_yr)
levelsof state, local(all_state)
gen p75 = 0
bysort state ndc_code: egen state_tot_pres_high = sum(tot_pres_high) // excludes year on purpose
	foreach st of local all_state{
		// within the state, what drugs are below 75%-ile over the whole period?  might miss some new products, especially late ones
		summarize state_tot_pres_high if state == "`st'", d
		replace p75 = 1 if state_tot_pres_high < `r(p75)' & state == "`st'"
	}
	
	
		*** COMPOSITE INSIDE GOOD - prescription count  *** 
preserve 
	// how many prescriptions were given of p75% drugs within the state year?
	keep if p75 == 1 
	keep state tot_pres_high yr ndc_code
	collapse (sum) tot_pres_high (firstnm) ndc_code  , by(state yr)
	replace ndc_code = "99999999998" // keep an NDC for the composite inside good.
	save "${hcci_located}state_yr_composite_inside_count.dta", replace
restore 


	****** COMPOSITE INSIDE GOOD - mean copay and deductible, weighted by total prescriptions ****** 
preserve 
	// what was the mean price of the composite inside good, weighted by how many times it's in the data
	keep if p75 == 1 
	keep state avg_deduct avg_copay yr ndc_code state_tot_pres_high 
	collapse (firstnm) ndc_code (mean) avg_deduct avg_copay [fw=state_tot_pres_high] , by(state yr)
	replace ndc_code = "99999999998"
	save "${hcci_located}state_yr_composite_inside_price.dta", replace
	merge 1:1 state yr ndc_code using "${hcci_located}state_yr_composite_inside_count.dta"
	drop _merge 
	save "${hcci_located}state_year_composite_inside.dta", replace
restore 

	******* OUTSIDE OPTION - by state year.  ******* 
	drop if p75 == 1                                         // drop the lower 75 %ile by quantity
	append using "${hcci_located}state_year_composite_inside.dta" // add back the composite inside good
	bysort state yr: egen st_pop_count = sum(tot_pat_high)   // total number of patients among top 25%
	bysort state yr: egen st_pres_count = sum(tot_pres_high) // total number of prescriptions among top 25%
	gen outside_patients = st_pop_count*0.2                  // adding 20% of the population as outside option choosers.
	gen outside_pres = outside_patients*2.25                 // 2.25 prescriptions per outside patient (the mean)
	replace st_pop_count = st_pop_count + outside_patients   // total patients in state market, including outside option patients
	replace st_pres_count = st_pres_count + outside_pres     // total number of prescriptions including outside option patients pres. added
	expand 2 if ndc_code == "99999999998", gen(dd)           // this is the composite inside good
	replace ndc_code = "99999999999" if dd == 1              // this is the outside option 
	replace tot_pres_high = outside_pres if ndc_code == "99999999999"
	gen market_shares = tot_pres_high/st_pres_count          // these do work out to be 1 across all markets.  
 	keep if market_shares != .
	
	
	****************** PRODUCT FEATURES  *********************
	merge m:1 ndc_code using "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta"
	* the only unmerged are: small market-share products, plus composite inside and outside options.
	drop if _merge == 2 // small market share products 
	drop _merge 
	/*
	with just this information, I can duplicate
	- active ingredients
	- dea schedule
	- route of administration 	
	*/
	
	
* Conversion from various units of measurement to common mg/l, as much as possible.

	merge m:1 ndc_code using "${op_fp}units_measurement.dta"
	drop if _merge == 2
	drop _merge 
	
	
* Package sizes (e.g., number of pills, mL  )

	merge m:1 ndc_code using "${op_fp}units_quantity.dta"
	
	keep if  unit_quantity != . | (ndc_code == "99999999998" | ndc_code == "99999999999") // stick to pills and related for now, but keep outside option.
	
		* just using pills so these are assigned to the median value (100 tablets)
	replace gas_quantity = 0 if ndc_code == "99999999998" // composite inside good
	replace liquid_quantity = 0 if ndc_code == "99999999998"
	replace unit_quantity = 100 if ndc_code == "99999999998"
	
	replace gas_quantity = 0 if ndc_code == "99999999999" // outside good
	replace liquid_quantity = 0 if ndc_code == "99999999999"
	replace unit_quantity = 100 if ndc_code == "99999999999" // reset this part of outside good to zero later, after creating shares. 
	
	replace avg_copay = 0 if ndc_code == "99999999999"
	drop if _merge == 2
	drop _merge 

	
* Add the MME by ingredient.  
	merge m:1 ndc_code using "${op_fp}per_ndc_mme.dta"
	local vars1 "codeine fentanyl hydrocodone hydromorphone methadone morphine oxycodone oxymorphone tramadol pentazocine opium meperidine butorphanol non_zero_mme mme"
	foreach vv of local vars1{
		replace `vv' = 0 if ndc_code == "99999999998" // composite inside good
		replace `vv' = 0 if ndc_code == "99999999999" // outside good 
		replace `vv' = 0 if `vv' == .                 // must be 0/1 
	}
	drop if _merge == 2
	drop _merge 
	
* Other ingredient:
gen other = 1
egen oo = rowtotal(codeine hydrocodone hydromorphone methadone morphine oxycodone tramadol opium)
replace other = 0 if oo > 0 & oo != .
	
	* check 
egen other_test = rowtotal( other codeine hydrocodone hydromorphone methadone morphine oxycodone tramadol opium)
	// never exceeds 1, never 0  
	
* how should liquid quantity be translated into tablet?  
		* TODO - this needs to be done in units_measurement.do 

	
* Now for better market shares, especially of tablets. 
	* total tablets sold...
	* TODO - this is going to set some market shares back to zero, only for outside good.  
	gen total_tablets = unit_quantity*tot_pres_high 
	
	replace unit_quantity = 0 if ndc_code == "99999999999" // reset outside good quantity. 

	
* state-year market shares

	bysort state yr: egen styrtot = sum(total_tablets)
	gen market_share = total_tablets/styrtot 
	
* some package size variables:
	gen small_package = 1 if unit_quantity <= 30
	gen medium_package = 1 if unit_quantity > 30 & unit_quantity <= 120
	gen large_package = 1 if unit_quantity > 120 & unit_quantity != . // it's never missing.
	
	foreach v1 of varlist small_package medium_package large_package{
		replace `v1' = 0 if `v1' == . 
	}
	
	replace small_package = 0 if ndc_code == "99999999999" // reset outside good quantity.
	replace medium_package = 0 if ndc_code == "99999999999" // reset outside good quantity.
	replace large_package = 0 if ndc_code == "99999999999" // reset outside good quantity.


	* add all ndc's .
	levelsof state, local(st1)
	// 	foreach s of local st1{
	// 		di "_c_`s'_"
	// 	}
	levelsof yr, local(yr1)
preserve
		keep ndc_code 
		duplicates drop ndc_code, force
		foreach state of local st1{
			foreach y of local yr1{
				gen _c_`state'_`y' = 0
			}
		}
	reshape long _c_AK_ _c_AL_ _c_AR_ _c_AZ_ _c_CA_ _c_CO_ _c_CT_ _c_DC_ _c_DE_ _c_FL_ _c_GA_ _c_HI_ _c_IA_ _c_ID_ _c_IL_ _c_IN_ _c_KS_ _c_KY_ _c_LA_ _c_MA_ _c_MD_ _c_ME_ _c_MI_ _c_MN_ _c_MO_ _c_MS_ _c_MT_ _c_NC_ _c_ND_ _c_NE_ _c_NH_ _c_NJ_ _c_NM_ _c_NV_ _c_NY_ _c_OH_ _c_OK_ _c_OR_ _c_PA_ _c_RI_ _c_SC_ _c_SD_ _c_TN_ _c_TX_ _c_UT_ _c_VA_ _c_VT_ _c_WA_ _c_WI_ _c_WV_ _c_WY_, i(ndc_code) j(year)
	
	rename _c_*_ c_*
	
	reshape long c_, i(ndc_code year) j(state) string
	replace c_ = 1e-8
	rename year yr 
	* save and proceed from here. 
	save "${op_fp}all_ndc_state_year.dta", replace 
restore 

* market share outputs:
	preserve 
		keep state yr ndc_code market_share
		* comment this out and check size 
		/*
		merge 1:1 state yr ndc_code using "${op_fp}all_ndc_state_year.dta"
		replace market_share = c_ if  _merge == 2 // adding goods w/ zero market share.
		drop _merge 
		drop c_ 
		*/
		sort state yr ndc_code 
		export delimited using "/Users/austinbean/Desktop/programs/opioids/state_year_shares.csv", replace
		save "${op_fp}state_year_shares.dta", replace
	restore 
	

	
* features needed: state, year, ndc_code, price (avg copay), mme
	* package size?  
* product feature outputs:
	* some opioids are not available in pills: fentanyl oxymorphone meperidine butorphanol 
	* one product is available in a single pill: pentazocine
	preserve 
		duplicates drop ndc_code, force 
		keep yr ndc_code ndccode mme avg_copay tramadol oxycodone morphine methadone hydromorphone hydrocodone codeine other small_package medium_package large_package 
		sort ndc_code 
		export delimited using "/Users/austinbean/Desktop/programs/opioids/products_characteristics.csv", replace
		save "${op_fp}just_characteristics.dta", replace
	restore 
	
	

* for the instruments... need (markets) state, year, (characteristics) price, ingredient, package size, mme
preserve  
	/*
	merge 1:1 state yr ndc_code using "${op_fp}all_ndc_state_year.dta"
	replace market_share = c_ if  _merge == 2 // adding goods w/ zero market share.
	drop _merge 
	drop c_ 
	*/
	keep state yr ndc_code ndccode mme avg_copay tramadol oxycodone morphine methadone hydromorphone hydrocodone codeine other small_package medium_package large_package 
	sort state yr ndc_code
	save "${op_fp}diff_iv_inputs.dta", replace
restore 
