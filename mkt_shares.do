* mkt shares...
	* see also pop_markets.do 
		* per pop_markets, reasonable to assume 10% of the population takes opioids.  What about broader painkillers
		* another option: every privately insured person above a certain age is a potential taker in this market.
	* Here do the market shares as national-years.
		
		* HIPAA space API Key:  90B0031BCED14BCD880C273DA32F744D504F2C45687A41AF9B9629FB790718A7

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


 *********************** TO GENERATE NATIONAL MARKET SHARES **********************************
if 0{ // skip when not doing national shares.  

	* Using collapse - watch out the weights apply to ALL statistics, not just the one closest.  

	preserve 	
		collapse (sum) nat_pres_low=tot_pres_low nat_pres_high=tot_pres_high nat_pres_rand=pres_count_rand nat_pats_low=tot_pat_low  nat_pats_high=tot_pat_high nat_pats_rand=pat_count_rand, by(ndc_code yr) // JUST sums - weights apply to all stats.  	
		save "${hcci_located}national_tmp1.dta", replace
	restore 

	preserve 
		collapse (mean) copay_low=avg_copay deduct_low=avg_deduct [fw=tot_pres_low], by(ndc_code yr)
		save "${hcci_located}national_tmp2.dta", replace
	restore 

	preserve 
		collapse (mean) copay_high=avg_copay deduct_high=avg_deduct [fw=tot_pres_high], by(ndc_code yr)
		save "${hcci_located}national_tmp3.dta", replace
	restore 


	* Generate national market shares - market will be nation/year.
	preserve 
		collapse (sum) nat_total_pres_low=tot_pres_low  nat_total_pres_high=tot_pres_high nat_total_pres_rand=pres_count_rand nat_total_pats_low=tot_pat_low nat_total_pats_high=tot_pat_high nat_total_pats_rand=pat_count_rand, by(yr)
		save "${hcci_located}national_tmp4.dta", replace
	restore 


		use "${hcci_located}national_tmp1.dta", clear
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp2.dta", nogen 
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp3.dta", nogen 
		merge m:1 yr using "${hcci_located}national_tmp4.dta", nogen 
		

				* 75 %ile and above gets 150 products in this year.  Probably that's where to start.  
				* collapse the bottom 75% of products into one "OTHER" category.
		levelsof yr, local(all_yr)
		gen p75 = 0 
		foreach nm of local all_yr{
			summarize nat_pats_low, d 
			replace p75 = 1 if nat_pats_low < `r(p75)' & yr == `nm'
		}
	preserve 
		keep if p75 == 0
		drop p75 
		save "${hcci_located}national_inside_goods.dta"	
	restore 
		
		* keep, collapse, etc - that is, create the <75th %ile product out of these 
		keep if p75 == 1
	preserve 
		keep ndc_code yr nat_pres_low nat_pats_low copay_low deduct_low nat_total_pres_low nat_total_pats_low
		collapse (sum) nat_pres_low nat_pats_low  (firstnm) ndc_code, by(yr)
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp5.dta", replace 
	restore 

	preserve 
		keep ndc_code yr nat_pres_low nat_pats_low copay_low deduct_low nat_total_pres_low nat_total_pats_low
		collapse (mean) copay_low deduct_low (firstnm) ndc_code [fw=nat_pres_low] ,by(yr) 
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp6.dta", replace 

	restore
		
	preserve 
		keep ndc_code yr nat_pres_high nat_pats_high copay_high deduct_high nat_total_pres_high nat_total_pats_high
		collapse (sum) nat_pres_high nat_pats_high  (firstnm) ndc_code, by(yr)
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp7.dta", replace
	restore 
		
	preserve 
		keep ndc_code yr nat_pres_high nat_pats_high copay_high deduct_high nat_total_pres_high nat_total_pats_high
		collapse (mean) copay_high deduct_high (firstnm) ndc_code [fw=nat_pres_high] ,by(yr) 
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp8.dta", replace
	restore 

		use "${hcci_located}national_tmp5.dta", clear
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp6.dta", nogen 
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp7.dta", nogen 
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp8.dta", nogen 
		save "${hcci_located}national_composite_inside_good.dta", replace 

		clear 
		use "${hcci_located}national_inside_goods.dta"
		append using "${hcci_located}national_composite_inside_good.dta"

		save "${hcci_located}national_shares.dta", replace
}
******************************** END NATIONAL MARKET SHARES *********************************
	
	
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
	
	... still really want the MME  
	*/
	
	
	* simple product characteristics  
	merge m:1 productndc using "${op_fp}simple_product_chars.dta"
	* TODO outside good all zeros.
	* TODO composite inside as well?  not price


stop	

	* What's left?  Convert these into shares using the outside option. 


