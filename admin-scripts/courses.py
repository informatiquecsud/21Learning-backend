import click
from gql import gql

from common import *
from load_graphql import filegql
from utils import *


def commit_create_course(client, course):
    # TODO: check that course doesn't exist yet (put CHECK constraint into DB)
    pass


def get_course_id_by_name(client, course_name):
    ''' returns the id of the course or None if the course doesn't exist '''
    res = client.execute(gql('''
        query getCourseByName($courseName: String!) {
            course: courses(where: {course_name: {_eq: $courseName}}) {
                id
            }
        }
        '''), variable_values={
        'courseName': course_name
    })

    try:
        course_id = res['course'][0]['id']
        return course_id
    except Exception as e:
        return None


def get_child_courses(client, course_name):
    ''' checks if course `course_name` is a base course for some other course '''

    res = client.execute(filegql('getChildCourses'),
                         variable_values={"courseName": course_name})
    try:
        course = res['courses'][0]
    except Exception as e:
        click.echo("Course does not exist", err=True)
    return course['child_courses']


def commit_remove_course(client, course_name):
    ''' remove course from database '''
    res = client.execute(filegql('removeCourse'), variable_values={
        'courseName': course_name
    })

    nb_affected_rows = res['delete_courses']['affected_rows']
    if nb_affected_rows > 0:
        click.echo("Course deleted successfully")
    elif nb_affected_rows == 0:
        click.echo(f"Unable to remove course '{course_name}'", err=True)

    return nb_affected_rows


def course_ls_students(client, courseinfo):
    ''' get the list of students enrolled in a course or [] if there is non '''
    res = exec_with_fields(client, filegql('getCourseStudents'),
                           courseinfo, ['coursename', 'courseId'])
    try:
        user_courses = res['courses'][0]['user_courses']
        users = [uc['auth_user'] for uc in user_courses]
        return users
    except:
        click.echo(f"Unable to get student list of course {courseinfo}")
        return None


def list_all_base_courses(client):
    try:
        res = client.execute(gql('''
            query {
            courses {
                course_name
                base_course
            }
            }
        '''))

        return [c for c in res['courses'] if c['course_name'] == c['base_course']]
    except Exception as e:
        return []


def all_base_courses(ctx, args, incomplete):
    
    # config = env2config(os.environ)
    # client = create_client(config)
    # return list_all_base_courses(client)
    courses = [c for c in os.environ.get('COURSES', '').split(' ') if incomplete in c]
    return courses