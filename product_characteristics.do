* product characteristics
/*

EARLIER version - should use mkt_shares instead - creates shares and characteristics.  

* What product properties?
	* active ingredients CHECK 
	* delivery method/dosage form OR maybe routename, but there's not much variation CHECK 
	* MME - this is the important TODO
	* DEA schedule CHECK 


	* Can the DEA opioid list be merged to this one, taking off the last two digits of that NDC code?
* market share data given in national_market_shares.do - need to merge via NDC 



*/



local whereami = "austinbean"
global op_fp "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/`whereami'/Desktop/programs/opioids/"


* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
	



* keep opioids only 
	* not 100% sure this is everything we want.
	replace pharm_class = lower(pharm_class)
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	keep if opi_ind == 1
	drop if tropi_ind == 1
	drop opi_ind tropi_ind 
	
	/*
	* temp file to match strings:
	keep productndc
	replace productndc = subinstr(productndc, "-", "", .)
	export delimited using "/Users/austinbean/Desktop/fda_ndcs.csv", datafmt replace
	*/
		
* NDC codes are correct - don't lengthen them.  These exclude just the last 1 or two digits,but varying lengths prior to the - are fine.  

* CHARACTERISTICS 
	
	
	
* route name indicators.  
preserve 
	rename productndc NDC
	keep NDC routename
	split routename, p(";")
	gen routebackup = routename1 // there may be two names, keep the first.  
	drop routename 
	gen rr = _n
	reshape long routename, i(rr) j(ctr)
	replace routename = strtrim(routename)
	drop if routename == ""
	bysort routename: gen rctr = _n
	bysort routename: egen tctr = max(rctr)
	replace routename = "OTHER" if tctr < 20
	tabulate routename, gen(route_n)
	/*
	foreach v1 of varlist route_n*{
		qui levelsof routename if `v1' == 1, local(nm)
		di "rename `v1'  "`nm'" "
	}
	*/
	collapse (sum) route_n* (firstnm) routename, by(NDC)
		* collapse infrequent methods of delivery into "OTHER"
	levelsof routename, local(rrn)
	foreach nm of local rrn{
		count if routename == "`nm'"
		if `r(N)' < 20{
			replace routename = "OTHER" if routename == "`nm'"
		}
	}
	
	rename route_n* route*
	reshape long route, i(NDC)

	duplicates drop NDC routename, force
	duplicates tag NDC, gen(dd)
	drop dd _j route
	rename routename ROUTE

	
	save "${op_fp}route_inds.dta", replace 
restore 



