* which firms produce which products?

/*

assign firms to each other.
Look up firm and see where it was 

seems like the first four to five of the NDC do identify firms (including subsidiaries),
but one firm can have more than one number?  eg.  Hikma 0143 and 0054, 
or McKesson 49348 and 62011

Ultimately these still have to be looked up.  

labeler information from NBER:

https://www.nber.org/research/data/ndc-labeler-code-product-code-crosswalk
*/


global op_fp "/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/"
global op_pr "/Users/austinbean/Desktop/programs/opioids/"

	use "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", clear
	merge 1:1 ndc_code using "${op_pr}mme_by_ndc.dta"
	drop if _merge ==2 
	drop _merge 
	
split ndccode, p("-")

keep ndccode*  labelername	

duplicates drop ndccode1 labelername, force

	if 0{
			// remove some junk 
		replace labelername = subinstr(labelername, ",", "", .)
		replace labelername = subinstr(labelername, " Inc", " ", .)
		replace labelername = subinstr(labelername, " LLC", " ", .)
		replace labelername = subinstr(labelername, ".", "", .)
		replace labelername = strtrim(labelername)
		
		preserve 
			duplicates drop labelername, force 
			levelsof labelername, local(labs)
			foreach lb of local labs{
				quietly levelsof ndccode1 if labelername == "`lb'", local(nd)
				foreach ndc of local nd{
					di "* `lb'"
					di "	replace firmid = `ndc' if ndccode == `ndc'"
					di " "
				}
			}
		restore
	} 


***** ALL FIRMS ****
	// one source of data: https://www.drugs.com/pharmaceutical-companies.html
	// perhaps does not have historical data, and is producer, not labeler focused.  
gen firmid = ""
sort labelername

	
* AbbVie
	* prior to 2013 this was part of Abbott labs, which does not appear.  
    replace firmid = "0074" if ndccode == "0074"
 
* Actavis Pharma
	// later merged w/ allergan, but after this data
    replace firmid = "0228" if ndccode == "0228"
	replace firmid = "0228" if labelername == "Actavis Pharma"
 
* Allergan
	// later merged w/ actavis, but after this data.
    replace firmid = "0023" if ndccode == "0023"
 
* American Health Packaging
	// subsidiary of AmerisourceBergen - assign to that code 
    replace firmid = "24385" if ndccode == "68084"
 
* American Regent
	// a Daiichi Sankyo Group Company
    replace firmid = "0517" if ndccode == "0517"
 
* Amerisource Bergen
    replace firmid = "24385" if ndccode == "24385"
 
* Amneal Pharmaceuticals of New York
    replace firmid = "0115" if ndccode == "0115"
 
* Aphena Pharma Solutions - Tennessee
    replace firmid = "43353" if ndccode == "43353"
 
* Apotex Corp
	// "proudly Canadian" no other owner
    replace firmid = "60505" if ndccode == "60505"
 
* AstraZeneca LP
	// https://en.wikipedia.org/wiki/AstraZeneca#Acquisition_history
    replace firmid = "0186" if ndccode == "0186"
 
* Bausch Health US
	// related to the eye guys.
    replace firmid = "0095" if ndccode == "0095"
 
* Baxter Healthcare Corporation
	// seems to be independent.
    replace firmid = "0338" if ndccode == "0338"
 
* Bayer HealthCare
	// acquired Merck, but in 2014.  
    replace firmid = "0280" if ndccode == "0280"
 
* Boehringer Ingelheim Pharmaceuticals
	// no relevant acquisitions during this period
    replace firmid = "0597" if ndccode == "0597"
 
* Breckenridge Pharmaceutical
	// subsidiary of Towa pharmaceuticals
    replace firmid = "51991" if ndccode == "51991"
 
* Bryant Ranch Prepack
	// "market leader in repackaged pharmaceuticals" ?  Ugh.
	// also packages for dispensing directly in doctors offices.  
    replace firmid = "63629" if ndccode == "63629"
 
* Chain Drug Consortium
	// looks independent
    replace firmid = "68016" if ndccode == "68016"
 
* Chain Drug Marketing Association
	// independent supplier to smaller pharmacies
    replace firmid = "63868" if ndccode == "63868"
 
