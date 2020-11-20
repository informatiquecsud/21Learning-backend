import click

from common import *
from courses_cli import *
from users_cli import *


@cli.command()
@pass_config
def show_config(config):
    click.echo(str(config))


'''

Examples

dbmanage add-course --basecourse doi-2gy-20-21 --institution "Collège du Sud" --start-date 2020-08-31 doi-2gy5
dbmanage import-students --csvfile ../data/2gy5.csv --course-name  doi-2gy5

'''