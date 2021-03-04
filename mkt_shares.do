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
	replace ndc_code = "00000000000" // keep an NDC for the composite inside good.
	save "${hcci_located}state_yr_composite_inside_count.dta", replace
restore 


	****** COMPOSITE INSIDE GOOD - mean copay and deductible, weighted by total prescriptions ****** 
preserve 
	// what was the mean price of the composite inside good, weighted by how many times it's in the data
	keep if p75 == 1 
	keep state avg_deduct avg_copay yr ndc_code state_tot_pres_high 
	collapse (firstnm) ndc_code (mean) avg_deduct avg_copay [fw=state_tot_pres_high] , by(state yr)
	replace ndc_code = "00000000000"
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
	expand 2 if ndc_code == "00000000000", gen(dd)           // this is the composite inside good
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
	
	keep if  unit_quantity != . | (ndc_code == "00000000000" | ndc_code == "99999999999") // stick to pills and related for now, but keep outside option.
	
		* just using pills so these are assigned to the median value (100 tablets)
	replace gas_quantity = 0 if ndc_code == "00000000000" // composite inside good
	replace liquid_quantity = 0 if ndc_code == "00000000000"
	replace unit_quantity = 100 if ndc_code == "00000000000"
	
	replace gas_quantity = 0 if ndc_code == "99999999999" // outside good
	replace liquid_quantity = 0 if ndc_code == "99999999999"
	replace unit_quantity = 100 if ndc_code == "99999999999"
	drop if _merge == 2
	drop _merge 

	
* Add the MME by ingredient.  
	merge m:1 ndc_code using "${op_fp}per_ndc_mme.dta"
	local vars1 "codeine fentanyl hydrocodone hydromorphone methadone morphine oxycodone oxymorphone tramadol pentazocine opium meperidine butorphanol non_zero_mme mme"
	foreach vv of local vars1{
		replace `vv' = 0 if ndc_code == "00000000000" // composite inside good
		replace `vv' = 0 if ndc_code == "99999999999" // outside good 
	}
	drop if _merge == 2
	drop _merge 
	
	
* how should liquid quantity be translated into tablet?  
		* TODO - this needs to be done in units_measurement.do 

	
* Now for better market shares, especially of tablets. 
	* total tablets sold...
	
	gen total_tablets = unit_quantity*tot_pres_high 
	
* state-year market shares

	bysort state yr: egen styrtot = sum(total_tablets)
	gen market_share = total_tablets/styrtot 
	
* some package size variables:
	gen small_package = 1 if unit_quantity <= 30
	gen medium_package = 1 if unit_quantity > 30 & unit_quantity <= 120
	gen large_package = 1 if unit_quantity > 120 & unit_quantity != . // it's never missing.  

* market share outputs:
	preserve 
		keep state yr ndc_code market_share 
		export delimited using "/Users/austinbean/Desktop/programs/opioids/state_year_shares.csv", replace
	restore 
	
* features needed: state, year, ndc_code, price (avg copay), mme
	* package size?  
* product feature outputs:
	* some opioids are not available in pills: fentanyl oxymorphone meperidine butorphanol 
	* one product is available in a single pill: pentazocine
	preserve 
		duplicates drop ndc_code, force 
		keep yr ndc_code mme avg_copay tramadol oxycodone morphine methadone hydromorphone hydrocodone codeine small_package medium_package large_package 
		export delimited using "/Users/austinbean/Desktop/programs/opioids/products_characteristics.csv", replace
	restore 
