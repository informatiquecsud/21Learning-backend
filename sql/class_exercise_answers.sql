-- all answers from class like 1gy_ to exercice with div_id like data-ch1__35-a
SELECT
    div_id,
    first_name,
    last_name,
    act,
    timestamp
FROM
    useinfo
    LEFT JOIN auth_user ON useinfo.sid = auth_user.username
WHERE
    useinfo.course_id LIKE '%1gy5'
    AND div_id LIKE 'data-ch1%35-a'
ORDER BY
    timestamp DESC
LIMIT 50;

