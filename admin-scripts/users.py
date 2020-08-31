import click
from gql import gql
from gql.transport.exceptions import TransportQueryError

from load_graphql import filegql

from utils import generate_random_password, exec_with_fields


def map_fields_to_userinfo(student):
    ''' maps csv fields to a user dictionary '''
    userinfo = {}
    userinfo['email'] = student['E-Mail']
    if userinfo['email'] == '':
        raise ValueError(f"User {student} has empty email")

    userinfo['username'] = student['E-Mail'].split('@')[0]
    userinfo['first_name'] = student['Prénom']
    userinfo['last_name'] = student['Nom']

    return userinfo


def get_user_by_email(client, email):
    res = client.execute(gql('''
        query getUserByEmail($email: String!) {
            auth_user(where: {email: {_eq: $email}}) {
                id
                username
                last_name
                first_name
                course_name
                email
            }
        }'''), variable_values={
        'email': email
    })
    try:
        return res['auth_user'][0]
    except Exception as e:
        return None


def get_user_by_userinfo(client, userinfo):
    res = exec_with_fields(client, filegql('getUserByUserinfo'), userinfo, [
        'username',
        'first_name',
        'last_name',
        'email',
        'id'
    ])
    try:
        return res['user'][0]
    except Exception as e:
        click.echo(f"Unable to find user with userinfo: {userinfo}. Reason: {str(e)}. Result of query: {res}", err=True)
        return None


def create_user_helper(client, userinfo):
    res = exec_with_fields(client, filegql('createUser'), userinfo, [
        'username',
        'password',
        'first_name',
        'last_name',
        'email',
        'course_name'
    ])
    return res['insert_auth_user_one']


def remove_user_by_userinfo(client, userinfo):
    res = exec_with_fields(client, filegql('removeUserByUserinfo'), userinfo, [
        'username',
        'password',
        'first_name',
        'last_name',
        'email',
        'course_name'
    ])
    
    return res

def add_user_to_course(client, course_id, userinfo):
    try:
        res = client.execute(filegql('addUserToCourse'), variable_values={
            'userId': userinfo['id'],
            'courseId': course_id
        })

        print(res)

        return res['insert_user_courses_one']
    except TransportQueryError as e:
        click.echo(f"Unable to add user {userinfo} to course with id={course_id}: {str(e)}")
        

def remove_student_from_course(client, courseinfo, userinfo):
    pass


def findUsers(client, userinfo):
    res = client.execute(
        filegql('findMatchingUser'), 
        variable_values={
            'username': f"%{userinfo['username']}%",
            'emailPattern': f"%{userinfo['email']}%",
            'firstName': f"%{userinfo['first_name']}%",
            'lastName': f"%{userinfo['last_name']}%",
        }
    )

    try:
        users = res['auth_user']
    except Exception as e:
        users = []

    return users