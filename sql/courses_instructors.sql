SELECT
    u.username,
    u.email,
    c.course_name
FROM
    auth_user AS u
    LEFT JOIN auth_membership AS m ON m.user_id = u.id
    LEFT JOIN auth_group AS g ON g.id = m.group_id
    LEFT JOIN course_instructor ON course_instructor.instructor = u.id
    LEFT JOIN courses AS c ON c.id = course_instructor.course
WHERE
    g.role = 'instructor'
