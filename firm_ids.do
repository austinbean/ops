* which firms produce which products?

/*

assign firms to each other.
Look up firm and see where it was 

seems like the first four to five of the NDC do identify firms (including subsidiaries),
but one firm can have more than one number?  eg.  Hikma 0143 and 0054, 
or McKesson 49348 and 62011

Ultimately these still have to be looked up.  
*/


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"

	use "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", clear
	merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"
	drop if _merge ==2 
	drop _merge 
	
split ndccode, p("-")	

duplicates drop ndccode1 labelername, force

* Abbvie

* Actavis Pharma


* 
