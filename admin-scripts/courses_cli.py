import sys
import os

from common import *
from courses import *

import utils
import users

###################
## courses-ls
###################


@cli.command()
@click.option('--only-base', is_flag=True, default=False, help='shows only base courses that have no parent (NOT IMPLEMENTED)')
@pass_config
def courses_ls(config, only_base):
    client = create_client(config)
    courses = courses_ls(client, only_base)
    for  course in courses:
        click.echo(f"Course {course['course_name']} with id={course['id']}")


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
def course_add(
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


# TODO: I don't understand how to use the context ctx to pass objects around
# like the api client => ctx.obj is None
def autocomplete_username(ctx, args, incomplete):
    userinfo = {'username': incomplete}
    return  []
    # return utils.dict_project(
    #     users.findUsers(ctx.obj['client'], userinfo),
    #     fields=['username']
    # )


@cli.command()
@click.argument("coursename", type=str)
@click.option("--username", "-u", type=str, autocompletion=autocomplete_username)
@pass_config
def course_add_teacher(config, coursename, username):
    client = create_client(config)
    course_id = get_course_id_by_name(client, coursename)
    user = users.get_user_by_userinfo(client, {'username': username})

    if config.verbose: print(course_id, user['id'])

    # make this user a participant to the course
    userinfo = {'username': username, 'id': user['id']}
    res = users.add_user_to_course(client, course_id, userinfo)

    # make this user a teacher for the course
    res = client.execute(filegql('makeInstructorForCourse'), variable_values={
        'userId': user['id'],
        'courseId': course_id
    })


    
    
    
    