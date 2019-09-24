SELECT
    *
FROM
    auth_group
    LEFT JOIN auth_group_validity ON auth_group_validity.auth_group_id = auth_group.id
WHERE
    auth_group.id > 0 --{{cond}}
