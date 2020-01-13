* import all HCCI...



local whereami = "tuk39938"
global hcci_located  "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
di "${hcci_located}"


import delimited "${hcci_located}all_member_count_by_cbsa_month.csv", clear 
rename mbr_cbsa_cd cbsa_code 
save "${hcci_located}cbsa_data/member_count_by_cbsa_month.dta", replace
