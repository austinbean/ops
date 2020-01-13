* import all HCCI...



local whereami = "tuk39938"
global hcci_located  "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
di "${hcci_located}"


import delimited "${hcci_located}all_member_count_by_cbsa_month.csv", clear 
rename mbr_cbsa_cd cbsa_code 
save "${hcci_located}cbsa_data/member_count_by_cbsa_month.dta", replace

import delimited "${hcci_located}all_opioid_deps_diag_state_year.csv", clear 
save "${hcci_located}state_data/opioid_dependence_diagnoses_by_state_yr.dta", replace

import excel "${hcci_located}op_depend_subs_to_first_op_presc.xlsx", sheet("Sheet1") firstrow clear
rename STATE state
save "${hcci_located}state_data/opioid_deps_after_first_op_pres.dta", replace

import delimited "${hcci_located}all_painmed_state_year.csv", varnames(1) encoding(ISO-8859-2) stringcols(1) clear 
save "${hcci_located}state_data/all_painmeds_by_state_year.dta", replace 
