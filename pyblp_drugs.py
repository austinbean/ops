# PyBLP on drug data.  

import pyblp 
import pandas as pd 
import numpy as np
    # "_no_outside" does not have an outside option, so shares sum to much less than 1.
product_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/py_blp_demographics.csv")



# Random coefficients formulation ... 
X1_formulation = pyblp.Formulation('1 + prices')
X2_formulation = pyblp.Formulation('1 + mme + package')
product_formulations = (X1_formulation, X2_formulation)
mc_integration = pyblp.Integration('monte_carlo', size=50, specification_options={'seed': 0})
mc_problem = pyblp.Problem(product_formulations, product_data, integration=mc_integration)
bfgs = pyblp.Optimization('bfgs', {'gtol': 1e-4})
results1 = mc_problem.solve(sigma=np.ones((3, 3)), optimization=bfgs)


agent_formulation = pyblp.Formulation('0 + male + hhinc + unemp')
demo_problem = pyblp.Problem(product_formulations, product_data, agent_formulation, consumer_data)
results2 = mc_problem.solve(sigma = np.eye(3), optimization=bfgs)