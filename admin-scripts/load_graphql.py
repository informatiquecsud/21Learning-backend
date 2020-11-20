from gql import gql

def filegql(query):
    with open(f"graphql/{query}.graphql") as fd:
        return gql(fd.read())