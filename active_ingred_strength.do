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

	* destring:
	destring active_numerator_strength1, replace
	destring active_numerator_strength2, replace
	destring active_numerator_strength3, replace
	destring active_numerator_strength4, replace
	
	* It is possible to do MME equivalents and find stronger ones, but it's going to be a lot of data work.  
		* There are no more than 80 unique substances (probably fewer)
		* There are not more than 40 "unit types", e.g., mg/l or something. 
		
		keep substancename*
		drop substancename 
		gen rr = _n
		reshape long substancename, i(rr) j(ctr)
		drop rr ctr
		duplicates drop substancename, force
		* there are 71 substance names - that's it.  Maybe that is manageable.  Though there is the problem that these numbers are messed up.  