* Cosette Pharmaceuticals
	// independent 
    replace firmid = "0713" if ndccode == "0713"
 
* Dispensing Solutions
	// information difficult to find?  might be owned by mckesson but that is not clear.  
    replace firmid = "55045" if ndccode == "55045"
 
* E Fougera &amp; Co a division of Fougera Pharmaceuticals
    replace firmid = "0168" if ndccode == "0168"
 
* EPIC PHARMA
    replace firmid = "42806" if ndccode == "42806"
 
* Eon Labs
	// part of Sandoz, which is part of Novartis - assigned to Novartis.  
    replace firmid = "0078" if ndccode == "0185"
 
* G&amp;W Laboratories
	// now owned by a firm called Cossette pharma, but after this data.  
    replace firmid = "0713" if ndccode == "0713"
 
* GD Searle  Division of Pfizer
	// already has the Pfizer labeler code 
    replace firmid = "0025" if ndccode == "0025"
 
* Genentech
	// subsidiary of Roche after 2009, but Roche does not appear here.  
	// Roche has a large number of subsidiaries 
    replace firmid = "0004" if ndccode == "0004"
 
* GlaxoSmithKline Consumer Healthcare Holdings (US)
	// has many subsidiaries. 
    replace firmid = "0067" if ndccode == "0067"
 
* Greenstone
	// subsidiary of pfizer 
    replace firmid = "0025" if ndccode == "59762"
 
* HJ Harkins Company
	// privately held, seems independent.  http://hjharkinscompanyinc.com/
    replace firmid = "52959" if ndccode == "52959"
 
* Harmon Store
	// maybe a small drug store chain?  This is a confusing one.
    replace firmid = "63940" if ndccode == "63940"
 
* Heritage Pharmaceuticals
	// owned by an Indian pharma company called Emcure
    replace firmid = "23155" if ndccode == "23155"
 
* Heritage Pharmaceuticals  d/b/a Avet Pharmaceuticals
	// same as above: owned by Emcure.
    replace firmid = "23155" if ndccode == "23155"
 
* Hikma Pharmaceuticals USA
	// this one has some subsidiaries 
    replace firmid = 0054 if ndccode == 0054
 
* Hospira
    replace firmid = 0409 if ndccode == 0409
 
* IVAX Pharmaceuticals
    replace firmid = 0172 if ndccode == 0172
 
* Impax Generics
    replace firmid = 0115 if ndccode == 0115
 
* Indivior
    replace firmid = 12496 if ndccode == 12496
 
* International Medication Systems Limited
    replace firmid = 76329 if ndccode == 76329
 
* Janssen Pharmaceuticals
    replace firmid = 50458 if ndccode == 50458
 
* L Perrigo Company
    replace firmid = 0113 if ndccode == 0113
 
* Lake Erie Medical &amp; Surgical Supply DBA Quality Care Products
    replace firmid = 49999 if ndccode == 49999
 
* Lake Erie Medical DBA Quality Care Products
    replace firmid = 49999 if ndccode == 49999
 
* Lannett Company
    replace firmid = 0527 if ndccode == 0527
 
* Liberty Pharmaceuticals
    replace firmid = 0440 if ndccode == 0440
 
* Major
    replace firmid = 0904 if ndccode == 0904
 
* Major Pharmaceuticals
    replace firmid = 0904 if ndccode == 0904
 
* Mallinckrodt
    replace firmid = 0406 if ndccode == 0406
 
* Marnel Pharmaceutcals
    replace firmid = 0682 if ndccode == 0682
 
* Marnel Pharmaceuticals
    replace firmid = 0682 if ndccode == 0682
 
* McKesson
    replace firmid = 49348 if ndccode == 49348
 
* McKesson (Health Mart)
    replace firmid = 62011 if ndccode == 62011
 
* McKesson Corporation dba SKY Packaging
    replace firmid = 63739 if ndccode == 63739
 
* Mckesson
    replace firmid = 49348 if ndccode == 49348
 
* Mylan Pharmaceuticals
    replace firmid = 0378 if ndccode == 0378
 
