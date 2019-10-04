SELECT
    auth_user.username,
    ROLE,
    courses.course_name,
    user_courses.*
FROM
    auth_user
    LEFT JOIN auth_membership ON auth_membership.user_id = auth_user.id
    LEFT JOIN auth_group ON auth_group.id = auth_membership.group_id
    LEFT JOIN user_courses ON user_courses.user_id = auth_user.id
    LEFT JOIN courses ON courses.id = user_courses.course_id
WHERE
    ROLE = upper('1gy7')
    AND courses.course_name = 'doi';

