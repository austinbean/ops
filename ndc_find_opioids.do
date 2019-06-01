
* Tag opioid products in FDA NDC files

global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
	replace pharm_class = lower(pharm_class)
		* tagging tropi pharm_class and then dropping will keep only opioid-related when tagging based on opi
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	drop if tropi_ind == 1
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	keep if opi_ind == 1
	drop opi_ind tropi_ind
	
* active numerator strength and unit have multiple entries per drug
	split active_numerator_strength, p(";")
	split active_ingred_unit, p(";")
	* redo this so the units are constant
	
* active substance may be more than one ingredient per drug
	split substancename, p(";")
	* to identify all actual opioid compounds, take those with one ingredient and match unique names?
	preserve
	keep substancename*
	drop substancename
	gen id = _n
	reshape long substancename, i(id) j(ctt)
	drop if substancename == ""
	duplicates drop substancename, force
	* there are 70 unique substances
	* Do we know how much of each ingredient for multi-ingredient drugs?
		* Yes we do - they are listed in order: substancename, active_numerator_strength, active_ingred_unit
	
	
	
	
	
	
* package file
	import delimited "${op_fp}ndctext/package.txt", clear 
