SELECT DISTINCT
    auth_user.last_name AS "Nom",
    auth_user.first_name AS "Prénom",
    act AS "Réponse",
    useinfo.timestamp AS "quand ?"
FROM useinfo 
LEFT JOIN auth_user ON useinfo.sid = auth_user.username
LEFT JOIN questions ON useinfo.div_id = questions.name
WHERE div_id LIKE 'zpd4r1DM0qg' 
    AND useinfo.course_id LIKE 'doi-1920-1gy11' 
ORDER BY auth_user.last_name, auth_user.first_name, useinfo.timestamp desc
