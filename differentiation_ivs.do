* Differentiation Instruments


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


	

use "${op_fp}diff_iv_inputs.dta", clear	// this is the correct characteristics file, from mkt_shares.do
	
split ndccode, p("-")

rename ndccode1 labelerid

merge m:1 labelerid using "${op_pr}product_ownership.dta" 
drop if _merge == 2 // NB outside option and composite inside goods don't match but need to be kept.
drop _merge 


* TODO: construct the prices p_hat here...


* square root of squared price differences:	
	* sqrt( sum_j' (p_j - p_j')^2 )
	
	
* square root of squared distance across a discrete category
	* sqrt( sum_j' ( mme_j - mme_j')^2 )
	
	
* count of products w/ same discrete category - package size:
		* sum_j' ind(package_size_j == package_size_j')
		
		
* count of products w/ same active ingredient:
	* sum_j' ind(ingredient_j == ingredient_j')
		
* * * * Covariances * * * *

* Cov price/mme 
	* \sum_j'  ( p_j' - p_j)(mme_j' - mme_j)
	
* Cov price/package 
	* \sum_j' (p_j' - p_j)^2 ind(package_size_j' - package_size_j )
	
* Cov price/ingredient
	* sum_j' (p_j' - p_j)^2 ind(ingredient_j == ingredient_j')
	
* Cov mme/package 
	* sum_j' (p_j' - p_j)^2 ind(package_size_j' - package_size_j)
	
	
* Cov mme/ingredient 
	* sum_j' (mme_j - mme_j')^2 ind(ingredient_j == ingredient_j')
	
	
	
* * * * Int * * * *

* price 
	* p_j sum_j' ( p_j' - p_j )

* mme 
	* mme_j sum_j' (mme_j' - mme_j)
