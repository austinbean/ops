* variable labeler

ds geo_id name st_cd st_abbrev cbsa_code, not
local list1 `r(varlist)'





foreach varl of varlist `list1'{
	replace `varl' = subinstr(`varl', "number", "#", .)
	replace `varl' = subinstr(`varl', "percent", "%", .)

	replace `varl' = subinstr(`varl', "!!", " ", .) 
	levelsof `varl' if geo_id == "id", local(vll)
	label variable `varl' `vll'

}
