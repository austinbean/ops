* add state code:

gen st_cd = substr(geo_id, -2, .)
gen st_abbrev = ""


replace st_abbrev = "AL" if lower(name) =="alabama"	// 01 AL	Alabama
replace st_abbrev = "AK" if lower(name) =="alaska"	// 02 AK	Alaska
replace st_abbrev = "AZ" if lower(name) =="arizona"	//04 AZ 	Arizona
replace st_abbrev = "AR" if lower(name) =="arkansas"	//05  AR	Arkansas
replace st_abbrev = "CA" if lower(name) =="california"	//06  CA	California
replace st_abbrev = "CO" if lower(name) =="colorado"	//08  CO	Colorado
replace st_abbrev = "CT" if lower(name) =="connecticut"	//09  CT	Connecticut
replace st_abbrev = "DE" if lower(name) =="delaware"	//10  DE	Delaware
replace st_abbrev = "DC" if lower(name) =="district of columbia"	//10  DC	Washington, DC
replace st_abbrev = "FL" if lower(name) =="florida"	//12 FL	Florida
replace st_abbrev = "GA" if lower(name) =="georgia"	//13  GA	Georgia
replace st_abbrev = "HI" if lower(name) =="hawaii"	//15  HI	hawaii
replace st_abbrev = "ID" if lower(name) =="idaho"	//16  ID	Idaho
replace st_abbrev = "IL" if lower(name) =="illinois"	//17  IL	Illinois
replace st_abbrev = "IN" if lower(name) =="indiana"	//18  IN	Indiana
replace st_abbrev = "IA" if lower(name) =="iowa"	//19  IA	Iowa
replace st_abbrev = "KS" if lower(name) =="kansas"	//20  KS	Kansas
replace st_abbrev = "KY" if lower(name) =="kentucky"	//21  KY	Kentucky
replace st_abbrev = "LA" if lower(name) =="louisiana"	//22  LA	Louisiana
replace st_abbrev = "ME" if lower(name) =="maine"	//23  ME	Maine
replace st_abbrev = "MD" if lower(name) =="maryland"	//24  MD	Maryland
replace st_abbrev = "MA" if lower(name) =="massachusetts"	//25  MA	Massachusetts
replace st_abbrev = "MI" if lower(name) =="michigan"	//26  MI	Michigan
replace st_abbrev = "MN" if lower(name) =="minnesota"	//27  MN	Minnesota
replace st_abbrev = "MS" if lower(name) =="mississippi"	//28  MS	Mississippi
replace st_abbrev = "MO" if lower(name) =="missouri"	//29  MO	Missouri
replace st_abbrev = "MT" if lower(name) =="montana"	//30  MT	Montana
replace st_abbrev = "NE" if lower(name) =="nebraska"	//31  NE	Nebraska
replace st_abbrev = "NV" if lower(name) =="nevada"	//32  NV	Nevada
replace st_abbrev = "NH" if lower(name) =="new hampshire"	//33  NH	New Hampshire
replace st_abbrev = "NJ" if lower(name) =="new jersey"	//34  NJ	New Jersey
replace st_abbrev = "NM" if lower(name) =="new mexico"	//35  NM	New Mexico
replace st_abbrev = "NY" if lower(name) =="new york"	//36  NY	New York
replace st_abbrev = "NC" if lower(name) =="north carolina"	//37  NC	North Carolina
replace st_abbrev = "ND" if lower(name) =="north dakota"	//38  ND	North Dakota
replace st_abbrev = "OH" if lower(name) =="ohio"	//39  OH	Ohio
replace st_abbrev = "OK" if lower(name) =="oklahoma"	// 40  OK	Oklahoma
replace st_abbrev = "OR" if lower(name) =="oregon"	//41   OR	Oregon
replace st_abbrev = "PA" if lower(name) =="pennsylvania"	//PA	Pennsylvania
replace st_abbrev = "PR" if lower(name) =="puerto rico"	//72  PR	Puerto Rico
replace st_abbrev = "RI" if lower(name) =="rhode island"	//44  RI	Rhode Island
replace st_abbrev = "SC" if lower(name) =="south carolina"	//45  SC	South Carolina
replace st_abbrev = "SD" if lower(name) =="south dakota"	//46  SD	South Dakota
replace st_abbrev = "TN" if lower(name) =="tennessee"	//47  TN	Tennessee
replace st_abbrev = "TX" if lower(name) =="texas"	//48  TX	Texas
replace st_abbrev = "UT" if lower(name) =="utah"	//49  UT	Utah
replace st_abbrev = "VT" if lower(name) =="vermont"	//50  VT	Vermont
replace st_abbrev = "VA" if lower(name) =="virginia"	//51   VA	Virginia
replace st_abbrev = "WA" if lower(name) =="washington"	//53  WA	Washington
replace st_abbrev = "WV" if lower(name) =="west virginia"	//54  WV	West Virginia
replace st_abbrev = "WI" if lower(name) =="wisconsin"	//55  WI	Wisconsin
replace st_abbrev = "WY" if lower(name) =="wyoming"	//56  WY	Wyoming