* substance indicators  
preserve 
	rename productndc NDC
	keep NDC substancename 
	split substancename, p(";")
	rename substancename subs_back 
	gen rr = _n
	reshape long substancename, i(rr) j(ctr)
	drop rr ctr
	replace substancename = strtrim(substancename)
	drop if substancename == ""
	bysort substancename: gen ctr = _n
	bysort substancename: egen tctr = max(ctr)
	replace substancename = "OTHER" if tctr < 20 // changes 443 values 
	tabulate substancename, generate(sub_sn) 
	/*
	* Generate some variable names.  
	foreach v1 of varlist sub_*{
		qui levelsof substancename if `v1' == 1, local(nm)
		di "rename `v1'  "`nm'" "
	}
	*/
	collapse (sum) sub_* , by(NDC)
	* rename to indicate which indicator is which ingredient.  		
	rename sub_sn1  sb_ACETAMINOPHEN 
	rename sub_sn2  sb_BUPRENORPHINE 
	rename sub_sn3  sb_BUPRENORPHINE_HYDROCHLORIDE 
	rename sub_sn4  sb_CAFFEINE 
	rename sub_sn5  sb_CODEINE_PHOSPHATE 
	rename sub_sn6  sb_FENTANYL 
	rename sub_sn7  sb_FENTANYL_CITRATE 
	rename sub_sn8  sb_HYDROCODONE_BITARTRATE 
	rename sub_sn9  sb_HYDROMORPHONE_HYDROCHLORIDE 
	rename sub_sn10 sb_IBUPROFEN 
	rename sub_sn11  sb_LOPERAMIDE_HYDROCHLORIDE 
	rename sub_sn12  sb_MEPERIDINE_HYDROCHLORIDE 
	rename sub_sn13  sb_METHADONE_HYDROCHLORIDE 
	rename sub_sn14  sb_MORPHINE_SULFATE 
	rename sub_sn15  sb_NALOXONE_HYDROCHLORIDE 
	rename sub_sn16  sb_NALOXONE_HYDROCHLORIDE_DIHYDR
	rename sub_sn17  sb_NALTREXONE_HYDROCHLORIDE 
	rename sub_sn18  sb_OTHER 
	rename sub_sn19  sb_OXYCODONE_HYDROCHLORIDE 
	rename sub_sn20  sb_OXYMORPHONE_HYDROCHLORIDE 
	rename sub_sn21  sb_PROMETHAZINE_HYDROCHLORIDE 
	rename sub_sn22  sb_TAPENTADOL_HYDROCHLORIDE 
	rename sub_sn23  sb_TRAMADOL_HYDROCHLORIDE
	
	foreach v1 of varlist sb_*{
		replace `v1' = 1 if `v1' > 1 & `v1' != .
		assert `v1' != .
	}
	save "${op_fp}subs_inds.dta", replace 
restore 


* DEA Schedule - here everyone has just one.  
	tab deaschedule, gen(DEA_SCHED)
	gen DEA = ""
	replace DEA = "2" if DEA_SCHED1 == 1
	replace DEA = "3" if DEA_SCHED2 == 1
	replace DEA = "4" if DEA_SCHED3 == 1
	replace DEA = "5" if DEA_SCHED4 == 1
	
	


* Merge the indicators back in.
* still have to deal with MME 
	rename productndc NDC
	duplicates drop NDC, force
	merge 1:1 NDC using "${op_fp}subs_inds.dta", nogen // all match 
	merge 1:1 NDC using "${op_fp}route_inds.dta", nogen // all match 
	
	
	keep  NDC sb_* DEA ROUTE 
	
save "${op_fp}product_chars.dta", replace


* Just for the sake of getting started, let's use these simple characteristics.  


gen DEA2 = 1 if DEA == "2"
replace DEA2 = 0 if DEA2 == .
gen ORAL = 1 if ROUTE == "ORAL"
replace ORAL = 0 if ORAL == .

gen simple_fent = 1 if  sb_FENTANYL == 1 | sb_FENTANYL_CITRATE == 1
replace simple_fent = 0 if simple_fent == .

gen simple_oxy = 1 if sb_OXYCODONE_HYDROCHLORIDE  == 1
replace simple_oxy = 0 if simple_oxy == .

gen simple_hydro = 1 if sb_HYDROCODONE_BITARTRATE == 1
replace simple_hydro = 0 if simple_hydro == .

keep NDC simple_fent simple_hydro simple_oxy DEA2 ORAL
export delimited "${op_fp}simple_product_chars.csv", replace

* for merging w/ market share and characteristic data in national_market_shares.do 
	rename NDC productndc 
	save "${op_fp}simple_product_chars.dta", replace 
	
stop 
	

	

* morphine mme:


	/*
	https://www.cdc.gov/drugoverdose/pdf/calculating_total_daily_dose-a.pdf
	OPIOID (doses in mg/day except where noted) CONVERSION FACTOR
Codeine 0.15
Fentanyl transdermal (in mcg/hr) 2.4
Hydrocodone 1
Hydromorphone 4
Methadone
1-20 mg/day 4
21-40 mg/day 8
41-60 mg/day 10
≥ 61-80 mg/day 12
Morphine 1
Oxycodone 1.5
Oxymorphone 3 
	*/
	
	/*
preserve 
* this is a pain - there are a lot of different dosage forms.  Tablets are easy, but liquids are not.  
	replace substancename = lower(substancename)
	split substancename, p(";")
	split active_numerator_strength, p(";")
	split active_ingred_unit, p(";")

	* destring:
	destring active_numerator_strength1, replace
	destring active_numerator_strength2, replace
	destring active_numerator_strength3, replace
	destring active_numerator_strength4, replace
	* nothing more needs to be done with these 
	gen mme1 = 0
	gen mme2 = 0
	gen mme3 = 0
	gen mme4 = 0
	* mme
	// TODO - the solutions are going to require more work.  EG product id 0603-1588_02eac02b-67d5-463d-91e3-0ea7cb1b7ba4 
	// is per https://www.hipaaspace.com/medical_billing/coding/national.drug.codes/txt/0603-1588-58 a 473 ml bottle.
	// with 10 mg/5ml so 940 mg about.  Solutions will need to be looked up.
	// Probably all solutions need to be done separately.  
	/*
* NOT DONE YET
	foreach nm of numlist 1(1)4 {
		replace mme`nm' = 0.15*active_numerator_strength`nm' if( (active_ingred_unit`nm' == "mg/1" | active_ingred_unit`nm' == "[hp_X]/1") & regexm(substancename`nm', "codeine")
		* there is one more codeine to do  - mg/5ml solution.
		
		replace mme`nm' = 2.4*active_numerator_strength`nm' if( (active_ingred_unit`nm' == "ug/1" | active_ingred_unit`nm' == "[hp_X]/1") & regexm(substancename`nm', "fentanyl")

	}
	
	*/
	
restore 
*/		
		
	


	

 /*		
* can potentially combine some substances, but it isn't that clear why or how this is permitted.  Better to assign any w/ less than 10 to OTHER 
	* This site will give synonyms: https://pubchem.ncbi.nlm.nih.gov/
	* EG buprenorphine is a synonym for buprenorphine hydrochloride. 
replace substancename = "BUPRENORPHINE" if substancename == "BUPRENORPHINE HYDROCHLORIDE"
	* sufentanil sufentanil citrate
replace substancename = "SUFENTANIL" if substancename == "SUFENTANIL CITRATE" // combine, but this is a small category (6), so set to other.
replace substancename = "OTHER" if substancename == "SUFENTANIL"

replace substancename = "OTHER" if substancename == "BUTORPHANOL TARTRATE"
replace substancename = "OTHER" if substancename == "CARISOPRODOL"
replace substancename = "OTHER" if substancename == "CHLORPHENIRAMINE"
	* CHLORPHENIRAMINE - not clear this can be identified w/ CHLORPHENIRAMINE MALEATE
replace substancename = "OTHER" if substancename == "CHLORPHENIRAMINE MALEATE"
replace substancename = "OTHER" if substancename == "CHLORPHENIRAMINE"

	* the codeine's are not the same: https://pubmed.ncbi.nlm.nih.gov/10189654/
replace substancename = "OTHER" if substancename == "CODEINE ANHYDROUS"
replace substanc
*/
