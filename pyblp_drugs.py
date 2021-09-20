# PyBLP on drug data.  

import pyblp 
import pandas as pd 
import numpy as np
    # "_no_outside" does not have an outside option, so shares sum to much less than 1.
product_data = pd.read_csv("./pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("./py_blp_demographics.csv")


# try the plain vanilla logit formulation first.  
    # product_data has the demand instruments

logit_f = pyblp.Formulation('prices', absorb='C(ndc_code)')
logit_p = pyblp.Problem(logit_f, product_data)
logit_r = logit_p.solve()
        # add package size
logit_f2 = pyblp.Formulation('prices + package')
logit_p2 = pyblp.Problem(logit_f2, product_data)
logit_r2 = logit_p2.solve()
        # active ingredient.  
logit_f3 = pyblp.Formulation('prices + ingred')
logit_p3 = pyblp.Problem(logit_f3, product_data)
logit_r3 = logit_p3.solve()
        # package, active ingredient
logit_f4 = pyblp.Formulation('prices + ingred + package')
logit_p4 = pyblp.Problem(logit_f4, product_data)
logit_r4 = logit_p4.solve()

# Random coefficients formulation ... 
    # could put package in non random coeff.
    # adding a 1 to X1 formulation "works" but no SEs
    # having just prices + package w/ NDC fe's gives no SEs
X1_formulation = pyblp.Formulation('1 + prices + mme + package')
X2_formulation = pyblp.Formulation('0 + prices + mme + package')


    # MC integration
product_formulations = (X1_formulation, X2_formulation) 
mc_integration = pyblp.Integration('monte_carlo', size=500, specification_options={'seed': 0})
mc_problem = pyblp.Problem(product_formulations, product_data, integration=mc_integration)
bfgs = pyblp.Optimization('bfgs', {'gtol': 1e-8})
iteration_options = pyblp.Iteration(method='squarem', method_options={'max_evaluations': 10000})

with pyblp.parallel(10):
    results1 = mc_problem.solve(sigma=np.eye(3), optimization=bfgs, iteration=iteration_options)



   # exact integration
#pr_integration = pyblp.Integration('product', size=5)
#pr_problem = pyblp.Problem(product_formulations, product_data, integration=pr_integration)
#pr_problem.solve(sigma=np.eye(3), optimization=bfgs)
