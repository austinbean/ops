* Differentiation Instruments
	* TODO - predicted price is required, I think?  

global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


	

use "${op_fp}diff_iv_inputs.dta", clear	// this is the correct characteristics file, from mkt_shares.do
	
split ndccode, p("-")

rename ndccode1 labelerid

merge m:1 labelerid using "${op_pr}product_ownership.dta" 
drop if _merge == 2 // NB outside option and composite inside goods don't match but need to be kept.
drop _merge 

* TODO: construct the prices p_hat here...
	* In the Gandhi/Houde paper this is p. 15 - 16
	* Cites Reynaert/Verboven 2013



* generate groups
egen sub_check = rowtotal(codeine hydrocodone hydromorphone methadone morphine oxycodone tramadol other)
replace other = 1 if sub_check == 0 
egen substance = group(codeine hydrocodone hydromorphone methadone morphine oxycodone tramadol other)
label define subs 8 "codeine" 7 "hydrocodone" 6 "hydromorphone" 5 "methadone" 4 "morphine" 3 "oxycodone" 2 "tramadol" 1 "other", replace
label values substance subs

	* need to reduce the number of packages or add "other"
		* outside option has a package size - it should be 0
egen op = rowtotal(*package)
gen other_package = 0
replace other_package = 1 if op == 0
drop op
egen package = group(small_package medium_package large_package other_package)
label define packs  1 "outside_option" 2 "large_package" 3 "medium_package" 4 "small package", replace
label values package packs

* Construct some rows  
	* Prices and MME
foreach v1 of varlist avg_copay mme package substance{
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

merge m:1 state yr using "${op_fp}mkt_year_package.dta", nogen

gen cov_price_package_instrument = 0
gen cpp_accum = 0

foreach v1 of numlist 1(1)`l1'{
	replace cpp_accum = cpp_accum + (avg_copay`v1' - price)^2 if package == package`v1' & avg_copay`v1' != . & package`v1' != .
}

replace cov_price_package_instrument = cpp_accum 


* Cov price/ingredient
	* sum_j' (p_j' - p_j)^2 ind(ingredient_j == ingredient_j')
	
merge m:1 state yr using "${op_fp}mkt_year_substance.dta", nogen

gen cov_price_ingredient_instrument = 0
gen cpi_accum  = 0
	
foreach v1 of numlist 1(1)`l1'{
	replace cpi_accum = cpi_accum + (avg_copay`v1' - price)^2 if substance == substance`v1' & avg_copay`v1' != . & substance`v1' != .
}

replace cov_price_ingredient_instrument = cpi_accum 
	
* Cov mme/package 
	* sum_j' (mme_j - mme_j')^2 ind(package_size_j' - package_size_j)

gen cov_mme_package_instrument = 0
gen cmp_accum = 0

foreach v1 of numlist 1(1)`l1'{
	replace cmp_accum = cmp_accum + (morphine_eq - mme`v1')^2 if package == package`v1' & mme`v1' != . & package`v1' != .
}

replace cov_mme_package_instrument = cmp_accum 

	
	
* Cov mme/ingredient 
	* sum_j' (mme_j - mme_j')^2 ind(ingredient_j == ingredient_j')
	
gen cov_mme_ingredient_instrument = 0
gen cmi_accum  = 0
	
foreach v1 of numlist 1(1)`l1'{
	replace cmi_accum = cmi_accum + (morphine_eq - mme`v1')^2 if package == package`v1' & avg_copay`v1' != . & package`v1' != .
}

replace cov_mme_ingredient_instrument = cmi_accum 
	
	
* * * * Int * * * *

* price 
	* p_j sum_j' ( p_j' - p_j )

gen pp_accum =  0

foreach v of varlist avg_copay*{
	count if `v' == .
	replace pp_accum = pp_accum + price*(price - `v') if `v' != .
}
gen p_prod_instrument = pp_accum
	
* mme 
	* mme_j sum_j' (mme_j' - mme_j)
gen mmme_accum =  0

foreach v of varlist mme*{
	replace mmme_accum = mmme_accum + morphine_eq*(morphine_eq - `v') if `v' != .
}
gen mme_prod_instrument = mmme_accum


* Collect 

keep ndc_code state yr ndccode mme_prod_instrument p_prod_instrument cov_price_ingredient_instrument cov_mme_package_instrument cov_price_ingredient_instrument cov_price_package_instrument cov_price_mme_instrument sub_instrument package_instrument mme_instrument p_instrument


* standardize within markets
	* check if this is acceptable.   At least dividing by std surely is.  

foreach vv of varlist mme_prod_instrument p_prod_instrument cov_price_ingredient_instrument cov_mme_package_instrument  cov_price_package_instrument cov_price_mme_instrument sub_instrument package_instrument mme_instrument p_instrument{
	bysort state yr: egen s`vv' = std(`vv')
}


sort yr state ndc_code 

keep yr state ndc_code ndccode smme_prod_instrument sp_prod_instrument scov_price_ingredient_instrument scov_mme_package_instrument scov_price_package_instrument scov_price_mme_instrument ssub_instrument spackage_instrument smme_instrument sp_instrument



export delimited "${op_pr}differentiation_ivs.csv", replace
save "${op_pr}differentiation_ivs.dta", replace
