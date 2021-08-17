# PyBLP on drug data.  

import pyblp 
import pandas as pd 

product_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/pyblp_test_no_outside.csv.csv")
consumer_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/py_blp_demographics.csv")

X1_formulation = pyblp.Formulation('0 + prices', absorb='C(ndc_code)')
X2_formulation = pyblp.Formulation('1 + mme')
product_formulations = (X1_formulation, X2_formulation)
mc_integration = pyblp.Integration('monte_carlo', size=50, specification_options={'seed': 0})
mc_problem = pyblp.Problem(product_formulations, product_data, integration=mc_integration)
