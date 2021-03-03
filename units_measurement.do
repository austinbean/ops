* units of measurement.


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"




use "${op_pr}drug_characteristics.dta", clear
merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"
drop if _merge ==2 
drop _merge 

keep strengthunit ndccode ndc11code productndc ndc_code NDC_Numeric querycode
split strengthunit, p(";")
drop strengthunit 

reshape long strengthunit, i(ndc_code) j(strct)
drop if strengthunit == ""
drop strct NDC_Numeric
replace strengthunit = strtrim(strengthunit)
gen conversion_factor = .

* nearly everything is mg/l 
replace conversion_factor = 1000 if strengthunit == "mg/mL"
replace conversion_factor = 800 if strengthunit == "mg/1.25mL"
replace conversion_factor = 500 if strengthunit == "mg/2mL"
replace conversion_factor = 400 if strengthunit == "mg/2.5mL"
replace conversion_factor = 333.33 if strengthunit == "mg/3mL"
replace conversion_factor = 200 if strengthunit == "mg/5mL"
replace conversion_factor = 100 if strengthunit == "mg/10mL"
replace conversion_factor = 66.66 if strengthunit == "mg/15mL"
replace conversion_factor = 50 if strengthunit == "mg/20mL"
replace conversion_factor = 20 if strengthunit == "mg/50mL"
replace conversion_factor = 1 if strengthunit == "mg/1" // nothing to convert.
replace conversion_factor = 1 if strengthunit == "ug/mL" // nothing to convert.
replace conversion_factor = 0.001 if strengthunit == "ug/1"


duplicates drop ndc_code, force 

save "${op_fp}units_measurement.dta", replace

/*
not easily converted =: 
------------+-----------------------------------
* solids? 
     g/100g |          4        0.29        0.29
        g/g |          1        0.07        0.37
       mg/g |          6        0.44       87.77
	  
	  
	  
* fentanyl patches do have MME. See footnote 8 of:
https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovContra/Downloads/Opioid-Morphine-EQ-Conversion-Factors-April-2017.pdf

* hourly:	   
       ug/h |         34        2.49       99.27
------------+-----------------------------------
*/
