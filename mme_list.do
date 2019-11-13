* CDC Opioid List
/*
This file is a list from the CDC with morphine MMEs for every 11 digit NDC code.
In that case it is probably better / more useful.  
*/



global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"



* opioids w/ MME from CDC, plus maybe some additions.  Source was pdmpassist.org  
	* If this list has all of the NDCs, then it's a better list anyway.  So: use this instead of what we already have.  Ask them to upload it as a table.  

clear 
import excel "${op_fp}Conversion Reference Table.xlsx", sheet("Opioids") firstrow
gen productndc = substr(NDC, 1, 9)

drop if MME_Conversion_Factor == . // there is one product with a missing MME 
save "${op_fp}opioid_mme.dta", replace


export delimited using "/Users/austinbean/Desktop/programs/opioids/opioid_11digitNDC_mmes.csv", replace


