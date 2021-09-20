
import pyblp
import pandas as pd
import numpy as np 
import matplotlib.pyplot as plt

# "_no_outside" does not have an outside option, so shares sum to much less than 1.
product_data = pd.read_csv("./pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("./py_blp_demographics.csv")


X1_formulation = pyblp.Formulation('0 + prices', absorb = 'C(ndc_code)') # linear
X2_formulation = pyblp.Formulation('1 + prices + mme + package')         # non-linear
product_formulations = (X1_formulation, X2_formulation)
agent_formulation = pyblp.Formulation('0 + male + hhinc + unemp')
demo_problem = pyblp.Problem(product_formulations, product_data, agent_formulation, consumer_data)
bfgs = pyblp.Optimization('bfgs', {'gtol': 1e-12})
iteration_options = pyblp.Iteration(method='squarem', method_options={'max_evaluations': 50000})

initial_sigma = np.eye(4)  
initial_pi = np.array([[1, 0, 0], [0,1,0], [0,0,1], [1, 0, 0] ])
with pyblp.parallel(10):
    results2 = demo_problem.solve(sigma=initial_sigma, pi=initial_pi, optimization=bfgs, iteration=iteration_options)

# sigma params are all estimated to be zero.

elasticities = results2.compute_elasticities()
diversions = results2.compute_diversion_ratios()
