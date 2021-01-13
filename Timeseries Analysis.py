import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


owid_url = 'https://covid.ourworldindata.org/data/owid-covid-data.csv'
owid_df = pd.read_csv(owid_url)[['location', 'population', 'date', 
                                 'stringency_index', 'new_cases_smoothed_per_million', 
                                 'reproduction_rate', 'total_deaths_per_million']]

print(owid_df['population'].describe())
high_pop_df = owid_df[owid_df.population >= 2500000]

cases = high_pop_df.pivot(index="date", columns="location", values="new_cases_smoothed_per_million")
reproduction_rate = high_pop_df.pivot(index="date", columns="location", values="reproduction_rate")
stringency = high_pop_df.pivot(index="date", columns="location", values="stringency_index")
high_pop_df['total_deaths_per_million'] = high_pop_df.groupby('location')['total_deaths_per_million'].transform('max')
deaths = high_pop_df[['location', 'total_deaths_per_million']].drop_duplicates()


countries = []

for country, deaths in zip(deaths['location'], deaths['total_deaths_per_million']):
    case_responsiveness = max([stringency[country].corr(cases[country].shift(i)) for i in range(-14, 1)])
    case_effectiveness = min([stringency[country].corr(cases[country].shift(i)) for i in range(1, 15)])
    
    rate_responsiveness = max([stringency[country].corr(reproduction_rate[country].shift(i)) for i in range(-14, 1)])
    rate_effectiveness = min([stringency[country].corr(reproduction_rate[country].shift(i)) for i in range(1, 15)])
    row_dict = {'country': country,
                'death_rate': deaths,
                'case_response': case_responsiveness,
                'case_effect': case_effectiveness,
                'rate_response': rate_responsiveness,
                'rate_effect': rate_effectiveness}
    countries.append(row_dict)

df = pd.DataFrame(countries)
sns.pairplot(df)
plt.show()
