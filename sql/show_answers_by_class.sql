SELECT
    auth_user.last_name AS "Nom",
    auth_user.first_name AS "Prénom",
    act AS "Réponse",
    useinfo.timestamp AS "quand ?",
    questions.question AS "Donnée"
FROM
    useinfo
    LEFT JOIN auth_user ON useinfo.sid = auth_user.username
    LEFT JOIN questions ON useinfo.div_id = questions. "name"
WHERE
    div_id = 'data-ch1-exo-37-b'
    AND useinfo.course_id LIKE 'doi%1gy5'
    --ORDER BY auth_user.last_name, auth_user.first_name
ORDER BY
    useinfo.timestamp;

