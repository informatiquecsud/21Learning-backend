import click
import os
from collections import namedtuple


from gql import Client, AIOHTTPTransport


class Config(object):
    def __init__(self):
        self.verbose = False

    def __str__(self):
        return '\n'.join([f"{var}={value}" for var, value in vars(self).items()])


pass_config = click.make_pass_decorator(Config, ensure=True)


def get_env(vars):
    env = {}
    for var in vars:
        if var not in os.environ:
            click.echo(f"{var} not defined", err=True)
            exit(1)
        env[var] = os.environ.get(var) or ()

    env["HASURA_API_URL"] = f"https://api.{env['RUNESTONE_HOST']}/v1/graphql"

    return env

def env2config(env):
    return namedtuple("Env", env.keys())(*env.values())


def api(url, headers):
    # Select your transport with a defined url endpoint
    transport = AIOHTTPTransport(url=url, headers=headers)

    # Create a GraphQL client using the defined transport
    client = Client(transport=transport, fetch_schema_from_transport=True)
    return client

def create_client(config):
    api_client = api(url=config.HASURA_API_URL, headers={
        'x-hasura-admin-secret': config.HASURA_ADMIN_SECRET_KEY
    })

    return api_client


@click.group(chain=True)
@click.option("--verbose", is_flag=True, help="More verbose output")
@pass_config
@click.pass_context
def cli(ctx, config, verbose):
    env = get_env([
        "HASURA_ADMIN_SECRET_KEY",
        "RUNESTONE_HOST"
    ])
    config.verbose = verbose

    config.HASURA_API_URL = env['HASURA_API_URL']
    config.RUNESTONE_HOST = env['RUNESTONE_HOST']
    config.HASURA_ADMIN_SECRET_KEY = env['HASURA_ADMIN_SECRET_KEY']