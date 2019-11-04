UPDATE
    question_grades
SET
    score = 2
WHERE
    question_grades.useinfo_id IN (
        SELECT
            u.id
        FROM
            question_grades AS g
            INNER JOIN useinfo AS u ON g.useinfo_id = u.id
        WHERE
            g.course_name LIKE '%1gy5'
            AND g.div_id LIKE 'exa1A%'
            AND substring(u.act FROM '1813') = '1813'
        ORDER BY
            g.div_id,
            g.sid);

