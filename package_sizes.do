* drug quantities

/*

this is annoying, but package sizes differ substantially across NDCs
would like to extract some quantity information 

for regexes: http://userguide.icu-project.org/strings/regexp

https://unicode-org.github.io/icu/

- many are bottle.  bottles are either table or liquid.
*/


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"




use "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", clear
	merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"

	
	duplicates drop packagedescription, force // drops almost nothing.
	drop if packagedescription == ""
	gen matched = 0 
	
* about half are tablets:

	gen table_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= TABLET)")
	* works except for "blister pack", where one tablet in one blister pack, 100 blister pack per carton, e.g.
	gen blister_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= BLISTER)")
		* there is one which was obviously wrong using the above 
	replace matched = 1 if table_num != .
	replace matched = 1 if blister_num != .
	
	* when capsule is eventually followed by bottle - sometimes separated by "extended release" or other words, e.g.
	gen capsule_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CAPSULE)(.+)(?= in 1 BOTTLE)")
		
* decent number are liquid 
	gen liquid_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= mL in 1 BOTTLE)")
	gen liquid_mult = ustrregexs(1) if ustrregexm(packagedescription,"(\d+)(?= BOTTLE in 1 )")
	replace liquid_mult = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CARTON in 1 )") & liquid_num != "" & liquid_mult == ""
	
* good number of vials:

	gen vial_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= mL in 1 VIAL, SINGLE-DOSE)")
		* TODO - this doesn't work yet.  try spaces???
	gen many_vials = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= VIAL)(.+)(?= TRAY)")
	
		* number of vials: number before VIAL not preceded by mL
	gen num_vial_int = ustrregexs(1) if ustrregexm(packagedescription, "(?<!mL)(\d+ VIAL)")
	gen num_vials = ustrregexs(1) if ustrregexm(num_vial_int, "(\d+)")
	drop num_vial_int 
	
* tray in case, cup in tray, ml in cup
	gen cup_dose = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= mL in 1 CUP)")
	gen num_cups = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CUP, UNIT-DOSE)")
		* two categories, one doesn't have the next line
	gen num_tray = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= TRAY in 1)")
	
* granules 
	gen num_granules = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= GRANULE)")
	
* cartridges
	gen cart_quant = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= mL in 1 (AMPULE|CARTRIDGE))")
	gen quant_amp = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= (AMPULE|CARTRIDGE) in 1)")

	
* pouch in carton, patch in pouch, hours in patch 
	gen patch_dose = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= h in 1 PATCH)") // always 72
	gen pouch_cart = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= POUCH in 1)")

* film in pouch nearly doable with previous: 
	gen films = ustrregexs(1) if ustrregexm(packagedescription,"(\d+)(?= FILM)(.+)(?= POUCH)")

* sprays
	gen spray = ustrregexs(1) if ustrregexm(packagedescription,"(\d+)(?= SPRAY)(.+)(?= in 1)")

* suppository (in box and in packet)

	gen supp = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= SUPPOSITORY in 1 BOX)")
	gen supp_pac = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= SUPPOSITORY in 1 PAC)")
	gen pac_box = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= PACKET in 1 (BOX|CARTON))")
	
* grams in tubes in cartons, syringes in boxes 
	gen tube_gram = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= (g|mL) in 1 (TUBE|SYRINGE))")
	gen tube_cart = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= (TUBE|SYRINGE) in 1)")

* lozenge in container:
	gen loz_cont = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= LOZENGE in 1)")
	gen cont_cart = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CONTAINER in 1)")

* mL in bag:
	gen bag_cont = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= mL in 1 BAG)")
	gen cart_bag = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= BAG in 1)")
	
* grams in glass bottles
	gen glass_bottle = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= g in 1 BOTTLE,)")

* aerosol in canister:
	gen aero_cont = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= AEROSOL)(.+)(?= in 1 CANISTER)")
	gen cart_aero = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CANISTER in 1 CARTON)")

* one typo: 
	gen patch_typo = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= PATCH in 1)")


