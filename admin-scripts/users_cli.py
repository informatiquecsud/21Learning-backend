import csv
import sys
import os

from common import *
from users import *

import courses

from utils import charsets

###################
## import students
###################

# TODO: Has some bugs and doesn't work
@cli.command()
@click.option("--coursename", "-c", type=str, help="course to add the user to")
@click.argument("username", type=str)
@pass_config
def user_add_to_course(config, coursename, username):
    client = create_client(config)
    userinfo = {'username': username}
    try:
        res = add_user_to_course_by_name(client, coursename, userinfo)
        if config.verbose: 
            click.echo(f"Successfully added user with username={username} to course {coursename}")
    except Exception as e:
        click.echo(f"Unable to add user '{username}'' to course '{coursename}''. Reason: {str(e)}", err=True)





@cli.command()
@click.option("--csvfile", type=click.Path(), help="path to the csv file to load the class from")
@click.option("--course-name", default='doi', help="course to add the students into")
@click.option("--delimiter", default=';', help="CSV field delimiter")
@click.option("--quotechar", default='"', help="Character used to delimit single fields containing delimiter")
@click.option("--passwd-from-csvfile", is_flag=True, default=False, help="Indicate if password should be read from csv file")
@pass_config
def import_students(config, csvfile, course_name, delimiter, quotechar, passwd_from_csvfile):
    """Loads a class of students from a csv file into the database"""
    client = create_client(config)

    # check whether course with `course_name` exists and gets id
    course_id = courses.get_course_id_by_name(client, course_name)
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

        for line, student in enumerate(reader):
            try:
                userinfo = map_fields_to_userinfo(student)
                userinfo['course_name'] = course_name
                userinfo['instructor'] = False
                userinfo['course_id'] = course_name
                if config.verbose: 
                    click.echo(f"Userinfo: {userinfo}")

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
                        click.echo(
                            f"Password for user {userinfo['username']} => {userinfo['password']}")

                        user = create_user_helper(client, userinfo)
                    except TransportQueryError as e:
                        click.echo(
                            f"Unable to create user with email={userinfo['email']}: {str(e)}")
                        continue

                # add the user as a student in the desired course
                insert_user_courses_one = add_user_to_course(client, course_id, user)
                print(insert_user_courses_one)
            except Exception as e:
                click.echo(f"Unable to load student : {str(e)}")


@cli.command()
@click.argument('username', type=str)
@pass_config
def create_user(config, username):
    pass


