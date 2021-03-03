* National shares

* starts in mkt_shares.do, this continues from there.  


/*
- characteristics information comes from drug_characteristics.dta, which is created by import_scraped_characteristics.do
	* these can be merged by ndc_code.  
	* many don't match from using b/c these shares have collapsed many products. 
	
- would also like to merge the simple_product_chars from product_characteristics.do 

This can probably be done on productndc , but maybe m:1 	
there is also ndccode, which is too long.  

*/

local whereami = "austinbean"
global demo_filep = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/census_demographic_files/"

global hcci_located  "/Users/`whereami'/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/"
di "${hcci_located}"

** make some national share files:


 *********************** TO GENERATE NATIONAL MARKET SHARES **********************************
if 0{ // skip when not doing national shares.  

	* Using collapse - watch out the weights apply to ALL statistics, not just the one closest.  

	preserve 	
		collapse (sum) nat_pres_low=tot_pres_low nat_pres_high=tot_pres_high nat_pres_rand=pres_count_rand nat_pats_low=tot_pat_low  nat_pats_high=tot_pat_high nat_pats_rand=pat_count_rand, by(ndc_code yr) // JUST sums - weights apply to all stats.  	
		save "${hcci_located}national_tmp1.dta", replace
	restore 

	preserve 
		collapse (mean) copay_low=avg_copay deduct_low=avg_deduct [fw=tot_pres_low], by(ndc_code yr)
		save "${hcci_located}national_tmp2.dta", replace
	restore 

	preserve 
		collapse (mean) copay_high=avg_copay deduct_high=avg_deduct [fw=tot_pres_high], by(ndc_code yr)
		save "${hcci_located}national_tmp3.dta", replace
	restore 


	* Generate national market shares - market will be nation/year.
	preserve 
		collapse (sum) nat_total_pres_low=tot_pres_low  nat_total_pres_high=tot_pres_high nat_total_pres_rand=pres_count_rand nat_total_pats_low=tot_pat_low nat_total_pats_high=tot_pat_high nat_total_pats_rand=pat_count_rand, by(yr)
		save "${hcci_located}national_tmp4.dta", replace
	restore 


		use "${hcci_located}national_tmp1.dta", clear
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp2.dta", nogen 
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp3.dta", nogen 
		merge m:1 yr using "${hcci_located}national_tmp4.dta", nogen 
		

				* 75 %ile and above gets 150 products in this year.  Probably that's where to start.  
				* collapse the bottom 75% of products into one "OTHER" category.
		levelsof yr, local(all_yr)
		gen p75 = 0 
		foreach nm of local all_yr{
			summarize nat_pats_low, d 
			replace p75 = 1 if nat_pats_low < `r(p75)' & yr == `nm'
		}
	preserve 
		keep if p75 == 0
		drop p75 
		save "${hcci_located}national_inside_goods.dta"	
	restore 
		
		* keep, collapse, etc - that is, create the <75th %ile product out of these 
		keep if p75 == 1
	preserve 
		keep ndc_code yr nat_pres_low nat_pats_low copay_low deduct_low nat_total_pres_low nat_total_pats_low
		collapse (sum) nat_pres_low nat_pats_low  (firstnm) ndc_code, by(yr)
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp5.dta", replace 
	restore 

	preserve 
		keep ndc_code yr nat_pres_low nat_pats_low copay_low deduct_low nat_total_pres_low nat_total_pats_low
		collapse (mean) copay_low deduct_low (firstnm) ndc_code [fw=nat_pres_low] ,by(yr) 
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp6.dta", replace 

	restore
		
	preserve 
		keep ndc_code yr nat_pres_high nat_pats_high copay_high deduct_high nat_total_pres_high nat_total_pats_high
		collapse (sum) nat_pres_high nat_pats_high  (firstnm) ndc_code, by(yr)
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp7.dta", replace
	restore 
		
	preserve 
		keep ndc_code yr nat_pres_high nat_pats_high copay_high deduct_high nat_total_pres_high nat_total_pats_high
		collapse (mean) copay_high deduct_high (firstnm) ndc_code [fw=nat_pres_high] ,by(yr) 
		replace ndc_code = "00000000000"
		save "${hcci_located}national_tmp8.dta", replace
	restore 

		use "${hcci_located}national_tmp5.dta", clear
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp6.dta", nogen 
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp7.dta", nogen 
		merge 1:1 ndc_code yr using "${hcci_located}national_tmp8.dta", nogen 
		save "${hcci_located}national_composite_inside_good.dta", replace 

		clear 
		use "${hcci_located}national_inside_goods.dta"
		append using "${hcci_located}national_composite_inside_good.dta"

		save "${hcci_located}national_shares.dta", replace
}
******************************** END NATIONAL MARKET SHARES *********************************
	




	use "${hcci_located}national_tmp1.dta", clear
	merge 1:1 ndc_code yr using "${hcci_located}national_tmp2.dta", nogen 
	merge 1:1 ndc_code yr using "${hcci_located}national_tmp3.dta", nogen 
	merge m:1 yr using "${hcci_located}national_tmp4.dta", nogen 
	
	
