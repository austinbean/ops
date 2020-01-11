* educational attainment to keep

keep cbsa_code st_cd st_abbrev geo_id name s1501_c01_002e s1501_c01_003e s1501_c01_004e s1501_c01_005e s1501_c01_007e s1501_c01_008e s1501_c01_011e s1501_c01_012e s1501_c01_013e s1501_c02_002e s1501_c02_003e s1501_c02_004e s1501_c02_005e s1501_c02_007e s1501_c02_008e s1501_c02_009e s1501_c02_010e s1501_c02_011e s1501_c02_012e s1501_c02_013e s1501_c03_002e s1501_c03_003e s1501_c03_004e s1501_c03_005e s1501_c03_007e s1501_c03_008e s1501_c03_009e s1501_c03_010e s1501_c03_011e s1501_c03_012e s1501_c03_013e s1501_c01_033e s1501_c01_034e s1501_c01_035e s1501_c01_036e s1501_c01_037e s1501_c02_033e s1501_c02_034e s1501_c02_035e s1501_c02_036e s1501_c02_037e s1501_c03_033e s1501_c03_034e s1501_c03_035e s1501_c03_036e s1501_c03_037e


rename s1501_c01_002e total_less_than_hs_grad
rename s1501_c01_003e total_hs_grad // see also 009e below
rename s1501_c01_004e total_some_college // see also 010e below
rename s1501_c01_005e total_bachelors
rename s1501_c01_007e total_less_than_9th_grade
rename s1501_c01_008e total_only_9_12_grade
//rename s1501_c01_009e total_hs_grad // what's the difference 003e above?
//rename s1501_c01_010e total_some_college // what's the difference 004e?
rename s1501_c01_011e total_aa_degree
rename s1501_c01_012e total_ba_degree
rename s1501_c01_013e total_grad_degree

rename s1501_c02_002e male_less_than_hs_grad
rename s1501_c02_003e male_hs_grad // see also 009e below
rename s1501_c02_004e male_some_college // see also 010e below 
rename s1501_c02_005e male_bachelors
rename s1501_c02_007e male_less_than_9th_grade
rename s1501_c02_008e male_only_9_12_grade
// rename s1501_c02_009e // see 003e above
//rename s1501_c02_010e  // see 010e above
rename s1501_c02_011e male_aa_degree
rename s1501_c02_012e male_ba_degree
rename s1501_c02_013e male_grad_degree

rename s1501_c03_002e female_less_than_hs_grad
rename s1501_c03_003e female_hs_grad // see also 009e below
rename s1501_c03_004e female_some_college // see also 010e below
rename s1501_c03_005e female_bachelors
rename s1501_c03_007e female_less_than_9th_grade
rename s1501_c03_008e female_only_9_12_grade
//rename s1501_c03_009e // see 003e above
//rename s1501_c03_010e // see 010e above
rename s1501_c03_011e female_aa_degree
rename s1501_c03_012e female_ba_degree
rename s1501_c03_013e female_grad_degree

* drop extras?
drop  s1501_c02_009e s1501_c02_010e s1501_c03_009e s1501_c03_010e


* income by education 

label variable s1501_c01_033e "med earn prior yr  < HS Grad"
rename s1501_c01_033e all_med_earn_pr_yr_lt_h_grad

label variable s1501_c01_034e "med earn prior yr HS grad"
rename s1501_c01_034e all_med_earn_pr_yr_h_grad

label variable s1501_c01_035e "med earn prior yr some college"
rename s1501_c01_035e all_med_earn_pr_yr_sm_coll

label variable s1501_c01_036e "med earn prior yr coll deg"
rename s1501_c01_036e all_med_earn_pr_yr_coll_deg

label variable s1501_c01_037e "med earn prior yr grad prof deg."
rename s1501_c01_037e all_med_earn_pr_yr_grad_deg

* MALES
label variable s1501_c02_033e "male med earn prior yr  < HS Grad"
rename s1501_c02_033e male_med_earn_pr_yr_lt_h_grad

label variable s1501_c02_034e "male med earn prior yr HS grad"
rename s1501_c02_034e male_med_earn_pr_yr_h_grad

label variable s1501_c02_035e "male med earn prior yr some college"
rename s1501_c02_035e male_med_earn_pr_yr_sm_coll

label variable s1501_c02_036e "male med earn prior yr coll deg"
rename s1501_c02_036e male_med_earn_pr_yr_coll_deg

label variable s1501_c02_037e "male med earn prior yr grad prof deg."
rename s1501_c02_037e male_med_earn_pr_yr_grad_deg


* FEMALES
label variable s1501_c03_033e "fem med earn prior yr  < HS Grad"
rename s1501_c03_033e fem_med_earn_pr_yr_lt_h_grad

label variable s1501_c03_034e "fem med earn prior yr HS grad"
rename s1501_c03_034e fem_med_earn_pr_yr_h_grad

label variable s1501_c03_035e "fem med earn prior yr some college"
rename s1501_c03_035e fem_med_earn_pr_yr_sm_coll

label variable s1501_c03_036e "fem med earn prior yr coll deg"
rename s1501_c03_036e fem_med_earn_pr_yr_coll_deg

label variable s1501_c03_037e "fem med earn prior yr grad prof deg."
rename s1501_c03_037e fem_med_earn_pr_yr_grad_deg
