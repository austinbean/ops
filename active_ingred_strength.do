* Units of active ingredient...
	* is strength determinable from this data?  


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
* keep opioids only 
	* not 100% sure this is everything we want.
	replace pharm_class = lower(pharm_class)
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	keep if opi_ind == 1
	drop if tropi_ind == 1
	
* split active ingredients.  
	split active_numerator_strength, p(";")
	split active_ingred_unit, p(";")
	split substancename, p(";")
