import sys
import csv

from random import choice


def create_password(length=5):
    alphabet = 'QWERTZUIOPASDFGHJKLYXCVBNM'
    passwd = ''.join([choice(alphabet) for _ in range(length)])
    return passwd


if len(sys.argv) != 3:
    print("Usage: ", sys.argv[0], 'csvfilename', 'coursename')
    exit(1)

filename = sys.argv[1]
coursename = sys.argv[2]

created_users = []


with open(filename, 'r', newline='', encoding='utf-8') as csvfile:
    reader = csv.reader(csvfile, delimiter=';')
    header = csvfile.readline()
    for last_name, first_name, email, username, group in reader:
        passwd = create_password()
        print("INSERT INTO auth_user (last_name, first_name, email, username, registration_key, created_on) VALUES ({});".format(
            (', '.join(["'{}'"] * 5) + ', now()').format(
                last_name, first_name, email, username, passwd
            )
        ))

        sql = '''INSERT INTO user_courses (user_id, course_id)
            SELECT auth_user.id, courses.id
            FROM auth_user
            LEFT JOIN courses ON courses.course_name = '{course_name}'
            WHERE auth_user.username = '{user_name}'; '''.format(
            course_name=coursename,
            user_name=username
        )

        print(sql)

        sql = '''
            UPDATE auth_user SET request_resetpw = '{new_passwd}' WHERE username='{username}';
        '''.format(new_passwd=passwd, username=username)
        print(sql)

        created_users.append({
            'Nom': last_name,
            'Prénom': first_name,
            'User': username,
            'Mot de passe initial': passwd
        })

        passwd_filename = filename.split('.')[0] + '.passwords.csv'
        with open(passwd_filename, 'w', encoding='utf-8') as passwordfile:
            if len(created_users) > 0:
                fieldnames = created_users[0].keys()
            writer = csv.DictWriter(passwordfile, fieldnames=fieldnames, delimiter=';')
            writer.writeheader()
            writer.writerows(created_users)
