* Units of active ingredient...
	* is strength determinable from this data?  
	* note this Alabama policy: https://medicaid.alabama.gov/alert_detail.aspx?ID=13222 - denial of high MME opioid claims.   Interesting.  
	* NYC calculator: https://www1.nyc.gov/site/doh/providers/health-topics/mme-calculator.page
	* PLAN: add MME equivalents when they are not otherwise present.  
	* See this from the DEA too.  This does not appear to be MME: https://www.deadiversion.usdoj.gov/quotas/conv_factor/index.html 
		* maybe this one is best: 
	* This one links to a better CDC file at the end: http://www.pdmpassist.org/pdf/BJA_performance_measure_aid_MME_conversion.pdf
/* 
presentation form matters ->
 https://tenncare.magellanhealth.com/static/docs/Program_Information/TennCare_MME_Conversion_Chart.pdf

a cdc tool with clinical support in mind:

 https://www.cdc.gov/drugoverdose/prescribing/guideline.html#tabs-2-3
*/

global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"



* opioids w/ MME from CDC, plus maybe some additions.  Source was pdmpassist.org  
	* If this list has all of the NDCs, then it's a better list anyway.  So: use this instead of what we already have.  Ask them to upload it as a table.  

clear 
import excel "${op_fp}Conversion Reference Table.xlsx", sheet("Opioids") firstrow
gen productndc = substr(NDC, 1, 9)
save "${op_fp}opioid_mme_by_ndc.dta", replace

clear
import excel "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/Conversion Reference Table.xlsx", sheet("Summary Table") cellrange(A3:B27) firstrow
rename Opioidstrengthinmgexceptwh Opioidstrength 
label variable Opioidstrength "Strength in mg except where noted"
save "${op_fp}opioid_raw_ingred_mme.dta", replace




* product file
	import delimited "${op_fp}ndctext/product.txt", clear 
* keep opioids only 
	* not 100% sure this is everything we want.
	replace pharm_class = lower(pharm_class)
	gen opi_ind = 1 if strpos(pharm_class, "opi")
	gen tropi_ind = 1 if strpos(pharm_class, "tropi")
	keep if opi_ind == 1
	drop if tropi_ind == 1
	
		
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
* there are duplicates within NDC but these are mostly new ANDA for the same drug 
	rename productndc NDC
	replace NDC = subinstr(NDC, "-", "", .)
	duplicates tag NDC, gen(ddd)
	bysort NDC: egen mxdate = max(startmarketingdate)
	drop if startmarketingdate != mxdate & ddd > 0
	drop ddd 
	duplicates drop NDC, force 
	
* merge morphine MME
	merge 1:1 NDC using "${op_fp}opioid_mme_by_ndc.dta"
	
* 
	
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
*preserve 		
		keep substancename* 
		drop substancename 
		gen rr = _n
		reshape long substancename, i(rr) j(ctr)
		drop rr ctr
		replace substancename = strtrim(substancename)
		duplicates drop substancename, force
		drop if substancename == ""
	gen mme = 0
	levelsof substancename, local(nms)
	
	foreach nm of local nms{
		di `" replace mme = if substancename == "`nm'" "'
	}
