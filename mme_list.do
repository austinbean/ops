* CDC Opioid List
/*
This file is a list from the CDC with morphine MMEs for every 11 digit NDC code.
In that case it is probably better / more useful.  
*/



global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"



* opioids w/ MME from CDC, plus maybe some additions.  Source was pdmpassist.org  
	* If this list has all of the NDCs, then it's a better list anyway.  So: use this instead of what we already have.  Ask them to upload it as a table.  
if 0{
clear 
import excel "${op_fp}Conversion Reference Table.xlsx", sheet("Opioids") firstrow
gen productndc = substr(NDC, 1, 9)

drop if MME_Conversion_Factor == . // there is one product with a missing MME 
save "${op_fp}opioid_mme.dta", replace


export delimited using "/Users/austinbean/Desktop/programs/opioids/opioid_11digitNDC_mmes.csv", replace
}

* another import of the CDC list:
import excel "${op_pr}CDC_Oral_Morphine_Milligram_Equivalents_Sept_2018.xlsx", sheet("Opioids") firstrow clear
rename NDC ndc_code // note that ndc_code is different from ndccode and query code in the drug_characteristics.dta file.
save "${op_pr}mme_by_ndc.dta", replace



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
https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovContra/Downloads/Oral-MME-CFs-vFeb-2018.pdf

Buprenorphine film/tabletiii (mg)
Buprenorphine patchiii(mcg/hr)
Buprenorphine filmiii (mcg)
Butorphanol (mg) 7
Codeine (mg) 0.15
Dihydrocodeine (mg) 0.25
Fentanyl buccal or SL tablets, or lozenge/trocheiv
(mcg)
0.13
Fentanyl film or oral sprayv (mcg) 0.18
Fentanyl nasal sprayvi (mcg) 0.16
Fentanyl patchvii (mcg) 7.2
Hydrocodone (mg) 1
Hydromorphone (mg) 4
Levorphanol tartrate (mg) 11
Meperidine hydrochloride (mg) 0.1
Methadoneviii (mg) 3
>0, <= 20 4
>20, <=40 8
>40, <=60 10
>60 12
Morphine (mg) 1
Opium (mg) 1
Oxycodone (mg) 1.5
Oxymorphone (mg) 3
Pentazocine (mg) 0.37
Tapentadolix (mg) 0.4
Tramadol (mg) 0.1 

another: https://apps.health.ny.gov/pub/ctrldocs/bne/nyosammeformulation.pdf

A calculator... 
https://www1.nyc.gov/site/doh/providers/health-topics/mme-calculator.page
This is what I need to use.  

https://ww2.health.wa.gov.au/-/media/Files/Corporate/general-documents/Health-Networks/WA-Cancer-and-Palliative-Care/How-to-use-the-Opioid-Conversion-Guide.pdf

https://www.palliativedrugs.com/download/081230_Opioid%20_Conversion_Chart_08.pdf

A list by NDC: 
https://www.cdc.gov/drugoverdose/data-files/CDC_Oral_Morphine_Milligram_Equivalents_Sept_2018.xlsx
*/	
	
	use "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", clear
	merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"
	// todo this has a mistake b/c now a bunch of non-opioids will get MME's  
	split substancename, p(";")
	split strengthunit, p(";")
	split strengthnumber, p(";")

	rename substancename xsubsname
	rename strengthnumber xstrengthnum
	rename strengthunit xstrengthu 
	
	reshape long substancename strengthunit strengthnumber, i(ndc_code) j(sbctr)
	drop if substancename == ""
	
	keep substancename strengthunit strengthnumber 
		
	replace substancename = strtrim(substancename)   // a few codeine entries have a leading space. 
	replace strengthnumber = strtrim(strengthnumber) // more spaces
	replace strengthuni = strtrim(strengthunit)      // also
	
	duplicates drop substancename strengthunit strengthnumber , force
	sort substancename strengthunit strengthnumber
	
	* TODO - can also think about identifying painkillers this way to get market share right.  
		* MME 
	gen codeine = regexm(lower(substancename), "codeine")
	gen fentanyl = regexm(lower(substancename), "fentanyl")
	gen hydrocodone = regexm(lower(substancename), "hydrocodone")
	gen hydromorphone = regexm(lower(substancename), "hydromorphone")
	gen methadone = regexm(lower(substancename), "methadone")
	gen morphine = regexm(lower(substancename), "morphine")
	gen oxycodone = regexm(lower(substancename), "oxycodone")
	gen oxymorphone = regexm(lower(substancename), "oxymorphone")
	gen tramadol = regexm(lower(substancename), "tramadol")
	egen non_zero_mme = rowtotal(codeine fentanyl hydrocodone hydromorphone methadone morphine oxycodone oxymorphone)

	preserve 
		keep if non_zero_mme == 0 
		save "/Users/austinbean/Desktop/programs/opioids/no_mme_active_ingredients.dta", replace
	restore 
	
	keep if non_zero_mme == 1
	
	gen mme = 0
	if 0 { // this loop is just needed to generate some statements programmatically.  
	qui levelsof substancename, local(subs)
	foreach sb of local subs{
		qui levelsof strengthunit if substancename == "`sb'", local(strens)
		foreach streng of local strens{
			qui levelsof strengthnumber if substancename == "`sb'" & strengthunit == "`streng'", local(units)
			
			foreach un of local units{
				di "replace mme =  if substancename == `sb' & strengthunit == `streng' & strengthnumber == `un'"
			}
		}
		
	}
	}

	* codeine 
