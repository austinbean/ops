# production


import pyblp
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

product_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/pyblp_test_no_outside.csv")
consumer_data = pd.read_csv("/Users/austinbean/Desktop/programs/opioids/py_blp_demographics.csv")


X1_formulation = pyblp.Formulation('0 + prices', absorb='C(ndc_code)')   # linear
X2_formulation = pyblp.Formulation('1 + prices + mme + package')         # non-linear
X3_formulation = pyblp.Formulation('1 + mme + package')                  # supply-side
product_formulations = (X1_formulation, X2_formulation, X3_formulation)
agent_formulation = pyblp.Formulation('0 + male + hhinc + unemp')
supply_problem = pyblp.Problem(product_formulations, product_data, agent_formulation, consumer_data)
bfgs = pyblp.Optimization('bfgs', {'gtol': 1e-4})
intial_sigma = np.eye(4)
initial_pi = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1], [1, 0, 0]])
results = supply_problem.solve(sigma=initial_sigma,pi=initial_pi, costs_bounds=(0.001, None), optimization=bfgs)