* there are 60 unique substances.	
 replace mme = if substancename == "ACETAMINOPHEN" 
 replace mme = if substancename == "ALFENTANIL HYDROCHLORIDE" 
 replace mme = if substancename == "ALVIMOPAN" 
 replace mme = if substancename == "ASPIRIN" 
 replace mme = if substancename == "BUPIVACAINE HYDROCHLORIDE" 
 replace mme = if substancename == "BUPRENORPHINE" 
 replace mme = if substancename == "BUPRENORPHINE HYDROCHLORIDE" 
 replace mme = if substancename == "BUPROPION HYDROCHLORIDE" 
 replace mme = if substancename == "BUTALBITAL" 
 replace mme = if substancename == "BUTORPHANOL TARTRATE" 
 replace mme = if substancename == "CAFFEINE" 
 replace mme = if substancename == "CARISOPRODOL" 
 replace mme = if substancename == "CHLORPHENIRAMINE" 
 replace mme = if substancename == "CHLORPHENIRAMINE MALEATE" 
 replace mme = if substancename == "CODEINE ANHYDROUS" 
 replace mme = if substancename == "CODEINE PHOSPHATE" 
 replace mme = if substancename == "CODEINE SULFATE" 
 replace mme = if substancename == "DIHYDROCODEINE BITARTRATE" 
 replace mme = if substancename == "ELUXADOLINE" 
 replace mme = if substancename == "FENTANYL" 
 replace mme = if substancename == "FENTANYL CITRATE" 
 replace mme = if substancename == "FENTANYL HYDROCHLORIDE" 
 replace mme = if substancename == "GUAIFENESIN" 
 replace mme = if substancename == "HOMATROPINE METHYLBROMIDE" 
 replace mme = if substancename == "HYDROCODONE" 
 replace mme = if substancename == "HYDROCODONE BITARTRATE" 
 replace mme = if substancename == "HYDROMORPHONE HYDROCHLORIDE" 
 replace mme = if substancename == "IBUPROFEN" 
 replace mme = if substancename == "LEVORPHANOL TARTRATE" 
 replace mme = if substancename == "LOPERAMIDE HYDROCHLORIDE" 
 replace mme = if substancename == "MEPERIDINE HYDROCHLORIDE" 
 replace mme = if substancename == "METHADONE HYDROCHLORIDE" 
 replace mme = if substancename == "METHYLNALTREXONE BROMIDE" 
 replace mme = if substancename == "MORPHINE" 
 replace mme = if substancename == "MORPHINE HYDROCHLORIDE" 
 replace mme = if substancename == "MORPHINE SULFATE" 
 replace mme = if substancename == "NALBUPHINE HYDROCHLORIDE" 
 replace mme = if substancename == "NALDEMEDINE TOSYLATE" 
 replace mme = if substancename == "NALOXEGOL OXALATE" 
 replace mme = 0 if substancename == "NALOXONE" // speculative, but justifiable given that it is an opioid antagonist
 replace mme = 0 if substancename == "NALOXONE HYDROCHLORIDE" // speculative, but justifiable given that it is an opioid antagonist
 replace mme = 0 if substancename == "NALOXONE HYDROCHLORIDE DIHYDRATE" // speculative, but justifiable given that it is an opioid antagonist
 replace mme = if substancename == "NALTREXONE" 
 replace mme = if substancename == "NALTREXONE HYDROCHLORIDE" 
 replace mme = if substancename == "OXYCODONE" 
 replace mme = if substancename == "OXYCODONE HYDROCHLORIDE" 
 replace mme = if substancename == "OXYMORPHONE HYDROCHLORIDE" 
 replace mme = if substancename == "PENTAZOCINE" 
 replace mme = if substancename == "PENTAZOCINE HYDROCHLORIDE" 
 replace mme = if substancename == "PHENYLEPHRINE HYDROCHLORIDE" 
 replace mme = if substancename == "PROMETHAZINE HYDROCHLORIDE" 
 replace mme = if substancename == "PSEUDOEPHEDRINE HYDROCHLORIDE" 
 replace mme = if substancename == "REMIFENTANIL HYDROCHLORIDE" 
 replace mme = if substancename == "SUFENTANIL" 
 replace mme = if substancename == "SUFENTANIL CITRATE" 
 replace mme = if substancename == "TAPENTADOL" 
 replace mme = if substancename == "TAPENTADOL HYDROCHLORIDE" 
 replace mme = if substancename == "TRAMADOL HYDROCHLORIDE" 
 replace mme = if substancename == "TRIAMCINOLONE" 
 replace mme = if substancename == "TRIPROLIDINE HYDROCHLORIDE" 


	
	

