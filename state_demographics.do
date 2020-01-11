* state demographics, 2010
* note that filename of .csv includes original date of download, so this needs to be changed with a different version


global demo_filep = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/census_demographic_files/"
global ops_prog_filep = "/Users/austinbean/Desktop/programs/opioids/"

* age by state: 

 import delimited "${demo_filep}age_by_state/ACSST5Y2010.S0101_data_with_overlays_2020-01-09T130809.csv", varnames(1)  clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}age_to_keep.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}age_by_state/age_by_state.dta", replace

* disability status by state:

 import delimited "${demo_filep}disability_status_by_state/ACSST1Y2010.S1810_data_with_overlays_2020-01-09T144939.csv", varnames(1) clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}disability_to_keep.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}disability_status_by_state/disability_status_by_state.dta", replace
 
* educational attainment
 
 import delimited "${demo_filep}educational_attainment_by_state/ACSST5Y2010.S1501_data_with_overlays_2020-01-09T125512.csv", varnames(1) clear 
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}educational_attain_to_keep.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}educational_attainment_by_state/educ_attain_by_state.dta", replace

 
  * TO KEEP START BELOW

 
* employment by state
 import delimited "${demo_filep}employment_rate_by_state/ACSST5Y2010.S2301_data_with_overlays_2020-01-09T144033.csv", varnames(1) clear 
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 sort name
 drop cbsa_code 
 save  "${demo_filep}employment_rate_by_state/employment_by_state.dta", replace
 
* health insurance by state
 import delimited "${demo_filep}health_insurance_status_by_state/ACSST1Y2010.S2701_data_with_overlays_2020-01-09T145049.csv", varnames(1) clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}health_insurance_status_by_state/health_ins_by_state.dta", replace
 
* income by state
 import delimited "${demo_filep}income_by_state/ACSST5Y2010.S1901_data_with_overlays_2020-01-09T131200.csv", varnames(1) clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}income_by_state/income_by_state.dta", replace
 
* race by state
 import delimited "${demo_filep}race_by_state/ACSDT5Y2010.B02001_data_with_overlays_2020-01-09T130601.csv", varnames(1) clear 
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}race_by_state/race_by_state.dta", replace

 
 * Merge across files 
 use "${demo_filep}age_by_state/age_by_state.dta", clear
 merge 1:1 st_abbrev using "${demo_filep}disability_status_by_state/disability_status_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}educational_attainment_by_state/educ_attain_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}employment_rate_by_state/employment_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}health_insurance_status_by_state/health_ins_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}income_by_state/income_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}race_by_state/race_by_state.dta", nogen
 
