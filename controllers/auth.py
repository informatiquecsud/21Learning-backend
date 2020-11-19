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
    
    #del payload["user"]
    #del payload["user_groups"]
    payload['user'] = {
        'id': user_id
    }
    
    payload['https://21-learning.com/jwt/claims']['x-hasura-user-id'] = str(user_id)
    return payload


secret_key = os.environ.get('RUNESTONE_AUTH_JWT_KEY', "WnpAGcjSNKJXaKaGUhmnJLmweCllXKtqTCZrreRwnmHTsJIEHMUhYYRgcMuBVmCN")
validity = 60 * 60 * 24
myjwt = AuthJWT(
    auth,
    secret_key=secret_key,
    user_param='username',
    pass_param='password',
    algorithm='HS512',
    refresh_expiration_delta=validity,
    expiration=validity,
    additional_payload=transform_payload_to_hasura,
    
)



def login():
    # set CORS headers to allow authentication from other domains
    # TODO: should restrict to *.21-learning.com
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Max-Age'] = 86400
    response.headers['Access-Control-Allow-Headers'] = '*'
    response.headers['Access-Control-Allow-Methods'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    return myjwt.jwt_token_manager()
