SELECT
    u.id,
    u.username,
    u.email,
    g.role
FROM
    auth_user AS u
    LEFT JOIN auth_membership AS m ON m.user_id = u.id
    LEFT JOIN auth_group AS g ON g.id = m.group_id
GROUP BY
    u.id,
    g.role
ORDER BY
    g.role,
    u.username
