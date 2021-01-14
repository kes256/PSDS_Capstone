import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from statsmodels.regression.linear_model import OLS

cia_df = pd.read_csv('../data/factbook.csv')
owid_url = 'https://covid.ourworldindata.org/data/owid-covid-data.csv'
owid_df = pd.read_csv(owid_url)[['iso_code', 'human_development_index', 'total_cases_per_million']]
owid_df['total_cases_per_million'] = owid_df.groupby('iso_code')['total_cases_per_million'].transform('max')
owid_df.drop_duplicates(inplace=True)
owid_cia_df = pd.merge(owid_df, cia_df, left_on='iso_code', right_on='code')

for col in owid_cia_df.columns:
    print(col)

index = ['human_development_index']
demographics = ['data.people.population.total',
                'data.people.age_structure.0_to_14.percent',
                'data.people.age_structure.15_to_24.percent',
                'data.people.age_structure.25_to_54.percent',
                'data.people.age_structure.55_to_64.percent',
                'data.people.age_structure.65_and_over.percent',
                'data.people.median_age.total.value',
                'data.people.death_rate.deaths_per_1000_population',
                'data.people.urbanization.urban_population.value']
infrastructure = ['data.energy.electricity.access.total_electrification.value',
                  'data.energy.electricity.installed_generating_capacity.kW',
                  'data.energy.refined_petroleum_products.consumption.bbl_per_day',
                  'data.energy.natural_gas.consumption.cubic_metres',
                  'data.energy.carbon_dioxide_emissions_from_consumption_of_energy.megatonnes',
                  'data.communications.internet.users.percent_of_population']
health = ['data.people.drinking_water_source.improved.total.value',
          'data.people.sanitation_facility_access.improved.total.value',
          'data.people.major_infectious_diseases.count',
          'data.people.physicians_density.physicians_per_1000_population',
          'data.people.hospital_bed_density.beds_per_1000_population',
          'data.people.major_infectious_diseases.degree_of_risk',
          'data.people.adult_obesity.percent_of_adults',
          'data.people.infant_mortality_rate.total.value',
          'data.people.life_expectancy_at_birth.total_population.value',
          'data.people.total_fertility_rate.children_born_per_woman']
education = ['data.people.literacy.total_population.value',
             'data.people.school_life_expectancy.total.value',
             'data.people.education_expenditures.percent_of_gdp',
             'data.communications.internet.users.percent_of_population']
economy = ['data.economy.gdp.purchasing_power_parity.annual_values.value',
           'data.economy.gdp.composition.by_sector_of_origin.sectors.agriculture.value',
           'data.economy.gdp.composition.by_sector_of_origin.sectors.industry.value',
           'data.economy.gdp.composition.by_sector_of_origin.sectors.services.value',
           'data.economy.unemployment_rate.annual_values.value',
           'data.economy.public_debt.annual_values.value',
           'data.people.net_migration_rate.migrants_per_1000_population',
           'data.economy.population_below_poverty_line.value']
areas = [demographics, infrastructure, health, education, economy]

index_correlations = []
for area in areas:
    for field in area:
        correlation = owid_cia_df[field].corr(owid_cia_df['total_cases_per_million'])
        index_correlations.append((field, correlation ** 2))

index_correlations = sorted(index_correlations, key=lambda x: x[1], reverse=True)[1:]
for pair in index_correlations:
    print(pair)
print(f'no field analysed from the World Factbook has significant correlation with the maximum reported cases/million')

index_correlations = []
for area in areas:
    for field in area:
        correlation = owid_cia_df[field].corr(owid_cia_df[index[0]])
        index_correlations.append((field, correlation ** 2))

index_correlations = sorted(index_correlations, key=lambda x: x[1], reverse=True)[1:]
for pair in index_correlations:
    print(pair)

variables = [field for field, corr in index_correlations if corr >= 0.7]
index_predictor_df = owid_cia_df[index + variables].dropna()
index_df = index_predictor_df[index[0]] * 100
result = OLS(index_df, index_predictor_df[variables]).fit()
print(f'summary of OLS predicting Human Development Index from CIA World Factbook features with R^2 > 0.7:')
print(result.summary())

predicted_index = result.predict(index_predictor_df[variables])
percent_error = abs((index_df - predicted_index) / index_df)
sns.scatterplot(x=predicted_index, y=index_df)
print(max(percent_error), np.mean(percent_error))

print(f'summary of OLS predicting Human Development Index from subset of CIA World Factbook features with R^2 > 0.7:')
print(f'subset chosen based on previous OLS - only those with coefficient ~10x greater than the standard error for that coefficient were kept')
variables = ['data.communications.internet.users.percent_of_population',
             'data.people.school_life_expectancy.total.value',
             'data.people.life_expectancy_at_birth.total_population.value',
             'data.people.literacy.total_population.value']
index_predictor_df = owid_cia_df[index + variables].dropna()
index_df = index_predictor_df[index[0]] * 100
result = OLS(index_df, index_predictor_df[variables]).fit()
result.summary()

predicted_index = result.predict(index_predictor_df[variables])
percent_error = abs((index_df - predicted_index) / index_df)
sns.scatterplot(x=predicted_index, y=index_df)
print(max(percent_error), np.mean(percent_error))

variables = ['human_development_index', 'data.communications.internet.users.percent_of_population']
df = owid_cia_df[variables].dropna()
sns.scatterplot(x=df['data.communications.internet.users.percent_of_population'], y=df['human_development_index'])
plt.show()