replace mme = 2.3 if substancename == "CODEINE PHOSPHATE" & strengthunit ==  "mg/1" & strengthnumber ==  "15"
replace mme = 2.45 if substancename == "CODEINE PHOSPHATE" & strengthunit ==  "mg/1" & strengthnumber ==  "16"
replace mme = 4.5 if substancename == "CODEINE PHOSPHATE" & strengthunit ==  "mg/1" & strengthnumber ==  "30"
replace mme = 9 if substancename == "CODEINE PHOSPHATE" & strengthunit ==  "mg/1" & strengthnumber ==  "60"
replace mme = 0.31 if substancename == "CODEINE PHOSPHATE" & strengthunit ==  "mg/5mL" & strengthnumber ==  "10"
replace mme = 1.15  if substancename == "CODEINE PHOSPHATE" & strengthunit ==  "mg/5mL" & strengthnumber ==  "7.5"
		* TODO - are these perfect substitutes?  Phosphate and sulfate
replace mme = 2.3 if substancename == "CODEINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "15"
replace mme = 4.5 if substancename == "CODEINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "30"
replace mme = 9 if substancename == "CODEINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "60"

	* fentanyl 
	* these are per hour, so they are patches.  
replace mme = 240 if substancename == "FENTANYL" & strengthunit == "ug/h" & strengthnumber == "100"
replace mme = 30 if substancename == "FENTANYL" & strengthunit == "ug/h" & strengthnumber == "12"
replace mme = 30 if substancename == "FENTANYL" & strengthunit == "ug/h" & strengthnumber == "12.5"
replace mme = 60 if substancename == "FENTANYL" & strengthunit == "ug/h" & strengthnumber == "25"
replace mme = 120 if substancename == "FENTANYL" & strengthunit == "ug/h" & strengthnumber == "50"
replace mme = 180 if substancename == "FENTANYL" & strengthunit == "ug/h" & strengthnumber == "75"
	* These are a bit uncertain
replace mme = 156 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/1" & strengthnumber == "1200"
replace mme = 208 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/1" & strengthnumber == "1600"
replace mme = 26 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/1" & strengthnumber == "200"
replace mme = 52 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/1" & strengthnumber == "400"
replace mme = 78 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/1" & strengthnumber == "600"
replace mme = 104 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/1" & strengthnumber == "800"
replace mme = 6.5 if substancename == "FENTANYL CITRATE" & strengthunit == "ug/mL" & strengthnumber == "50"

	* hydrocodone 

replace mme = 10 if substancename == "HYDROCODONE BITARTRATE" & strengthunit == "mg/1" & strengthnumber == "10"
replace mme = 5 if substancename == "HYDROCODONE BITARTRATE" & strengthunit == "mg/1" & strengthnumber == "5"
replace mme = 7.5 if substancename == "HYDROCODONE BITARTRATE" & strengthunit == "mg/1" & strengthnumber == "7.5"
replace mme = 0.5 if substancename == "HYDROCODONE BITARTRATE" & strengthunit == "mg/15mL" & strengthnumber == "7.5"
replace mme = 0.5 if substancename == "HYDROCODONE BITARTRATE" & strengthunit == "mg/5mL" & strengthnumber == "2.5"
replace mme = 1 if substancename == "HYDROCODONE BITARTRATE" & strengthunit == "mg/5mL" & strengthnumber == "5"

	* hydromorphone 

replace mme = 8 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "2"
replace mme = 12 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "3"
replace mme = 16 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "4"
replace mme = 32 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "8"
replace mme = 4 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/mL" & strengthnumber == "1"
replace mme = 40 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/mL" & strengthnumber == "10"
replace mme = 8 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/mL" & strengthnumber == "2"
replace mme = 16 if substancename == "HYDROMORPHONE HYDROCHLORIDE" & strengthunit == "mg/mL" & strengthnumber == "4"

	* methadone 

