DELETE FROM auth_user
WHERE id IN (
        SELECT
            u.id
        FROM
            auth_user AS u
        LEFT JOIN auth_membership AS m ON m.user_id = u.id
        LEFT JOIN auth_group AS g ON g.id = m.group_id
    WHERE
        m.group_id IS NULL);

