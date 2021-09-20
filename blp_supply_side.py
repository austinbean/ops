# production
# Takes about 2 hours at a very loose tolerance.  Optimization does not converge
# in step 1.
    # iteration_options = pyblp.Iterations(method='squarem', method_options={max_evaluations:10000})

import pyblp
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

product_data = pd.read_csv("./pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("./py_blp_demographics.csv")


X1_formulation = pyblp.Formulation('1 + mme')                            # linear / taking prices out of this line
X2_formulation = pyblp.Formulation('1 + prices + mme + package')         # non-linear
X3_formulation = pyblp.Formulation('1 + mme + package')                  # supply-side
product_formulations = (X1_formulation, X2_formulation, X3_formulation)
agent_formulation = pyblp.Formulation('0 + male + hhinc')  # + unemp
supply_problem = pyblp.Problem(product_formulations, product_data, agent_formulation, consumer_data)
bfgs = pyblp.Optimization('bfgs', {'gtol': 1e-8})
initial_sigma = np.eye(4)        # length X2 
initial_pi = np.random.rand(4,2) # length X2 x length agent_formulation
iteration_options = pyblp.Iteration(method='squarem', method_options={'max_evaluations': 50000})
with pyblp.parallel(10):
    results = supply_problem.solve(sigma=initial_sigma,pi=initial_pi, costs_bounds=(0.001, None), optimization=bfgs, iteration=iteration_options)

costs = results.compute_costs()
markups = results.compute_markups(costs=costs)

# Merger sim
hhi = results.compute_hhi()
profits = results.compute_profits(costs=costs)
cs = results.compute_consumer_surpluses()

product_data['merger_ids'] = '78' # suppose merge to monopoly.  

changed_prices = results.compute_approximate_prices(firm_ids=product_data['merger_ids'],costs=costs)

changed_shares = results.compute_shares(changed_prices)
