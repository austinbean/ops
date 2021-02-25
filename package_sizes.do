* drug quantities

/*

this is annoying, but package sizes differ substantially across NDCs

*/


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"




use "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", clear
	merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"

	
* TODO - next thing to figure out is the number of units, b/c larger package size is better.  
	duplicates drop packagedescription, force // drops almost nothing.
	* tablet 
	* tablet in blister pack 
	* capsule
	* patch in pouch :(
	* vial
	* single-does in 1 pouch :(
	* bottle 
	* capsule in blister pack in carton :/ 
	* aerosol metered in 1 canister 
	* 1 kit in one blister pack 
	* dropper, bottle 
	* cup unit dose in 1 tray 
	* spray in cartridge 
	* ampule in pouch 
	* suppository in packet 
	* granule delayed release in carton 
	* ampule in tray 
	* vial multidose in carton in case 
	* tube in carton 
	* ampule in cello pack 
	* tablet in pail (?)
	* syringe in carton 
	* at about row 700

		
