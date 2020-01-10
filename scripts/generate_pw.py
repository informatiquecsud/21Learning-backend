
from random import randint
import sys


def generate_pw(length=5):
    return ''.join([chr(65 + randint(0, 25)) for _ in range(length)])


def main():
    filename = sys.argv[1]
    with open(filename, 'r', encoding='utf-8') as account_csv:
        for line in account_csv:
            username, group, password = line.split(';')
            print(
                f'rsmanage resetpw --username {username} --password {generate_pw()} --group {group}')


main()
