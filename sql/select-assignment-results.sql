SELECT
    g.*,
    REPLACE(u.act, E'\n', '||') AS "answer"
FROM
    question_grades AS g
    INNER JOIN useinfo AS u ON g.useinfo_id = u.id
WHERE
    g.course_name LIKE '%1gy5'
    AND g.div_id LIKE 'exa1C%'
ORDER BY
    g.div_id,
    g.sid;

