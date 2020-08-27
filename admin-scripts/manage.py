import click
import sys
import csv

from gql import gql, Client, AIOHTTPTransport
from gql.transport.exceptions import TransportQueryError
from load_graphql import filegql

from common import *
from courses import *
from users import *


@cli.command()
@pass_config
def show_config(config):
    click.echo(str(config))


@cli.command()
@pass_config
def get_courses(config):
    query = filegql('get_courses')

    # Execute the query on the transport
    result = config.client.execute(query)
    click.echo(result, color=True)


###################
## add-course
###################

@cli.command()
@click.argument("course-name", type=str)
@pass_config
def remove_course(config, course_name):
    client = create_client(config)

    # TODO: this kind of check should be done with a trigger in the database

    ## check whether this course is a base course for other courses that depend on it
    child_courses = get_child_courses(client, course_name)
    if len(child_courses) > 0:
        click.echo(f"Course '{course_name}'' has child courses. Aborted!", err=True)
        sys.exit(1)

    commit_remove_course(client, course_name)


@cli.command()
@click.argument("course-name", type=str)
@click.option("--basecourse", help="The name of the basecourse", autocompletion=all_base_courses)
@click.option(
    "--start-date", default="2001-01-01", help="Start Date for the course in YYYY-MM-DD"
)
@click.option("--python3", is_flag=True, default=True, help="Use python3 style syntax")
@click.option(
    "--login-required",
    is_flag=True,
    default=True,
    help="Only registered users can access this course?",
)
@click.option("--institution", default="Anonymous", help="Your institution")
@click.option("--language", default="python", help="Default Language for your course")
@click.option("--host", default="runestone.academy", help="runestone server host name")
@click.option(
    "--allow_pairs",
    is_flag=True,
    default=False,
    help="enable experimental pair programming support",
)
@pass_config
def add_course(
    config,
    course_name,
    basecourse,
    start_date,
    python3,
    login_required,
    institution,
    language,
    host,
    allow_pairs,
):
    """Create a course in the database"""

    execute = create_client(config).execute

    done = False
    if course_name:
        use_defaults = True
    else:
        use_defaults = False
    while not done:
        if not course_name:
            course_name = click.prompt("Course Name")
        if not python3 and not use_defaults:
            python3 = (
                "T" if click.confirm("Use Python3 style syntax?", default="T") else "F"
            )
        else:
            python3 = "T" if python3 else "F"
        if not basecourse and not use_defaults:
            basecourse = click.prompt("Base Course")
        if not start_date and not use_defaults:
            start_date = click.prompt("Start Date YYYY-MM-DD")
        if not institution and not use_defaults:
            institution = click.prompt("Your institution")
        if not login_required and not use_defaults:
            login_required = (
                "T" if click.confirm("Require users to log in", default="T") else "F"
            )
        else:
            login_required = "T" if login_required else "F"
        if not allow_pairs and not use_defaults:
            allow_pairs = (
                "T"
                if click.confirm("Enable pair programming support", default=False)
                else "F"
            )
        else:
            allow_pairs = "T" if allow_pairs else "F"

        res = execute(filegql("getCourseIdByName"),
                      variable_values={'courseName': course_name})

        if res['courses'] == []:
            done = True
        else:
            click.confirm(
                "Course {} already exists continue with a different name?".format(
                    course_name
                ),
                default=True,
                abort=True,
            )

    res = execute(filegql("createCourse"), variable_values={
        'courseName': course_name,
        'baseCourseName': basecourse,
        'python3' : python3,
        'term_start_date' : start_date,
        'login_required' : login_required,
        'institution' : institution,
        'allow_pairs' : allow_pairs,
    })

    click.echo(res)

    click.echo("Course added to DB successfully")

###################
## import students
###################


@cli.command()
@click.option("--csvfile", help="path to the csv file to load the class from")
@click.option("--course-name", default='doi', help="course to add the students into")
@click.option("--delimiter", default=';', help="CSV field delimiter")
@click.option("--quotechar", default='"', help="Character used to delimit single fields containing delimiter")
@click.option("--passwd-from-csvfile", is_flag=True, default=False, help="Indicate if password should be read from csv file")
@pass_config
def import_students(config, csvfile, course_name, delimiter, quotechar, passwd_from_csvfile):
    """Loads a class of students from a csv file into the database"""
    client = create_client(config)

    # check whether course with `course_name` exists and gets id
    course_id = get_course_id_by_name(client, course_name)
    if config.verbose:
        click.echo(f"Found course `{course_name}` with id={course_id}")
    if course_id is None:
        click.echo(f"Unable to find course with course_name={course_name}. Aborting!")
        sys.exit(1)

    # il faut mettre l'encoding utf-8-sig pour qu'il n'y ait pas le
    # caractère BOM pour dire si c'est du little ou du big indian
    # https://stackoverflow.com/questions/17912307/u-ufeff-in-python-string
    with open(csvfile, 'r', encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=delimiter, quotechar=quotechar)

        users = []

        try:
            for line, student in enumerate(reader):
                userinfo = map_fields_to_userinfo(student)
                userinfo['course_name'] = course_name
                userinfo['instructor'] = False
                userinfo['course_id'] = course_name

                # Check if user already exists or create her
                user = get_user_by_userinfo(client, userinfo)
                if user:
                    config.verbose and click.echo(
                        f"Found existing user with id={user['id']} and email={user['email']}, currently in course_name={user['course_name']}")
                else:
                    # create user if non existent
                    config.verbose and click.echo(
                        f"User with email={userinfo['email']} not found! Creating new user ... with password={userinfo['password']}")
                    try:
                        userinfo['password'] = student.get(
                            'Mot de passe', None) or generate_random_password(length=5)
                        click.echo(f"Password for user {userinfo['username']} => {userinfo['password']}")

                        user = create_user(client, userinfo)
                    except TransportQueryError as e:
                        click.echo(
                            f"Unable to create user with email={userinfo['email']}: {str(e)}")
                        continue

                # add the user as a student in the desired course
                insert_user_courses_one = add_student_to_course(client, course_id, user)
                print(insert_user_courses_one)
        except UnicodeDecodeError as e:
            click.echo(f"Unable to load student : {str(e)}")



'''

Examples

*   dbmanage add-course --basecourse doi-2gy-20-21 --institution "Collège du Sud" --start-date 2020-08-31 doi-2gy5

'''