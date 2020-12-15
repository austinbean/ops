* state demographics, 2010
* note that filename of .csv includes original date of download, so this needs to be changed with a different version


global demo_filep = "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/census_demographic_files/"
global ops_prog_filep = "/Users/austinbean/Desktop/programs/opioids/"

* age by state: 

 import delimited "${demo_filep}age_by_state/ACSST5Y2010.S0101_data_with_overlays_2020-01-09T130809.csv", varnames(1)  clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}age_to_keep.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}age_by_state/age_by_state.dta", replace

* disability status by state:

 import delimited "${demo_filep}disability_status_by_state/ACSST1Y2010.S1810_data_with_overlays_2020-01-09T144939.csv", varnames(1) clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}disability_to_keep.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}disability_status_by_state/disability_status_by_state.dta", replace
 
* educational attainment
 
 import delimited "${demo_filep}educational_attainment_by_state/ACSST5Y2010.S1501_data_with_overlays_2020-01-09T125512.csv", varnames(1) clear 
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}educational_attain_to_keep.do"
 sort name
 drop cbsa_code 
 save "${demo_filep}educational_attainment_by_state/educ_attain_by_state.dta", replace
 
* employment by state
 import delimited "${demo_filep}employment_rate_by_state/ACSST5Y2010.S2301_data_with_overlays_2020-01-09T144033.csv", varnames(1) clear 
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}employment_to_keep.do"
 sort name
 drop cbsa_code 
 save  "${demo_filep}employment_rate_by_state/employment_by_state.dta", replace
  
  /*
* health insurance by state
	* USE THE OTHER ONE - not this one 
 import delimited "${demo_filep}health_insurance_status_by_state/ACSST1Y2010.S2701_data_with_overlays_2020-01-09T145049.csv", varnames(1) clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}health_insurance_to_keep.do" 
 sort name
 drop cbsa_code 
 save "${demo_filep}health_insurance_status_by_state/acs_health_ins_by_state.dta", replace
 */
 
* another health insurance by state 
	* USE THIS ONE.  
  import excel "${demo_filep}health_insurance_status_by_state/hic04_acs.xlsx", cellrange(A4:AX577)  clear
  replace D = "2019" if _n == 1
  replace E = "2019" if _n == 1
  replace F = "2019" if _n == 1
  replace H = "2018" if _n == 1
  replace I = "2018" if _n == 1
  replace J = "2018" if _n == 1
  replace L = "2017" if _n == 1
  replace M = "2017" if _n == 1
  replace N = "2017" if _n == 1
  replace P = "2016" if _n == 1
  replace Q = "2016" if _n == 1
  replace R = "2016" if _n == 1
  replace T = "2015" if _n == 1
  replace U = "2015" if _n == 1
  replace V = "2015" if _n == 1
  replace X = "2014" if _n == 1
  replace Y = "2014" if _n == 1
  replace Z = "2014" if _n == 1
  replace AB = "2013" if _n == 1
  replace AC = "2013" if _n == 1
  replace AD = "2013" if _n == 1  
  replace AF = "2012" if _n == 1
  replace AG = "2012" if _n == 1
  replace AH = "2012" if _n == 1  
  replace AJ = "2011" if _n == 1
  replace AK = "2011" if _n == 1
  replace AL = "2011" if _n == 1  
  replace AN = "2010" if _n == 1
  replace AO = "2010" if _n == 1
  replace AP = "2010" if _n == 1
  replace AR = "2009" if _n == 1
  replace AS = "2009" if _n == 1
  replace AT = "2009" if _n == 1  
  replace AV = "2008" if _n == 1
  replace AW = "2008" if _n == 1
  replace AX = "2008" if _n == 1 
  foreach varb of varlist F J N R V Z AD AH AL AP AT AX{
	replace `varb' = "MOE" if _n == 2
  }
  
  ds 
  foreach varb of varlist `r(varlist)'{
  	di "`varb'"
  	gen vv`varb' = `varb'[2]+" "+`varb'[1] 
	replace `varb' = vv`varb' if _n == 1
	levelsof `varb' if _n == 1, local(v`varb')

  }
  drop vv* 

  
  ds 
  foreach varb of varlist `r(varlist)'{
	rename `varb' `=strtoname(`varb'[1])'
  }
  drop if _n <= 2
  rename _Nation_State Nation_or_State
  rename _Coverage Coverage_Type
  replace Coverage_Type = subinstr(Coverage_Type, ".", "", .)
  reshape long Estimate_ Margin_of_error_ Percent_ MOE_ , i(Nation_or_State Coverage_Type) j(yr)
  
  destring Estimate_, replace
  replace Estimate = Estimate*1000
  
  replace Margin_of_error_ = "0" if Margin_of_error == "Z"
  destring Margin_of_error_, replace
  replace Margin_of_error_ = Margin_of_error_*1000

  destring Percent_, replace
  
  replace MOE_ = "0" if MOE_ == "Z"
  destring MOE_, replace 
  
  sort Nation_or_State yr Coverage_Type
  
  rename Nation_or_State name 
  gen geo_id = name 
  do "${ops_prog_filep}make_state_codes.do"
  replace st_abbrev = "US" if geo_id == "United States"
  replace st_cd = "" 
  
