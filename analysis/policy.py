"""
Analysis of government policies, risk assessment, and death rates

Citations:
https://www.bsg.ox.ac.uk/research/research-projects/coronavirus-government-response-tracker
National Policy data:
Thomas Hale, Sam Webster, Anna Petherick, Toby Phillips, and Beatriz Kira. (2020).
Oxford COVID-19 Government Response Tracker. Blavatnik School of Government.

Risk of Openness Index:
Thomas Hale, Toby Phillips, Anna Petherick, Beatriz Kira, Noam Angrist, Katy Aymar, Sam Webster, Saptarshi Majumdar,
Laura Hallas, Helen Tatlow, Emily Cameron-Blake (2020).
Risk of Openness index: When do government responses need to be increased or maintained? Blavatnik School of Government.
"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import plotly_express as px
import seaborn as sns
from datetime import timedelta

policy = pd.read_csv('../data/OxCGRT_08Jan2021.csv')
policy.loc[policy["RegionCode"].isnull(), 'RegionCode'] = policy["CountryCode"]
policy.loc[policy["RegionName"].isnull(), 'RegionName'] = policy["CountryName"]

risk = pd.read_csv('../data/riskindex_timeseries_08Jan2021.csv')
policy['Date'] = pd.to_datetime(policy['Date'], format='%Y%m%d')
risk['Date'] = pd.to_datetime(risk['Date'], yearfirst=True)

one_step = timedelta(days=1)
policy['prev_day'] = policy['Date'] - one_step
diffs = pd.merge(policy, policy, left_on=['RegionCode', 'prev_day'], right_on=['RegionCode', 'Date'], suffixes=[None, '_prev'])
diffs['NewDeaths'] = diffs['ConfirmedDeaths'] - diffs['ConfirmedDeaths_prev']
diffs['NewCases'] = diffs['ConfirmedCases'] - diffs['ConfirmedCases_prev']
policy = pd.merge(diffs[['RegionCode', 'Date', 'NewDeaths', 'NewCases']], policy, on=['RegionCode', 'Date'])
policy.loc[policy["NewDeaths"].isnull(), 'NewDeaths'] = policy["ConfirmedDeaths"]
policy.loc[policy["NewCases"].isnull(), 'NewCases'] = policy["ConfirmedCases"]
policy["NewDeaths_log"] = policy["NewDeaths"].apply(lambda x: np.log(max(x, 0.1)))
policy["NewCases_log"] = policy["NewCases"].apply(lambda x: np.log(max(x, 0.1)))

percent_change = pd.merge(policy, policy, left_on=['RegionCode', 'prev_day'], right_on=['RegionCode', 'Date'], suffixes=[None, '_prev'])
percent_change['NewDeathsPercentChange'] = percent_change['NewDeaths'] / percent_change['NewDeaths_prev']
percent_change['NewCasesPercentChange'] = percent_change['NewCases'] / percent_change['NewCases_prev']
policy = pd.merge(percent_change[['RegionCode', 'Date', 'NewDeathsPercentChange', 'NewCasesPercentChange']], policy, on=['RegionCode', 'Date'])
policy = policy.drop(['prev_day'], axis=1)

policy = policy[policy.groupby('RegionCode')['NewCases'].cumsum() > 30]
policy.dropna(subset=['NewDeaths', 'NewCases'], inplace=True)
all_data = pd.merge(policy, risk, how='left', on=['CountryCode', 'Date'])
washington_data = all_data[all_data['RegionName'] == 'Washington']
#washington_policy.plot()
#plt.show()
#print(policy.columns)
policy_indices = policy[['CountryName', 'CountryCode', 'RegionName', 'RegionCode', 'Jurisdiction', 'Date',
                         'ConfirmedCases', 'ConfirmedDeaths', 'StringencyIndexForDisplay',
                         'GovernmentResponseIndexForDisplay', 'ContainmentHealthIndexForDisplay',
                         'EconomicSupportIndexForDisplay']]

#print(risk.columns)
#sns.pairplot(all_data,
#             x_vars=['NewCases_log', 'NewDeaths_log'],
#             y_vars=['ContainmentHealthIndexForDisplay',
#                     'EconomicSupportIndexForDisplay', 'openness_risk'])
sns.pairplot(all_data,
             x_vars=['NewCasesPercentChange', 'NewDeathsPercentChange', 'cases_controlled'],
             y_vars=['ContainmentHealthIndexForDisplay', 'EconomicSupportIndexForDisplay',
                     'openness_risk'],
             kind='kde')
#washington_data[['NewDeaths']].plot()
#sns.histplot(all_data[all_data['cases_controlled'] < 1], x='cases_controlled', y='ContainmentHealthIndexForDisplay')
plt.show()

