from random import choice


def generate_random_password(length=8, chars='0123456789'):
    return ''.join([choice(chars) for _ in range(length)])


def dict_project(dictionary, fields):
    return {k: v for (k, v) in dictionary.items() if k in fields}

def exec_with_fields(client, query, data, variables):
    return client.execute(query, variable_values=dict_project(data, variables))