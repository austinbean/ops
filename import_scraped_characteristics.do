* import the web query results w/ the properties of the NDCs.

  import delimited "/Users/austinbean/Desktop/programs/opioids/ndc_scraped.csv", clear
  
  gen nn = substr(querycode, 2, .) // generates the NDC code.  Should be saved AS STRING to preserve leading zeros.
  
  rename nn ndc_code
  
  save "/Users/austinbean/Desktop/programs/opioids/drug_characteristics.dta", replace
  