// replace mme =  if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "g/g" & strengthnumber == "1"
replace mme = 30 if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "10"
replace mme = 120 if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "40"
replace mme = 15 if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "5"
replace mme = 6 if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "mg/5mL" & strengthnumber == "10"
replace mme = 3 if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "mg/5mL" & strengthnumber == "5"
replace mme = 30 if substancename == "METHADONE HYDROCHLORIDE" & strengthunit == "mg/mL" & strengthnumber == "10"

	* morphine 

replace mme = 10 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "10"
replace mme = 100 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "100"
replace mme = 15 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "15"
replace mme = 20 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "20"
replace mme = 200 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "200"
replace mme = 30 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "30"
replace mme = 5 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "5"
replace mme = 50 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "50"
replace mme = 60 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "60"
replace mme = 80 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/1" & strengthnumber == "80"
replace mme = 2 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/5mL" & strengthnumber == "10"
replace mme = 20 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/5mL" & strengthnumber == "100"
replace mme = 4 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/5mL" & strengthnumber == "20"
replace mme = 0.5 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "0.5"
replace mme = 1 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "1"
replace mme = 10 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "10"
replace mme = 2 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "2"
replace mme = 20 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "20"
replace mme = 25 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "25"
replace mme = 4 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "4"
replace mme = 5 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "5"
replace mme = 50 if substancename == "MORPHINE SULFATE" & strengthunit == "mg/mL" & strengthnumber == "50"

	* oxycodone 

replace mme = 15 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "10"
replace mme = 22.5 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "15"
replace mme = 45 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "30"
replace mme = 7 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "4.8355"
replace mme = 60 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "40"
replace mme = 7.5 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "5"
replace mme = 11.3 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "7.5"
replace mme = 30 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/5mL" & strengthnumber == "100"
replace mme = 1.5 if substancename == "OXYCODONE HYDROCHLORIDE" & strengthunit == "mg/5mL" & strengthnumber == "5"

	* oxymorphone 

replace mme = 30 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "10"
replace mme = 45 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "15"
replace mme = 60 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "20"
replace mme = 90 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "30"
replace mme = 120 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "40"
replace mme = 15 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "5"
replace mme = 22.5 if substancename == "OXYMORPHONE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "7.5"

	* tramadol
	
replace mme = 10 if substancename == "TRAMADOL HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "100"
replace mme = 20 if substancename == "TRAMADOL HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "200"
replace mme = 30 if substancename == "TRAMADOL HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "300"
replace mme = 3.75 if substancename == "TRAMADOL HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "37.5"
replace mme = 5 if substancename == "TRAMADOL HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "50"

		* Below here from the CDC source.  

	* butorphanol
replace mme = 0.7 if substancename == "BUTORPHANOL TARTRATE" & strengthunit == "mg/mL" & strengthnumber == "1"
replace mme = 7 if substancename == "BUTORPHANOL TARTRATE" & strengthunit == "mg/mL" & strengthnumber == "10"
replace mme = 1.4 if substancename == "BUTORPHANOL TARTRATE" & strengthunit == "mg/mL" & strengthnumber == "2"
 	
	* Meperidine 
replace mme =5  if substancename == "MEPERIDINE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "50"		

	* opium
replace mme = 30 if substancename ==  "OPIUM" & strengthunit ==  "mg/1" & strengthnumber ==  "30"
replace mme = 30 if substancename ==  "OPIUM" & strengthunit ==  "mg/1" & strengthnumber ==  "60"

	* pentazocine
replace mme = 18.5 if substancename == "PENTAZOCINE HYDROCHLORIDE" & strengthunit == "mg/1" & strengthnumber == "50"
	stop
	
* TODO - next thing to figure out is the number of units, b/c larger package size is better.  
	duplicates drop packagedescription, force // drops almost nothing.
	* tablet 
	* tablet in blister pack 
	* capsule
	* patch in pouch :(
	* vial
	* single-does in 1 pouch :(
	* bottle 
	* capsule in blister pack in carton :/ 
	* aerosol metered in 1 canister 
	* 1 kit in one blister pack 
	* dropper, bottle 
	* cup unit dose in 1 tray 
	* spray in cartridge 
	* ampule in pouch 
	* suppository in packet 
	* granule delayed release in carton 
	* ampule in tray 
	* vial multidose in carton in case 
	* tube in carton 
	* ampule in cello pack 
	* tablet in pail (?)
	* syringe in carton 
	* at about row 700

		
