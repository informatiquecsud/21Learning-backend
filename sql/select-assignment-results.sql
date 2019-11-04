SELECT
    g.*,
    SPLIT_PART(REPLACE(REPLACE(u.act, E'\n', ''), '====', '|'), '|', 1) AS "answer"
FROM
    question_grades AS g
    INNER JOIN useinfo AS u ON g.useinfo_id = u.id
WHERE
    g.course_name LIKE '%1gy5'
    AND g.div_id LIKE 'exa1A%'
ORDER BY
    g.div_id;

