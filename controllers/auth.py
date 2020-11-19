# -*- coding: utf-8 -*-
import json
import os
import requests
from six.moves.urllib.parse import unquote
from six.moves.urllib.error import HTTPError
import logging

from gluon.restricted import RestrictedError
from gluon.tools import AuthJWT

logger = logging.getLogger(settings.logger)
logger.setLevel(settings.log_level)

def transform_payload_to_hasura(payload):
    user_id = payload['user']['id']
    user_groups = payload['user_groups']
    allowed_roles = ["student"]
    default_role = 'student'
    for (key, value) in user_groups.items():
        if value == 'instructor':
            role = 'teacher'
            default_role = 'teacher'
        allowed_roles += [role]
    
    payload["https://21-learning.com/jwt/claims"] = {
        "x-hasura-allowed-roles": allowed_roles,
        "x-hasura-default-role": default_role,
        "x-hasura-org-id": "1"
    }
    
    del payload["user"]
    del payload["user_groups"]
    
    
    payload['https://21-learning.com/jwt/claims']['x-hasura-user-id'] = str(user_id)
    return payload

secret_key = os.environ.get('RUNESTONE_AUTH_JWT_KEY', "WnpAGcjSNKJXaKaGUhmnJLmweCllXKtqTCZrreRwnmHTsJIEHMUhYYRgcMuBVmCN")
myjwt = AuthJWT(
    auth,
    secret_key=secret_key,
    user_param='username',
    pass_param='password',
    algorithm='HS512',
    expiration=60 * 60 * 24,
    additional_payload=transform_payload_to_hasura
)



def login():
    return myjwt.jwt_token_manager()