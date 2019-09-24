DELETE FROM auth_user
WHERE id IN (
        SELECT
            auth_user.id
        FROM
            auth_group
        LEFT JOIN auth_membership ON auth_membership.group_id = auth_group.id
        LEFT JOIN auth_user ON auth_user.id = auth_membership.user_id
    WHERE
        auth_group.id = {id});

