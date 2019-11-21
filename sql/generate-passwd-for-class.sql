SELECT
    'rsmanage resetpw --username ' || auth_user.username || ' --password ' || random_passwd (5)
FROM
    auth_user
    LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
    LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
WHERE
    auth_group.role LIKE '1GY3';