* NCS HealthCare of KY  dba Vangard Labs
    replace firmid = 0615 if ndccode == 0615
 
* NDC
    replace firmid = 43128 if ndccode == 43128
 
* Nephron SC
    replace firmid = 0487 if ndccode == 0487
 
* Novartis Consumer Health
    replace firmid = "0078" if ndccode == "0067"
 
* Novartis Pharmaceutical Corporation
    replace firmid = "0078" if ndccode == "0078"
 
* PD-Rx Pharmaceuticals
    replace firmid = 55289 if ndccode == 55289
 
* Paddock Laboratories
    replace firmid = 0574 if ndccode == 0574
 
* Par Pharmaceutical
    replace firmid = 0603 if ndccode == 0603
 
* Patriot Pharmaceuticals
    replace firmid = 10147 if ndccode == 10147
 
* Pfizer Consumer Healthcare
    replace firmid = "0025" if ndccode == "0573"
 
* Pfizer Laboratories Div Pfizer
    replace firmid = "0025" if ndccode == "0025"
 
* Pharmaceutical Associates
    replace firmid = 0121 if ndccode == 0121
 
* Polygen Pharmaceuticals
    replace firmid = 52605 if ndccode == 52605
 
* Qualitest Pharmaceutical
    replace firmid = 0603 if ndccode == 0603
 
* Qualitest Pharmaceuticals
    replace firmid = 0603 if ndccode == 0603
 
* RUGBY LABORATORIES
    replace firmid = 0536 if ndccode == 0536
 
* Rebel Distributors Corp
    replace firmid = 21695 if ndccode == 21695
 
* Reckitt Benckiser Pharmaceuticals
    replace firmid = 12496 if ndccode == 12496
 
* Rite Aid Corporation
    replace firmid = 11822 if ndccode == 11822
 
* Roxane Laboratories
    replace firmid = 0054 if ndccode == 0054
 
* Rugby Laboratories
    replace firmid = 0536 if ndccode == 0536
 
* Sandoz
	// part of Novartis.
    replace firmid = "0078" if ndccode == "0781"
 
* SandozInc
	// part of Novartis.
    replace firmid = "0078" if ndccode == "0781"
 
* Select Brand
    replace firmid = 15127 if ndccode == 15127
 
* SpecGx
    replace firmid = 0406 if ndccode == 0406
 
* Strategic Sourcing Services
    replace firmid = 62011 if ndccode == 62011
 
* Sunmark
    replace firmid = 49348 if ndccode == 49348
 
* TARGET Corporation
    replace firmid = 11673 if ndccode == 11673
 
* Target Corporation
    replace firmid = 11673 if ndccode == 11673
 
* Taro Pharmaceuticals USA
    replace firmid = 51672 if ndccode == 51672
 
* Teligent Pharma
    replace firmid = 52565 if ndccode == 52565
 
* Teva Parenteral Medicines
    replace firmid = 0703 if ndccode == 0703
 
* Teva Pharmaceuticals USA
    replace firmid = 0093 if ndccode == 0093
 
* Topco Associates
    replace firmid = 36800 if ndccode == 36800
 
* Unit Dose Services
    replace firmid = 50436 if ndccode == 50436
 
* Upsher-Smith Laboratories
    replace firmid = 0832 if ndccode == 0832
 
* WALGREEN CO
    replace firmid = 0363 if ndccode == 0363
 
* WALGREEN COMPANY
    replace firmid = 0363 if ndccode == 0363
 
* Wal-Mart Stores
    replace firmid = 49035 if ndccode == 49035
 
* Walgreen Company
    replace firmid = 0363 if ndccode == 0363
 
* Walgreens
    replace firmid = 0363 if ndccode == 0363
 
* West-Ward Pharmaceuticals Corp
	// part of Hikma and was during this period
    replace firmid = "0054" if ndccode == "0054"
 
* West-ward Pharmaceutical Corp
	// part of Hikma and was during this period
    replace firmid = "0054" if ndccode == "0143"
 
* Wyeth Consumer Healthcare
    replace firmid = 0031 if ndccode == 0031
 
* Zydus Pharmaceuticals (USA)
    replace firmid = 68382 if ndccode == 68382
 

