* Differentiation Instruments
	* TODO - scale all of these at the end


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


	

use "${op_fp}diff_iv_inputs.dta", clear	// this is the correct characteristics file, from mkt_shares.do
	
split ndccode, p("-")

rename ndccode1 labelerid

merge m:1 labelerid using "${op_pr}product_ownership.dta" 
drop if _merge == 2 // NB outside option and composite inside goods don't match but need to be kept.
drop _merge 

* TODO: construct the prices p_hat here...


* Construct some rows  
	* Prices and MME
foreach v1 of varlist avg_copay mme{
	preserve 
		keep state yr `v1' ndc_code 
		bysort state yr: gen ctr = _n 
		drop ndc_code 
		reshape wide `v1', i(state yr) j(ctr)
		save "${op_fp}mkt_year_`v1'.dta", replace
	restore 
}


* square root of squared price differences:	
	* sqrt( sum_j' (p_j - p_j')^2 )
rename avg_copay price 
	
merge m:1 state yr using "${op_fp}mkt_year_avg_copay.dta", nogen
gen p_accum =  0

foreach v of varlist avg_copay*{
	replace p_accum = p_accum + (price - `v')^2 if `v' != .
}
gen p_instrument = sqrt(p_accum)
	
	

* square root of squared distance across a discrete category
	* sqrt( sum_j' ( mme_j - mme_j')^2 )
rename mme morphine_eq
		
merge m:1 state yr using "${op_fp}mkt_year_mme.dta", nogen
gen mme_accum =  0

foreach v of varlist mme*{
	replace mme_accum = mme_accum + (morphine_eq - `v')^2 if `v' != .
}
gen mme_instrument = sqrt(mme_accum)
	
	
* count of products w/ same discrete category - package size:
		* sum_j' ind(package_size_j == package_size_j')
	
gen package_instrument = 0
foreach v1 of varlist small_package medium_package large_package {
	bysort state yr: egen package_sum_`v1' = sum(`v1')
}
foreach v1 of varlist small_package medium_package large_package {
	replace package_instrument = package_sum_`v1' - 1 if `v1' == 1
}	
	
* count of products w/ same discrete category - active ingredient:
	* sum_j' ind(ingredient_j == ingredient_j')
	
gen sub_instrument = 0
foreach v1 of varlist codeine hydrocodone hydromorphone methadone morphine oxycodone tramadol other {
	bysort state yr: egen sub_sum_`v1' = sum(`v1')
}
foreach v1 of varlist codeine hydrocodone hydromorphone methadone morphine oxycodone tramadol other {
	replace sub_instrument = sub_sum_`v1' - 1 if `v1' == 1
}
		

* * * * Covariances * * * *
	* requires ssc install findname
findname avg_copay*, local(cop_var)
local l1: word count `cop_var'


* Cov price/mme 
	* \sum_j'  ( p_j' - p_j)(mme_j' - mme_j)
	
gen cov_price_mme_instrument = 0
gen cpm_accum = 0

foreach v1 of numlist 1(1)`l1'{
	replace cpm_accum = cpm_accum + (avg_copay`v1' - price)*(mme`v1' - morphine_eq) if avg_copay`v1' != . & mme`v1' != .
}

replace cov_price_mme_instrument = cpm_accum 
	
* Cov price/package 
	* \sum_j' (p_j' - p_j)^2 ind(package_size_j' - package_size_j ) # the sum of squared prices if the package sizes are the same.  
	
* Cov price/ingredient
	* sum_j' (p_j' - p_j)^2 ind(ingredient_j == ingredient_j')
	
* Cov mme/package 
	* sum_j' (p_j' - p_j)^2 ind(package_size_j' - package_size_j)
	
* Cov mme/ingredient 
	* sum_j' (mme_j - mme_j')^2 ind(ingredient_j == ingredient_j')
	
	
	
* * * * Int * * * *

* price 
	* p_j sum_j' ( p_j' - p_j )
	
gen pp_accum =  0

foreach v of varlist avg_copay*{
	replace pp_accum = pp_accum + price*(price - `v') if `v' != .
}
gen p_prod_instrument = sqrt(pp_accum)
	
* mme 
	* mme_j sum_j' (mme_j' - mme_j)
gen mmme_accum =  0

foreach v of varlist mme*{
	replace mmme_accum = mmme_accum + morphine_eq*(morphine_eq - `v') if `v' != .
}
gen mme_prod_instrument = sqrt(mmme_accum)