replace st_cd = "01" if lower(geo_id) =="alabama"	// 01 AL	Alabama
replace st_cd = "02" if lower(geo_id) =="alaska"	// 02 AK	Alaska
replace st_cd = "04" if lower(geo_id) =="arizona"	//04 AZ 	Arizona
replace st_cd = "05" if lower(geo_id) =="arkansas"	//05  AR	Arkansas
replace st_cd = "06" if lower(geo_id) =="california"	//06  CA	California
replace st_cd = "08" if lower(geo_id) =="colorado"	//08  CO	Colorado
replace st_cd = "09" if lower(geo_id) =="connecticut"	//09  CT	Connecticut
replace st_cd = "10" if lower(geo_id) =="delaware"	//10  DE	Delaware
replace st_cd = "11" if lower(geo_id) =="district of columbia"	//11  DC	Washington, DC
replace st_cd = "12" if lower(geo_id) =="florida"	//12 FL	Florida
replace st_cd = "13" if lower(geo_id) =="georgia"	//13  GA	Georgia
replace st_cd = "15" if lower(geo_id) =="hawaii"	//15  HI	hawaii
replace st_cd = "16" if lower(geo_id) =="idaho"	//16  ID	Idaho
replace st_cd = "17" if lower(geo_id) =="illinois"	//17  IL	Illinois
replace st_cd = "18" if lower(geo_id) =="indiana"	//18  IN	Indiana
replace st_cd = "19" if lower(geo_id) =="iowa"	//19  IA	Iowa
replace st_cd = "20" if lower(geo_id) =="kansas"	//20  KS	Kansas
replace st_cd = "21" if lower(geo_id) =="kentucky"	//21  KY	Kentucky
replace st_cd = "22" if lower(geo_id) =="louisiana"	//22  LA	Louisiana
replace st_cd = "23" if lower(geo_id) =="maine"	//23  ME	Maine
replace st_cd = "24" if lower(geo_id) =="maryland"	//24  MD	Maryland
replace st_cd = "25" if lower(geo_id) =="massachusetts"	//25  MA	Massachusetts
replace st_cd = "26" if lower(geo_id) =="michigan"	//26  MI	Michigan
replace st_cd = "27" if lower(geo_id) =="minnesota"	//27  MN	Minnesota
replace st_cd = "28" if lower(geo_id) =="mississippi"	//28  MS	Mississippi
replace st_cd = "29" if lower(geo_id) =="missouri"	//29  MO	Missouri
replace st_cd = "30" if lower(geo_id) =="montana"	//30  MT	Montana
replace st_cd = "31" if lower(geo_id) =="nebraska"	//31  NE	Nebraska
replace st_cd = "32" if lower(geo_id) =="nevada"	//32  NV	Nevada
replace st_cd = "33" if lower(geo_id) =="new hampshire"	//33  NH	New Hampshire
replace st_cd = "34" if lower(geo_id) =="new jersey"	//34  NJ	New Jersey
replace st_cd = "35" if lower(geo_id) =="new mexico"	//35  NM	New Mexico
replace st_cd = "36" if lower(geo_id) =="new york"	//36  NY	New York
replace st_cd = "37" if lower(geo_id) =="north carolina"	//37  NC	North Carolina
replace st_cd = "38" if lower(geo_id) =="north dakota"	//38  ND	North Dakota
replace st_cd = "39" if lower(geo_id) =="ohio"	//39  OH	Ohio
replace st_cd = "40" if lower(geo_id) =="oklahoma"	// 40  OK	Oklahoma
replace st_cd = "41" if lower(geo_id) =="oregon"	//41   OR	Oregon
replace st_cd = "42" if lower(geo_id) =="pennsylvania"	//42 PA	Pennsylvania
replace st_cd = "72" if lower(geo_id) =="puerto rico"	//72  PR	Puerto Rico
replace st_cd = "44" if lower(geo_id) =="rhode island"	//44  RI	Rhode Island
replace st_cd = "45" if lower(geo_id) =="south carolina"	//45  SC	South Carolina
replace st_cd = "46" if lower(geo_id) =="south dakota"	//46  SD	South Dakota
replace st_cd = "47" if lower(geo_id) =="tennessee"	//47  TN	Tennessee
replace st_cd = "48" if lower(geo_id) =="texas"	//48  TX	Texas
replace st_cd = "49" if lower(geo_id) =="utah"	//49  UT	Utah
replace st_cd = "50" if lower(geo_id) =="vermont"	//50  VT	Vermont
replace st_cd = "51" if lower(geo_id) =="virginia"	//51   VA	Virginia
replace st_cd = "53" if lower(geo_id) =="washington"	//53  WA	Washington
replace st_cd = "54" if lower(geo_id) =="west virginia"	//54  WV	West Virginia
replace st_cd = "55" if lower(geo_id) =="wisconsin"	//55  WI	Wisconsin
replace st_cd = "56" if lower(geo_id) =="wyoming"	//56  WY	Wyoming

