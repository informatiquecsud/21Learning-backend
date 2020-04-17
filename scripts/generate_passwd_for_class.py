
import sys
from random import choice

filename = sys.argv[1]


def create_password(length=5):
    alphabet = 'QWERTZUIOPASDFGHJKLYXCVBNM'
    passwd = ''.join([choice(alphabet) for _ in range(length)])
    return passwd


with open(filename, 'r', encoding='utf-8') as csvfile:
    headers = csvfile.readline()

    for line in csvfile:
        print(create_password())
