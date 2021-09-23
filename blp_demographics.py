
import pyblp
import pandas as pd
import numpy as np 


# "_no_outside" does not have an outside option, so shares sum to much less than 1.
product_data = pd.read_csv("./pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("./py_blp_demographics.csv")


X1_formulation = pyblp.Formulation('0 + prices', absorb = 'C(ndc_code)') # linear
X2_formulation = pyblp.Formulation('1 + prices + mme + package')         # non-linear
product_formulations = (X1_formulation, X2_formulation)
agent_formulation = pyblp.Formulation('0 + male + hhinc + unemp + education + labor')        # options: male, race, disability, hhinc, education, labor, unemp
demo_problem = pyblp.Problem(product_formulations, product_data, agent_formulation, consumer_data)
bfgs = pyblp.Optimization('l-bfgs-b', {'gtol': 1e-14})
iteration_options = pyblp.Iteration(method='squarem', method_options={'max_evaluations': 200000})

initial_sigma = np.eye(4) 
sigma_lower = (-3)*np.eye(4)
sigma_upper = 3*np.eye(4)
initial_pi = np.array([[1, 0, 0,0,0], [0,1,1,1,0], [0,1,1,0,0], [1,0,0,0,1] ])
with pyblp.parallel(10):
    results2 = demo_problem.solve(sigma=initial_sigma, sigma_bounds=(sigma_lower, sigma_upper), pi=initial_pi, optimization=bfgs, iteration=iteration_options)


elasticities = results2.compute_elasticities()
diversions = results2.compute_diversion_ratios()
