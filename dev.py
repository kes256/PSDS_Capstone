"""
Workspace for exploring data and testing ideas
"""
import json
import pandas as pd
import requests
from io import StringIO

who_url = 'https://covid19.who.int/WHO-COVID-19-global-data.csv'
who_credit = 'WHO coronavirus disease (COVID-19) dashboard. Geneva: World Health Organization, 2020. Available online: https://covid19.who.int/'
owid_url = 'https://covid.ourworldindata.org/data/owid-covid-data.json'
owid_credit = 'Hasell, J., Mathieu, E., Beltekian, D. et al. A cross-country database of COVID-19 testing. Sci Data 7, 345 (2020). https://doi.org/10.1038/s41597-020-00688-8'
cia_factbook_credit = 'CIA World Factbook JSON compiled by Ian Coleman (add links?)'

oxcgrt_url = 'https://covidtrackerapi.bsg.ox.ac.uk/api/v2/stringency/actions/{ALPHA-3}/{YYYY-MM-DD}'

with open('factbook.json', errors='replace') as f:
    s = f.read()
    cia_factbook = json.loads(s)

owid_response = requests.get(owid_url)
owid = json.loads(owid_response.content)

with open('iso_code_to_cia.txt') as f:
    iso_code_lookup = json.load(f)

bad_codes = []
for code in owid.keys():
    try:
        name = iso_code_lookup[code]
    except KeyError:
        bad_codes.append(code)
for code in bad_codes:
    del owid[code]

unit_set = set()


def recurse_keys(input_dict, path, key_set):
    try:
        for key in input_dict.keys():
            if key == 'note':
                pass
            new_path = f'{path}, {key}'
            if type(input_dict[key]) != dict:
                key_set.add(new_path)
                if key == 'units':
                    unit_set.add(f'{path}, {input_dict[key]}')
            recurse_keys(input_dict[key], new_path, key_set)
    except:
        pass
    return key_set

all_keys = set()
country_keys = {}
for key in iso_code_lookup.values():
    country_keys[key] = recurse_keys(cia_factbook['countries'][key], 'countries', set())
    all_keys.update(country_keys[key])
for line in sorted(unit_set):
    print(line)

total = len(country_keys.keys())
order_me = []
for key in all_keys:
    count = 0
    for country, key_set in country_keys.items():
        if key in key_set:
            count += 1
    order_me.append((count/total, f'({count} out of {total}), {key}\n'))

ordered = sorted(order_me, reverse=True)

with open('keys.txt', 'w') as f:
    for a, b in ordered:
        f.write(f'{a} {b}')
