* Units of active ingredient...
	* is strength determinable from this data?  

local whereami = "tuk39938"
global op_fp "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/`whereami'/Desktop/programs/opioids/"

		* Import the MME equivalents.

clear
import excel "${op_fp}CDC_Oral_Morphine_Milligram_Equivalents_Sept_2017.xlsx", sheet("Opioids") firstrow
destring DEAClassCode, replace
save "${op_fp}mme_opioids.dta", replace 

clear
import excel "${op_fp}CDC_Oral_Morphine_Milligram_Equivalents_Sept_2017.xlsx", sheet("Abuse-Deterrent Opioids") firstrow
destring NDC_Numeric, replace
append using "${op_fp}mme_opioids.dta"

	* How many product NDC codes have different MME factors at the 9 digit NDC code level?
gen productndc = substr(NDC, 1, 9)
bysort productndc: gen ctr = _n 
bysort productndc: egen countr = max(ctr)
drop ctr 
bysort productndc: egen max_mme = max(MME_Conversion_Factor)
bysort productndc: egen min_mme = min(MME_Conversion_Factor)
gen d1 = max_mme - min_mme 
unique MME_Conversion_Factor, by(productndc) gen(mme_count)
bysort productndc: egen mmme = max(mme_count)
	* It turns out only four 9 digit NDC's are associated with different MME_conversion_factors. 
	* These cover only 19 unique substances.  This is not a big deal.  
	replace MME_Conversion_Factor = min_mme if mmme > 1 & mmme != .
	* Now all nine-digit NDC's have the same MME_conversion_factor.  
preserve 
	duplicates drop productndc, force 
	keep productndc MME_Conversion_Factor 
	save "${op_fp}mme_conversion_factors_by_ndc.dta", replace 
restore 
split Generic_Drug_Name, p("/")

	/*
	TODO - figure out the extent to which we can assign MME to substances on the 
	basis of when it appears in this data.  
	*/



* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
* keep opioids only 
	* not 100% sure this is everything we want.
	replace pharm_class = lower(pharm_class)
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	keep if opi_ind == 1
	drop if tropi_ind == 1
	
* correct NDC length:
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
	gen nd2 = subinstr(productndc, "-", "", . )
	replace productndc = nd2 
	drop nd2 
	merge m:1 productndc using "${op_fp}mme_conversion_factors_by_ndc.dta"
	* Barely any of these actually match.  Maybe 360/6,800
	/*
	TODO - we know what the ingredients are.  We can maybe match that way.
	*/
	
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

		
