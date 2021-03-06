* Opioids and equivalents.

/*
- the purpose of this file is to check what string matches will get opioids
- starts by looking for anything with the string "op" in the drug class.
- in the end, can drop anything with the string "tropi" and then keep "opi"
and this will be only opioids
- Not yet clear is whether this is everything we should be interested in.  

-> 

*/

local locd = "austinbean"
*global locd "Austin Bean"
global op_fp "/Users/`locd'/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/`locd'/Desktop/programs/opioids/"




* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
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
	gen NDC = subinstr(productndc, "-", "", .)
		* FOR THE HCCI DATA SIMULATION 
	preserve 
	keep NDC pharm_class 
	rename NDC shortndc 
	duplicates drop shortndc, force 
	rename pharm_class MAJ_THRPTC_CL_pharm 
	save "${op_fp}ndc_pharm_class.dta", replace 
	restore 
*  opioid related:
	preserve
	duplicates drop pharm_class, force
	replace pharm_class = lower(pharm_class)
	gen op_ind = 1 if strpos(pharm_class, "op")
	keep if op_ind == 1
	*levelsof pharm_class, local(op_dr)
	
	split pharm_class, p(" ")
foreach var1 of varlist pharm_classes*{
	
	gen `var1'_ind = 1 if strpos(`var1', "op")

}

	keep pharm_clas*
	gen id = _n
	drop pharm_classes
	drop pharm_classes_ind
	rename pharm_classes*_ind pharm_classes_ind*
		* fast provided only done for the strpos(pharm_class, "op") matches
	reshape long pharm_classes pharm_classes_ind, i(id) j(ctt)
		* from 45,000,000 rows to 650,000 in the next step
	drop if pharm_classes == ""
		* to 6,575 rows
	keep if pharm_classes_ind == 1
		* to 72
	duplicates drop pharm_classes, force
	sort pharm_classes
	* There are 72 words in some pharmacy class which contain the string "op" 
	* Every mention of "opioid" will be captured by matching on "opi"
	restore
	
	
* List all pharmacy classes including string "opi"
	duplicates drop pharm_class, force
	replace pharm_class = lower(pharm_class)
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	keep if opi_ind == 1
	drop if tropi_ind == 1
	* Now should have ONLY opioids.
		* this gets only opioids.  
	gen opioid = 1 if strpos(pharm_class, "opioid")

	
	foreach op1 of local op_dr{
		di "     "
		di "`op1'"
		di "     "    
	}

* There are four unique words with the string "opi" : Thyrotropin, Gonadotropin, Adrenocorticotropic and Opioid	
* the other three involve "tropi", so drop "trop" and keep "opi"
	
	
	gen prob_opi = 0
	foreach op1 of local op_dr{
	
		replace prob_opi = 1 if pharm_class == "`op1'"
	
	}
		
	
	

*import delimited "${op_fp}ndctext/package.txt", clear 