rename name Nation_or_State 
drop geo_id  

keep if yr == 2010

drop Percent_ MOE_ Margin_of_error_
rename Estimate_ insured_2010_
replace Coverage_Type = subinstr(Coverage_Type, " ", "_", .)
replace Coverage_Type = subinstr(Coverage_Type, "-", "_", .)
reshape wide insured_2010_, i(Nation_or_State) j(Coverage_Type) string

  
  save "${demo_filep}health_insurance_status_by_state/health_ins_by_state.dta", replace
 
* income by state
 import delimited "${demo_filep}income_by_state/ACSST5Y2010.S1901_data_with_overlays_2020-01-09T131200.csv", varnames(1) clear
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}income_to_keep.do" 
 sort name
 drop cbsa_code 
 save "${demo_filep}income_by_state/income_by_state.dta", replace
 
* race by state
 import delimited "${demo_filep}race_by_state/ACSDT5Y2010.B02001_data_with_overlays_2020-01-09T130601.csv", varnames(1) clear 
 gen cbsa_code = .
 do "${ops_prog_filep}make_state_codes.do"
 do "${ops_prog_filep}name_abbreviator.do"
 do "${ops_prog_filep}variable_labeler.do"
 drop if geo_id == "id"
 do "${ops_prog_filep}destring_and_replace.do"
 do "${ops_prog_filep}race_to_keep.do" 
 sort name
 drop cbsa_code 
 save "${demo_filep}race_by_state/race_by_state.dta", replace

 
 * Merge across files 
 use "${demo_filep}age_by_state/age_by_state.dta", clear
 merge 1:1 st_abbrev using "${demo_filep}disability_status_by_state/disability_status_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}educational_attainment_by_state/educ_attain_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}employment_rate_by_state/employment_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}health_insurance_status_by_state/health_ins_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}income_by_state/income_by_state.dta", nogen
 merge 1:1 st_abbrev using "${demo_filep}race_by_state/race_by_state.dta", nogen
 
 *drop if Nation_or_State == "United States"
 *drop Nation_or_State
 
 * Generate better names:
 rename total_10_14 pop_10_14
 rename total_15_19 pop_15_19
 rename total_20_24 pop_20_24
 rename total_25_29 pop_25_29
 rename total_30_34 pop_30_34
 rename total_35_39 pop_35_39
 rename total_40_44 pop_40_44
 rename total_45_49 pop_45_49
 rename total_50_54 pop_50_54
 rename total_55_59 pop_55_59
 rename total_60_64 pop_60_64
 rename total_65_69 pop_65_69
 rename total_70_74 pop_70_74
 rename total_75_79 pop_75_79
 rename total_80_84 pop_80_84
 rename total_85_plus pop_85_plus
 
 
 export delimited using "${ops_prog_filep}state_demographics.csv", replace
 
 * Save here 
 
 keep geo_id name 
 save "${demo_filep}state_names_and_geoids.dta", replace
 
