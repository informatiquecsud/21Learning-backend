from random import choice

charsets = {
    'digits': '0123456789',
    'lower': 'qwertzuiopasdfghjklyxcvbnm',
    'upper': 'QWERTZUIOPASDFGHJKLYXCVBNM',
    'letters': 'QWERTZUIOPASDFGHJKLYXCVBNMqwertzuiopasdfghjklyxcvbnm',
    'special': 'QWERTZUIOPASDFGHJKLYXCVBNMqwertzuiopasdfghjklyxcvbnm1234567890?!_.$%*"+=)(/',
}

def generate_random_password(length=8, alphabet='digits'):
    return ''.join([choice(charsets[alphabet]) for _ in range(length)])


def dict_project(dictionary, fields):
    return {k: v for (k, v) in dictionary.items() if k in fields}

def exec_with_fields(client, query, data, variables=None, fake=False):
    if variables is None:
        variables = data.keys()
    if fake:
        print(query, data, variables)
    return client.execute(query, variable_values=dict_project(data, variables))