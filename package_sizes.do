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
	drop if _merge ==2 
	drop _merge 
	
	// DELETE below LATER
	keep packagedescription 
	//DELETE above LATER
	
	duplicates drop packagedescription, force // drops almost nothing.
	drop if packagedescription == ""
	gen matched = 0 
	gen unit_quantity = .
* about half are tablets and/or capsules:

	gen table_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= TABLET)")
	* works except for "blister pack", where one tablet in one blister pack, 100 blister pack per carton, e.g.
	gen blister_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= BLISTER)")
	destring table_num, replace
	destring blister_num, replace
		* there is one which was obviously wrong using the above; "36 POUCH in 1 CARTON (0363-0421-68)  &gt; 2 TABLET, EFFERVESCENT in 1 POUCH"
	replace unit_quantity = table_num if table_num != . & blister_num == . & matched == 0
	replace matched = 1 if table_num != . & blister_num == . & matched == 0
	
	replace unit_quantity = table_num*blister_num if table_num != . & blister_num != . & matched == 0	
	replace matched = 1 if table_num != . & blister_num != . & matched == 0	
	
	* when capsule is eventually followed by bottle - sometimes separated by "extended release" or other words, e.g.
	gen capsule_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CAPSULE)(.+)(?= in 1 BOTTLE)")
	destring capsule_num, replace
	gen cap_bottle = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= BOTTLE in 1 (BOX|CARTON|PACKAGE))")
	destring cap_bottle, replace
	
	replace unit_quantity = capsule_num if capsule_num != . & cap_bottle == . & matched == 0
	replace matched = 1 if capsule_num != . & cap_bottle == . & matched == 0
	
	replace unit_quantity = capsule_num*cap_bottle if capsule_num != . & cap_bottle != . & matched == 0
	replace matched = 1 if capsule_num != . & cap_bottle != . & matched == 0
	
	* capsule blister pack (in bottle/box/carton exclusively)
	gen capblis_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CAPSULE)(.+)(?= in 1 BLISTER)")
	destring capblis_num, replace
	
	gen capblis_bottle = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= BLISTER PACK in 1 (BOX|CARTON|PACKAGE))")
	destring capblis_bottle, replace 
	
	replace unit_quantity = capblis_num*capblis_bottle if capblis_num != . & capblis_bottle != . & matched == 0
	replace matched = 1 if capblis_num != . & capblis_bottle != . & matched == 0
	
	* granules 
	gen num_granules = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= GRANULE)")
	destring num_granules, replace 
	
	replace unit_quantity = num_granules if num_granules != . & matched == 0
	replace matched = 1 if num_granules != . & matched == 0

		
gen liquid_quantity = .
* decent number are liquid 
	* TODO - this is a hard one: 6 CARTON in 1 CASE (0406-8003-12)  &gt; 1 BOTTLE, PLASTIC in 1 CARTON &gt; 120 mL in 1 BOTTLE, PLASTIC

	gen liquid_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= mL in 1 BOTTLE)")
	destring liquid_num, replace
	
	gen liquid_mult = ustrregexs(1) if ustrregexm(packagedescription,"(\d+)(?= (BOTTLE|CARTON) in 1 )")
	destring liquid_mult, replace 
	
	replace liquid_quantity = liquid_num if liquid_num != . & liquid_mult == . & matched == 0
	replace matched = 1 if liquid_num != . & liquid_mult == . & matched == 0
	
	replace liquid_quantity = liquid_num*liquid_mult if liquid_num != . & liquid_mult != . & matched == 0
	replace matched = 1 if liquid_num != . & liquid_mult != . & matched == 0
	
* good number of vials:
		* note \d*\.?\d* matches decimal numbers, inc. .5, 0.5, 5, e.g.
	gen vial_num = ustrregexs(1) if ustrregexm(packagedescription, "(\d*\.?\d*)(?= mL in 1 VIAL)")
	destring vial_num, replace
	
	gen many_vials = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= VIAL)(.+)(?= (TRAY|CARTON))")
	replace many_vials = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= VIAL)(.+)(|= in 1 POUCH)") & many_vials == "" & matched == 0 // handles a special case.
	destring many_vials, replace 
	

	gen pouch_vials = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= POUCH in 1 CARTON)") & matched == 0 // another part of the special case.
	destring pouch_vials, replace
	
	replace liquid_quantity = vial_num if vial_num != . & many_vials == . & pouch_vials == . & matched == 0
	replace matched = 1 if vial_num != . & many_vials == . & pouch_vials == . & matched == 0
	
	replace liquid_quantity = vial_num*many_vials if vial_num != . & many_vials != . & pouch_vials == . & matched == 0
	replace matched = 1 if vial_num != . & many_vials != . &  pouch_vials == . & matched == 0
	
	replace liquid_quantity = vial_num*many_vials*pouch_vials if vial_num != . & many_vials != . &  pouch_vials != . & matched == 0
	replace matched = 1 if vial_num != . & many_vials != . &  pouch_vials != . & matched == 0
	
* tray in case, cup in tray, ml in cup
	gen cup_dose = ustrregexs(1) if ustrregexm(packagedescription, "(\d*\.?\d*)(?= mL in 1 CUP)") //decimal
	destring cup_dose, replace
	
	gen num_cups = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= CUP, UNIT-DOSE)")
	destring num_cups, replace 
	
		* two categories, one doesn't have the next line
	gen num_tray = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= TRAY in 1)")
	destring num_tray, replace 
	
	replace liquid_quantity = cup_dose*num_cups if cup_dose != . & num_cups != . & num_tray == . & matched == 0
	replace matched = 1 if cup_dose != . & num_cups != . & num_tray == . & matched == 0
	
	replace liquid_quantity = cup_dose*num_cups*num_tray if cup_dose != . & num_cups != . & num_tray != . & matched == 0
	replace matched = 1 if cup_dose != . & num_cups != . & num_tray != . & matched == 0
	

	
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
	gen patch_typo = ustrregexs(1) if ustrregexm(packagedescription, "(\d+)(?= PATCH in 1 PATCH)")


