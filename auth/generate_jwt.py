import jwt
from time import time
from random import randint

random_key = ''.join([chr(randint(65, 120)) for _ in range(64)])


payload = {
    "sub": "1234567890",
    "name": "Cédric Donner",
    "admin": True,
    "iat": time() + 365 * 24 * 3600,
    "https://hasura.io/jwt/claims": {
        "x-hasura-allowed-roles": [
            "teacher-1gy5",
            "teacher-1gy7",
            "teacher-1gy8",
            "teacher-1gy11",
            "teacher-1ecg7",
            "student",
            "admin"
        ],
        "x-hasura-default-role": "user",
        "x-hasura-user-id": "156",
        "x-hasura-org-id": "1"
    }
}
encoded_jwt = jwt.encode(payload, 'secret', algorithm='HS512')

print('generated secret key:', random_key)
print('generated token:', encoded_jwt)
