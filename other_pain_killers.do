* other pain relievers


clear
local locd = "austinbean"
*global locd "Austin Bean"
global op_fp "/Users/`locd'/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/`locd'/Desktop/programs/opioids/"




* product file
	import delimited "${op_fp}ndctext/product.txt", clear 

gen pain_match = 0
replace pain_match = 1 if regexm( lower(substancename) , "acetaminophen")
replace pain_match = 1 if regexm( lower(substancename) , "alfentanil" )
replace pain_match = 1 if regexm( lower(substancename) , "aspirin")
replace pain_match = 1 if regexm( lower(substancename) , "belladonna")
replace pain_match = 1 if regexm( lower(substancename) , "benzhydrocodone")
replace pain_match = 1 if regexm( lower(substancename) , "buprenorphine")
replace pain_match = 1 if regexm( lower(substancename) , "butalbital")
replace pain_match = 1 if regexm( lower(substancename) , "butorphanol")
replace pain_match = 1 if regexm( lower(substancename) , "choline salicylate")
replace pain_match = 1 if regexm( lower(substancename) ,"codeine")
replace pain_match = 1 if regexm( lower(substancename) ,"diclofenac")
replace pain_match = 1 if regexm( lower(substancename) ,"diflunisal" )
replace pain_match = 1 if regexm( lower(substancename) ,"dihydrocodeine")
replace pain_match = 1 if regexm( lower(substancename) ,"diphenhydramine" )
replace pain_match = 1 if regexm( lower(substancename) ,"esomeprazole" )
replace pain_match = 1 if regexm( lower(substancename) ,"etodolac" )
replace pain_match = 1 if regexm( lower(substancename) ,"famotidine" )
replace pain_match = 1 if regexm( lower(substancename) ,"fenoprofen" )
replace pain_match = 1 if regexm( lower(substancename) ,"fentanyl")
replace pain_match = 1 if regexm( lower(substancename) ,"flurbiprofen" )
replace pain_match = 1 if regexm( lower(substancename) ,"hydrocodone")
replace pain_match = 1 if regexm( lower(substancename) ,"hydromorphone" )
replace pain_match = 1 if regexm( lower(substancename) ,"ibuprofen")
replace pain_match = 1 if regexm( lower(substancename) ,"indomethacin" )
replace pain_match = 1 if regexm( lower(substancename) ,"isometheptene")
replace pain_match = 1 if regexm( lower(substancename) ,"ketoprofen" )
replace pain_match = 1 if regexm( lower(substancename) ,"ketorolac" )
replace pain_match = 1 if regexm( lower(substancename) ,"lansoprazole" )
replace pain_match = 1 if regexm( lower(substancename) ,"levorphanol" )
replace pain_match = 1 if regexm( lower(substancename) ,"magnesium salicylate" )
replace pain_match = 1 if regexm( lower(substancename) ,"mefenamic acid" )
replace pain_match = 1 if regexm( lower(substancename) ,"meloxicam" )
replace pain_match = 1 if regexm( lower(substancename) ,"mepiridine" )
replace pain_match = 1 if regexm( lower(substancename) ,"meprobomate")
replace pain_match = 1 if regexm( lower(substancename) ,"methadone" )
replace pain_match = 1 if regexm( lower(substancename) ,"misoprostol")
replace pain_match = 1 if regexm( lower(substancename) ,"morphine")
replace pain_match = 1 if regexm( lower(substancename) ,"nabumetone" )
replace pain_match = 1 if regexm( lower(substancename) ,"nalbuphine")
replace pain_match = 1 if regexm( lower(substancename) ,"naloxone")
replace pain_match = 1 if regexm( lower(substancename) ,"naltrexone")
replace pain_match = 1 if regexm( lower(substancename) ,"naproxen" )
replace pain_match = 1 if regexm( lower(substancename) ,"opium")
replace pain_match = 1 if regexm( lower(substancename) ,"oxaprozin" )
replace pain_match = 1 if regexm( lower(substancename) ,"oxycodone")
replace pain_match = 1 if regexm( lower(substancename) ,"oxymorphone" )
replace pain_match = 1 if regexm( lower(substancename) ,"pamabrom")
replace pain_match = 1 if regexm( lower(substancename) ,"pentazocine")
replace pain_match = 1 if regexm( lower(substancename) ,"piroxicam" )
replace pain_match = 1 if regexm( lower(substancename) ,"propoxyphene")
replace pain_match = 1 if regexm( lower(substancename) ,"pyrilamine")
replace pain_match = 1 if regexm( lower(substancename) ,"remifentanil" )
replace pain_match = 1 if regexm( lower(substancename) ,"salicylamide")
replace pain_match = 1 if regexm( lower(substancename) ,"salsalate" )
replace pain_match = 1 if regexm( lower(substancename) ,"sufentanil" )
replace pain_match = 1 if regexm( lower(substancename) ,"sulindac" )
replace pain_match = 1 if regexm( lower(substancename) ,"tapentadol" )
replace pain_match = 1 if regexm( lower(substancename) ,"tolmetin" )
replace pain_match = 1 if regexm( lower(substancename) ,"tramadol")
replace pain_match = 1 if regexm( lower(substancename) ,"ziconotide")


* keep pain matches

keep if pain_match == 1 


	split productndc, p("-")
	gen len1 = strlen(productndc1)
	gen len2 = strlen(productndc2)
* pad the front if the format is to short
	replace productndc = "0"+productndc if len1 == 4
	replace productndc = "00"+productndc if len1 == 3
	replace productndc = "000"+productndc if len1 == 2
	replace productndc = "0000"+productndc if len1 == 1
* pad the end in case it is to short
	replace productndc = productndc+"0" if len2 == 3
	replace productndc = productndc+"00" if len2 == 2
	replace productndc = productndc+"000" if len2 == 1
* drop unused
	drop len1 productndc1 productndc2 
	gen lentest = strlen(productndc)
	tab lentest 
	drop lentest 
	gen NDC = subinstr(productndc, "-", "", .)
	
	
* export
	export excel NDC using "/Users/austinbean/Desktop/programs/opioids/other_pain_meds.xls", firstrow(variables) replace
	export delimited NDC using "/Users/austinbean/Desktop/programs/opioids/other_pain_meds.csv", quote replace



