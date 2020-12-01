import json


with open('factbook.json', errors='replace') as f:
    factbook = json.load(f)


def count_diseases(disease_dict):
    count = 0
    for key in disease_dict.keys():
        if type(disease_dict[key]) == list:
            count += len(disease_dict[key])
    return count


def recurse_keys(input_dict, path):
    try:
        key_list = list(input_dict.keys())
        for key in key_list:
            if key == 'note':
                pass
            new_path = f'{path}, {key}'
            if type(input_dict[key]) != dict:
                if 'purchasing_power_parity' in path or 'public_debt' in path or 'unemployment_rate' in path:
                    if key == 'annual_values':
                        input_dict[key] = input_dict[key][0]
            if 'major_infectious_diseases' == key:
                #print(key, new_path)
                count = count_diseases(input_dict[key])
                input_dict[key]['count'] = count
                if input_dict[key]['degree_of_risk'] == 'intermediate':
                    input_dict[key]['degree_of_risk'] = 1
                elif input_dict[key]['degree_of_risk'] == 'high':
                    input_dict[key]['degree_of_risk'] = 2
                elif input_dict[key]['degree_of_risk'] == 'very high':
                    input_dict[key]['degree_of_risk'] = 3
                else:
                    input_dict[key]['degree_of_risk'] = 0

            recurse_keys(input_dict[key], new_path)
    except:
        pass


recurse_keys(factbook, '')
with open('clean_factbook.json', 'w') as f:
    json.dump(factbook, f)
