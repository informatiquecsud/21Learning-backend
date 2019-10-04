# using SendGrid's Python Library
# https://github.com/sendgrid/sendgrid-python
import os
import sys
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

# read classname from argv
try:
    assert len(sys.argv) == 3
    classname = sys.argv[1]
    int(classname.split('gy')[1])
    sender_email = sys.argv[2]
    assert sender_email.split('@')[1] == 'edufr.ch'
except:
    print('Utilistion: send_passwd.py <level>gy<class:int> <sender_email>')
    sys.exit(1)

# load template
with open('template.html', 'r', encoding='utf-8') as template_file:
    template = template_file.read()


passwd_file = f'passwords-{classname}.csv'
students = []
with open(os.path.join('..', 'data', passwd_file)) as csv_file:
    for line in csv_file:
        fields = [f.strip() for f in line.split(';')]
        students.append(
            {
                'login': fields[0],
                'password': fields[2],
                'email': fields[0] + '@studentfr.ch'
            }
        )

# load students
for student in students:
    print("Sending welcome email to", student['email'])
    message = Mail(
        from_email=sender_email,
        to_emails=student['email'],
        subject='Ton mot de passe pour le site 21Learning',
        html_content=template.format(
            login=student['login'],
            password=student['password'],
            sender='Cédric Donner'
        )
    )

    try:
        sg = SendGridAPIClient(os.environ.get('SENDGRID_API_KEY'))
        response = sg.send(message)
        print(response.status_code)
        print(response.body)
        print(response.headers)
    except Exception as e:
        print(e)
