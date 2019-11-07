import fileinput
import csv


def transform_comment(comment):
    if comment == "NULL":
        comment = ""

    comment = comment.replace("'", "''")
    comment = comment.replace('"', r'\"')

    return comment


score_reader = csv.DictReader(fileinput.input(), delimiter=',', quotechar='"')
table = "question_grades"
for row in score_reader:
    id = row["id"]
    score = row["score"]
    comment = transform_comment(row["comment"])

    sql = f'UPDATE {table} SET score={score}, comment=\'{comment}\' WHERE id={id};'
    print(sql)

    # id
    # # sid
    # # course_name
    # # div_id
    # # useinfo_id
    # # deadline
    # # score
    # # comment
    # 3
