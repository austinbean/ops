* abbreviator
* abbreviates variable names:

ds geo_id name st_cd st_abbrev cbsa_code, not
local list1 `r(varlist)'


foreach varl of varlist `list1'{
	di "`varl'"
	replace `varl' = ustrregexra(`varl', "Margin of Error", "MoE") if geo_id == "id" // only do this for one entry w/ names
	replace `varl' = ustrregexra(`varl', "Estimate", "Est") if geo_id == "id"
	replace `varl' = ustrregexra(lower(`varl'), "percent imputed", "p_i") if geo_id == "id"
	replace `varl' = ustrregexra(lower(`varl'), "population", "pop") if geo_id == "id"
	replace `varl' = ustrregexra(lower(`varl'), "total", "tot") if geo_id == "id"
	replace `varl' = ustrregexra(lower(`varl'), "summary indicators", "sum_ind") if geo_id == "id"
}



