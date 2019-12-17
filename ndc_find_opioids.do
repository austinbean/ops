* Tag opioid products in FDA NDC files

global op_fp "/Users/tuk39938/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/tuk39938/Desktop/programs/opioids/"


* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
	replace pharm_class = lower(pharm_class)
		* tagging tropi pharm_class and then dropping will keep only opioid-related when tagging based on opi
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	drop if tropi_ind == 1
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	keep if opi_ind == 1
	drop opi_ind tropi_ind
	
	* reference on meaning of pharm classes:
	* https://www.fda.gov/industry/structured-product-labeling-resources/pharmacologic-class 
	* There are not other things to worry about in the pain-relief category.  There's tylenol, NSAIDs and opioids.  
	
	
* Fix leading zero problem with short NDC codes
	split productndc, p("-")
	gen len1 = strlen(productndc1)
	gen len2 = strlen(productndc2)
	* pad the front if the format is to short
	replace productndc = "0"+productndc if len1 == 4
	replace productndc = "00"+productndc if len1 == 3
	replace productndc = "000"+productndc if len1 == 2
	replace productndc = "0000"+productndc if len1 == 1
	* pad the end in case it is to short
	replace productndc = productndc+"0" if len2 == 3
	replace productndc = productndc+"00" if len2 == 2
	replace productndc = productndc+"000" if len2 == 1
	* drop unused
	drop len1 productndc1 productndc2 
	gen lentest = strlen(productndc)
	tab lentest 
	drop lentest 
	
* Generate a list of product NDC's only	

	preserve 
	duplicates drop productndc, force
	keep productndc proprietaryname substancename
	export delimited using "${op_pr}opioid_ndc_list.csv", replace datafmt
	restore
*/	
	
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
	drop id ctt 
	export delimited using "${op_fp}opioid_ingredient_list.csv", replace
	restore
	* there are 70 unique substances in any "opi" class drug
	* Do we know how much of each ingredient for multi-ingredient drugs?
		* Yes we do - they are listed in order: substancename, active_numerator_strength, active_ingred_unit

	* There are a few duplicate productndc numbers - frequently the difference is "startmarketdate", at least once  
	* some other piece of info like DEA schedule is missing in one of them
	

	
	
* package file
	import delimited "${op_fp}ndctext/package.txt", clear 
