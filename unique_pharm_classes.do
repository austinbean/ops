* unique pharm_classes



global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"


* product file
	import delimited "${op_fp}ndctext/product.txt", clear 	
	keep pharm_class 
	*sample 20

* replace commas by spaces
	gen pharm_cl = subinstr(pharm_class, ",", " ", .)
	
	split pharm_cl, p("]")
	
	gen id = _n
	drop pharm_cl
	reshape long pharm_cl, i(id) j(ctt)
	drop if pharm_cl == ""
	unique pharm_cl 

	
	
	* unique vals.  
drop pharm_classes
drop id
sort pharm_cl
bysort pharm_cl: gen ctr = _n
bysort pharm_cl: egen appearances = max(ctr)
drop ctr 
replace pharm_cl = pharm_cl+"]"
drop ctt
duplicates drop pharm_cl, force


drop category
gen category = substr(pharm_cl, strpos(pharm_cl, "[") , .)
bysort category: gen ctr = _n 
bysort category: egen category_freq = max(ctr)
drop ctr 

sort pharm_cl 

save "${op_fp}pharm_class_list.dta", replace



