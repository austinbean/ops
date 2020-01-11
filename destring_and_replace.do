* destring, replace

ds geo_id name st_cd st_abbrev cbsa_code, not
local list1 `r(varlist)'

foreach varl of varlist `list1'{
	replace `varl' = "" if `varl' == "*****"
	replace `varl' = "" if `varl' == "**"
	replace `varl' = "" if `varl' == "-"
	replace `varl' = "1" if `varl' == "(X)"
	replace `varl' = "" if `varl' == "N"
	capture destring `varl', replace

}
