* Differentiation Instruments


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"

	use "${op_pr}drug_characteristics.dta", clear
	merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"
	drop if _merge ==2 
	drop _merge 
	
split ndccode, p("-")

duplicates drop ndccode1 labelername, force

* Need to add the product characteristics too.  


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
