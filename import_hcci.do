* import all HCCI...



local whereami = "austinbean"
global hcci_located  "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
di "${hcci_located}"

	* Member Count by CBSA-Month
import delimited "${hcci_located}all_member_count_by_cbsa_month.csv", clear 
rename mbr_cbsa_cd cbsa_code 
save "${hcci_located}cbsa_data/member_count_by_cbsa_month.dta", replace


	* Opioid Dependence Diagnoses by State-Year
import delimited "${hcci_located}all_opioid_deps_diag_state_year.csv", clear 
save "${hcci_located}state_data/opioid_dependence_diagnoses_by_state_yr.dta",  replace



	* Opioid Dependence Diagnoses for those for whom we observe a first opioid prescription
import excel "${hcci_located}op_depend_subs_to_first_op_presc.xlsx", sheet("Sheet1") firstrow clear
rename STATE state
save "${hcci_located}state_data/opioid_deps_after_first_op_pres.dta", replace

	* TODO - can we get a count of prescriptions until dependence diagnosis too?

	*All pain medicine prices, counts, etc. by state.
import delimited "${hcci_located}all_painmed_state_year.csv", varnames(1) encoding(ISO-8859-2) stringcols(1) clear 
save "${hcci_located}state_data/all_painmeds_by_state_year.dta", replace 

	
	* CBSA member count, prescription count, year, avg coinsurance, deductible, copay, cbsa BY MONTH
import delimited "${hcci_located}cbsa_avg_coins_copay_deduct_memct.csv", varnames(1) clear 
save "${hcci_located}cbsa_data/cbsa_avg_coins_copay_deduct_memct.dta", replace

	* CBSA YEAR avg and sd of coins, deduct, copay by ndc code, w/ total presc. count.
import delimited "${hcci_located}cbsa_avg_ccd_sddev_memct.csv", varnames(1) clear
sort cbsa yr ndc_code
save "${hcci_located}cbsa_data/cbsa_avg_ccd_sddev_memct.dta", replace


	* Member share by CBSA month 
import delimited "${hcci_located}mem_share_by_cbsa_month.csv", varnames(1) encoding(ISO-8859-2) clear 
save "${hcci_located}cbsa_data/mem_share_by_cbsa_month.dta", replace

	* Count of members taking opioids by CBSA-Month
	import delimited "${hcci_located}opioid_member_count_by_cbsa_month.csv", varnames(1) encoding(ISO-8859-2) clear 
	save "${hcci_located}cbsa_data/opioid_member_count_by_cbsa_month.dta", replace

	
	* state average payment variables
import delimited "${hcci_located}state_avg_ccd_sddev_memct.csv", varnames(1) clear 
save "${hcci_located}state_data/state_avg_ccd_sddev_memct.dta", replace


	* count of opioid patient by state year:
	
import excel "${hcci_located}total_opioid_patients_by_state_year.xlsx", sheet("Sheet1") firstrow case(lower) clear

save "${hcci_located}state_data/total_opioid_patients_state_year.dta", replace

	* Total patients by state year
import excel "${hcci_located}total_patients_by_state_year.xlsx", sheet("Sheet1") firstrow case(lower) clear
save "${hcci_located}state_data/total_patients_by_state_year.dta", replace

	* state average payment amounts w/out sd's 
 import delimited "${hcci_located}state_avg_coins_copay_deduct_memct.csv", varnames(1) clear 
save "${hcci_located}state_data/state_avg_prices_no_sds.dta", replace
