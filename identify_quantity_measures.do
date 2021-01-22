* identify quantities

/*

what package information implies what quantity... runs if necessary in national_market_shares.do

*/

keep if _merge != 2   
	split packagedescription
	keep packagedescription*
	gen id = _n
	rename packagedescription packd
	reshape long packagedescription, i(id) j(ctrr)
	drop if packagedescription == ""
	sort packagedescription 
	duplicates drop packagedescription packd, force
