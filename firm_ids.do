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

	use "${op_pr}drug_characteristics.dta", clear
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
drop ndccode 
rename ndccode1 ndccode 

	
* AbbVie
	* prior to 2013 this was part of Abbott labs, which does not appear.  
    replace firmid = "0074" if ndccode == "0074"
 
* Actavis Pharma
	// later merged w/ allergan, but after this data
    replace firmid = "0228" if ndccode == "0228"
	replace firmid = "0228" if regexm(lower(labelername),"actavis")
 
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
	replace firmid = "43353" if ndccode == "67544"
 
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
    replace firmid = "0054" if ndccode == "0054"
	replace firmid = "0054" if ndccode == "0641"
 
* Hospira
	// earlier part of Abbott, but spun off prior to this period.  
	// part of Pfizer after 2015 but not in this data.  
    replace firmid = "0409" if ndccode == "0409"
 
* IVAX Pharmaceuticals
	// owned by TEVA 
    replace firmid = "0093" if ndccode == "0172"
 
* Impax Generics
	// purchased by Amneal, but after this data
    replace firmid = "0115" if ndccode == "0115"
 
* Indivior
	// division of Reckitt-Benckiser until 2014
    replace firmid = "12496" if ndccode == "12496"
 
* International Medication Systems Limited
	// Subsidiary of Amphastar
    replace firmid = "76329" if ndccode == "76329"
 
* Janssen Pharmaceuticals
	// subsidiary of Johnson and Johnson 
    replace firmid = "50458" if ndccode == "50458"
 
* L Perrigo Company
	// independent but has subsidiaries, per Wikipedia article.  
    replace firmid = "0113" if ndccode == "0113"
 
* Lake Erie Medical &amp; Surgical Supply DBA Quality Care Products
	// this might be just a store? this one is confusing
    replace firmid = "49999" if ndccode == "49999"
 
* Lake Erie Medical DBA Quality Care Products
	// same as above.  TODO
    replace firmid = "49999" if ndccode == "49999"
 
* Lannett Company
	// independent
    replace firmid = "0527" if ndccode == "0527"
 
* Liberty Pharmaceuticals
	// independent
    replace firmid = "0440" if ndccode == "0440"
 
* Major
	//  affiliated w/ Rugby as of 2012
	// TODO - one firm after 2012  
    replace firmid = "0904" if ndccode == "0904"
 
* Mallinckrodt
	// independent, w/ many subsidiaries
    replace firmid = "0406" if ndccode == "0406"
  
* Marnel Pharmaceuticals
	// dermatology products?
    replace firmid = "0682" if ndccode == "0682"
 
* McKesson
	// distributor maybe?  Very large firm.  
    replace firmid = "49348" if ndccode == "49348"
 
* McKesson (Health Mart)
    replace firmid = "49348" if ndccode == "62011"
 
* McKesson Corporation dba SKY Packaging
    replace firmid = "49348" if ndccode == "63739"
 
* Mckesson
    replace firmid = "49348" if ndccode == "49348"
 
* Mylan Pharmaceuticals
	// as of 2020 part of Pfizer 
    replace firmid = "0378" if ndccode == "0378"
 
* NCS HealthCare of KY  dba Vangard Labs
	// independent?  now closed.
    replace firmid = "0615" if ndccode == "0615"
 
* NDC
	// TODO this is more likely a data entry error than anything else...
    replace firmid = "43128" if ndccode == "43128"
 
* Nephron SC
	// TODO - weird firm for this data.
    replace firmid = "0487" if ndccode == "0487"
 
* Novartis Consumer Health
    replace firmid = "0078" if ndccode == "0067"
 
* Novartis Pharmaceutical Corporation
    replace firmid = "0078" if ndccode == "0078"
 
* PD-Rx Pharmaceuticals
	// probably a packager
    replace firmid = "55289" if ndccode == "55289"
 
* Paddock Laboratories
	//  a subsidiary of Perrigo 
    replace firmid = "0113" if ndccode == "0574"
 
* Par Pharmaceutical
	// an Endo company.  acquired qualitest in 2010 (this data)
    replace firmid = "0603" if ndccode == "0603"
 
