# PyBLP on drug data.  

import pyblp 
import pandas as pd 
import numpy as np
    # "_no_outside" does not have an outside option, so shares sum to much less than 1.
product_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/py_blp_demographics.csv")


# TODO - 
# 1 higher number of iterations on delta    
# 2 parallel over markets  

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
bfgs = pyblp.Optimization('bfgs', {'gtol': 1e-4})
iteration_options = pyblp.Iteration(method='squarem', method_options={'max_evaluations': 10000})

    # skip solving this for the moment.  
with pyblp.parallel(4):
    results1 = mc_problem.solve(sigma=np.eye(3), optimization=bfgs, iteration=iteration_options)

'''
Nonlinear Coefficient Estimates (Robust SEs in Parentheses):
==========================================================
Sigma:       prices             mme            package    
-------  ---------------  ---------------  ---------------
prices    +6.702476E-02                                   
         (+7.480505E-03)                                  
                                                          
  mme     +0.000000E+00    -4.280262E-05                  
                          (+6.031130E-01)                 
                                                          
package   +0.000000E+00    +0.000000E+00    +8.869733E-01 
                                           (+3.711029E-02)
==========================================================

Beta Estimates (Robust SEs in Parentheses):
==================================================================
       1             prices             mme            package    
---------------  ---------------  ---------------  ---------------
 -3.106047E+00    -3.853283E-02    +1.084368E-02    +1.234579E+00 
(+9.386053E-02)  (+7.435396E-03)  (+3.724808E-03)  (+2.105925E-02)
==================================================================
'''


    # iteration:   NOT USED YET.  Maybe not needed...
    # TODO - adjusting delta iterations bound 
    # TODO - parallelize  
    # iteration = pyblp.Iteration('squarem', {'norm': np.linalg.norm, 'scheme': 1})


   # exact integration
#pr_integration = pyblp.Integration('product', size=5)
#pr_problem = pyblp.Problem(product_formulations, product_data, integration=pr_integration)
#pr_problem.solve(sigma=np.eye(3), optimization=bfgs)
