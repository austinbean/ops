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
*/	
	
	use "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", clear
	
	split substancename, p(";")
	split strengthunit, p(";")
	split strengthnumber, p(";")

	rename substancename xsubsname
	rename strengthnumber xstrengthnum
	rename strengthunit xstrengthu 
	
	reshape long substancename strengthunit strengthnumber, i(ndc_code) j(sbctr)
	drop if substancename == ""
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
	
	* codeine 
	
	* fentanyl 
	
	* hydrocodone 
	
	* hydromorphone 
	
	* methadone 
	
	* morphine 
	
	* oxycodone 
	
	* oxymorphone 
		
	* redo after reshape.  
	egen non_zero_mme = rowtotal(codeine fentanyl hydrocodone hydromorphone methadone morphine oxycodone oxymorphone)

	*
	gen MME = 0 if non_zero_mme == 0

		