* 
	
	
			* 75 %ile and above gets 150 products in this year.  Probably that's where to start.  
			* collapse the bottom 75% of products into one "OTHER" category.
	levelsof yr, local(all_yr)
	gen p75 = 0 
	foreach nm of local all_yr{
		summarize nat_pats_low, d 
		replace p75 = 1 if nat_pats_low < `r(p75)' & yr == `nm'
	}
	
	* NB: some products might appear to be new or not if they are near this threshold in some year...?  
	
preserve 
	keep if p75 == 0
	save "${hcci_located}national_shares_interim.dta", replace 
restore 
	
	keep if p75 == 1
	* Now this generates a composite inside good which aggregates the smaller market shares (below 75th %ile)
		* Caveat - this good gets a pretty large share, I guess?  Let's see.  
preserve 
	collapse (firstnm) ndc_code (sum) nat_pres_low nat_pres_high nat_pres_rand nat_pats_low nat_pats_high nat_pats_rand, by(yr) // JUST sums - weights apply to all stats.  	
	replace ndc_code = "00000000000"
	save "${hcci_located}nat_share_tm1.dta", replace
restore 

preserve 
	collapse (firstnm) ndc_code (mean) copay_low deduct_low [fw=nat_pres_low], by(yr)
	replace ndc_code = "00000000000"
	save "${hcci_located}nat_share_tm2.dta", replace
restore 

preserve 
	collapse (firstnm) ndc_code (mean) copay_high deduct_high [fw=nat_pres_high], by( yr)
	replace ndc_code = "00000000000"
	save "${hcci_located}nat_share_tm3.dta", replace
restore 

	use "${hcci_located}nat_share_tm1.dta", clear
	merge 1:1 ndc_code yr using "${hcci_located}nat_share_tm2.dta", nogen 
	merge 1:1 ndc_code yr using "${hcci_located}nat_share_tm3.dta", nogen 

	append using "${hcci_located}national_shares_interim.dta"
* Then append?  

	* NOW add outside good shares.  
		* Either 3% more than are buying, or whole population over some age. 
		* then x avg. prescriptions per person.
		* correct market share is (I believe) number of prescriptions, not people.
	
	
	merge m:1 ndc_code using "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta"
	drop if _merge == 2 // small market share products 
	drop _merge 
	
	merge m:1 productndc using "${op_fp}simple_product_chars.dta"

* Now try to get the Morphine equivalent.
	* this file exists but it's not in {op_fp}
//	preserve
//		do "${op_fp}identify_quantity_measures.do"	
//	restore
	* quantity measures: 
		* aerosol, 
		* ampule, 
		* blister - but refers to tablets in a blister 
		* bottle - only useful w/ liquid measure like mL, otherwise refers to pills
		* Box - sometimes pouch, 
		* Canister 
		* capsule 
		* carton - sometimes bottle in carton, pouch in carton, blister pack in carton, 
		* Granule 
		* Kit - as in one kit in one blister pack 
		* pack - appears w/ blister 
		* patch - appears w/ pouch, since patch appears in patch. 
		* pellets - appears w/ capsule 
		* pouch - contains patch 
		* spray 
		* vial 
		
	* there's a finite number of these and they are doable.
	
 
* put the national total prescriptions for the composite inside good.
	bysort yr: egen npt = max(nat_total_pats_high)
	replace nat_total_pats_high = npt if nat_total_pats_high == . 
	drop npt 
	
	bysort yr: egen npp = max(nat_total_pres_high)
	replace nat_total_pres_high = npp if nat_total_pres_high == . 
	drop npp 

* add 20% as an outside option.

	gen outside_patients = nat_total_pats_high*0.2  // 20% of the market missing - no evidence on this, just a working assumption
	gen outside_presc = outside_patients*2.25       // 2.25 prescriptions per person per year is what the data shows - outside option choosers just like inside people.
	replace nat_total_pres_high = nat_total_pres_high + outside_presc // update market size w/ outside option choosers' prescriptions
	// add five observations w/ those as choices
	gen market_shares = nat_pres_high/nat_total_pres_high 
	keep if market_shares != .
	
* share for the outside good. 
expand 2 if ndc_code == "00000000000", gen(dd)
replace ndc_code = "99999999999" if dd == 1
replace market_shares = outside_presc/nat_total_pres_high if dd == 1


* quick check on features.  
	* DEA2 ORAL simple_fent simple_oxy simple_hydro
	
	* TO FIX LATER:
	replace DEA2 = 0 if DEA2 == .
	replace ORAL = 1 if ORAL == .
	replace simple_fent = 0 if simple_fent == .
	replace simple_oxy = 0 if simple_oxy == .
	replace simple_hydro = 0 if simple_hydro == .

	* outside option has all characteristics 0 
	replace ORAL = 0 if ndc_code == "99999999999"
	
	save "${hcci_located}national_shares.dta", replace
	export delimited "${hcci_located}national_shares.csv", replace
	
