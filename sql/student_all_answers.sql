-- all answers from a particular student to all exercises matching a certain pattern
SELECT
    div_id,
    first_name,
    last_name,
    act,
    timestamp,
    event,
    div_id
FROM
    useinfo
    LEFT JOIN auth_user ON useinfo.sid = auth_user.username
WHERE
    useinfo.course_id LIKE '%1gy5'
    AND first_name LIKE '%Noémie%'
    AND last_name LIKE '%%'
    AND event <> 'page'
ORDER BY
    timestamp DESC
LIMIT 50;