* Patriot Pharmaceuticals
	// authorized generics for Johnson and Johnson / Janssen.  
    replace firmid = "50458" if ndccode == "10147"
 
* Pfizer Consumer Healthcare
    replace firmid = "0025" if ndccode == "0573"
 
* Pfizer Laboratories Div Pfizer
    replace firmid = "0025" if ndccode == "0069"
 
* Pharmaceutical Associates
	// subsidiary of beach products, which otherwise does not appear
    replace firmid = "0121" if ndccode == "0121"
 
* Polygen Pharmaceuticals
	// find neither subsidiaries nor parents
    replace firmid = "52605" if ndccode == "52605"
 
* Qualitest Pharmaceutical
	// acquired by Endo in 2010 (see Par Pharma above)
    replace firmid = "0603" if ndccode == "0603"
 
* RUGBY LABORATORIES
	* affiliated with Major after 2012 (this data)
	* TODO - acquired during this period.  
    replace firmid = "0536" if ndccode == "0536"
 
* Rebel Distributors Corp
	// probably a distributor.
    replace firmid = "21695" if ndccode == "21695"
 
* Reckitt Benckiser Pharmaceuticals
	// has a subsidiary listed above.  
    replace firmid = "12496" if ndccode == "12496"
 
* Rite Aid Corporation
	// large drug store chain
    replace firmid = "11822" if ndccode == "11822"
 
* Roxane Laboratories
	// acquired by Hikma 
	// already have same labeler code. 
    replace firmid = "0054" if ndccode == "0054"
 
 
* Sandoz
	// part of Novartis.
    replace firmid = "0078" if ndccode == "0781"
 
* SandozInc
	// part of Novartis.
    replace firmid = "0078" if ndccode == "0781"
 
* Select Brand
	// ID uncertain b/c of boring name.
    replace firmid = "15127" if ndccode == "15127"
 
* SpecGx
	// mallinckrodt 
    replace firmid = "0406" if ndccode == "0406"
 
* Strategic Sourcing Services
	// nothing findable.
    replace firmid = "62011" if ndccode == "62011"
 
* Sunmark
	// probably independent. 
    replace firmid = "49348" if ndccode == "49348"
 
* TARGET Corporation
	// large retailer
    replace firmid = "11673" if ndccode == "11673"
 
* Taro Pharmaceuticals USA
	// acquired by SUN of India (2010) - no other appearances in this data.
    replace firmid = "51672" if ndccode == "51672"
 
* Teligent Pharma
	// appears independent.  
    replace firmid = "52565" if ndccode == "52565"
 
* Teva Parenteral Medicines
    replace firmid = "0093" if ndccode == "0703"
 
* Teva Pharmaceuticals USA
    replace firmid = "0093" if ndccode == "0093"
 
* Topco Associates
	// distributor to other pharmacies
	// broadly speaking a purchasing group for a bunch of grocery chains and related.
    replace firmid = "36800" if ndccode == "36800"
 
* Unit Dose Services
	// distributor
    replace firmid = "50436" if ndccode == "50436"
 
* Upsher-Smith Laboratories
	// part of Sawai of Japan.  makes generics
    replace firmid = "0832" if ndccode == "0832"
 
* WALGREEN CO
	// large chain... 
    replace firmid = "0363" if ndccode == "0363"
 
* Wal-Mart Stores
	// large chain 
    replace firmid = "49035" if ndccode == "49035"
 
 
* West-Ward Pharmaceuticals Corp
	// part of Hikma and was during this period
    replace firmid = "0054" if ndccode == "0054"
 
* West-ward Pharmaceutical Corp
	// part of Hikma and was during this period
    replace firmid = "0054" if ndccode == "0143"
 
* Wyeth Consumer Healthcare
	// acquired by Pfizer in the start of 2009 (this data)
    replace firmid = "0025" if ndccode == "0031"
 
* Zydus Pharmaceuticals (USA)
	// owned by Cadila of India.  
    replace firmid = "68382" if ndccode == "68382"
 
save "${op_pr}product_ownership.dta", replace
