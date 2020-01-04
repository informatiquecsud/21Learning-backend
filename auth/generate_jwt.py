import jwt
import datetime
from random import randint


def get_random_char():
    code = randint(65, 120)
    while code in range(91, 97):
        code = randint(65, 120)
    return chr(code)


random_key = ''.join([get_random_char() for _ in range(64)])
secret_key = 'WnpAGcjSNKJXaKaGUhmnJLmweCllXKtqTCZrreRwnmHTsJIEHMUhYYRgcMuBVmCN'


payload = {
    "sub": "1234567890",
    "name": "Cédric Donner",
    "admin": True,
    "iat": datetime.datetime.utcnow(),
    "exp": datetime.datetime.utcnow() + datetime.timedelta(seconds=365 * 24 * 3600),
    "https://21-learning.com/jwt/claims": {
        "x-hasura-allowed-roles": [
            "teacher",
            "student",
            "admin"
        ],
        "x-hasura-default-role": "teacher",
        "x-hasura-user-id": "156",
        "x-hasura-org-id": "1"
    }
}
encoded_jwt = jwt.encode(payload, secret_key, algorithm='HS512')

print('generated secret key:', secret_key)
print('generated token:', encoded_jwt)