@cli.command()
@click.option("--instructor", is_flag=True, help="Make this user an instructor")
@click.option(
    "--fromfile",
    default=None,
    type=click.File(mode="r"),
    help="read a csv file of users of the form username, email, first_name, last_name, password, course",
)
@click.option("--username", help="Username, must be unique")
@click.option("--password", help="password - plaintext -- sorry")
@click.option("--first_name", help="Real first name")
@click.option("--last_name", help="Real last name")
@click.option("--email", help="email address for password resets")
@click.option("--course", help="course to register for")
@pass_config
def inituser(
    config,
    instructor,
    fromfile,
    username,
    password,
    first_name,
    last_name,
    email,
    course,
):
    """Add a user (or users from a csv file)"""
    os.chdir(findProjectRoot())

    if fromfile:
        # if fromfile then be sure to get the full path name NOW.
        # csv file should be username, email first_name, last_name, password, course
        # users from a csv cannot be instructors
        for line in csv.reader(fromfile):
            if len(line) != 6:
                click.echo("Not enough data to create a user.  Lines must be")
                click.echo("username, email first_name, last_name, password, course")
                exit(1)
            if "@" not in line[1]:
                click.echo("emails should have an @ in them in column 2")
                exit(1)
            userinfo = {}
            userinfo["username"] = line[0]
            userinfo["password"] = line[4]
            userinfo["first_name"] = line[2]
            userinfo["last_name"] = line[3]
            userinfo["email"] = line[1]
            userinfo["course"] = line[5]
            userinfo["instructor"] = False
            os.environ["RSM_USERINFO"] = json.dumps(userinfo)
            res = subprocess.call(
                "python web2py.py --no-banner -S runestone -M -R applications/runestone/rsmanage/makeuser.py",
                shell=True,
            )
            if res != 0:
                click.echo(
                    "Failed to create user {} error {} fix your data and try again".format(
                        line[0], res
                    )
                )
                exit(1)

    else:
        userinfo = {}
        userinfo["username"] = username or click.prompt("Username")
        userinfo["password"] = password or click.prompt("Password", hide_input=True)
        userinfo["first_name"] = first_name or click.prompt("First Name")
        userinfo["last_name"] = last_name or click.prompt("Last Name")
        userinfo["email"] = email or click.prompt("email address")
        userinfo["course"] = course or click.prompt("course name")
        if not instructor:
            if (
                username and course
            ):  # user has supplied other info via CL parameter safe to assume False
                userinfo["instructor"] = False
            else:
                userinfo["instructor"] = click.confirm(
                    "Make this user an instructor", default=False
                )

        os.environ["RSM_USERINFO"] = json.dumps(userinfo)
        res = subprocess.call(
            "python web2py.py --no-banner -S runestone -M -R applications/runestone/rsmanage/makeuser.py",
            shell=True,
        )
        if res != 0:
            click.echo(
                "Failed to create user {} error {} fix your data and try again. Use --verbose for more detail".format(
                    userinfo["username"], res
                )
            )
            exit(1)
        else:
            click.echo("Success")


@cli.command()
@click.option("--username", help="Username, must be unique")
@click.option("--password", help="password - plaintext -- sorry")
@click.option("--random-password", type=str, is_flag=True, default=False, help="generates random password")
@click.option("--output-format", type=click.Choice(['csv', 'json'], case_sensitive=False), default='csv', help="format to print the new password")
@click.option("--password-length", type=int, default=5, help="number of chars in the password to generate", show_default=True)
@click.option("--alphabet", type=click.Choice(charsets.keys()), default='digits', help="charaset to choose from")
@pass_config
def resetpw(config, username, password, random_password, output_format, password_length, alphabet, group=None):
    client = create_client(config)

    if random_password:
        password = generate_random_password(password_length)

    """Utility to change a users password. Useful If they can't do it through the normal mechanism"""
    userinfo = {}
    userinfo["username"] = username or click.prompt("Username")
    userinfo["password"] = password or click.prompt("Password", hide_input=True)

    try:
        res = exec_with_fields(client, filegql('resetPassword'),
                               userinfo, ['username', 'password'])

        if config.verbose:
            click.echo(res)

        if res['update_auth_user']['affected_rows'] > 0:
            click.echo(f"Password successfully changed for user {userinfo['username']}")
            if output_format == 'csv':
                click.echo(f"{username};{password}")
            elif output_format == 'json':
                userdict = {}
                userdict['username'] = username
                uesrdict['password'] = password
                click.echo({'user': userdict})
                

        else:
            click.echo(f"No password changed for user {userinfo['username']}", err=True)

    except Exception as e:
        click.echo(f"Error while trying to change password: {str(e)}")


# @cli.command()
# @click.argument("course", type=str)
# @click.option("--password-length", type=int, default=5, help="number of chars in the password to generate", show_default=True)
# @click.option("--alphabet", type=click.Choice(charsets.keys()), default='digits', help="charaset to choose from")
# @click.option("--password", type=str, help="password for every user in the course")
# @pass_config
# def resetpw_for_course(config, course, password_length, alphabet, password):
#     # get the user list from the course `course`

#     # for each user, reset the password
#     password = password or generate_random_password(
#         length=password_length, alphabet=alphabet)
#     if config.verbose:
#         print('generated password', password)


