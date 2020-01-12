* metro area demographics, 2010
* note that filename of .csv includes original date of download, so this needs to be changed with a different version
	* NOTE some files do not have all CBSA for disability status or health insurance status


global demo_filep = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/census_demographic_files/"
global ops_prog_filep = "/Users/austinbean/Desktop/programs/opioids/"

* age by metro area: 

 import delimited "${demo_filep}age_by_metro_area/ACSST5Y2010.S0101_data_with_overlays_2020-01-09T131614.csv", varnames(1) clear
 gen st_cd = .
 gen st_abbrev = .
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}age_to_keep.do"
 sort name
 drop st_cd st_abbrev
 save "${demo_filep}age_by_metro_area/age_by_metro_area.dta", replace

* disability status by metro_area:

 import delimited "${demo_filep}/disability_status_by_metro_area/ACSST1Y2010.S1810_data_with_overlays_2020-01-09T144424.csv", varnames(1) clear
 gen st_cd = .
 gen st_abbrev = . 
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}disability_to_keep.do"
 sort name
 drop st_cd st_abbrev
 save "${demo_filep}disability_status_by_metro_area/disability_status_by_metro_area.dta", replace
 
* educational attainment
 
 import delimited "${demo_filep}/educational_attainment_by_metro_area/ACSST5Y2010.S1501_data_with_overlays_2020-01-09T132235.csv", varnames(1) clear 
 gen st_cd = .
 gen st_abbrev = .
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}educational_attain_to_keep.do"
 sort name
 drop st_cd st_abbrev
 save "${demo_filep}educational_attainment_by_metro_area/educ_attain_by_metro_area.dta", replace
 
* employment by metro area
 import delimited "${demo_filep}employment_rate_by_metro_area/ACSST5Y2010.S2301_data_with_overlays_2020-01-09T143635.csv", varnames(1) clear 
 gen st_cd = .
 gen st_abbrev = .
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}employment_to_keep.do"
 sort name
 drop st_cd st_abbrev
 save  "${demo_filep}employment_rate_by_metro_area/employment_by_metro_area.dta", replace
 
* health insurance by metro area
 import delimited "${demo_filep}health_insurance_status_by_metro_area/ACSST1Y2010.S2701_data_with_overlays_2020-01-09T144555.csv", varnames(1) clear
 gen st_cd = .
 gen st_abbrev = .
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
  do "${ops_prog_filep}health_insurance_to_keep.do" 
 sort name
 drop st_cd st_abbrev
 save "${demo_filep}health_insurance_status_by_metro_area/health_ins_by_metro_area.dta", replace
 
* income by metro area
 import delimited "${demo_filep}income_by_metro_area/ACSST5Y2010.S1901_data_with_overlays_2020-01-09T131350.csv", varnames(1) clear
 gen st_cd = .
 gen st_abbrev = .
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}income_to_keep.do" 
 sort name
 drop st_cd st_abbrev
 save "${demo_filep}income_by_metro_area/income_by_metro_area.dta", replace
 
* race by metro area
 import delimited "${demo_filep}race_by_metro_area/ACSDT5Y2010.B02001_data_with_overlays_2020-01-09T141459.csv", varnames(1) clear 
 gen st_cd = .
 gen st_abbrev = .
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}race_to_keep.do" 
 sort name
 drop st_cd st_abbrev
 save "${demo_filep}race_by_metro_area/race_by_metro_area.dta", replace


 * Merge across files 
	* NOTE - health insurance and disability status not available for about half of cbsa codes.  
 
 use "${demo_filep}age_by_metro_area/age_by_metro_area.dta", clear
 merge 1:1 cbsa_code using "${demo_filep}disability_status_by_metro_area/disability_status_by_metro_area.dta", nogen // MANY MISSINGS
 merge 1:1 cbsa_code using "${demo_filep}educational_attainment_by_metro_area/educ_attain_by_metro_area.dta", nogen
 merge 1:1 cbsa_code using "${demo_filep}employment_rate_by_metro_area/employment_by_metro_area.dta", nogen
 merge 1:1 cbsa_code using "${demo_filep}health_insurance_status_by_metro_area/health_ins_by_metro_area.dta", nogen // MANY MISSINGS
 merge 1:1 cbsa_code using "${demo_filep}income_by_metro_area/income_by_metro_area.dta", nogen
 merge 1:1 cbsa_code using "${demo_filep}race_by_metro_area/race_by_metro_area.dta", nogen
 
